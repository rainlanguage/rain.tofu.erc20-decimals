<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Security Audit — Pass 1

**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Auditor:** A05
**Date:** 2026-02-21

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimalsImplementation` (line 13)

### Functions and Line Numbers

| Function | Visibility | Mutability | Line |
|---|---|---|---|
| `decimalsForTokenReadOnly` | `internal` | `view` | 29 |
| `decimalsForToken` | `internal` | (non-payable) | 108 |
| `safeDecimalsForToken` | `internal` | (non-payable) | 135 |
| `safeDecimalsForTokenReadOnly` | `internal` | `view` | 159 |

### Types, Errors, and Constants Defined

**Imported from `ITOFUTokenDecimals.sol`:**

- `struct TOFUTokenDecimalsResult` — `{ bool initialized; uint8 tokenDecimals; }`
- `enum TOFUOutcome` — `Initial (0)`, `Consistent (1)`, `Inconsistent (2)`, `ReadFailure (3)`
- `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`

**Defined in this library:**

- `bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567` (line 15) — the ABI selector for `decimals()`

### Assembly Block — Opcode-by-Opcode Analysis

The assembly block appears inside `decimalsForTokenReadOnly` at lines 45–57:

```solidity
assembly ("memory-safe") {
    mstore(0, selector)
    success := staticcall(gas(), token, 0, 0x04, 0, 0x20)
    if lt(returndatasize(), 0x20) {
        success := 0
    }
    if success {
        readDecimals := mload(0)
        if gt(readDecimals, 0xff) {
            success := 0
        }
    }
}
```

| Operation | What it does |
|---|---|
| `mstore(0, selector)` | Writes the 4-byte `decimals()` selector right-padded with 28 zero bytes into scratch space at memory offset 0x00–0x1f. Because `mstore` writes a full 32-byte word, only bytes 0x00–0x03 contain the selector; bytes 0x04–0x1f are zeroed. |
| `staticcall(gas(), token, 0, 0x04, 0, 0x20)` | Calls `token.decimals()` with no ETH, forwarding all remaining gas. Calldata is bytes 0x00–0x03 (the selector, 4 bytes). Return data is written into memory at offset 0x00–0x1f (32 bytes max). Returns 1 on success, 0 on revert/failure. |
| `if lt(returndatasize(), 0x20) { success := 0 }` | If the callee returned fewer than 32 bytes, force-fails success. Rejects empty returns, reverts, and short non-ABI returns. |
| `if success { readDecimals := mload(0) ... }` | Only runs if the call succeeded and returned ≥ 32 bytes. Loads the 32-byte word that was written into offset 0x00 by `staticcall`. |
| `if gt(readDecimals, 0xff) { success := 0 }` | Rejects any value that does not fit in a `uint8`. ABI-encoded `uint8` values must be zero-padded to 32 bytes, so a well-formed response will always be ≤ 0xff. Values > 0xff indicate either a non-uint8 return type or a malformed token. |

---

## Security Analysis

### 1. Assembly block memory safety

**Scratch space usage:** EVM free memory begins at 0x80 by convention. Bytes 0x00–0x3f are scratch space; Solidity makes no guarantees about their content and compilers may clobber them freely between statements. The code uses 0x00–0x1f for both calldata (write before call) and return data (write by `staticcall`). This is a well-established pattern for low-level ABI calls.

**Out-of-bounds concern:** `mstore(0, selector)` writes exactly 32 bytes to 0x00–0x1f. `staticcall` output is bounded to 0x20 bytes at 0x00–0x1f. No write occurs outside scratch space. No allocated heap objects are at risk of being overwritten.

**`memory-safe` annotation:** The annotation promises the compiler that the assembly does not read or write memory outside scratch space (0x00–0x3f) and the function's own allocated memory. The code accesses only 0x00–0x1f, which is within scratch space. The annotation is correct.

**Calldata construction — `mload(0)` after `staticcall`:**

After `staticcall` writes the 32-byte return value into offset 0x00, `mload(0)` reads the full 32-byte word that was just deposited. This word is the ABI-encoded `uint256` (or `uint8`) value returned by `decimals()`. The subsequent `gt(readDecimals, 0xff)` check validates that it fits in a `uint8`.

One subtlety: `mstore(0, selector)` writes bytes 0x00–0x03 as the selector and zeroes bytes 0x04–0x1f. After `staticcall` writes to 0x00–0x1f, the original contents of those bytes are fully overwritten by the callee's return data (or remain as written by `mstore` if `returndatasize` is 0 and the call succeeds, but that case is already rejected by the `lt(returndatasize(), 0x20)` guard). So `mload(0)` reliably reads the callee-supplied word. No stale-selector contamination of the loaded value is possible.

### 2. The `staticcall` pattern

**Calldata:** Bytes 0x00–0x03, length 4. Correctly encodes the bare `decimals()` call with no arguments.

**Return data handling:** Return data is written directly into scratch space at 0x00. The code does not use `returndatacopy`; instead it specifies an output buffer in the `staticcall` arguments. EVM semantics: if `returndatasize` < 0x20, only that many bytes are written, and the rest of the output buffer is unchanged (i.e., they retain whatever `mstore(0, selector)` wrote). However, the `lt(returndatasize(), 0x20)` check fires first and sets `success := 0` before `mload(0)` is ever reached, so stale bytes in the output buffer from the short-return path cannot affect `readDecimals`.

**Failure modes handled:**
- Revert in callee: `staticcall` returns 0 → `success` is already 0, early return with `ReadFailure`.
- Empty return (e.g. EOA/non-contract): `staticcall` may return 1 with `returndatasize()` = 0 → caught by the `lt(returndatasize(), 0x20)` guard.
- Short return (< 32 bytes): caught by the same guard.
- Return value too large for `uint8`: caught by `gt(readDecimals, 0xff)`.
- `address(0)` target: `staticcall` to address 0 calls the identity precompile, which echoes its input. The 4-byte selector calldata will be returned as 4 bytes. `returndatasize()` will be 4, which is less than 0x20, so the guard fires and `success` is set to 0 → `ReadFailure`. Confirmed correct by the test `testDecimalsForTokenReadOnlyAddressZero`.

### 3. `returndatasize` check

`if lt(returndatasize(), 0x20) { success := 0 }` — requires at least 32 bytes of return data for success to remain true. This is the correct minimum for a well-formed ABI-encoded value. The check correctly rejects all non-conforming returns.

### 4. `gt(readDecimals, 0xff)` uint8 range check

`readDecimals` is a `uint256` Yul variable (stack slot). After `mload(0)` it contains the full 32-byte word returned by the callee. A compliant ERC-20 `decimals()` returning `uint8` will ABI-encode the value as a 32-byte big-endian word with 31 leading zero bytes, so the value will always be 0–255. The check `gt(readDecimals, 0xff)` correctly rejects any value > 255. This handles the case where a broken token returns a `uint256` that does not fit in `uint8`.

### 5. State consistency — storage writes only on `Initial`

In `decimalsForToken` (line 118):

```solidity
if (tofuOutcome == TOFUOutcome.Initial) {
    sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: readDecimals});
}
```

Storage is written **only** when `tofuOutcome == TOFUOutcome.Initial`, which is returned from `decimalsForTokenReadOnly` only when `!tofuTokenDecimals.initialized` is true (i.e., no prior value stored) and the read succeeded. `Consistent`, `Inconsistent`, and `ReadFailure` never cause a write. This is correct.

### 6. Reentrancy

`staticcall` is used, which prohibits state modification in the callee. It is impossible for the callee to re-enter `decimalsForToken` or `safeDecimalsForToken` and cause a state mutation during the external call. The `view` modifier on `decimalsForTokenReadOnly` additionally prohibits state writes in that function. No reentrancy vector exists.

### 7. Error handling — all paths

| Condition | Path | Outcome |
|---|---|---|
| `staticcall` returns 0 (revert) | `success = false` from opcode | `ReadFailure` |
| `returndatasize() < 0x20` | `success := 0` in assembly | `ReadFailure` |
| `readDecimals > 0xff` | `success := 0` in assembly | `ReadFailure` |
| Read success, `!initialized` | `Initial` branch | `Initial` (+ store in `decimalsForToken`) |
| Read success, `initialized`, values match | `Consistent` branch | `Consistent` |
| Read success, `initialized`, values differ | `Inconsistent` branch | `Inconsistent` |

All paths are accounted for. `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` correctly treat only `Initial` and `Consistent` as success, reverting on `Inconsistent` and `ReadFailure`.

### 8. `safeDecimalsForTokenReadOnly` — TOFU guarantee absent before initialization

This is documented explicitly in the NatSpec (lines 148–151) and is an inherent design trade-off, not a bug: without storing state, every call before initialization is a fresh `Initial` read, so inconsistency between two consecutive `safeDecimalsForTokenReadOnly` calls on a token that changes its return value between those calls cannot be detected. The warning is present in the code comments. This is `INFO` level — acknowledged design limitation, correctly documented.

---

## Findings

### INFO-01: `safeDecimalsForTokenReadOnly` provides no TOFU protection before first store

**Severity:** INFO

**Location:** `safeDecimalsForTokenReadOnly`, lines 159–169; NatSpec warning at lines 148–151.

**Description:** Until `decimalsForToken` has been called at least once for a given token, every invocation of `safeDecimalsForTokenReadOnly` will return `TOFUOutcome.Initial` and will not detect any inconsistency between calls. A token that changes its `decimals()` return value between two read-only calls will silently return different values on each call.

**Assessment:** This is a documented design limitation, not a vulnerability. The NatSpec explicitly warns callers. No fix is required; callers are responsible for ensuring initialization before relying on the read-only variant for TOFU protection.

---

## Summary

No security vulnerabilities were identified. The assembly block is memory-safe, uses scratch space correctly, and handles all failure modes. The `staticcall` pattern is correctly constructed. The `returndatasize` check and `uint8` range check together ensure only well-formed `uint8`-valued responses are accepted. Storage writes occur only on the `Initial` path. `staticcall` prevents reentrancy. All error paths produce correct and consistent outcomes. One INFO-level design limitation is present and correctly documented in the source.
