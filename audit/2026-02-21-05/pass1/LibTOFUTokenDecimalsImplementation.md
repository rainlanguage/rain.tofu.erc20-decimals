# Audit A05 - Pass 1 (Security) - LibTOFUTokenDecimalsImplementation.sol

**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Auditor:** A05
**Date:** 2026-02-21

---

## 1. Evidence of Thorough Reading

### Library Name
- `LibTOFUTokenDecimalsImplementation` (line 13)

### Functions (name + line number)
| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `decimalsForTokenReadOnly` | 29 | `internal` | `view` |
| `decimalsForToken` | 109 | `internal` | (state-modifying) |
| `safeDecimalsForToken` | 136 | `internal` | (state-modifying) |
| `safeDecimalsForTokenReadOnly` | 160 | `internal` | `view` |

### Types / Errors / Constants
| Item | Kind | Location |
|---|---|---|
| `TOFU_DECIMALS_SELECTOR` | `bytes4 constant` = `0x313ce567` | line 15 |
| `TOFUTokenDecimalsResult` | struct (imported) | `ITOFUTokenDecimals.sol` line 13 -- fields: `bool initialized`, `uint8 tokenDecimals` |
| `TOFUOutcome` | enum (imported) | `ITOFUTokenDecimals.sol` line 19 -- values: `Initial(0)`, `Consistent(1)`, `Inconsistent(2)`, `ReadFailure(3)` |
| `ITOFUTokenDecimals.TokenDecimalsReadFailure` | error (imported) | `ITOFUTokenDecimals.sol` line 52 -- params: `(address token, TOFUOutcome tofuOutcome)` |

### Imports (line 5)
- `TOFUTokenDecimalsResult`, `TOFUOutcome`, `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol`

---

## 2. Security Review

### 2.1 Assembly Block Analysis (lines 45-57)

The core assembly block in `decimalsForTokenReadOnly`:

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

#### Memory layout correctness

- `mstore(0, selector)`: Writes `0x313ce567` to memory at position 0. `mstore` writes 32 bytes, placing the 4-byte selector left-padded in the high bytes at `0x00..0x1f`. The `staticcall` then sends bytes `0x00..0x03`, which correctly contains the selector bytes.
- The `staticcall` output buffer is `(0, 0x20)`: writes return data to memory `0x00..0x1f`. This overwrites the selector, but the selector is no longer needed.
- `mload(0)`: Reads the full 32 bytes at position 0, which is the full `uint256` return value from the call. This is correct -- ABI encoding of `uint8` returns a 32-byte word with the value right-aligned.
- Memory positions `0x00-0x3f` are Solidity's scratch space, so this usage is legitimate and does not conflict with the free memory pointer or existing allocations.

#### `returndatasize() < 0x20` guard

This check ensures at least 32 bytes were returned. If a contract returns fewer bytes (e.g., raw `uint8` without ABI encoding, or empty return), the call is treated as a failure. This is correct and sufficient -- it prevents reading stale/garbage memory from position 0 if `returndatacopy` (implicitly done by the output parameters of `staticcall`) only wrote partial data. When `returndatasize() < 0x20`, the `staticcall` still writes whatever data it received to the output buffer, but the remaining bytes at position 0 would contain leftover data from the `mstore(0, selector)`. The guard correctly catches this.

#### `gt(readDecimals, 0xff)` guard

ERC20 `decimals()` returns `uint8`. ABI encoding places the value in the lowest byte of a 32-byte word. The check `gt(readDecimals, 0xff)` correctly rejects any value that does not fit in a `uint8`. This catches malicious tokens returning values like `256` or `type(uint256).max`. The subsequent `uint8(readDecimals)` cast on line 71 is safe because this guard has already verified the range.

#### `staticcall` usage

`staticcall` is used rather than `call`, which means the called token contract cannot modify state during the call. This eliminates reentrancy through the decimals read path.

#### Gas forwarding

