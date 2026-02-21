# Audit Pass 2 -- Test Coverage: LibTOFUTokenDecimals

**Auditor Agent:** A03
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimals.sol`

## Evidence of Thorough Reading

### Source: `LibTOFUTokenDecimals` (library)

**Constants:**
- `TOFU_DECIMALS_DEPLOYMENT` (line 29-30): `ITOFUTokenDecimals(0x200e12D10bb0c5E4a17e7018f0F1161919bb9389)`
- `TOFU_DECIMALS_EXPECTED_CODE_HASH` (line 36-37): `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41`
- `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (lines 44-45): long hex literal

**Error:**
- `TOFUTokenDecimalsNotDeployed(address expectedAddress)` (line 24)

**Functions:**
- `ensureDeployed()` (line 51-58): `internal view` -- checks code.length != 0 and codehash matches
- `decimalsForTokenReadOnly(address token)` (line 66-71): `internal view` -- calls ensureDeployed then delegates
- `decimalsForToken(address token)` (line 79-84): `internal` -- calls ensureDeployed then delegates
- `safeDecimalsForToken(address token)` (line 89-92): `internal` -- calls ensureDeployed then delegates
- `safeDecimalsForTokenReadOnly(address token)` (line 97-100): `internal view` -- calls ensureDeployed then delegates

### Test Functions Across All Test Files

**`LibTOFUTokenDecimals.t.sol` (LibTOFUTokenDecimalsTest):**
1. `testDeployAddress` -- verifies Zoltu deployment matches TOFU_DECIMALS_DEPLOYMENT
2. `testNotMetamorphic` -- checks no metamorphic opcodes in singleton bytecode
3. `testNoCBORMetadata` -- checks no CBOR metadata in singleton bytecode
4. `testExpectedCodeHash` -- asserts deployed codehash matches TOFU_DECIMALS_EXPECTED_CODE_HASH
5. `testExpectedCreationCode` -- asserts creation code matches TOFU_DECIMALS_EXPECTED_CREATION_CODE
6. `testEnsureDeployedRevert` -- reverts when no contract at expected address
7. `testEnsureDeployedRevertWrongCodeHash` -- reverts when code exists but codehash differs
8. `testDecimalsForTokenReadOnlyRevert` -- reverts when singleton not deployed
9. `testDecimalsForTokenRevert` -- reverts when singleton not deployed
10. `testSafeDecimalsForTokenRevert` -- reverts when singleton not deployed
11. `testSafeDecimalsForTokenReadOnlyRevert` -- reverts when singleton not deployed

**`LibTOFUTokenDecimals.decimalsForToken.t.sol` (LibTOFUTokenDecimalsDecimalsForTokenTest):**
1. `testDecimalsForTokenAddressZero` -- ReadFailure for address(0)
2. `testDecimalsForTokenValidValue(uint8,uint8)` -- fuzz: Initial then Consistent/Inconsistent
3. `testDecimalsForTokenInvalidValueTooLarge(uint256)` -- fuzz: ReadFailure for >0xff
4. `testDecimalsForTokenInvalidValueTooLargeInitialized(uint8,uint256)` -- fuzz: ReadFailure after init
5. `testDecimalsForTokenInvalidValueNotEnoughData(bytes,uint256)` -- fuzz: ReadFailure for short data
6. `testDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8,bytes,uint256)` -- fuzz: ReadFailure after init
7. `testDecimalsForTokenTokenContractRevert` -- ReadFailure when token reverts
8. `testDecimalsForTokenTokenContractRevertInitialized(uint8)` -- ReadFailure when token reverts after init

