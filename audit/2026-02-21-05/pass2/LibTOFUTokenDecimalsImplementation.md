# Audit Pass 2 -- Test Coverage: LibTOFUTokenDecimalsImplementation

**Auditor:** A05
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimalsImplementation.sol` (171 lines)

---

## 1. Source File Summary

The library exposes 4 functions and 1 constant:

| # | Member | Mutability | Line |
|---|--------|-----------|------|
| 1 | `TOFU_DECIMALS_SELECTOR` | constant `bytes4` | 15 |
| 2 | `decimalsForTokenReadOnly` | `view` | 29-79 |
| 3 | `decimalsForToken` | state-changing | 109-123 |
| 4 | `safeDecimalsForToken` | state-changing | 136-146 |
| 5 | `safeDecimalsForTokenReadOnly` | `view` | 160-170 |

---

## 2. Test File Inventory

### 2a. `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationTest`

| Test Function | Line |
|---------------|------|
| `testDecimalsSelector` | 14 |

### 2b. `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationDecimalsForTokenReadOnlyTest`

| Test Function | Line |
|---------------|------|
| `testDecimalsForTokenReadOnlyAddressZero(uint8)` | 16 |
| `testDecimalsForTokenReadOnlyValidValue(uint8,uint8)` | 30 |
| `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256,uint8)` | 51 |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes,uint256,uint8)` | 68 |
| `testDecimalsForTokenReadOnlyTokenContractRevert(uint8)` | 94 |

### 2c. `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationDecimalsForTokenTest`

| Test Function | Line |
|---------------|------|
| `testDecimalsForTokenAddressZero(uint8)` | 16 |
| `testDecimalsForTokenValidValue(uint8,uint8)` | 29 |
| `testDecimalsForTokenInvalidValueTooLarge(uint256,uint8)` | 52 |
| `testDecimalsForTokenInvalidValueNotEnoughData(bytes,uint256,uint8)` | 68 |
| `testDecimalsForTokenNoStorageWriteOnNonInitial(uint8,uint256)` | 95 |
| `testDecimalsForTokenNoStorageWriteOnInconsistent(uint8,uint8)` | 120 |
| `testDecimalsForTokenCrossTokenIsolation(uint8,uint8)` | 142 |
| `testDecimalsForTokenTokenContractRevert(uint8)` | 168 |

### 2d. `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenTest`

| Test Function | Line |
|---------------|------|
| `testSafeDecimalsForTokenAddressZeroUninitialized()` | 21 |
| `testSafeDecimalsForTokenAddressZeroInitialized(uint8)` | 26 |
| `testSafeDecimalsForTokenInitial(uint8)` | 34 |
| `testSafeDecimalsForTokenValidValue(uint8,uint8)` | 41 |
| `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized(uint256)` | 60 |
| `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint256,uint8)` | 69 |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized(bytes,uint256)` | 79 |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(bytes,uint256,uint8)` | 95 |
| `testSafeDecimalsForTokenTokenContractRevertUninitialized()` | 114 |
| `testSafeDecimalsForTokenTokenContractRevertInitialized(uint8)` | 121 |

### 2e. `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenReadOnlyTest`

| Test Function | Line |
|---------------|------|
| `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized()` | 21 |
| `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized(uint8)` | 26 |
| `testSafeDecimalsForTokenReadOnlyValidValue(uint8,uint8)` | 32 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized(uint256)` | 51 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint256,uint8)` | 60 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized(bytes,uint256)` | 72 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(bytes,uint256,uint8)` | 88 |
| `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized()` | 107 |
| `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` | 134 |
| `testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken(uint8,uint8)` | 117 |

---

## 3. Coverage Matrix

The table below shows which test scenarios are covered for each function. A checkmark indicates a test exists; an X indicates a gap.

| Scenario | `decimalsForTokenReadOnly` | `decimalsForToken` | `safeDecimalsForToken` | `safeDecimalsForTokenReadOnly` |
|----------|:---:|:---:|:---:|:---:|
| address(0) uninitialized | YES | YES | YES | YES |
| address(0) initialized | YES | YES | YES | YES |
| Valid value - Initial path | YES | YES | YES | YES |
| Valid value - Consistent path | YES | YES | YES | YES |
| Valid value - Inconsistent path | YES | YES | YES | YES |
| Overwide decimals (>0xff) uninitialized | YES | YES | YES | YES |
| Overwide decimals (>0xff) initialized | YES | YES | YES | YES |
| Short/insufficient returndata uninitialized | YES | YES | YES | YES |
| Short/insufficient returndata initialized | YES | YES | YES | YES |
| Contract revert (vm.etch hex"fd") uninitialized | YES | YES | YES | YES |
| Contract revert (vm.etch hex"fd") initialized | YES | YES | YES | YES |
| Storage write isolation (no write on non-Initial) | N/A (view) | YES | -- | N/A (view) |
| Cross-token isolation | -- | YES | -- | -- |
| Integration: decimalsForToken -> safeDecimalsForTokenReadOnly | -- | -- | -- | YES |
| TOFU_DECIMALS_SELECTOR correctness | (separate test file) | -- | -- | -- |

---

## 4. Findings