`gas()` forwards all remaining gas to the `staticcall`. Since `staticcall` cannot modify state, the worst case is the called token consuming all gas and causing an out-of-gas revert in the calling transaction. This is an inherent property of any external call and is not specific to this implementation.

### 2.2 State Consistency Analysis

#### `decimalsForToken` (lines 109-123)

```solidity
function decimalsForToken(...) internal returns (TOFUOutcome, uint8) {
    (TOFUOutcome tofuOutcome, uint8 tokenDecimals) = decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
    if (tofuOutcome == TOFUOutcome.Initial) {
        sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: tokenDecimals});
    }
    return (tofuOutcome, tokenDecimals);
}
```

- Storage write occurs **only** on `Initial` outcome (first successful read).
- `Consistent`, `Inconsistent`, and `ReadFailure` outcomes never write storage.
- This is correct: the TOFU invariant is that the first successfully read value is permanently stored.
- Verified by tests: `testDecimalsForTokenNoStorageWriteOnNonInitial` and `testDecimalsForTokenNoStorageWriteOnInconsistent`.

#### `initialized` flag logic

The `TOFUTokenDecimalsResult` struct uses `bool initialized` to distinguish between:
- `{initialized: false, tokenDecimals: 0}` -- uninitialized (default storage)
- `{initialized: true, tokenDecimals: 0}` -- token with 0 decimals

In `decimalsForTokenReadOnly` (line 67): `if (!tofuTokenDecimals.initialized)` correctly branches to `Initial` only when the mapping entry has never been written. A token with 0 decimals gets `{initialized: true, tokenDecimals: 0}` written on first read, and subsequent reads correctly enter the `else` branch for consistency checking.

This is sound. The `initialized` flag correctly disambiguates stored-zero from uninitialized.

### 2.3 Safe Function Revert Completeness

#### `safeDecimalsForToken` (lines 136-146) and `safeDecimalsForTokenReadOnly` (lines 160-170)

Both use the same guard:
```solidity
if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
    revert ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome);
}
```

The `TOFUOutcome` enum has four values: `Initial(0)`, `Consistent(1)`, `Inconsistent(2)`, `ReadFailure(3)`.

The condition allows `Initial` and `Consistent` to pass through; `Inconsistent` and `ReadFailure` both trigger a revert. This is complete -- all four enum values are handled. If the enum were ever extended with a fifth value, it would also revert (fail-closed), which is the safe default.

### 2.4 `memory-safe` Annotation

The assembly block is annotated `"memory-safe"`. Solidity's memory-safe assembly contract requires that the block only access memory in the scratch space (`0x00-0x3f`) or memory allocated via the free memory pointer. This block reads/writes only at positions `0x00-0x1f`, which is within scratch space. The annotation is correct.

However, note that `decimalsForTokenReadOnly` first loads from storage into memory on line 34:
```solidity
TOFUTokenDecimalsResult memory tofuTokenDecimals = sTOFUTokenDecimals[token];
```
This allocates a memory struct via the free memory pointer (at `0x80+`). The assembly block then overwrites `0x00-0x1f`, which does not conflict with this allocation. The struct remains intact after the assembly block. This is correct.

---

## 3. Findings

### A05-01 [INFO] Gas griefing via unbounded gas forwarding in staticcall

**Location:** Line 47
**Code:** `staticcall(gas(), token, 0, 0x04, 0, 0x20)`

**Description:** All remaining gas is forwarded to the external `staticcall`. A malicious or gas-intensive token contract could consume arbitrarily large amounts of gas in its `decimals()` implementation (e.g., via large loops or precompile calls) without reverting, causing the caller to pay excessive gas fees.

**Impact:** A caller invoking `decimalsForToken` or any variant with a malicious token address would pay for all gas consumed by that token's `decimals()` function. Since `staticcall` prevents state changes, the malicious contract cannot extract value beyond gas waste.