**`LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (LibTOFUTokenDecimalsDecimalsForTokenReadOnlyTest):**
1. `testDecimalsForTokenReadOnlyAddressZero` -- ReadFailure for address(0)
2. `testDecimalsForTokenReadOnlyValidValue(uint8,uint8)` -- fuzz: always Initial (no storage write)
3. `testDecimalsForTokenReadOnlyConsistentInconsistent(uint8,uint8)` -- fuzz: Consistent/Inconsistent after init
4. `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` -- proves read-only does not persist
5. `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` -- fuzz: ReadFailure for >0xff
6. `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8,uint256)` -- fuzz: ReadFailure after init
7. `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes,uint256)` -- fuzz: ReadFailure for short data
8. `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8,bytes,uint256)` -- fuzz: ReadFailure after init
9. `testDecimalsForTokenReadOnlyTokenContractRevert` -- ReadFailure when token reverts
10. `testDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` -- ReadFailure when token reverts after init

**`LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` (LibTOFUTokenDecimalsSafeDecimalsForTokenTest):**
1. `testSafeDecimalsForTokenAddressZero` -- reverts with ReadFailure for address(0)
2. `testSafeDecimalsForTokenValidValue(uint8)` -- fuzz: returns correct decimals
3. `testSafeDecimalsForTokenConsistentInconsistent(uint8,uint8)` -- fuzz: succeeds or reverts Inconsistent
4. `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint8,uint256)` -- fuzz: reverts after init
5. `testSafeDecimalsForTokenInvalidValueTooLarge(uint256)` -- fuzz: reverts for >0xff
6. `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8,bytes,uint256)` -- fuzz: reverts after init
7. `testSafeDecimalsForTokenInvalidValueNotEnoughData(bytes,uint256)` -- fuzz: reverts for short data
8. `testSafeDecimalsForTokenContractRevertInitialized(uint8)` -- reverts when token reverts after init
9. `testSafeDecimalsForTokenContractRevert` -- reverts when token reverts

**`LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` (LibTOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest):**
1. `testSafeDecimalsForTokenReadOnlyAddressZero` -- reverts with ReadFailure for address(0)
2. `testSafeDecimalsForTokenReadOnlyValidValue(uint8)` -- fuzz: returns correct decimals
3. `testSafeDecimalsForTokenReadOnlyConsistentInconsistent(uint8,uint8)` -- fuzz: succeeds or reverts
4. `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8,uint256)` -- fuzz: reverts after init
5. `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` -- fuzz: reverts for >0xff
6. `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8,bytes,uint256)` -- fuzz: reverts after init
7. `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes,uint256)` -- fuzz: reverts for short data
8. `testSafeDecimalsForTokenReadOnlyContractRevertInitialized(uint8)` -- reverts when token reverts after init
9. `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` -- proves read-only does not persist
10. `testSafeDecimalsForTokenReadOnlyContractRevert` -- reverts when token reverts

**`LibTOFUTokenDecimals.realTokens.t.sol` (LibTOFUTokenDecimalsRealTokensTest):**
1. `testRealTokenWETH` -- WETH 18 decimals Initial then Consistent
2. `testRealTokenUSDC` -- USDC 6 decimals Initial then Consistent
3. `testRealTokenWBTC` -- WBTC 8 decimals Initial then Consistent
4. `testRealTokenDAI` -- DAI 18 decimals Initial then Consistent
5. `testRealTokenDecimalsForTokenReadOnlyWETH` -- read-only then stateful for WETH
6. `testRealTokenDecimalsForTokenReadOnlyUSDC` -- read-only then stateful for USDC
7. `testRealTokenDecimalsForTokenReadOnlyWBTC` -- read-only then stateful for WBTC
8. `testRealTokenDecimalsForTokenReadOnlyDAI` -- read-only then stateful for DAI
9. `testRealTokenSafeDecimalsForTokenWETH` -- safe read WETH
10. `testRealTokenSafeDecimalsForTokenUSDC` -- safe read USDC
11. `testRealTokenSafeDecimalsForTokenWBTC` -- safe read WBTC
12. `testRealTokenSafeDecimalsForTokenDAI` -- safe read DAI
13. `testRealTokenSafeDecimalsForTokenReadOnlyWETH` -- safe read-only WETH
14. `testRealTokenSafeDecimalsForTokenReadOnlyUSDC` -- safe read-only USDC
15. `testRealTokenSafeDecimalsForTokenReadOnlyWBTC` -- safe read-only WBTC
16. `testRealTokenSafeDecimalsForTokenReadOnlyDAI` -- safe read-only DAI
17. `testRealTokenCrossTokenIsolation` -- multi-token storage isolation

## Coverage Analysis

### Hardcoded Constants Testing

- **TOFU_DECIMALS_DEPLOYMENT address**: Tested via `testDeployAddress` which deploys via Zoltu and asserts the address matches. ADEQUATE.
- **TOFU_DECIMALS_EXPECTED_CODE_HASH**: Tested via `testExpectedCodeHash` which deploys a fresh instance and asserts its codehash matches the constant. ADEQUATE.
- **TOFU_DECIMALS_EXPECTED_CREATION_CODE**: Tested via `testExpectedCreationCode` which asserts `type(TOFUTokenDecimals).creationCode` matches the constant. ADEQUATE.

### Function Coverage Summary

- **`ensureDeployed()`**: Tested for success (via `testDeployAddress`), revert on no code (`testEnsureDeployedRevert`), and revert on wrong codehash (`testEnsureDeployedRevertWrongCodeHash`). ADEQUATE.
- **`decimalsForToken(address)`**: Tested for all four outcomes (Initial, Consistent, Inconsistent, ReadFailure), including address(0), value too large, insufficient data, contract revert, and all of these both uninitialized and initialized. ADEQUATE.
- **`decimalsForTokenReadOnly(address)`**: Tested for all four outcomes, does-not-write-storage assertion, and all failure modes both uninitialized and initialized. ADEQUATE.
- **`safeDecimalsForToken(address)`**: Tested for success, and revert paths for ReadFailure and Inconsistent, in both uninitialized and initialized states. ADEQUATE.
- **`safeDecimalsForTokenReadOnly(address)`**: Tested for success, revert paths, does-not-write-storage, in both states. ADEQUATE.

## Findings

No findings. Coverage for `LibTOFUTokenDecimals.sol` is thorough.

All five functions (`ensureDeployed`, `decimalsForToken`, `decimalsForTokenReadOnly`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) have dedicated test coverage across all logical branches. Every error path (`TOFUTokenDecimalsNotDeployed` for no code and wrong codehash; `TokenDecimalsReadFailure` for Inconsistent and ReadFailure) is exercised. The three hardcoded constants (address, codehash, creation code) are each independently verified. Fuzz testing covers the full `uint8` decimals range. Real-token fork tests validate integration against production contracts. The does-not-write-storage invariant is explicitly tested for both read-only functions.
