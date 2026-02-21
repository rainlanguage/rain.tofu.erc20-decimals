# Audit Pass 2 -- Test Coverage

**Source:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Agent:** A02
**Date:** 2026-02-21

## Evidence of Thorough Reading

### Source file: `src/lib/LibTOFUTokenDecimalsImplementation.sol`

- **Library:** `LibTOFUTokenDecimalsImplementation` (line 13)
- **Constant:** `TOFU_DECIMALS_SELECTOR` (line 15)
- **Functions:**
  - `decimalsForTokenReadOnly` (line 29) -- view, core assembly logic
  - `decimalsForToken` (line 109) -- stores on Initial
  - `safeDecimalsForToken` (line 136) -- reverts on bad outcome
  - `safeDecimalsForTokenReadOnly` (line 160) -- view, reverts on bad outcome

### Test file 1: `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`

- **Contract:** `LibTOFUTokenDecimalsImplementationDecimalsForTokenTest` (line 13)
- **Functions:**
  - `testDecimalsForTokenAddressZero` (line 16) -- fuzz on `storedDecimals`
  - `testDecimalsForTokenValidValue` (line 29) -- fuzz on `decimalsA`, `decimalsB`
  - `testDecimalsForTokenInvalidValueTooLarge` (line 52) -- fuzz on `decimals`, `storedDecimals`
  - `testDecimalsForTokenInvalidValueNotEnoughData` (line 68) -- fuzz on `data`, `length`, `storedDecimals`
  - `testDecimalsForTokenNoStorageWriteOnNonInitial` (line 95) -- fuzz on `decimalsA`, `tooLarge`
  - `testDecimalsForTokenNoStorageWriteOnInconsistent` (line 120) -- fuzz on `decimalsA`, `decimalsB`
  - `testDecimalsForTokenCrossTokenIsolation` (line 142) -- fuzz on `decimalsA`, `decimalsB`
  - `testDecimalsForTokenNoStorageWriteOnUninitializedReadFailure` (line 171) -- fuzz on `decimalsA`, `tooLarge`
  - `testDecimalsForTokenTokenContractRevert` (line 190) -- fuzz on `storedDecimals`

### Test file 2: `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`

- **Contract:** `LibTOFUTokenDecimalsImplementationDecimalsForTokenReadOnlyTest` (line 13)
- **Functions:**
  - `testDecimalsForTokenReadOnlyAddressZero` (line 16) -- fuzz on `storedDecimals`
  - `testDecimalsForTokenReadOnlyValidValue` (line 30) -- fuzz on `decimals`, `storedDecimals`
  - `testDecimalsForTokenReadOnlyInvalidValueTooLarge` (line 51) -- fuzz on `decimals`, `storedDecimals`
  - `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` (line 68) -- fuzz on `data`, `length`, `storedDecimals`
  - `testDecimalsForTokenReadOnlyTokenContractRevert` (line 94) -- fuzz on `storedDecimals`

### Test file 3: `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol`

- **Contract:** `LibTOFUTokenDecimalsImplementationTest` (line 13)
- **Functions:**
  - `testDecimalsSelector` (line 14) -- pure, no fuzz

### Test file 4: `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

- **Contract:** `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenTest` (line 14)
- **Functions:**
  - `externalSafeDecimalsForToken` (line 17) -- test helper wrapper
  - `testSafeDecimalsForTokenAddressZeroUninitialized` (line 21) -- no fuzz
  - `testSafeDecimalsForTokenAddressZeroInitialized` (line 26) -- fuzz on `storedDecimals`
  - `testSafeDecimalsForTokenInitial` (line 34) -- fuzz on `decimals`
  - `testSafeDecimalsForTokenValidValue` (line 41) -- fuzz on `decimalsA`, `decimalsB`
  - `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized` (line 60) -- fuzz on `decimals`
  - `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` (line 69) -- fuzz on `decimals`, `storedDecimals`
  - `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized` (line 79) -- fuzz on `data`, `length`
  - `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` (line 95) -- fuzz on `data`, `length`, `storedDecimals`
  - `testSafeDecimalsForTokenTokenContractRevertUninitialized` (line 114) -- no fuzz
  - `testSafeDecimalsForTokenTokenContractRevertInitialized` (line 121) -- fuzz on `storedDecimals`

### Test file 5: `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

