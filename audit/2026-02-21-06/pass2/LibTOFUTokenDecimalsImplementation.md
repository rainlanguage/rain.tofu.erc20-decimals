# Audit Pass 2 -- Test Coverage: LibTOFUTokenDecimalsImplementation

**Agent:** A04
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`

---

## Source Functions (with line numbers)

| # | Function | Lines | Visibility |
|---|----------|-------|------------|
| 1 | `decimalsForTokenReadOnly` | 29-79 | `internal view` |
| 2 | `decimalsForToken` | 109-123 | `internal` |
| 3 | `safeDecimalsForToken` | 136-146 | `internal` |
| 4 | `safeDecimalsForTokenReadOnly` | 160-170 | `internal view` |

Constant: `TOFU_DECIMALS_SELECTOR` (line 15)

---

## Test Functions (all test files)

### `LibTOFUTokenDecimalsImplementation.t.sol`
1. `testDecimalsSelector`

### `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
1. `testDecimalsForTokenAddressZero(uint8)`
2. `testDecimalsForTokenValidValue(uint8,uint8)`
3. `testDecimalsForTokenInvalidValueTooLarge(uint256,uint8)`
4. `testDecimalsForTokenInvalidValueNotEnoughData(bytes,uint256,uint8)`
5. `testDecimalsForTokenNoStorageWriteOnNonInitial(uint8,uint256)`
6. `testDecimalsForTokenNoStorageWriteOnInconsistent(uint8,uint8)`
7. `testDecimalsForTokenCrossTokenIsolation(uint8,uint8)`
8. `testDecimalsForTokenTokenContractRevert(uint8)`

### `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
1. `testDecimalsForTokenReadOnlyAddressZero(uint8)`
2. `testDecimalsForTokenReadOnlyValidValue(uint8,uint8)`
3. `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256,uint8)`
4. `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes,uint256,uint8)`
5. `testDecimalsForTokenReadOnlyTokenContractRevert(uint8)`

### `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
1. `testSafeDecimalsForTokenAddressZeroUninitialized`
2. `testSafeDecimalsForTokenAddressZeroInitialized(uint8)`
3. `testSafeDecimalsForTokenInitial(uint8)`
4. `testSafeDecimalsForTokenValidValue(uint8,uint8)`
5. `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized(uint256)`
6. `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint256,uint8)`
7. `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized(bytes,uint256)`
8. `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(bytes,uint256,uint8)`
9. `testSafeDecimalsForTokenTokenContractRevertUninitialized`
10. `testSafeDecimalsForTokenTokenContractRevertInitialized(uint8)`

### `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
1. `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized`
2. `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized(uint8)`
3. `testSafeDecimalsForTokenReadOnlyValidValue(uint8,uint8)`
4. `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized(uint256)`
5. `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint256,uint8)`
6. `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized(bytes,uint256)`
7. `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(bytes,uint256,uint8)`
8. `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized`
9. `testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken(uint8,uint8)`
10. `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)`

**Total: 35 test functions across 5 files.**

---

## Coverage Analysis

### Functions with no test coverage

All four library functions and the constant have test coverage. No uncovered functions.

### Edge cases analysis

| Edge case | `decimalsForToken` | `decimalsForTokenReadOnly` | `safeDecimalsForToken` | `safeDecimalsForTokenReadOnly` |
|-----------|---|---|---|---|
| decimals = 0 | Covered (fuzz uint8 includes 0) | Covered | Covered | Covered |
| decimals = 255 (max uint8) | Covered (fuzz uint8 includes 255) | Covered | Covered | Covered |
| address(0) | Covered | Covered | Covered | Covered |
| value > 0xff (too large) | Covered | Covered | Covered | Covered |
| returndata < 32 bytes | Covered | Covered | Covered | Covered |
| call reverts | Covered | Covered | Covered | Covered |
| Consistent path | Covered | Covered | Covered | Covered |
| Inconsistent path | Covered | Covered | Covered (reverts) | Covered (reverts) |
| ReadFailure path | Covered | Covered | Covered (reverts) | Covered (reverts) |
| Initial path | Covered | Covered | Covered | Covered |
| Cross-token isolation | Covered | -- | -- | -- |
| No storage write on non-Initial | Covered | N/A (view) | -- | N/A (view) |
| Storage write on Inconsistent | Covered | N/A (view) | -- | N/A (view) |

