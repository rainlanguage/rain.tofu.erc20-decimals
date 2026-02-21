# Audit Pass 2 - Test Coverage: `src/lib/LibTOFUTokenDecimals.sol`

**Agent:** A04
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimals.sol` (101 lines)

## Source File Summary

`LibTOFUTokenDecimals` is a caller-convenience library wrapping the deployed `TOFUTokenDecimals` singleton. It contains:

- **Error:** `TOFUTokenDecimalsNotDeployed(address expectedAddress)` (line 24)
- **Constants:**
  - `TOFU_DECIMALS_DEPLOYMENT` - hardcoded singleton address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` (line 29-30)
  - `TOFU_DECIMALS_EXPECTED_CODE_HASH` - `bytes32` hash for runtime code verification (line 36-37)
  - `TOFU_DECIMALS_EXPECTED_CREATION_CODE` - `bytes` init bytecode for Zoltu deployment (line 44-45)
- **Functions:**
  - `ensureDeployed()` - `internal view`, reverts if no code at singleton address OR codehash mismatch (lines 51-58)
  - `decimalsForTokenReadOnly(address)` - `internal view`, calls `ensureDeployed()` then delegates to singleton (lines 66-71)
  - `decimalsForToken(address)` - `internal`, calls `ensureDeployed()` then delegates to singleton (lines 79-84)
  - `safeDecimalsForToken(address)` - `internal`, calls `ensureDeployed()` then delegates to singleton (lines 89-92)
  - `safeDecimalsForTokenReadOnly(address)` - `internal view`, calls `ensureDeployed()` then delegates to singleton (lines 97-100)

## Test Files Reviewed

### 1. `test/src/lib/LibTOFUTokenDecimals.t.sol` (139 lines)

Evidence of thorough reading:

- **Lines 12-31:** Defines `LibTOFUTokenDecimalsTest` contract with external wrappers for all 5 library functions (`externalEnsureDeployed`, `externalDecimalsForTokenReadOnly`, `externalDecimalsForToken`, `externalSafeDecimalsForToken`, `externalSafeDecimalsForTokenReadOnly`). These wrappers exist because library `internal` functions cannot be called via `this.` directly; the wrappers enable `vm.expectRevert` testing.
- **Lines 33-40:** `testDeployAddress()` - Forks via `ETH_RPC_URL`, deploys via Zoltu, asserts deployed address matches `TOFU_DECIMALS_DEPLOYMENT`, then calls `ensureDeployed()` to confirm the happy path.
- **Lines 42-50:** `testNotMetamorphic()` - Deploys singleton locally, checks bytecode contains no metamorphic opcodes (SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2).
- **Lines 52-59:** `testNoCBORMetadata()` - Deploys singleton locally, checks no Solidity CBOR metadata is present.
- **Lines 61-65:** `testExpectedCodeHash()` - Deploys singleton locally, asserts `address.codehash` matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.
- **Lines 67-69:** `testExpectedCreationCode()` - Pure test, asserts `type(TOFUTokenDecimals).creationCode` matches `TOFU_DECIMALS_EXPECTED_CREATION_CODE`.
- **Lines 71-79:** `testEnsureDeployedRevert()` - Tests revert when NO code at the singleton address (no fork, no deployment). Expects `TOFUTokenDecimalsNotDeployed` error.
- **Lines 81-94:** `testEnsureDeployedRevertWrongCodeHash()` - Uses `vm.etch` to place different bytecode at the singleton address, asserts `ensureDeployed()` reverts with `TOFUTokenDecimalsNotDeployed`. This tests the codehash mismatch branch specifically.
- **Lines 96-138:** Four tests (`testDecimalsForTokenReadOnlyRevert`, `testDecimalsForTokenRevert`, `testSafeDecimalsForTokenRevert`, `testSafeDecimalsForTokenReadOnlyRevert`) verify that all four main functions revert with `TOFUTokenDecimalsNotDeployed` when the singleton is not deployed.

### 2. `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol` (138 lines)

Evidence of thorough reading:

- **Constructor (lines 12-19):** Forks, deploys via Zoltu, asserts address, calls `ensureDeployed()`.
- **`testDecimalsForTokenAddressZero` (line 21):** Tests `address(0)` yields `ReadFailure` with 0 decimals.
- **`testDecimalsForTokenValidValue` (line 27):** Fuzz test with `uint8 decimalsA, decimalsB`. Tests Initial on first call, then Consistent/Inconsistent depending on match.
- **`testDecimalsForTokenInvalidValueTooLarge` (line 46):** Fuzz test, mocks value > 0xff, asserts `ReadFailure`.
- **`testDecimalsForTokenInvalidValueTooLargeInitialized` (line 55):** Same but with prior initialization; asserts stored value preserved on `ReadFailure`.
- **`testDecimalsForTokenInvalidValueNotEnoughData` (line 72):** Fuzz test with truncated return data (0-31 bytes), asserts `ReadFailure`.
- **`testDecimalsForTokenInvalidValueNotEnoughDataInitialized` (line 87):** Same but with prior initialization.
- **`testDecimalsForTokenTokenContractRevert` (line 113):** Uses `vm.etch(hex"fd")` for reverting contract, asserts `ReadFailure`.
- **`testDecimalsForTokenTokenContractRevertInitialized` (line 121):** Same but with prior initialization; stored value preserved.