- **Contract:** `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenReadOnlyTest` (line 14)
- **Functions:**
  - `externalSafeDecimalsForTokenReadOnly` (line 17) -- test helper wrapper (view)
  - `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized` (line 21) -- no fuzz
  - `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized` (line 26) -- fuzz on `storedDecimals`
  - `testSafeDecimalsForTokenReadOnlyValidValue` (line 32) -- fuzz on `decimalsA`, `decimalsB`
  - `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized` (line 51) -- fuzz on `decimals`
  - `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` (line 60) -- fuzz on `decimals`, `storedDecimals`
  - `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized` (line 72) -- fuzz on `data`, `length`
  - `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` (line 88) -- fuzz on `data`, `length`, `storedDecimals`
  - `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized` (line 107) -- no fuzz
  - `testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken` (line 117) -- fuzz on `decimalsA`, `decimalsB`
  - `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized` (line 134) -- fuzz on `storedDecimals`

---

## Coverage Matrix

### `decimalsForTokenReadOnly` (line 29)

| Scenario | Covered? | Test(s) |
|---|---|---|
| Initial read (uninitialized, valid decimals) | Yes | `testDecimalsForTokenReadOnlyValidValue` (first half, before manual storage write) |
| Consistent read (stored matches live) | Yes | `testDecimalsForTokenReadOnlyValidValue` (branch where `storedDecimals == decimals`) |
| Inconsistent read (stored differs from live) | Yes | `testDecimalsForTokenReadOnlyValidValue` (branch where `storedDecimals != decimals`) |
| ReadFailure -- call to address(0) / EOA | Yes | `testDecimalsForTokenReadOnlyAddressZero` |
| ReadFailure -- token reverts | Yes | `testDecimalsForTokenReadOnlyTokenContractRevert` |
| ReadFailure -- return data > 255 | Yes | `testDecimalsForTokenReadOnlyInvalidValueTooLarge` |
| ReadFailure -- return data < 32 bytes | Yes | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` |
| decimals=0 boundary | Yes | Covered by fuzz range of `uint8` (includes 0) |
| decimals=255 boundary | Yes | Covered by fuzz range of `uint8` (includes 255) |
| ReadFailure returns stored value when initialized | Yes | All ReadFailure tests check both uninitialized (returns 0) and initialized (returns `storedDecimals`) |
| Does not write storage (view function) | Implicit | Function is `view`; Solidity compiler enforces no state mutation |

### `decimalsForToken` (line 109)

| Scenario | Covered? | Test(s) |
|---|---|---|
| Initial read stores value | Yes | `testDecimalsForTokenValidValue` (first call returns Initial, second returns Consistent/Inconsistent) |
| Consistent read | Yes | `testDecimalsForTokenValidValue` (branch `decimalsA == decimalsB`) |
| Inconsistent read | Yes | `testDecimalsForTokenValidValue` (branch `decimalsA != decimalsB`) |
| ReadFailure -- address(0) | Yes | `testDecimalsForTokenAddressZero` |
| ReadFailure -- token reverts | Yes | `testDecimalsForTokenTokenContractRevert` |
| ReadFailure -- return > 255 | Yes | `testDecimalsForTokenInvalidValueTooLarge` |
| ReadFailure -- return < 32 bytes | Yes | `testDecimalsForTokenInvalidValueNotEnoughData` |
| decimals=0 boundary | Yes | Covered by fuzz range |
| decimals=255 boundary | Yes | Covered by fuzz range |
| Storage immutability on ReadFailure (post-init) | Yes | `testDecimalsForTokenNoStorageWriteOnNonInitial` |
| Storage immutability on Inconsistent | Yes | `testDecimalsForTokenNoStorageWriteOnInconsistent` |
| No storage write on uninitialized ReadFailure | Yes | `testDecimalsForTokenNoStorageWriteOnUninitializedReadFailure` |
| Cross-token isolation | Yes | `testDecimalsForTokenCrossTokenIsolation` |

### `safeDecimalsForToken` (line 136)

| Scenario | Covered? | Test(s) |
|---|---|---|
| Initial read succeeds (no revert) | Yes | `testSafeDecimalsForTokenInitial` |
| Consistent read succeeds | Yes | `testSafeDecimalsForTokenValidValue` (branch `decimalsA == decimalsB`) |
| Inconsistent read reverts | Yes | `testSafeDecimalsForTokenValidValue` (branch `decimalsA != decimalsB`) |
| ReadFailure reverts -- address(0) uninitialized | Yes | `testSafeDecimalsForTokenAddressZeroUninitialized` |
| ReadFailure reverts -- address(0) initialized | Yes | `testSafeDecimalsForTokenAddressZeroInitialized` |
| ReadFailure reverts -- too large, uninitialized | Yes | `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized` |
| ReadFailure reverts -- too large, initialized | Yes | `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` |
| ReadFailure reverts -- not enough data, uninitialized | Yes | `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized` |
| ReadFailure reverts -- not enough data, initialized | Yes | `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` |
| ReadFailure reverts -- token reverts, uninitialized | Yes | `testSafeDecimalsForTokenTokenContractRevertUninitialized` |
| ReadFailure reverts -- token reverts, initialized | Yes | `testSafeDecimalsForTokenTokenContractRevertInitialized` |
| decimals=0 boundary | Yes | Covered by fuzz range |
| decimals=255 boundary | Yes | Covered by fuzz range |
| Correct revert selector and data | Yes | All revert tests use `vm.expectRevert` with exact selector + args |

### `safeDecimalsForTokenReadOnly` (line 160)

| Scenario | Covered? | Test(s) |
|---|---|---|
| Initial read succeeds (no revert) | Yes | `testSafeDecimalsForTokenReadOnlyValidValue` (first read is Initial) |
| Consistent read succeeds | Yes | `testSafeDecimalsForTokenReadOnlyValidValue` (branch `decimalsA == decimalsB`) |
| Inconsistent read reverts | Yes | `testSafeDecimalsForTokenReadOnlyValidValue` (branch `decimalsA != decimalsB`) |
| ReadFailure reverts -- address(0) uninitialized | Yes | `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized` |
| ReadFailure reverts -- address(0) initialized | Yes | `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized` |
| ReadFailure reverts -- too large, uninitialized | Yes | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized` |
| ReadFailure reverts -- too large, initialized | Yes | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` |
| ReadFailure reverts -- not enough data, uninitialized | Yes | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized` |
| ReadFailure reverts -- not enough data, initialized | Yes | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` |
| ReadFailure reverts -- token reverts, uninitialized | Yes | `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized` |
| ReadFailure reverts -- token reverts, initialized | Yes | `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized` |
| Cross-function storage agreement (init via `decimalsForToken`, read via `safeDecimalsForTokenReadOnly`) | Yes | `testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken` |
| decimals=0 boundary | Yes | Covered by fuzz range |
| decimals=255 boundary | Yes | Covered by fuzz range |

### `TOFU_DECIMALS_SELECTOR` constant (line 15)

| Scenario | Covered? | Test(s) |
|---|---|---|
| Matches `IERC20.decimals.selector` | Yes | `testDecimalsSelector` |

---

## Findings

### A02-1: `decimalsForTokenReadOnly` lacks explicit cross-token isolation test [INFORMATIONAL]

The `decimalsForTokenReadOnly` test file does not include a dedicated cross-token isolation test analogous to `testDecimalsForTokenCrossTokenIsolation` in the `decimalsForToken` test file. Because `decimalsForTokenReadOnly` is a `view` function that does not write storage, and because `decimalsForToken` delegates to it for the read logic, the risk is minimal -- the isolation property is transitively tested through `decimalsForToken`. However, a dedicated test at the `ReadOnly` level would provide defense-in-depth by verifying that manually pre-populated storage for one token does not leak into reads for another token.

### A02-2: `safeDecimalsForToken` lacks cross-function storage agreement test [INFORMATIONAL]

The `safeDecimalsForTokenReadOnly` test file includes `testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken` (line 117), which verifies that storage initialized via `decimalsForToken` is correctly read back through `safeDecimalsForTokenReadOnly`. However, there is no analogous test in the `safeDecimalsForToken` test file that initializes via `decimalsForToken` and then reads via `safeDecimalsForToken`. While this is implicitly covered (since `safeDecimalsForToken` calls `decimalsForToken` internally, and the `testSafeDecimalsForTokenValidValue` test exercises the init-then-read path within the same function), an explicit cross-function test would be marginally more thorough. Very low priority.

### A02-3: No explicit test for `decimals=0` and `decimals=255` as concrete (non-fuzz) cases [INFORMATIONAL]

All uint8 boundary values (0 and 255) are covered by the fuzz parameter space since the fuzzer generates `uint8` inputs that include 0 and 255 in the natural range. However, there are no concrete (non-fuzz) test cases that explicitly pass `decimals=0` or `decimals=255` as hardcoded values to guarantee these exact boundary values are always exercised regardless of fuzzer configuration (e.g., fuzz run count). For a security-critical boundary like `decimals=0` (distinguishing stored zero from uninitialized storage), an explicit concrete test would provide stronger assurance. The `decimals=0` case is particularly important because the `initialized` boolean flag exists specifically to handle it.

Note: Previous audit passes have already flagged the `decimals=0` boundary testing gap and concrete tests may have been added at other layers. This finding documents the gap at the `LibTOFUTokenDecimalsImplementation` unit test level specifically.

No findings.  above are informational observations only. The test coverage for `LibTOFUTokenDecimalsImplementation.sol` is comprehensive. All four source functions have thorough test coverage across happy paths, error/failure paths, edge cases, and fuzz tests. The test suite covers all key scenarios identified in the audit checklist.