---

## Findings

### Finding 1: No `decimalsForTokenReadOnly` does-not-write-storage test

**Severity: LOW**

`decimalsForTokenReadOnly` is a `view` function, so the compiler enforces it cannot write storage. However, the core logic is implemented via inline assembly (`staticcall`), and the read-only behavior is implicitly tested only by the fact that the function is `view`. There is no explicit test that verifies calling `decimalsForTokenReadOnly` on an uninitialized token leaves `sTOFUTokenDecimals[token].initialized == false` afterward. This would serve as a defense-in-depth check confirming the read-only semantics are preserved if the function signature were ever changed (e.g., removing `view`). The Solidity `view` modifier already provides the guarantee at the compiler level, so this is informational.

### Finding 2: No cross-token isolation test for `decimalsForTokenReadOnly`

**Severity: LOW**

`decimalsForToken` has a dedicated cross-token isolation test (`testDecimalsForTokenCrossTokenIsolation`) that verifies storing decimals for token A does not affect token B. No equivalent test exists for `decimalsForTokenReadOnly`. Since `decimalsForTokenReadOnly` is a `view` that reads from the same mapping storage, and the storage isolation is a property of Solidity mappings (not the function), the risk is low. The existing `decimalsForToken` cross-token test effectively covers the storage layout. However, a parallel test for `decimalsForTokenReadOnly` exercising the same pattern (read two different tokens with pre-populated storage, confirm each returns its own value) would be a minor completeness improvement.

### Finding 3: No test for `decimalsForToken` calling against an EOA (non-contract address with no code)

**Severity: INFO**

The `address(0)` tests cover a special case of "no code at address," but there is no explicit test using a random non-zero EOA (an address with no deployed code). When `staticcall` targets an EOA, it succeeds with zero returndata. The `returndatasize < 0x20` check in the assembly block should convert this into a `ReadFailure`. The `address(0)` test implicitly covers this behavior since `address(0)` is also an EOA, and the fuzz inputs do exercise this via `makeAddr` generating deterministic addresses that do have mock code. This is purely informational -- the code path is covered, just not under this specific label.

### Finding 4: `safeDecimalsForToken` lacks cross-token isolation and storage-write-on-Initial tests

**Severity: LOW**

`safeDecimalsForToken` delegates to `decimalsForToken`, so its storage behavior is transitively tested. However, there is no direct test verifying that:
- Calling `safeDecimalsForToken` on token A followed by token B results in both being independently initialized.
- The `Initial` call through `safeDecimalsForToken` actually writes storage (i.e., a follow-up call returns `Consistent`).

The `testSafeDecimalsForTokenValidValue` test does call `decimalsForToken` first to initialize, then calls `safeDecimalsForToken` with a potentially different value. But it never tests the end-to-end flow of `safeDecimalsForToken` initializing storage and then `safeDecimalsForToken` reading it back as `Consistent`. The `testSafeDecimalsForTokenInitial` test confirms the Initial path succeeds but does not verify storage was actually written by making a second call. Since `safeDecimalsForToken` delegates to `decimalsForToken` which is well-tested for storage writes, this is low severity.

### Finding 5: No test for `decimalsForToken` ReadFailure on first call (uninitialized) confirming no storage write

**Severity: LOW**

When `decimalsForToken` encounters a `ReadFailure` on the very first call (uninitialized storage), the code returns `ReadFailure` with `tokenDecimals = 0`. There is no explicit test that verifies storage remains uninitialized after this failure, meaning a subsequent valid call should still return `Initial` (not `Consistent`). The existing test `testDecimalsForTokenNoStorageWriteOnNonInitial` covers the case where storage is already initialized and then a ReadFailure occurs. But it does not test the scenario: (1) first call fails -> ReadFailure, (2) mock is fixed, (3) second call should be `Initial` because nothing was stored on the failed first attempt. This is a subtle but meaningful sequence to verify.

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 4 |
| INFO | 1 |

Overall, the test coverage for `LibTOFUTokenDecimalsImplementation` is thorough. All four functions are tested across all major outcome paths (Initial, Consistent, Inconsistent, ReadFailure). Edge cases for zero decimals, max uint8, address(0), oversized return values, short returndata, and reverting contracts are all covered. The findings are minor completeness improvements and defense-in-depth suggestions rather than gaps that indicate untested risk.