### 3. `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (165 lines)

Evidence of thorough reading:

- **Constructor (lines 11-19):** Same fork + deploy + assert pattern.
- **`testDecimalsForTokenReadOnlyAddressZero` (line 21):** `view` test, `address(0)` yields `ReadFailure`.
- **`testDecimalsForTokenReadOnlyValidValue` (line 27):** Fuzz test. Both calls return `Initial` because read-only never writes storage -- key behavioral difference from stateful variant.
- **`testDecimalsForTokenReadOnlyConsistentInconsistent` (line 43):** First initializes via stateful `decimalsForToken`, then verifies read-only sees `Consistent` or `Inconsistent`.
- **`testDecimalsForTokenReadOnlyDoesNotWriteStorage` (line 65):** Calls read-only, then stateful; stateful still sees `Initial`, proving no storage write.
- **Lines 78-164:** Mirror of the invalid-value, truncated-data, and revert tests from the stateful variant, adapted for read-only with pre-initialization via `decimalsForToken`.

### 4. `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` (127 lines)

Evidence of thorough reading:

- **Constructor (lines 13-21):** Same fork + deploy + assert pattern.
- **`testSafeDecimalsForTokenAddressZero` (line 23):** Expects revert with `TokenDecimalsReadFailure`.
- **`testSafeDecimalsForTokenValidValue` (line 28):** Fuzz test, asserts correct return.
- **`testSafeDecimalsForTokenConsistentInconsistent` (line 34):** Fuzz test, asserts success on consistent, revert with `Inconsistent` on mismatch.
- **Lines 54-126:** Full suite of invalid-value, truncated-data, and revert tests with both uninitialized and pre-initialized storage.

### 5. `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` (142 lines)

Evidence of thorough reading:

- **Constructor (lines 13-21):** Same fork + deploy + assert pattern.
- **`testSafeDecimalsForTokenReadOnlyAddressZero` (line 23):** Expects revert with `TokenDecimalsReadFailure`.
- **`testSafeDecimalsForTokenReadOnlyValidValue` (line 28):** Fuzz test, asserts correct return.
- **`testSafeDecimalsForTokenReadOnlyConsistentInconsistent` (line 34):** Uses stateful `decimalsForToken` to initialize, then tests read-only safe variant.
- **`testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` (line 126):** Calls read-only safe, then stateful; stateful still sees `Initial`.
- **Lines 54-141:** Full suite of invalid-value, truncated-data, and revert tests with both uninitialized and pre-initialized storage.

### 6. `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol` (122 lines)

Evidence of thorough reading:

- **Constants (lines 15-21):** WETH (18), USDC (6), WBTC (8), DAI (18) -- real mainnet addresses.
- **Constructor (lines 23-28):** Forks, deploys, asserts, calls `ensureDeployed()`.
- **`testRealTokenWETH` (line 31):** Tests `decimalsForToken` Initial + Consistent with real WETH.
- **`testRealTokenUSDC` (line 42):** Same for USDC (6 decimals).
- **`testRealTokenWBTC` (line 53):** Same for WBTC (8 decimals).
- **`testRealTokenDAI` (line 64):** Same for DAI (18 decimals).
- **`testRealTokenDecimalsForTokenReadOnly` (line 76):** Tests read-only on real WETH: Initial then Consistent after stateful init.
- **`testRealTokenSafeDecimalsForToken` (line 89):** Tests safe variant on real USDC.
- **`testRealTokenSafeDecimalsForTokenReadOnly` (line 98):** Tests safe read-only on real WBTC, with stateful init in between.
- **`testRealTokenCrossTokenIsolation` (line 110):** Initializes WETH and USDC, verifies each maintains own decimals.

## Coverage Analysis

### Functions Coverage Matrix

| Function | Tested Happy Path | Tested Revert/Error | Fuzz Tested | Real Token Test | Does-Not-Write Test |
|---|---|---|---|---|---|
| `ensureDeployed()` | Yes (constructor of all test contracts) | Yes (no code + wrong codehash) | N/A | Yes (constructor) | N/A |
| `decimalsForToken()` | Yes | Yes (multiple failure modes) | Yes | Yes (WETH/USDC/WBTC/DAI) | N/A (stateful by design) |
| `decimalsForTokenReadOnly()` | Yes | Yes (multiple failure modes) | Yes | Yes (WETH) | Yes |
| `safeDecimalsForToken()` | Yes | Yes (revert on failure/inconsistency) | Yes | Yes (USDC) | N/A (stateful by design) |
| `safeDecimalsForTokenReadOnly()` | Yes | Yes (revert on failure/inconsistency) | Yes | Yes (WBTC) | Yes |

### Constants Coverage

| Constant | Verified By Test |
|---|---|
| `TOFU_DECIMALS_DEPLOYMENT` | `testDeployAddress()` - asserts Zoltu deploy matches constant |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `testExpectedCodeHash()` - asserts deployed codehash matches |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `testExpectedCreationCode()` - asserts creation code matches |

