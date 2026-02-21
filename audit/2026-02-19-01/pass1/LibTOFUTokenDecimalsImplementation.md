# Security Audit Pass 1 -- LibTOFUTokenDecimalsImplementation.sol

**Auditor:** A02
**Date:** 2026-02-19
**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Commit:** `dd9cd1f` (branch `2026-02-19-safe-read`)

---

## 1. Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimalsImplementation` (line 18)

### Constants

| Name | Line | Value |
|------|------|-------|
| `TOFU_DECIMALS_SELECTOR` | 20 | `0x313ce567` (matches `ERC20.decimals()` selector) |

### Functions

| Function | Line | Visibility | Mutability |
|----------|------|------------|------------|
| `decimalsForTokenReadOnly` | 32 | `internal` | `view` |
| `decimalsForToken` | 99 | `internal` | (state-changing) |
| `safeDecimalsForToken` | 121 | `internal` | (state-changing) |
| `safeDecimalsForTokenReadOnly` | 137 | `internal` | `view` |

### Errors/Events/Structs Defined in File

None defined directly in this file. The following are imported from `ITOFUTokenDecimals.sol` and used:

- `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (used at lines 128, 144)
- `struct TOFUTokenDecimalsResult { bool initialized; uint8 tokenDecimals; }` (used throughout)
- `enum TOFUOutcome { Initial, Consistent, Inconsistent, ReadFailure }` (used throughout)

### Imports (line 5-10)

- `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome`, `TokenDecimalsReadFailure` from `../interface/ITOFUTokenDecimals.sol`

---

## 2. Security Findings

### A02-1: Memory Write at Offset 0 Overwrites Solidity Scratch Space -- INFO

**Location:** Lines 48-60 (assembly block in `decimalsForTokenReadOnly`)

**Description:**
The assembly block uses `mstore(0, selector)` at line 49 to place the 4-byte function selector at memory offset 0, then uses offset 0 as the output buffer for `staticcall` return data (`staticcall(gas(), token, 0, 0x04, 0, 0x20)`). After the call, `mload(0)` reads the return data from offset 0.

Memory offsets 0x00-0x3f are Solidity's "scratch space" -- they are designated for short-term use and are not expected to persist across Solidity operations. The memory-safe annotation on the assembly block (line 48) declares this usage is safe.

**Analysis:**
This is a well-known and intentional pattern. Solidity's own generated code also uses scratch space transiently. The key safety requirement is that no Solidity-generated code between the `mstore` and the `mload` relies on scratch space contents. In this assembly block, the only intervening operation is the `staticcall` itself, which is an EVM opcode and does not interact with Solidity's memory model. After the assembly block ends, scratch space is no longer referenced.

The `memory-safe` annotation is correct: the block only reads/writes scratch space (0x00-0x3f) and the free memory pointer is not modified.

**Severity:** INFO -- No vulnerability. Correct and standard usage.

---

### A02-2: staticcall Prevents Reentrancy and State Modification -- INFO

**Location:** Line 50

**Description:**
The external call to `decimals()` is performed via `staticcall`, which is the correct choice because:

1. `decimals()` is a view function in the ERC20 standard.
2. `staticcall` prevents the called contract from modifying state, eliminating reentrancy risks through this call path.
3. `staticcall` is consistent with the `view` modifier on `decimalsForTokenReadOnly`.

The `decimalsForToken` function (line 99) which can modify state calls `decimalsForTokenReadOnly` first (read-only external call via `staticcall`), then writes to storage only after the external call returns. This ordering is safe: the state write at line 110 occurs after the `staticcall` completes, so there is no read-after-write reentrancy concern.

**Severity:** INFO -- No vulnerability. Correctly mitigated by design.

---

### A02-3: Return Data Size Validation -- INFO

**Location:** Lines 51-53

**Description:**
After the `staticcall`, the code checks `returndatasize() < 0x20` and sets `success := 0` if the return data is less than 32 bytes. This prevents reading uninitialized/garbage memory when the called contract returns fewer bytes than expected.

**Analysis:**
This is correct. If a contract returns fewer than 32 bytes, the `staticcall` with output buffer size 0x20 will only write the actual returned bytes, leaving the rest of the buffer at whatever was previously in memory (which could be the selector bytes from `mstore(0, selector)`). By checking `returndatasize()`, the code avoids misinterpreting stale memory as valid return data. This also handles the case of calling an EOA (no code) which returns 0 bytes of data -- the `staticcall` to an EOA succeeds with `returndatasize() == 0`, which is correctly caught.

**Severity:** INFO -- No vulnerability. Correct validation.

---

### A02-4: uint8 Range Check for Decimals Value -- INFO

**Location:** Lines 56-58

**Description:**
The code checks `gt(readDecimals, 0xff)` after loading the 32-byte return value. If the value exceeds 255 (the maximum `uint8` value), `success` is set to 0, treating it as a read failure.

**Analysis:**
This is correct and important. The ERC20 `decimals()` function returns `uint8` per the standard, but a malicious or non-compliant token could return a larger value in its 32-byte return word. Without this check, a truncating cast to `uint8` could silently produce an incorrect decimals value. By treating values > 0xff as failures, the code avoids silent truncation.

Note: The check uses strict inequality (`gt`, not `gte`), so 0xff (255) itself is allowed, which is correct since 255 fits in `uint8`.

**Severity:** INFO -- No vulnerability. Correct validation.

---

### A02-5: Forwarding All Gas to External Call -- LOW

**Location:** Line 50 -- `staticcall(gas(), token, 0, 0x04, 0, 0x20)`

**Description:**
The `staticcall` forwards all remaining gas to the target token contract via `gas()`. A malicious token contract could consume all forwarded gas in its `decimals()` function (e.g., via an infinite loop in a `staticcall` context), causing the calling transaction to run out of gas.

**Analysis:**
This is a low-severity concern because:
1. The call is `staticcall`, so no state can be modified by the callee.
2. Gas griefing in a `staticcall` to a view function is an unusual attack vector -- a legitimate caller chooses which tokens to query.
3. Using a fixed gas stipend (e.g., 10,000 gas) could cause false failures on legitimate tokens that have more expensive `decimals()` implementations (e.g., proxy contracts).
4. The EVM's 63/64 gas forwarding rule means the caller retains 1/64 of gas, providing a minimal safety margin.

The current design prioritizes compatibility with all token implementations over protection against gas griefing by tokens the caller has already chosen to interact with.

**Severity:** LOW -- Theoretical gas griefing vector, but the design trade-off is reasonable and standard practice.

---

### A02-6: No `revert("...")` String Messages Used -- INFO

**Location:** Lines 128 and 144

**Description:**
The file uses only the custom error `TokenDecimalsReadFailure(address, TOFUOutcome)` for reverts in `safeDecimalsForToken` (line 128) and `safeDecimalsForTokenReadOnly` (line 144). No `revert("string message")` patterns are used anywhere in the file.

**Severity:** INFO -- Compliant with project conventions. Custom errors are gas-efficient and provide structured error data.

---

### A02-7: Inconsistent Outcome Returns Stored Value, Not Live Value -- INFO

**Location:** Lines 77-80

**Description:**
When the TOFU outcome is `Inconsistent`, the function returns the *stored* `tofuTokenDecimals.tokenDecimals` rather than the freshly read `readDecimals`. This means callers always receive the originally trusted value, not the new (potentially malicious) value.

**Analysis:**
This is the correct and documented behavior. The TOFU model trusts the first-read value. If a token changes its decimals after initial storage, the stored value is considered canonical. Returning the live value on inconsistency would defeat the purpose of TOFU. The caller is informed of the inconsistency via the `TOFUOutcome` enum and can decide how to handle it.

**Severity:** INFO -- Correct by design. Matches documented behavior.

---

### A02-8: ReadFailure on Uninitialized Storage Returns Zero Decimals -- INFO

**Location:** Lines 64-66

**Description:**
When a read failure occurs and the storage is uninitialized (`initialized == false`), the returned `tokenDecimals` value is 0 (the default for `uint8` in an uninitialized struct). This is because line 65 returns `tofuTokenDecimals.tokenDecimals`, which is 0 for uninitialized storage.

**Analysis:**
This is acceptable behavior. The `TOFUOutcome.ReadFailure` signal clearly indicates to the caller that the returned decimals value should not be trusted. The caller can check the outcome and handle accordingly. The `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` wrappers revert on `ReadFailure`, preventing callers from accidentally using the 0 value.

**Severity:** INFO -- The zero value is a safe default given the outcome signal.

---

### A02-9: decimalsForToken Stores on Initial Read Only -- INFO

**Location:** Lines 107-111

**Description:**
The `decimalsForToken` function stores the result only when `tofuOutcome == TOFUOutcome.Initial` (line 109). It does not store on `Consistent`, `Inconsistent`, or `ReadFailure` outcomes. This means:

- A `ReadFailure` on first call leaves storage uninitialized, so the next call can still succeed as `Initial`.
- An `Inconsistent` result never overwrites the stored value.
- A `Consistent` result correctly avoids an unnecessary SSTORE.

**Analysis:**
This is correct behavior. Not storing on `ReadFailure` means a transient network issue or temporary token problem does not permanently lock in a bad state. The next successful call will store the value as `Initial`.

**Severity:** INFO -- Correct design.

---

### A02-10: staticcall to EOA or Empty Address Succeeds with Zero Return Data -- INFO

**Location:** Lines 50-53

**Description:**
A `staticcall` to an address with no code (EOA or undeployed contract) succeeds at the EVM level and returns 0 bytes of data. The `returndatasize() < 0x20` check at line 51 correctly catches this case, setting `success := 0` and routing it to the `ReadFailure` outcome.

This includes `address(0)`, which is tested explicitly in the test suite.

**Severity:** INFO -- Correctly handled.

---

### A02-11: Memory Safety of Assembly Block -- Correctness Verification -- INFO

**Location:** Lines 48-60

**Description:**
Detailed memory safety analysis of the assembly block:

1. **mstore(0, selector)** -- Writes 32 bytes at offset 0. The `selector` is `bytes4`, so it occupies the high 4 bytes of the 32-byte word at offset 0. This is within scratch space (0x00-0x3f).

2. **staticcall input** -- Reads 4 bytes from offset 0 (`0, 0x04`). This correctly sends just the 4-byte function selector.

3. **staticcall output** -- Writes up to 32 bytes at offset 0 (`0, 0x20`). This overwrites the selector in scratch space with the return data. This is within scratch space.

4. **mload(0)** -- Reads 32 bytes from offset 0, which now contains the return data (if `returndatasize() >= 0x20`).

5. **Free memory pointer** (at 0x40) is never read or modified in the assembly block. The struct `tofuTokenDecimals` loaded at line 37 lives in memory allocated before the assembly block. Since only offsets 0x00-0x1f are written (within scratch space, which is 0x00-0x3f), the struct data (at 0x80+) is not corrupted.

**Severity:** INFO -- Memory usage is safe and correctly annotated.

---

### A02-12: safeDecimalsForToken Reverts on Both Inconsistent and ReadFailure -- INFO

**Location:** Lines 127-129 and 143-145

**Description:**
Both `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` check `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial` to decide whether to revert. This means they revert on both `Inconsistent` and `ReadFailure` outcomes.

**Analysis:**
This is correct and matches the documented "safe" behavior. The condition is logically equivalent to `tofuOutcome == TOFUOutcome.Inconsistent || tofuOutcome == TOFUOutcome.ReadFailure`. Since `TOFUOutcome` is a 4-value enum, checking "not Consistent and not Initial" covers exactly the two failure cases. If the enum were ever extended with new values, the negation pattern would default to reverting on unknown outcomes, which is fail-safe.

**Severity:** INFO -- Correct logic with fail-safe properties.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A02-1 | INFO | Memory write at offset 0 overwrites Solidity scratch space (correct usage) |
| A02-2 | INFO | staticcall prevents reentrancy and state modification |
| A02-3 | INFO | Return data size validation prevents reading uninitialized memory |
| A02-4 | INFO | uint8 range check prevents silent truncation |
| A02-5 | LOW | Forwarding all gas to external call (theoretical gas griefing) |
| A02-6 | INFO | No revert("...") string messages used |
| A02-7 | INFO | Inconsistent outcome returns stored value, not live value |
| A02-8 | INFO | ReadFailure on uninitialized storage returns zero decimals |
| A02-9 | INFO | decimalsForToken stores on initial read only |
| A02-10 | INFO | staticcall to EOA or empty address correctly handled |
| A02-11 | INFO | Memory safety of assembly block verified correct |
| A02-12 | INFO | safeDecimalsForToken reverts on both Inconsistent and ReadFailure (fail-safe) |

**Critical findings:** 0
**High findings:** 0
**Medium findings:** 0
**Low findings:** 1
**Informational findings:** 11

---

## Overall Assessment

The `LibTOFUTokenDecimalsImplementation` library is well-written and demonstrates careful attention to security. The assembly block is minimal, correctly uses scratch space, properly validates return data size and value range, and the `staticcall` usage eliminates reentrancy risks. Error handling is comprehensive: all failure modes (call failure, insufficient return data, out-of-range value, EOA targets) converge to the same `ReadFailure` outcome, and the `safe*` wrapper functions provide a fail-safe revert path.

The only finding above INFO severity is the standard practice of forwarding all gas to the `staticcall`, which is a theoretical gas griefing vector but an acceptable design trade-off for compatibility with diverse token implementations.