**Mitigation consideration:** A gas cap could be applied (e.g., `staticcall(50000, token, ...)`), but this could also cause legitimate tokens with unusual `decimals()` implementations (e.g., proxies with multiple delegate calls) to fail. The current approach is a reasonable design choice given the tradeoff. The `ReadFailure` path handles the out-of-gas case gracefully if the caller provides insufficient gas.

**Severity rationale:** INFO. This is an inherent property of external calls and is well understood. The design correctly handles all failure modes. Callers already bear the risk of interacting with arbitrary token contracts.

---

### A05-02 [INFO] `safeDecimalsForTokenReadOnly` does not provide TOFU protection before initialization

**Location:** Lines 160-170
**Code:**
```solidity
function safeDecimalsForTokenReadOnly(...) internal view returns (uint8) {
    (TOFUOutcome tofuOutcome, uint8 tokenDecimals) = decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
    if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
        revert ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome);
    }
    return tokenDecimals;
}
```

**Description:** Before `decimalsForToken` has been called for a given token (initializing storage), every call to `safeDecimalsForTokenReadOnly` returns `TOFUOutcome.Initial` and passes through. This means a malicious token that changes its `decimals()` return value between calls would not be detected by consecutive `safeDecimalsForTokenReadOnly` calls alone. Each call is a fresh "first use" with no stored reference to compare against.

**Impact:** If a caller uses only `safeDecimalsForTokenReadOnly` without a prior `decimalsForToken` call, the TOFU guarantee does not hold -- there is no stored value to detect inconsistency against.

**Mitigation consideration:** This is already documented in the NatSpec (lines 148-153 of the implementation and lines 90-93 of the interface). The `WARNING` comment explicitly states callers must ensure `decimalsForToken` has been called at least once. The documentation is clear and correct.

**Severity rationale:** INFO. The behavior is by design and explicitly documented. The `view` constraint of the function prevents it from initializing storage. Callers are warned.

---

### A05-03 [INFO] EOA and empty-code addresses correctly handled as ReadFailure

**Location:** Lines 45-57

**Description:** When `token` is an EOA or an address with no code, `staticcall` succeeds (returns `true`) but `returndatasize()` is 0. The guard `lt(returndatasize(), 0x20)` correctly catches this and sets `success := 0`, resulting in a `ReadFailure` outcome. This is verified by the `testDecimalsForTokenReadOnlyAddressZero` / `testDecimalsForTokenAddressZero` tests.

**Severity rationale:** INFO. Correct behavior, noted for completeness.

---

### A05-04 [INFO] Returndata overflow: tokens returning more than 32 bytes are handled correctly

**Location:** Line 47

**Description:** The `staticcall` output buffer is `(0, 0x20)` -- only the first 32 bytes of return data are copied to memory. If a token returns more than 32 bytes, the excess is ignored. The `returndatasize() < 0x20` check only ensures a minimum, not an exact match. A token returning, say, 64 bytes would pass the check, but only the first 32 bytes (the ABI-encoded `uint8` value) would be read via `mload(0)`. This is correct: ABI encoding specifies the return value in the first 32-byte slot, and extra data is irrelevant.

**Severity rationale:** INFO. The behavior is correct per ABI encoding conventions.

---

### A05-05 [INFO] No reentrancy risk due to staticcall

**Location:** Line 47

**Description:** The use of `staticcall` (rather than `call`) prevents the called token from modifying any state during the callback. This completely eliminates reentrancy as a concern for the `decimalsForTokenReadOnly` function. The `decimalsForToken` wrapper only writes storage after `decimalsForTokenReadOnly` returns, and only on the `Initial` path, so there is no reentrancy window.

**Severity rationale:** INFO. The pattern is secure by construction.

---

### A05-06 [INFO] `mstore(0, selector)` places selector in correct ABI position

**Location:** Line 46

