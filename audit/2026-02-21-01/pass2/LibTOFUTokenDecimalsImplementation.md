# Pass 2: Test Coverage Analysis — `LibTOFUTokenDecimalsImplementation.sol`

**Audit Agent:** A04
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Test files examined:**
- `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

---

## 1. Evidence of Thorough Reading

### 1.1 Source File Inventory (`src/lib/LibTOFUTokenDecimalsImplementation.sol`, 172 lines)

| Kind | Name | Line(s) | Notes |
|------|------|---------|-------|
| Import (struct) | `TOFUTokenDecimalsResult` | 8 | From `ITOFUTokenDecimals.sol` |
| Import (enum) | `TOFUOutcome` | 8 | `Initial`, `Consistent`, `Inconsistent`, `ReadFailure` |
| Import (error) | `TokenDecimalsReadFailure` | 9 | `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` |
| Import (interface) | `ITOFUTokenDecimals` | 6 | Not directly used in library logic |
| Library | `LibTOFUTokenDecimalsImplementation` | 18 | Top-level library |
| Constant | `TOFU_DECIMALS_SELECTOR` | 20 | `bytes4 constant = 0x313ce567` |
| Function | `decimalsForTokenReadOnly` | 34-84 | `internal view`, core read logic with assembly staticcall |
| Function | `decimalsForToken` | 113-127 | `internal`, delegates to `decimalsForTokenReadOnly`, stores on `Initial` |
| Function | `safeDecimalsForToken` | 140-150 | `internal`, wraps `decimalsForToken`, reverts on non-`Initial`/non-`Consistent` |
| Function | `safeDecimalsForTokenReadOnly` | 161-171 | `internal view`, wraps `decimalsForTokenReadOnly`, reverts on non-`Initial`/non-`Consistent` |

### 1.2 Branch/Path Inventory for `decimalsForTokenReadOnly` (lines 34-84)

| ID | Condition | Lines | Outcome |
|----|-----------|-------|---------|
| B1 | `staticcall` fails | 52 | `success = false` |
| B2 | `returndatasize() < 0x20` | 53-55 | `success = false` |
| B3 | `readDecimals > 0xff` | 58-60 | `success = false` |
| B4 | `!success` (overall read failure) | 66-68 | Return `(ReadFailure, storedDecimals)` |
| B5 | `!tofuTokenDecimals.initialized` (no stored value) | 72-76 | Return `(Initial, uint8(readDecimals))` |
| B6 | `readDecimals == tofuTokenDecimals.tokenDecimals` | 80 | Return `(Consistent, storedDecimals)` |
| B7 | `readDecimals != tofuTokenDecimals.tokenDecimals` | 80 | Return `(Inconsistent, storedDecimals)` |

### 1.3 Branch/Path Inventory for `decimalsForToken` (lines 113-127)

| ID | Condition | Lines | Outcome |
|----|-----------|-------|---------|
| B8 | `tofuOutcome == TOFUOutcome.Initial` | 123-124 | Writes to storage |
| B9 | `tofuOutcome != TOFUOutcome.Initial` | 123 (else) | Does NOT write to storage |

### 1.4 Branch/Path Inventory for `safeDecimalsForToken` (lines 140-150)

| ID | Condition | Lines | Outcome |
|----|-----------|-------|---------|
| B10 | `tofuOutcome` is `Initial` or `Consistent` | 146 | Returns `readDecimals` |
| B11 | `tofuOutcome` is `Inconsistent` or `ReadFailure` | 146-148 | Reverts with `TokenDecimalsReadFailure` |

### 1.5 Branch/Path Inventory for `safeDecimalsForTokenReadOnly` (lines 161-171)

| ID | Condition | Lines | Outcome |
|----|-----------|-------|---------|
| B12 | `tofuOutcome` is `Initial` or `Consistent` | 167 | Returns `readDecimals` |
| B13 | `tofuOutcome` is `Inconsistent` or `ReadFailure` | 167-169 | Reverts with `TokenDecimalsReadFailure` |

---

### 1.6 Test File: `LibTOFUTokenDecimalsImplementation.t.sol` (17 lines)

| Line | Test Function | Description |
|------|---------------|-------------|
| 14 | `testDecimalsSelector()` | Asserts `TOFU_DECIMALS_SELECTOR == IERC20.decimals.selector` |

### 1.7 Test File: `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol` (109 lines)

| Line | Test Function | Fuzz? | Description |
|------|---------------|-------|-------------|
| 16 | `testDecimalsForTokenReadOnlyAddressZero(uint8)` | Yes | ReadFailure on address(0), both uninitialized and initialized |
| 30 | `testDecimalsForTokenReadOnlyValidValue(uint8, uint8)` | Yes | Initial (uninitialized), then Consistent/Inconsistent (manual storage init) |
| 51 | `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256, uint8)` | Yes | ReadFailure when return > 0xff, uninitialized and initialized |
| 68 | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256, uint8)` | Yes | ReadFailure when returndata < 0x20, uninitialized and initialized |
| 94 | `testDecimalsForTokenReadOnlyTokenContractRevert(uint8)` | Yes | ReadFailure when token reverts (vm.etch with revert opcode), uninitialized and initialized |

