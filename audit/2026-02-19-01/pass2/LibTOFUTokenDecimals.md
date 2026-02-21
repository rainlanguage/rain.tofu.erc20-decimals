# Pass 2 -- Test Coverage Audit: `LibTOFUTokenDecimals.sol`

**Auditor**: A04
**Date**: 2026-02-19
**Source file**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol`

---

## 1. Evidence of Thorough Reading

### Source File: `LibTOFUTokenDecimals` (library)

| Item | Type | Line |
|---|---|---|
| `LibTOFUTokenDecimals` | library | 21 |
| `TOFUTokenDecimalsNotDeployed(address)` | error | 23 |
| `TOFU_DECIMALS_DEPLOYMENT` | constant (`ITOFUTokenDecimals`) | 28-29 |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | constant (`bytes32`) | 35-36 |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | constant (`bytes`) | 42-43 |
| `ensureDeployed()` | function (`internal view`) | 48 |
| `decimalsForTokenReadOnly(address)` | function (`internal view`) | 58 |
| `decimalsForToken(address)` | function (`internal`) | 66 |
| `safeDecimalsForToken(address)` | function (`internal`) | 74 |
| `safeDecimalsForTokenReadOnly(address)` | function (`internal view`) | 80 |

### Test File: `LibTOFUTokenDecimals.t.sol`

Contract: `LibTOFUTokenDecimalsTest`

| Test Function |
|---|
| `externalEnsureDeployed()` (helper) |
| `externalDecimalsForTokenReadOnly(address)` (helper) |
| `externalDecimalsForToken(address)` (helper) |
| `externalSafeDecimalsForToken(address)` (helper) |
| `externalSafeDecimalsForTokenReadOnly(address)` (helper) |
| `testDeployAddress()` |
| `testExpectedCodeHash()` |
| `testExpectedCreationCode()` |
| `testEnsureDeployedRevert()` |
| `testEnsureDeployedRevertWrongCodeHash()` |
| `testDecimalsForTokenReadOnlyRevert()` |
| `testDecimalsForTokenRevert()` |
| `testSafeDecimalsForTokenRevert()` |
| `testSafeDecimalsForTokenReadOnlyRevert()` |

### Test File: `LibTOFUTokenDecimals.decimalsForToken.t.sol`

Contract: `LibTOFUTokenDecimalsDecimalsForTokenTest`

| Test Function |
|---|
| `testDecimalsForTokenAddressZero()` |
| `testDecimalsForTokenValidValue(uint8, uint8)` (fuzz) |
| `testDecimalsForTokenInvalidValueTooLarge(uint256)` (fuzz) |
| `testDecimalsForTokenInvalidValueTooLargeInitialized(uint8, uint256)` (fuzz) |
| `testDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256)` (fuzz) |
| `testDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` (fuzz) |
| `testDecimalsForTokenTokenContractRevert()` |
| `testDecimalsForTokenTokenContractRevertInitialized(uint8)` (fuzz) |

### Test File: `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

Contract: `LibTOFUTokenDecimalsDecimalsForTokenReadOnlyTest`

| Test Function |
|---|
| `testDecimalsForTokenReadOnlyAddressZero()` |
| `testDecimalsForTokenReadOnlyValidValue(uint8, uint8)` (fuzz) |
| `testDecimalsForTokenReadOnlyConsistentInconsistent(uint8, uint8)` (fuzz) |
| `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` (fuzz) |
| `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8, uint256)` (fuzz) |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256)` (fuzz) |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` (fuzz) |
| `testDecimalsForTokenReadOnlyTokenContractRevert()` |
| `testDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` (fuzz) |

### Test File: `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`

Contract: `LibTOFUTokenDecimalsSafeDecimalsForTokenTest`

| Test Function |
|---|
| `testSafeDecimalsForTokenAddressZero()` |
| `testSafeDecimalsForTokenValidValue(uint8)` (fuzz) |
| `testSafeDecimalsForTokenConsistentInconsistent(uint8, uint8)` (fuzz) |
| `testSafeDecimalsForTokenInvalidValueTooLarge(uint256)` (fuzz) |
| `testSafeDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256)` (fuzz) |
| `testSafeDecimalsForTokenContractRevert()` |

### Test File: `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

Contract: `LibTOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest`

| Test Function |
|---|
| `testSafeDecimalsForTokenReadOnlyAddressZero()` |
| `testSafeDecimalsForTokenReadOnlyValidValue(uint8)` (fuzz) |
| `testSafeDecimalsForTokenReadOnlyConsistentInconsistent(uint8, uint8)` (fuzz) |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` (fuzz) |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256)` (fuzz) |
| `testSafeDecimalsForTokenReadOnlyContractRevert()` |