**Description:** `mstore(0, selector)` writes the `bytes4` value `0x313ce567` as a 32-byte word at position 0. In Solidity/YUL, a `bytes4` variable is stored left-aligned in the high 4 bytes of the word when written via `mstore`. The `staticcall` then reads `0x04` bytes starting at position 0, which are exactly the 4 selector bytes. This is the standard pattern for constructing calldata in assembly and is correct.

A test (`testDecimalsSelector`) in `LibTOFUTokenDecimalsImplementation.t.sol` confirms the selector value matches `IERC20.decimals.selector`.

**Severity rationale:** INFO. Correct implementation of a standard pattern.

---

### A05-07 [LOW] Stale memory read if staticcall returns less than 32 bytes but succeeds

**Location:** Lines 47-52

**Description:** Consider the scenario where `staticcall` returns `success = true` but copies fewer than 32 bytes of return data to the output buffer. The `staticcall(gas(), token, 0, 0x04, 0, 0x20)` instruction copies `min(returndatasize(), 0x20)` bytes to memory at position 0. If, hypothetically, `returndatasize()` were between 1 and 31, the remaining bytes at positions `returndatasize()..0x1f` would still contain data from the prior `mstore(0, selector)`.

However, this scenario is caught by the guard on line 48: `if lt(returndatasize(), 0x20) { success := 0 }`. This guard fires before `mload(0)` is reached, so stale memory is never interpreted as a decimals value. The defense is correct.

The only way `mload(0)` is reached is when both `success == true` (staticcall succeeded) and `returndatasize() >= 0x20` (at least 32 bytes returned). In that case, the full 32 bytes at position 0 are valid return data.

**Severity rationale:** LOW. The guard is correct and the stale-memory scenario is properly handled. This finding is noted because the pattern requires careful reasoning about memory state, and the correctness of the code depends entirely on the `returndatasize()` guard being present and ordered before the `mload`. If this guard were ever removed or reordered, the result would be a security vulnerability. The current code is secure.

---

### A05-08 [INFO] Struct packing efficiency

**Location:** `ITOFUTokenDecimals.sol` lines 13-16

**Description:** The `TOFUTokenDecimalsResult` struct contains `bool initialized` (1 byte) and `uint8 tokenDecimals` (1 byte). These pack into a single 32-byte storage slot. The struct correctly uses the minimum necessary types, and Solidity packs `bool` + `uint8` into the lowest 2 bytes of the slot, leaving the remaining 30 bytes as zero. Reading the struct from storage is a single `SLOAD`, and writing is a single `SSTORE`. This is gas-efficient.

**Severity rationale:** INFO. Noted for completeness.

---

## 4. Summary

| ID | Severity | Title |
|---|---|---|
| A05-01 | INFO | Gas griefing via unbounded gas forwarding in staticcall |
| A05-02 | INFO | `safeDecimalsForTokenReadOnly` lacks TOFU protection before initialization (documented) |
| A05-03 | INFO | EOA and empty-code addresses correctly handled as ReadFailure |
| A05-04 | INFO | Returndata overflow handled correctly |
| A05-05 | INFO | No reentrancy risk due to staticcall |
| A05-06 | INFO | Selector placement in memory is correct |
| A05-07 | LOW | Stale memory read prevented by returndatasize guard (fragile ordering dependency) |
| A05-08 | INFO | Struct packing is efficient |

**No CRITICAL, HIGH, or MEDIUM severity issues found.**

The assembly block is well-constructed, with correct memory usage within scratch space, proper guards for insufficient return data and out-of-range values, and appropriate use of `staticcall` to prevent reentrancy. The TOFU state machine (Initial -> Consistent/Inconsistent/ReadFailure) is implemented correctly with storage writes confined to the `Initial` transition only. The `initialized` flag properly disambiguates stored-zero from uninitialized storage.

The `safe*` variants correctly revert on all non-success outcomes (`Inconsistent`, `ReadFailure`) and are fail-closed against potential future enum extensions. The code quality is high, with thorough NatSpec documentation and comprehensive fuzz test coverage across all outcome paths.