### `ensureDeployed()` Sub-conditions

| Condition | Test |
|---|---|
| No code at address (`code.length == 0`) | `testEnsureDeployedRevert()` - no deployment, empty address |
| Wrong codehash | `testEnsureDeployedRevertWrongCodeHash()` - `vm.etch` with different bytecode |

## Findings

### A04-001 [INFO] All five library functions have dedicated test files with comprehensive coverage

All functions (`ensureDeployed`, `decimalsForToken`, `decimalsForTokenReadOnly`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) are tested across 6 test files. Each function is tested for:
- Happy-path behavior
- `address(0)` input
- Invalid return data (too large, truncated, revert)
- Both uninitialized and pre-initialized storage states
- Fuzz inputs where applicable
- `ensureDeployed` revert propagation (singleton not deployed)

No missing function-level coverage was identified.

### A04-002 [INFO] `ensureDeployed()` both sub-conditions tested

The `ensureDeployed()` function's two revert conditions are explicitly covered:
1. `testEnsureDeployedRevert()` tests the `code.length == 0` branch (no fork/deploy, address is empty).
2. `testEnsureDeployedRevertWrongCodeHash()` tests the `codehash !=` branch via `vm.etch` with different bytecode.

Additionally, all four wrapper functions are tested for revert when the singleton is not deployed (`testDecimalsForTokenReadOnlyRevert`, `testDecimalsForTokenRevert`, `testSafeDecimalsForTokenRevert`, `testSafeDecimalsForTokenReadOnlyRevert`).

### A04-003 [INFO] All three constants verified by tests

- `TOFU_DECIMALS_DEPLOYMENT` verified by Zoltu deployment address assertion in `testDeployAddress()` and in every test contract constructor.
- `TOFU_DECIMALS_EXPECTED_CODE_HASH` verified by `testExpectedCodeHash()` comparing deployed contract's `codehash`.
- `TOFU_DECIMALS_EXPECTED_CREATION_CODE` verified by `testExpectedCreationCode()` comparing `type(TOFUTokenDecimals).creationCode`.

### A04-004 [INFO] Real-token fork tests cover all 4 main functions

`LibTOFUTokenDecimals.realTokens.t.sol` tests:
- `decimalsForToken` with WETH (18), USDC (6), WBTC (8), DAI (18)
- `decimalsForTokenReadOnly` with WETH
- `safeDecimalsForToken` with USDC
- `safeDecimalsForTokenReadOnly` with WBTC
- Cross-token isolation (WETH + USDC)

### A04-005 [INFO] Does-not-write-storage tests present for both read-only variants

- `testDecimalsForTokenReadOnlyDoesNotWriteStorage` in `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` line 65.
- `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` in `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` line 126.

Both prove that read-only calls do not initialize storage by subsequently calling the stateful variant and observing `Initial` outcome.

### A04-006 [LOW] Real-token tests for `safeDecimalsForTokenReadOnly` test only one token

`testRealTokenSafeDecimalsForTokenReadOnly` tests only WBTC (8 decimals). While mock-based fuzz testing covers the full `uint8` range, real-token integration tests for this function could be strengthened by testing tokens with 18 decimals (WETH/DAI) and 6 decimals (USDC) to exercise the same variety as `decimalsForToken` real-token tests.

Similarly, `testRealTokenDecimalsForTokenReadOnly` only tests WETH and `testRealTokenSafeDecimalsForToken` only tests USDC. The stateful `decimalsForToken` is the only function tested against all 4 real tokens.

**Impact:** Very low. The underlying implementation is shared, so if `decimalsForToken` works with all 4 tokens, the read-only and safe variants almost certainly do too. The fuzz tests provide full-range coverage via mocks.

### A04-007 [LOW] No real-token test for `Inconsistent` outcome with actual on-chain tokens

All real-token tests only exercise `Initial` and `Consistent` outcomes. There is no real-token test demonstrating `Inconsistent` detection. This is understandable since well-behaved tokens don't change their decimals, but it means the `Inconsistent` path is only validated via `vm.mockCall`.

**Impact:** Very low. The `Inconsistent` path is thoroughly fuzz-tested with mocks. Testing with real tokens would require a malicious/upgradeable token that changes `decimals()` return value, which is not readily available on mainnet.

### A04-008 [INFO] Bytecode safety tests present

`testNotMetamorphic()` and `testNoCBORMetadata()` in `LibTOFUTokenDecimals.t.sol` provide additional safety assurance that the singleton bytecode cannot be metamorphic and has no CBOR metadata, supporting the deterministic deployment model.

## Summary

Test coverage for `src/lib/LibTOFUTokenDecimals.sol` is **comprehensive**. All functions, constants, error paths, and edge cases are tested. The `ensureDeployed()` function's two revert branches are both explicitly covered. Read-only variants have does-not-write-storage tests. Real-token fork tests cover all four main functions. No CRITICAL, HIGH, or MEDIUM gaps were identified. Two LOW findings note minor opportunities to expand real-token test breadth, but these have negligible impact given the thorough fuzz and mock coverage already in place.