---

## 2. Test Coverage Findings

### A04-1: `ensureDeployed()` both paths tested [INFO]

**Status**: Adequately covered.

`testEnsureDeployedRevert()` in `LibTOFUTokenDecimals.t.sol` (line 50) tests the path where no contract code exists at the expected address (runs without a fork, so address has no code). `testEnsureDeployedRevertWrongCodeHash()` (line 60) uses `vm.etch` to place different bytecode at the expected address, testing the codehash mismatch branch. The happy path is exercised in `testDeployAddress()` (line 31), which deploys via Zoltu on a fork and then calls `ensureDeployed()` successfully. Both branches of the `if` condition in `ensureDeployed()` are covered.

### A04-2: `TOFUTokenDecimalsNotDeployed` error tested [INFO]

**Status**: Adequately covered.

The error is tested in 6 separate tests in `LibTOFUTokenDecimals.t.sol`:
- `testEnsureDeployedRevert` (no code at address)
- `testEnsureDeployedRevertWrongCodeHash` (wrong codehash)
- `testDecimalsForTokenReadOnlyRevert` (singleton not deployed, calling `decimalsForTokenReadOnly`)
- `testDecimalsForTokenRevert` (singleton not deployed, calling `decimalsForToken`)
- `testSafeDecimalsForTokenRevert` (singleton not deployed, calling `safeDecimalsForToken`)
- `testSafeDecimalsForTokenReadOnlyRevert` (singleton not deployed, calling `safeDecimalsForTokenReadOnly`)

All four wrapper functions plus `ensureDeployed` directly are tested for the revert case. Each test verifies the exact selector and parameter encoding of the error.

### A04-3: All 4 wrapper functions tested through the singleton [INFO]

**Status**: Adequately covered.

Each of the 4 wrapper functions has a dedicated test file that deploys the real singleton via Zoltu on a mainnet fork and exercises the function through it:
- `decimalsForToken` -- `LibTOFUTokenDecimals.decimalsForToken.t.sol` (8 test functions)
- `decimalsForTokenReadOnly` -- `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (9 test functions)
- `safeDecimalsForToken` -- `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` (6 test functions)
- `safeDecimalsForTokenReadOnly` -- `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` (6 test functions)

All tests call the library functions (which internally call `ensureDeployed()` then delegate to the singleton), so the full call chain is exercised.

### A04-4: Creation code constant tested against compiled bytecode [INFO]

**Status**: Adequately covered.

`testExpectedCreationCode()` in `LibTOFUTokenDecimals.t.sol` (line 46) asserts `type(TOFUTokenDecimals).creationCode == LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CREATION_CODE`. This is a pure test (no fork needed) that directly compares the Solidity compiler output against the hardcoded constant, ensuring they remain in sync.

### A04-5: Hardcoded address and codehash verified [INFO]

**Status**: Adequately covered.

- **Address**: `testDeployAddress()` deploys via Zoltu on a mainnet fork and asserts the resulting address equals `TOFU_DECIMALS_DEPLOYMENT`. This confirms the deterministic deployment address matches the hardcoded constant.
- **Codehash**: `testExpectedCodeHash()` deploys a fresh `TOFUTokenDecimals` via `new` and asserts its `codehash` equals `TOFU_DECIMALS_EXPECTED_CODE_HASH`.

Both constants are validated against actual compiled/deployed artifacts.

### A04-6: Edge case -- `address(0)` token [INFO]

**Status**: Adequately covered.

All four wrapper functions are tested with `address(0)`:
- `testDecimalsForTokenAddressZero` -- returns `(ReadFailure, 0)`
- `testDecimalsForTokenReadOnlyAddressZero` -- returns `(ReadFailure, 0)`
- `testSafeDecimalsForTokenAddressZero` -- reverts with `TokenDecimalsReadFailure`
- `testSafeDecimalsForTokenReadOnlyAddressZero` -- reverts with `TokenDecimalsReadFailure`

### A04-7: Edge case -- singleton not deployed (undeployed chain) [INFO]

**Status**: Adequately covered.

The tests in `LibTOFUTokenDecimals.t.sol` that do NOT fork mainnet (lines 50-117) effectively simulate an undeployed chain. When no fork is created, the expected singleton address has zero code, and all four wrapper functions plus `ensureDeployed` are tested to revert with `TOFUTokenDecimalsNotDeployed`.

### A04-8: `decimalsForTokenReadOnly` read-only semantics not directly asserted via storage inspection [LOW]

**Observation**: `testDecimalsForTokenReadOnlyValidValue` (line 27 of the ReadOnly test file) correctly demonstrates that calling `decimalsForTokenReadOnly` twice always returns `Initial` (not `Consistent`), which indirectly proves that no state was written. However, there is no test that explicitly calls `decimalsForTokenReadOnly` followed by `decimalsForToken` to confirm that `decimalsForToken` still sees `Initial` (proving the read-only call did not write storage). The current test does prove the behavior via observing the outcome enum, but a direct cross-function assertion would make the read-only invariant more explicit.

**Severity**: LOW -- the existing tests do effectively demonstrate the read-only property through outcome observation, but a more direct assertion would strengthen confidence.

### A04-9: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` missing "initialized" state tests for read failures [LOW]