### A05-1 [LOW] No cross-token isolation test for `decimalsForTokenReadOnly`

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`

**Description:** The `decimalsForToken` test file includes `testDecimalsForTokenCrossTokenIsolation` which verifies that storing decimals for one token does not affect another. The `decimalsForTokenReadOnly` test file has no equivalent test. While `decimalsForTokenReadOnly` is a view function that does not write storage, it does read from the same mapping. A test that manually initializes two different tokens and then calls `decimalsForTokenReadOnly` on each would confirm the mapping lookup is correctly keyed by token address in the read path.

**Recommendation:** Add a fuzz test that manually initializes two token entries in `sTOFUTokenDecimals` with different decimals values, then calls `decimalsForTokenReadOnly` on each, asserting each returns `Consistent` with its own stored value (not the other token's value).

---

### A05-2 [LOW] No cross-token isolation test for `safeDecimalsForToken`

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

**Description:** The `safeDecimalsForToken` test file lacks a cross-token isolation test. Since `safeDecimalsForToken` delegates to `decimalsForToken` which does have this test, the underlying logic is covered, but there is no direct test at the `safe` wrapper level confirming that calling `safeDecimalsForToken` for token A and then token B returns independent results.

**Recommendation:** Add a test that initializes two tokens with different decimals via `safeDecimalsForToken`, then re-reads each, verifying independent values are returned.

---

### A05-3 [LOW] No cross-token isolation test for `safeDecimalsForTokenReadOnly`

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

**Description:** Same gap as A05-1 and A05-2 but for the read-only safe variant.

**Recommendation:** Add a test that manually initializes two token entries, then calls `safeDecimalsForTokenReadOnly` on each with matching mock values, confirming each returns its own stored decimals.

---

### A05-4 [LOW] No storage write isolation test for `safeDecimalsForToken`

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

**Description:** `safeDecimalsForToken` delegates to `decimalsForToken` and therefore inherits the storage-write-only-on-Initial behavior. The `decimalsForToken` test file has explicit tests (`testDecimalsForTokenNoStorageWriteOnNonInitial`, `testDecimalsForTokenNoStorageWriteOnInconsistent`) verifying that storage is not written on `Consistent`, `Inconsistent`, or `ReadFailure` outcomes. However, since `safeDecimalsForToken` reverts on `Inconsistent` and `ReadFailure`, the only non-reverting paths are `Initial` and `Consistent`. The `Consistent` path does not write storage by design, but this is only tested transitively through `decimalsForToken`. A direct test at the `safe` level would strengthen confidence.

Note: This is lower severity because the `safeDecimalsForToken` function reverts on non-success outcomes anyway, meaning storage writes on those paths would be rolled back even if they occurred.

**Recommendation:** Add a test that calls `safeDecimalsForToken` for Initial, then calls it again for Consistent, and verifies the stored value did not change (e.g., by reading the mapping directly or calling `decimalsForTokenReadOnly` afterward).

---

### A05-5 [INFO] `testDecimalsForTokenReadOnlyAddressZero` has an unused fuzz parameter

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`, line 16

**Description:** The test function signature is `testDecimalsForTokenReadOnlyAddressZero(uint8 storedDecimals)`. The `storedDecimals` parameter is used in the second half of the test (initialized path), so it serves a purpose. However, this is worth noting as the test name does not indicate it also covers the initialized path. The naming convention used by the `safe*` tests -- splitting into `*Uninitialized` and `*Initialized` variants -- is clearer.

**Recommendation:** No action required. This is an observation about naming consistency. The `decimalsForTokenReadOnly` and `decimalsForToken` test files combine uninitialized and initialized checks into single tests, while the `safe*` test files split them. Consider aligning the naming convention for readability.

---

### A05-6 [INFO] No integration test for `decimalsForToken` -> `safeDecimalsForToken`

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

**Description:** The `safeDecimalsForTokenReadOnly` test file has an integration test (`testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken`) that initializes storage via `decimalsForToken` and then reads through `safeDecimalsForTokenReadOnly`. There is no equivalent test that initializes via `decimalsForToken` and then reads through `safeDecimalsForToken`. The `testSafeDecimalsForTokenValidValue` test partially covers this by calling `decimalsForToken` directly and then `safeDecimalsForToken`, but it is labeled as testing "valid value" rather than being an explicit integration test.

**Recommendation:** The existing `testSafeDecimalsForTokenValidValue` test effectively serves as an integration test since it calls `decimalsForToken` first and then `safeDecimalsForToken`. No action strictly required, but an explicitly-named integration test would improve clarity.

---

### A05-7 [INFO] No explicit test for `decimalsForTokenReadOnly` returning stored value on `Inconsistent`

**Location:** `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`, line 30

**Description:** The `testDecimalsForTokenReadOnlyValidValue` test at line 42-48 does check the Inconsistent path and asserts that `readDecimals == storedDecimals` (line 47), correctly verifying that the **stored** value (not the freshly read inconsistent value) is returned. This is well covered. Noting for completeness that this important semantic property IS tested.

**Recommendation:** No action required. This is a positive observation -- the test correctly verifies the documented behavior that on `Inconsistent`, the previously stored value is returned.

---

## 5. Summary

The test suite is thorough and well-structured. All four functions plus the constant have dedicated test files. The core scenarios -- address(0), valid values across all outcome paths, overwide decimals, short returndata, and contract reverts -- are covered for every function, in both uninitialized and initialized states.

The `decimalsForToken` test file is the most comprehensive, including explicit storage-write isolation tests and cross-token isolation. The `safe*` wrappers have excellent coverage of the revert behavior on failure paths.

The identified gaps are all LOW or INFO severity. They relate to cross-token isolation and storage-write isolation tests being present only at the `decimalsForToken` level rather than being duplicated at the `safe*` wrapper level. Since the wrappers delegate to the core functions, the underlying logic is already tested; the missing tests would only add defense-in-depth at the wrapper boundary.

**Total findings: 7 (0 CRITICAL, 0 HIGH, 0 MEDIUM, 4 LOW, 3 INFO)**
