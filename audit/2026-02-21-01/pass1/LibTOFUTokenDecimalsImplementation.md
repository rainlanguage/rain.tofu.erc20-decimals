# Audit Pass 1 (Security) -- LibTOFUTokenDecimalsImplementation.sol

**Agent ID:** A04
**Date:** 2026-02-21
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Solidity Version:** `^0.8.25`

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimalsImplementation` (line 18)

### Functions

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `decimalsForTokenReadOnly` | 34 | `internal` | `view` |
| `decimalsForToken` | 113 | `internal` | (state-modifying) |
| `safeDecimalsForToken` | 140 | `internal` | (state-modifying) |
| `safeDecimalsForTokenReadOnly` | 161 | `internal` | `view` |

### Types, Errors, and Constants

**Constant (defined in this library):**
- `TOFU_DECIMALS_SELECTOR` (line 20): `bytes4` constant set to `0x313ce567` (the `decimals()` function selector).

**Types (imported from `ITOFUTokenDecimals.sol`):**
- `TOFUTokenDecimalsResult` -- struct with fields `bool initialized` and `uint8 tokenDecimals`.
- `TOFUOutcome` -- enum with values `Initial` (0), `Consistent` (1), `Inconsistent` (2), `ReadFailure` (3).

**Errors (imported from `ITOFUTokenDecimals.sol`):**
- `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`.

### Imports (line 5-10)

```solidity
import {
    ITOFUTokenDecimals,
    TOFUTokenDecimalsResult,
    TOFUOutcome,
    TokenDecimalsReadFailure
} from "../interface/ITOFUTokenDecimals.sol";
```

Note: `ITOFUTokenDecimals` is imported but not directly used in this library (it is only used by the concrete contract). This is not a security issue.

---

## Security Findings

### F-01: Scratch Space Write at Memory Address 0 -- Correctness of `memory-safe` Annotation

**Severity:** INFO

**Location:** Lines 50-62

**Description:**

The assembly block writes the 4-byte function selector to memory address 0 via `mstore(0, selector)` and reads 32 bytes of return data back into memory address 0 via the `staticcall` output parameters `(0, 0x20)`. It then reads the value back with `mload(0)`.

Solidity reserves memory addresses `0x00`-`0x3f` as "scratch space" specifically for short-term use. The `memory-safe` annotation requires that the assembly block either (a) only accesses memory it allocates via the free memory pointer, or (b) only uses scratch space at `0x00`-`0x3f` without moving the free memory pointer. This block uses scratch space exclusively and does not modify the free memory pointer, which is correct.

However, the function also reads a `memory` struct before the assembly block (line 39: `TOFUTokenDecimalsResult memory tofuTokenDecimals = sTOFUTokenDecimals[token]`). Since this struct is allocated via the free memory pointer (at `0x80` or later), and the assembly only touches addresses `0x00`-`0x1f`, there is no overlap. The `memory-safe` annotation is **correct**.

**Recommendation:** No action needed. The annotation is accurate.

---

### F-02: `staticcall` Gas Forwarding -- All Remaining Gas Passed to External Contract

**Severity:** LOW

**Location:** Line 52

```solidity
success := staticcall(gas(), token, 0, 0x04, 0, 0x20)
```

**Description:**

The `staticcall` forwards all remaining gas via `gas()`. A malicious or poorly written token contract could consume nearly all remaining gas in the `decimals()` call before returning (or reverting). Since `staticcall` cannot modify state, this cannot cause a reentrancy attack, but it could be used as a gas-griefing vector: a caller invoking `decimalsForToken` on a malicious token could have most of their gas consumed, causing the outer transaction to fail due to out-of-gas.

In practice, `decimals()` is expected to be a trivial view function. Passing all gas is the standard Solidity pattern for external calls and avoids the complexity of estimating a fixed gas stipend that must account for varying chain-specific costs.

**Recommendation:** Acceptable as-is. A fixed gas stipend (e.g., `2300` or `50000`) would harden against gas griefing but risks breaking on future EVM gas schedule changes or behind proxy contracts. The current approach is the more robust and standard choice.

---

### F-03: Return Data Size Validation

**Severity:** INFO

**Location:** Lines 53-55

```solidity
if lt(returndatasize(), 0x20) {
    success := 0
}
```

**Description:**

After a successful `staticcall`, the code checks that at least 32 bytes were returned. If fewer than 32 bytes are returned, `success` is set to 0, causing a `ReadFailure` outcome. This correctly handles:

- EOA addresses (no code, `staticcall` succeeds with 0 return data)
- Contracts that return fewer than 32 bytes
- Contracts with a fallback that returns no data

The check does not validate that the return data is *exactly* 32 bytes -- it allows larger return data. This is acceptable because the code only reads the first 32 bytes, and valid ABI-encoded `uint8` values always pad to 32 bytes. Tokens that return more data (e.g., with extra padding) are handled correctly since only the first word is loaded.

**Recommendation:** No action needed. The check is correct and sufficient.

---

### F-04: `uint8` Bounds Check on Read Decimals

**Severity:** INFO

**Location:** Lines 58-60

```solidity
if gt(readDecimals, 0xff) {
    success := 0
}
```

**Description:**

The `mload(0)` at line 57 loads a full 32-byte word from memory. If the token returns a value that is a valid `uint256` but exceeds `0xff` (255), it cannot represent a valid `uint8` decimals value. The code correctly treats this as a read failure rather than silently truncating.

This is important because without this check, a malicious token returning e.g. `256` would have that value silently truncated to `0` when cast to `uint8` at line 76, which could be exploited to manipulate decimal-dependent calculations.

**Recommendation:** No action needed. The bounds check is correct and critical for safety.

---

### F-05: Calling `decimals()` on Address Zero or EOA

**Severity:** INFO

**Location:** Line 52

**Description:**

When `token` is `address(0)` or any EOA (externally owned account), `staticcall` succeeds (returns `true`) but returns 0 bytes of data. The `returndatasize() < 0x20` check (line 53) catches this and sets `success` to `false`, correctly resulting in a `ReadFailure` outcome.

This is verified by the tests `testDecimalsForTokenReadOnlyAddressZero` and `testDecimalsForTokenAddressZero`.

**Recommendation:** No action needed. Handled correctly.

---

### F-06: Memory Contents at Address 0 After Failed `staticcall`

**Severity:** INFO

**Location:** Lines 50-62

**Description:**

When `staticcall` fails (returns `false`), the output buffer at address 0 is not written to -- the EVM does not copy return data on a failed call. The memory at address 0 will still contain the left-aligned selector bytes from the `mstore(0, selector)` at line 51. However, because `success` is `false`, the code never reads from address 0 (the `if success` guard at line 56 prevents it). The `readDecimals` variable retains its initialized value of `0`.

When `staticcall` succeeds but `returndatasize() < 0x20`, the same guard applies: `success` is set to `0` before the `mload(0)` would execute.

**Recommendation:** No action needed. The control flow is correct.

---

### F-07: State Consistency Between `decimalsForTokenReadOnly` and `decimalsForToken`

**Severity:** INFO

**Location:** Lines 113-127

**Description:**

`decimalsForToken` delegates the read logic entirely to `decimalsForTokenReadOnly` and only writes storage when the outcome is `Initial` (line 123-124). This means:

- `ReadFailure` never triggers a storage write (correct -- do not persist failures).
- `Consistent` never triggers a storage write (correct -- value already stored).
- `Inconsistent` never triggers a storage write (correct -- the original trusted value is preserved).

The storage write on `Initial` correctly sets both `initialized = true` and `tokenDecimals = readDecimals`, where `readDecimals` has already been validated as fitting in `uint8` by the assembly bounds check.

**Recommendation:** No action needed. The state management is correct.

---

### F-08: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` Revert Logic