**Observation**: For `safeDecimalsForToken`, when storage is already initialized (a valid value was stored by a prior call) and then a subsequent call encounters a `ReadFailure` (e.g., token starts reverting), the `safe` variant should revert with `TokenDecimalsReadFailure`. However, the test file for `safeDecimalsForToken` does not include an "initialized then ReadFailure" scenario (e.g., `testSafeDecimalsForTokenContractRevertInitialized`). The non-safe `decimalsForToken` test file does have these `*Initialized` variants (`testDecimalsForTokenTokenContractRevertInitialized`, `testDecimalsForTokenInvalidValueTooLargeInitialized`, `testDecimalsForTokenInvalidValueNotEnoughDataInitialized`). The same gap exists for `safeDecimalsForTokenReadOnly`.

Note: The underlying implementation function `safeDecimalsForTokenReadOnly` and `safeDecimalsForToken` delegate to the non-safe variants and then check the outcome. Since the non-safe variants are thoroughly tested for initialized+failure states at the `LibTOFUTokenDecimalsImplementation` level, the actual code paths ARE covered. The gap here is specifically at the `LibTOFUTokenDecimals` (singleton wrapper) layer, which adds the `ensureDeployed()` guard but otherwise delegates directly.

**Severity**: LOW -- the underlying implementation is thoroughly tested for these scenarios; this is a test layering gap rather than an uncovered code path.

### A04-10: No test for `ensureDeployed` success when called standalone (outside wrapper context) after Zoltu deploy [INFO]

**Status**: Actually covered. `testDeployAddress()` in `LibTOFUTokenDecimals.t.sol` (line 37) calls `LibTOFUTokenDecimals.ensureDeployed()` directly after deploying via Zoltu. Additionally, every fork-based test contract constructor also calls `ensureDeployed()` as a setup assertion. This is well covered.

### A04-11: Tests exercise fuzz inputs comprehensively [INFO]

**Status**: Good coverage. Fuzz tests are used for:
- Valid decimals values (`uint8` range) for both Initial and Consistent/Inconsistent paths
- Invalid decimals values too large (`uint256 > 0xff`)
- Invalid return data too short (`bytes` with `length` bounded to `0..31`)
- Consistent vs inconsistent second reads (two `uint8` fuzz inputs)
- Initialized state variants for read failures (in the non-safe test files)

The fuzz testing strategy is sound and covers the relevant input domains.

---

## Summary

| ID | Severity | Description |
|---|---|---|
| A04-1 | INFO | `ensureDeployed()` both paths (no code, wrong codehash) tested |
| A04-2 | INFO | `TOFUTokenDecimalsNotDeployed` error tested across all entry points |
| A04-3 | INFO | All 4 wrapper functions tested through deployed singleton |
| A04-4 | INFO | Creation code constant verified against compiler output |
| A04-5 | INFO | Hardcoded address and codehash verified against Zoltu deploy and compiler output |
| A04-6 | INFO | `address(0)` token edge case covered for all 4 wrappers |
| A04-7 | INFO | Undeployed singleton (simulated undeployed chain) tested for all entry points |
| A04-8 | LOW | Read-only semantics not cross-verified with stateful function sequencing |
| A04-9 | LOW | `safe*` wrappers missing "initialized then ReadFailure" test scenarios at the singleton layer |
| A04-10 | INFO | `ensureDeployed()` standalone success path is tested |
| A04-11 | INFO | Fuzz testing strategy is comprehensive and covers relevant input domains |

**Overall Assessment**: Test coverage for `LibTOFUTokenDecimals.sol` is thorough. All functions, constants, and error paths are tested. The two LOW findings (A04-8, A04-9) identify minor layering gaps where the `safe*` wrapper tests could be more exhaustive for initialized+failure states, and where the read-only non-mutation invariant could be cross-verified more explicitly. No CRITICAL, HIGH, or MEDIUM issues were found. The underlying code paths for these gaps are covered at the implementation layer.