### 1.8 Test File: `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol` (181 lines)

| Line | Test Function | Fuzz? | Description |
|------|---------------|-------|-------------|
| 16 | `testDecimalsForTokenAddressZero(uint8)` | Yes | ReadFailure on address(0), uninitialized and initialized |
| 29 | `testDecimalsForTokenValidValue(uint8, uint8)` | Yes | Initial on first call, Consistent/Inconsistent on second with different mock |
| 52 | `testDecimalsForTokenInvalidValueTooLarge(uint256, uint8)` | Yes | ReadFailure when > 0xff, uninitialized and initialized |
| 68 | `testDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256, uint8)` | Yes | ReadFailure when returndata < 0x20, uninitialized and initialized |
| 95 | `testDecimalsForTokenNoStorageWriteOnNonInitial(uint8, uint256)` | Yes | Storage not corrupted by ReadFailure (Initial -> ReadFailure -> Consistent) |
| 120 | `testDecimalsForTokenNoStorageWriteOnInconsistent(uint8, uint8)` | Yes | Storage not corrupted by Inconsistent (Initial -> Inconsistent -> Consistent) |
| 142 | `testDecimalsForTokenCrossTokenIsolation(uint8, uint8)` | Yes | Two different tokens do not cross-contaminate storage |
| 168 | `testDecimalsForTokenTokenContractRevert(uint8)` | Yes | ReadFailure on revert opcode, uninitialized and initialized |

### 1.9 Test File: `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` (128 lines)

| Line | Test Function | Fuzz? | Description |
|------|---------------|-------|-------------|
| 21 | `testSafeDecimalsForTokenAddressZeroUninitialized()` | No | Reverts with ReadFailure on address(0) uninitialized |
| 26 | `testSafeDecimalsForTokenAddressZeroInitialized(uint8)` | Yes | Reverts with ReadFailure on address(0) initialized |
| 34 | `testSafeDecimalsForTokenInitial(uint8)` | Yes | Initial path succeeds and returns correct decimals |
| 41 | `testSafeDecimalsForTokenValidValue(uint8, uint8)` | Yes | Initial then Consistent success / Inconsistent revert |
| 60 | `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized(uint256)` | Yes | Reverts ReadFailure when > 0xff, uninitialized |
| 69 | `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint256, uint8)` | Yes | Reverts ReadFailure when > 0xff, initialized |
| 79 | `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized(bytes, uint256)` | Yes | Reverts ReadFailure when returndata < 0x20, uninitialized |
| 95 | `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(bytes, uint256, uint8)` | Yes | Reverts ReadFailure when returndata < 0x20, initialized |
| 114 | `testSafeDecimalsForTokenTokenContractRevertUninitialized()` | No | Reverts ReadFailure on revert opcode, uninitialized |
| 121 | `testSafeDecimalsForTokenTokenContractRevertInitialized(uint8)` | Yes | Reverts ReadFailure on revert opcode, initialized |

### 1.10 Test File: `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` (121 lines)

| Line | Test Function | Fuzz? | Description |
|------|---------------|-------|-------------|
| 21 | `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized()` | No | Reverts with ReadFailure on address(0) uninitialized |
| 26 | `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized(uint8)` | Yes | Reverts with ReadFailure on address(0) initialized |
| 32 | `testSafeDecimalsForTokenReadOnlyValidValue(uint8, uint8)` | Yes | Initial success, Consistent success / Inconsistent revert |
| 51 | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized(uint256)` | Yes | Reverts ReadFailure when > 0xff, uninitialized |
| 60 | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint256, uint8)` | Yes | Reverts ReadFailure when > 0xff, initialized |
| 72 | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized(bytes, uint256)` | Yes | Reverts ReadFailure when returndata < 0x20, uninitialized |
| 88 | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(bytes, uint256, uint8)` | Yes | Reverts ReadFailure when returndata < 0x20, initialized |
| 107 | `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized()` | No | Reverts ReadFailure on revert opcode, uninitialized |
| 114 | `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` | Yes | Reverts ReadFailure on revert opcode, initialized |