**Severity:** INFO

**Location:** Lines 146-148 and 167-168

```solidity
if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
    revert TokenDecimalsReadFailure(token, tofuOutcome);
}
```

**Description:**

Both safe variants revert on `Inconsistent` and `ReadFailure`, and allow `Initial` and `Consistent` through. This is correct: `Initial` is the successful first-read case, and `Consistent` is the successful subsequent-read case.

Notably, `safeDecimalsForToken` calls `decimalsForToken` (the write variant), so on `Initial` the storage is written before the function returns. `safeDecimalsForTokenReadOnly` calls `decimalsForTokenReadOnly`, so no storage is ever written. The revert condition is identical in both, which is correct -- both should reject the same failure modes.

One behavioral note: `safeDecimalsForTokenReadOnly` when called on an uninitialized token will succeed with `TOFUOutcome.Initial` and return the live-read value without persisting it. On a subsequent call (still uninitialized), it will read again and return whatever the token says at that point, potentially a different value, both times as `Initial`. This is documented in the interface and is by-design, but callers should be aware that read-only does not provide TOFU guarantees on its own.

**Recommendation:** No action needed. The logic is correct and the behavioral nuance is documented.

---

### F-09: `staticcall` Output Buffer Overwrites Selector in Scratch Space

**Severity:** INFO

**Location:** Lines 51-52

```solidity
mstore(0, selector)
success := staticcall(gas(), token, 0, 0x04, 0, 0x20)
```

**Description:**

The `mstore(0, selector)` writes the 4-byte selector left-aligned into the 32-byte word at address 0 (bytes 0-3 contain the selector, bytes 4-31 are zeroed). The `staticcall` then reads 4 bytes starting at address 0 as input (correct), and writes up to 32 bytes of return data starting at address 0 as output (overwriting the selector).

This is safe because the selector is only needed as input to the `staticcall` and is never referenced again after the call. The output buffer placement at address 0 is an efficient use of scratch space.

**Recommendation:** No action needed. This is a correct and gas-efficient pattern.

---

### F-10: Potential for Inconsistent Behavior if Token `decimals()` Is Not Deterministic

**Severity:** LOW

**Location:** Lines 34-84 (overall `decimalsForTokenReadOnly` logic)

**Description:**

The TOFU model assumes that once a token's decimals are read and stored, subsequent reads will be compared against the stored value. If a token has a non-deterministic `decimals()` function (e.g., one that changes based on block number, timestamp, or some admin action), the following scenario is possible:

1. First call to `decimalsForToken`: reads `18`, stores `18`, returns `(Initial, 18)`.
2. Token admin changes decimals to `6`.
3. Second call: reads `6`, stored is `18`, returns `(Inconsistent, 18)`.

The library correctly handles this by returning the *stored* value (not the new live value) along with the `Inconsistent` outcome. This prevents silent corruption. The caller is responsible for deciding how to handle inconsistency. This is exactly the designed behavior and is well-documented.

**Recommendation:** No action needed. This is the intended design and is correctly implemented.

---

### F-11: No Reentrancy Risk Due to `staticcall`

**Severity:** INFO

**Location:** Line 52

**Description:**

The use of `staticcall` rather than `call` means the called contract cannot modify state, emit events, or make further state-changing calls. This eliminates reentrancy as an attack vector entirely. Even if a malicious token attempts to call back into the TOFU contract, it cannot alter the storage mapping.

Additionally, in `decimalsForToken` (the write variant), the storage write at line 124 occurs *after* the `staticcall` has completed and the result has been fully validated -- the checks-effects-interactions pattern is followed even though `staticcall` already provides sufficient protection.

**Recommendation:** No action needed.

---

### F-12: `mstore(0, selector)` Writes 32 Bytes but `selector` Is Only 4 Bytes

**Severity:** INFO

**Location:** Line 51

**Description:**

`mstore` always writes a full 32-byte word. The `selector` variable is `bytes4`, which Solidity places in the high-order (leftmost) 4 bytes of the 32-byte word, with the remaining 28 bytes zeroed. The `staticcall` reads only the first 4 bytes (`0x04` length parameter), so the zeroed trailing bytes are irrelevant.

The zeroing of bytes 4-31 is actually beneficial: when the `staticcall` output buffer writes return data to the same location, we need a clean 32-byte word. If the call succeeds but returns exactly 32 bytes, the entire word is overwritten. If the call fails or returns less, the `success` flag prevents reading from this location.

**Recommendation:** No action needed. Behavior is correct.

---

## Summary Table

| ID | Title | Severity | Status |
|---|---|---|---|
| F-01 | Scratch space write / `memory-safe` annotation correctness | INFO | Correct -- annotation is accurate |
| F-02 | `staticcall` forwards all remaining gas | LOW | Acceptable -- standard pattern, no state risk |
| F-03 | Return data size validation (`< 0x20`) | INFO | Correct and sufficient |
| F-04 | `uint8` bounds check (`> 0xff`) | INFO | Correct -- prevents silent truncation |
| F-05 | Calling `decimals()` on address(0) or EOA | INFO | Correctly handled as `ReadFailure` |
| F-06 | Memory contents after failed `staticcall` | INFO | Correct -- guarded by `success` flag |
| F-07 | State consistency between read-only and write functions | INFO | Correct -- only `Initial` triggers write |
| F-08 | Safe variant revert logic | INFO | Correct -- rejects `Inconsistent` and `ReadFailure` |
| F-09 | Output buffer overwrites selector in scratch space | INFO | Correct -- selector not needed after call |
| F-10 | Non-deterministic token `decimals()` handling | LOW | By design -- returns stored value on inconsistency |
| F-11 | No reentrancy risk due to `staticcall` | INFO | Correct -- `staticcall` prevents state modification |
| F-12 | `mstore` writes full 32-byte word for 4-byte selector | INFO | Correct -- no impact on behavior |

**Overall Assessment:** No CRITICAL, HIGH, or MEDIUM severity issues found. The inline assembly is well-written, uses scratch space correctly, validates all external call results thoroughly, and the `memory-safe` annotation is accurate. The library follows a sound defensive design with proper bounds checking, failure handling, and state isolation. The two LOW findings are inherent to the design pattern (gas forwarding is standard; non-deterministic decimals is the exact threat model TOFU addresses) and require no code changes.