---

## 2. Test Coverage Analysis

### 2.1 Constant: `TOFU_DECIMALS_SELECTOR` (line 20)

| Test | Covers |
|------|--------|
| `testDecimalsSelector` | Asserts equality with `IERC20.decimals.selector` |

**Verdict:** Fully covered.

### 2.2 Function: `decimalsForTokenReadOnly` (lines 34-84)

| Branch | ID | Tested? | Test(s) | Notes |
|--------|----|---------|---------|-------|
| staticcall fails (no code at address) | B1 | Yes | `testDecimalsForTokenReadOnlyAddressZero` | address(0) has no code |
| staticcall fails (contract reverts) | B1 | Yes | `testDecimalsForTokenReadOnlyTokenContractRevert` | `vm.etch` with revert opcode |
| returndatasize < 0x20 | B2 | Yes | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` | Fuzz with data truncated to 0..0x1f bytes |
| readDecimals > 0xff | B3 | Yes | `testDecimalsForTokenReadOnlyInvalidValueTooLarge` | Fuzz with values > 0xff |
| ReadFailure path (uninitialized) | B4 | Yes | All ReadFailure tests, first call | Returns `(ReadFailure, 0)` |
| ReadFailure path (initialized) | B4 | Yes | All ReadFailure tests, second call after manual init | Returns `(ReadFailure, storedDecimals)` |
| Initial path (uninitialized, valid) | B5 | Yes | `testDecimalsForTokenReadOnlyValidValue` | First call returns `(Initial, decimals)` |
| Consistent path | B6 | Yes | `testDecimalsForTokenReadOnlyValidValue` | When `storedDecimals == decimals` |
| Inconsistent path | B7 | Yes | `testDecimalsForTokenReadOnlyValidValue` | When `storedDecimals != decimals` |

**Verdict:** All branches covered with fuzz testing. Both uninitialized and initialized states are exercised for failure paths.

### 2.3 Function: `decimalsForToken` (lines 113-127)

| Branch | ID | Tested? | Test(s) | Notes |
|--------|----|---------|---------|-------|
| Storage write on Initial | B8 | Yes | `testDecimalsForTokenValidValue` | Implicit: second call is Consistent/Inconsistent, proving storage was written on first call |
| No storage write on non-Initial | B9 | Yes | `testDecimalsForTokenNoStorageWriteOnNonInitial`, `testDecimalsForTokenNoStorageWriteOnInconsistent` | Explicitly verifies ReadFailure and Inconsistent do not corrupt stored value |
| ReadFailure (all sub-branches) | B1-B4 | Yes | `testDecimalsForTokenAddressZero`, `testDecimalsForTokenInvalidValueTooLarge`, `testDecimalsForTokenInvalidValueNotEnoughData`, `testDecimalsForTokenTokenContractRevert` | Mirrors `decimalsForTokenReadOnly` tests |
| Cross-token isolation | -- | Yes | `testDecimalsForTokenCrossTokenIsolation` | Two tokens stored independently |

**Verdict:** All branches covered. Storage write/no-write behavior explicitly tested.

### 2.4 Function: `safeDecimalsForToken` (lines 140-150)

| Branch | ID | Tested? | Test(s) | Notes |
|--------|----|---------|---------|-------|
| Initial: succeeds | B10 | Yes | `testSafeDecimalsForTokenInitial`, `testSafeDecimalsForTokenValidValue` | Returns correct decimals |
| Consistent: succeeds | B10 | Yes | `testSafeDecimalsForTokenValidValue` | When `decimalsA == decimalsB` |
| Inconsistent: reverts | B11 | Yes | `testSafeDecimalsForTokenValidValue` | When `decimalsA != decimalsB` |
| ReadFailure: reverts (uninitialized) | B11 | Yes | `testSafeDecimalsForTokenAddressZeroUninitialized`, `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized`, `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized`, `testSafeDecimalsForTokenTokenContractRevertUninitialized` | All failure sub-types |
| ReadFailure: reverts (initialized) | B11 | Yes | `testSafeDecimalsForTokenAddressZeroInitialized`, `testSafeDecimalsForTokenInvalidValueTooLargeInitialized`, `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized`, `testSafeDecimalsForTokenTokenContractRevertInitialized` | All failure sub-types |

**Verdict:** All branches covered. Both revert cases (Inconsistent and ReadFailure) and both success cases (Initial and Consistent) tested.

### 2.5 Function: `safeDecimalsForTokenReadOnly` (lines 161-171)

| Branch | ID | Tested? | Test(s) | Notes |
|--------|----|---------|---------|-------|
| Initial: succeeds | B12 | Yes | `testSafeDecimalsForTokenReadOnlyValidValue` | First call (no manual init) |
| Consistent: succeeds | B12 | Yes | `testSafeDecimalsForTokenReadOnlyValidValue` | After manual init, same decimals |
| Inconsistent: reverts | B13 | Yes | `testSafeDecimalsForTokenReadOnlyValidValue` | After manual init, different decimals |
| ReadFailure: reverts (uninitialized) | B13 | Yes | `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized`, `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized`, `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized`, `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized` | All failure sub-types |
| ReadFailure: reverts (initialized) | B13 | Yes | `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized`, `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized`, `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized`, `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized` | All failure sub-types |

**Verdict:** All branches covered.

---

## 3. Coverage Gap Findings

### A04-1: No test for `decimalsForTokenReadOnly` when `readDecimals == 0` and `initialized == false` (explicit edge case)

**Severity:** INFO

**Description:** The `decimalsForTokenReadOnly` tests use `uint8` fuzz for `decimals`, which will statistically cover `decimals == 0` across fuzz runs. However, there is no dedicated test that specifically asserts the `Initial` outcome with `readDecimals == 0`, which is the critical edge case the `initialized` flag exists to protect. The fuzz input space of `uint8` means 0 is hit approximately 1/256 of the time, so this is likely exercised in practice, but an explicit pinned test would provide deterministic coverage of this exact edge case.

**Affected branch:** B5 (Initial path with readDecimals == 0)

**Recommendation:** Consider adding a pinned (non-fuzz) test that explicitly mocks `decimals()` returning 0, calls `decimalsForTokenReadOnly` on an uninitialized token, asserts `(Initial, 0)`, then manually sets `initialized = true, tokenDecimals = 0` in storage, calls again, and asserts `(Consistent, 0)`. This would deterministically prove the `initialized` flag correctly distinguishes "uninitialized zero" from "stored zero."

### A04-2: No test for `decimalsForToken` storing `tokenDecimals == 0` and correctly returning `Consistent` on re-read

**Severity:** INFO

**Description:** Similar to A04-1 but for the state-modifying `decimalsForToken`. There is no pinned test that verifies the full round-trip: (1) `decimalsForToken` with `decimals() == 0` returns `Initial` and stores `{initialized: true, tokenDecimals: 0}`, (2) a second call with `decimals() == 0` returns `(Consistent, 0)`. The fuzz tests cover this probabilistically.

**Affected branch:** B8 (storage write) combined with B6 (Consistent with stored 0)

**Recommendation:** Same as A04-1 -- a pinned test with `decimals == 0` for the `decimalsForToken` function would provide deterministic assurance.

### A04-3: No test for `decimalsForTokenReadOnly` confirming it does NOT write to storage

**Severity:** LOW

**Description:** The `decimalsForTokenReadOnly` function is declared `view` (enforced by the compiler), so it cannot write state. However, the test file for `decimalsForTokenReadOnly` never explicitly asserts that calling it does not mutate the `sTOFUTokenDecimals` mapping. This is compiler-enforced via the `view` modifier, but an explicit assertion (e.g., checking that `sTOFUTokenDecimals[token].initialized` remains `false` after calling `decimalsForTokenReadOnly`) would serve as a regression test against accidental removal of the `view` modifier or refactoring errors.

**Affected function:** `decimalsForTokenReadOnly` (lines 34-84)

**Recommendation:** Add an assertion in `testDecimalsForTokenReadOnlyValidValue` that after the first call (which returns `Initial`), the storage mapping entry remains uninitialized. This is defense-in-depth for the `view` guarantee.

### A04-4: No test for EOA (externally owned account) token address (non-contract, non-zero)

**Severity:** INFO

**Description:** The `address(0)` tests cover the case where there is no code at the target address, but they are specific to `address(0)`. There is no test with a random non-zero EOA address (no code deployed). In practice, `staticcall` to an EOA returns `success = true` with `returndatasize = 0`, which would be caught by the `returndatasize < 0x20` check (B2). While this is implicitly covered by B2 tests using `vm.mockCall` (which deploys mock code), a test using an actual EOA would validate the real EVM behavior for this edge case.

**Affected branch:** B2 (returndatasize < 0x20 via EOA with no code)

**Recommendation:** Consider adding a test that calls `decimalsForTokenReadOnly` with a fresh `makeAddr()` address that has no code deployed (without `vm.mockCall` or `vm.etch`). This would exercise the actual EVM `staticcall` behavior for codeless addresses. Note: In the EVM, `staticcall` to an address with no code returns `success = true` and `returndatasize = 0`, so this should produce `ReadFailure`.

### A04-5: No test for token returning exactly 32 bytes with value exactly `0xff` (boundary)

**Severity:** INFO

**Description:** The `gt(readDecimals, 0xff)` check at line 58 uses strict greater-than. The fuzz tests for `uint8 decimals` cover all values 0-255 (which are all <= 0xff), and the `uint256 decimals > 0xff` tests cover the failure side. However, there is no pinned test that explicitly tests the boundary value `0xff` (255) succeeds and `0x100` (256) fails. Fuzz testing probabilistically covers this, but a pinned boundary test would be more explicit.

**Affected branch:** B3 boundary between success and failure

**Recommendation:** Consider adding pinned tests: `decimals = 255` should return `Initial` with value 255; `decimals = 256` should return `ReadFailure`.

### A04-6: `safeDecimalsForTokenReadOnly` tests confirm read-only behavior but do not verify storage remains unmodified after `Initial`

**Severity:** INFO

**Description:** The `safeDecimalsForTokenReadOnly` test file tests the revert and success paths, but does not explicitly confirm that calling `safeDecimalsForTokenReadOnly` (which internally calls `decimalsForTokenReadOnly`) does not persist the decimals on the `Initial` outcome. Like A04-3, this is compiler-enforced via `view`, but an explicit regression test would be valuable.

**Affected function:** `safeDecimalsForTokenReadOnly` (lines 161-171)

**Recommendation:** After calling `safeDecimalsForTokenReadOnly` and receiving a successful result, assert that the underlying storage mapping remains uninitialized.

---

## 4. Summary Table

| ID | Finding | Severity | Branch/Function | Status |
|----|---------|----------|----------------|--------|
| A04-1 | No pinned test for `decimalsForTokenReadOnly` with `readDecimals == 0` (Initial/Consistent) | INFO | B5, B6 | Probabilistically covered by fuzz; deterministic pinned test recommended |
| A04-2 | No pinned test for `decimalsForToken` round-trip with `tokenDecimals == 0` | INFO | B8, B6 | Probabilistically covered by fuzz; deterministic pinned test recommended |
| A04-3 | No explicit assertion that `decimalsForTokenReadOnly` does not write storage | LOW | `decimalsForTokenReadOnly` | Compiler-enforced via `view`; explicit regression test recommended |
| A04-4 | No test with non-zero EOA address (no code, not via mockCall) | INFO | B2 | Implicitly covered; direct EVM behavior test recommended |
| A04-5 | No pinned boundary test at `readDecimals == 0xff` / `0x100` | INFO | B3 | Probabilistically covered by fuzz; pinned boundary test recommended |
| A04-6 | `safeDecimalsForTokenReadOnly` tests do not assert storage remains unmodified | INFO | `safeDecimalsForTokenReadOnly` | Compiler-enforced via `view`; regression test recommended |

### Overall Assessment

The test coverage for `LibTOFUTokenDecimalsImplementation.sol` is **excellent**. All four exported functions are tested across dedicated test files. Every identified branch (B1-B13) is exercised by at least one test. Fuzz testing is used extensively with appropriate input types (`uint8` for valid decimals, `uint256` for overflow cases, `bytes` for malformed return data). The test suite explicitly verifies:

- All four `TOFUOutcome` variants for each function
- Both uninitialized and initialized storage states for failure paths
- Storage immutability on non-Initial outcomes (`testDecimalsForTokenNoStorageWriteOnNonInitial`, `testDecimalsForTokenNoStorageWriteOnInconsistent`)
- Cross-token isolation (`testDecimalsForTokenCrossTokenIsolation`)
- Correct revert error encoding for safe variants

The findings are all INFO or LOW severity -- no CRITICAL, HIGH, or MEDIUM gaps were identified. The suggestions are defense-in-depth improvements (pinned boundary tests, explicit regression assertions for compiler-enforced guarantees) rather than gaps in fundamental coverage.
