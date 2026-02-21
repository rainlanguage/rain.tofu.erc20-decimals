# Audit Pass 2 — Test Coverage: `LibTOFUTokenDecimals.sol`

**Agent:** A03
**Date:** 2026-02-21
**Source:** `src/lib/LibTOFUTokenDecimals.sol` (101 lines)

---

## Evidence of Thorough Reading

### Source: `src/lib/LibTOFUTokenDecimals.sol`
- Library with 5 functions: `ensureDeployed()` (line 51), `decimalsForTokenReadOnly` (line 66), `decimalsForToken` (line 79), `safeDecimalsForToken` (line 89), `safeDecimalsForTokenReadOnly` (line 97).
- Three constants: `TOFU_DECIMALS_DEPLOYMENT` (line 29, address `0x200e...9389`), `TOFU_DECIMALS_EXPECTED_CODE_HASH` (line 36), `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (line 44).
- `ensureDeployed()` checks `code.length == 0 || codehash != expected` and reverts with `TOFUTokenDecimalsNotDeployed`.
- All four delegating functions call `ensureDeployed()` first, then delegate to `TOFU_DECIMALS_DEPLOYMENT.<method>(token)`.

### Test file: `LibTOFUTokenDecimals.t.sol` (139 lines)
- `LibTOFUTokenDecimalsTest` contract.
- External wrapper functions for all 5 library functions (lines 13-31).
- `testDeployAddress` (line 33): forks, deploys via Zoltu, asserts address matches constant, calls `ensureDeployed()`.
- `testNotMetamorphic` (line 47): deploys singleton, checks no metamorphic opcodes in bytecode.
- `testNoCBORMetadata` (line 56): deploys singleton, checks no CBOR metadata.
- `testExpectedCodeHash` (line 61): deploys singleton, asserts codehash matches constant.
- `testExpectedCreationCode` (line 67): pure test, asserts creation code matches constant.
- `testEnsureDeployedRevert` (line 71): no code at expected address, expects `TOFUTokenDecimalsNotDeployed` revert.
- `testEnsureDeployedRevertWrongCodeHash` (line 81): etches different code at expected address, expects same revert.
- `testDecimalsForTokenReadOnlyRevert` (line 96): no singleton deployed, expects revert on `decimalsForTokenReadOnly`.
- `testDecimalsForTokenRevert` (line 107): no singleton deployed, expects revert on `decimalsForToken`.
- `testSafeDecimalsForTokenRevert` (line 118): no singleton deployed, expects revert on `safeDecimalsForToken`.
- `testSafeDecimalsForTokenReadOnlyRevert` (line 129): no singleton deployed, expects revert on `safeDecimalsForTokenReadOnly`.

### Test file: `LibTOFUTokenDecimals.decimalsForToken.t.sol` (138 lines)
- `LibTOFUTokenDecimalsDecimalsForTokenTest` with fork + Zoltu deploy in constructor.
- `testDecimalsForTokenAddressZero` (line 21): address(0) returns ReadFailure, decimals=0.
- `testDecimalsForTokenValidValue` (line 27): fuzz test (uint8 decimalsA, uint8 decimalsB), tests Initial then Consistent/Inconsistent paths.
- `testDecimalsForTokenInvalidValueTooLarge` (line 46): fuzz, decimals > 0xff, returns ReadFailure.
- `testDecimalsForTokenInvalidValueTooLargeInitialized` (line 55): fuzz, initialized then too-large value, returns ReadFailure with stored decimals.
- `testDecimalsForTokenInvalidValueNotEnoughData` (line 72): fuzz, short return data, returns ReadFailure.
- `testDecimalsForTokenInvalidValueNotEnoughDataInitialized` (line 87): fuzz, initialized then short data, returns ReadFailure with stored decimals.
- `testDecimalsForTokenTokenContractRevert` (line 113): etch revert opcode, returns ReadFailure.
- `testDecimalsForTokenTokenContractRevertInitialized` (line 121): fuzz, initialized then etch revert, returns ReadFailure with stored decimals.

### Test file: `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (165 lines)
- `LibTOFUTokenDecimalsDecimalsForTokenReadOnlyTest` with fork + Zoltu deploy in constructor.
- `testDecimalsForTokenReadOnlyAddressZero` (line 21): address(0), ReadFailure, decimals=0.
- `testDecimalsForTokenReadOnlyValidValue` (line 27): fuzz, two calls both return Initial (no storage write).
- `testDecimalsForTokenReadOnlyConsistentInconsistent` (line 43): fuzz, initialize via `decimalsForToken`, then read-only sees Consistent/Inconsistent.
- `testDecimalsForTokenReadOnlyDoesNotWriteStorage` (line 65): fuzz, proves read-only does not write storage.
- `testDecimalsForTokenReadOnlyInvalidValueTooLarge` (line 78): fuzz, decimals > 0xff, ReadFailure.
- `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` (line 87): fuzz, initialized then too-large, ReadFailure with stored decimals.
- `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` (line 104): fuzz, short data, ReadFailure.
- `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` (line 118): fuzz, initialized then short data, ReadFailure with stored decimals.
- `testDecimalsForTokenReadOnlyTokenContractRevert` (line 142): etch revert, ReadFailure.
- `testDecimalsForTokenReadOnlyTokenContractRevertInitialized` (line 150): fuzz, initialized then revert, ReadFailure with stored decimals.

### Test file: `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` (127 lines)
- `LibTOFUTokenDecimalsSafeDecimalsForTokenTest` with fork + Zoltu deploy in constructor.
- `testSafeDecimalsForTokenAddressZero` (line 23): expects `TokenDecimalsReadFailure` revert.
- `testSafeDecimalsForTokenValidValue` (line 28): fuzz, succeeds with valid uint8 decimals.
- `testSafeDecimalsForTokenConsistentInconsistent` (line 34): fuzz, first call succeeds, second either succeeds (consistent) or reverts with Inconsistent.
- `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` (line 54): fuzz, initialized then too-large, reverts ReadFailure.
- `testSafeDecimalsForTokenInvalidValueTooLarge` (line 65): fuzz, uninitialized, too-large, reverts ReadFailure.
- `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` (line 75): fuzz, initialized then short data, reverts ReadFailure.
- `testSafeDecimalsForTokenInvalidValueNotEnoughData` (line 95): fuzz, uninitialized, short data, reverts ReadFailure.
- `testSafeDecimalsForTokenContractRevertInitialized` (line 110): fuzz, initialized then etch revert, reverts ReadFailure.
- `testSafeDecimalsForTokenContractRevert` (line 121): uninitialized, etch revert, reverts ReadFailure.

### Test file: `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` (142 lines)
- `LibTOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest` with fork + Zoltu deploy in constructor.
- `testSafeDecimalsForTokenReadOnlyAddressZero` (line 23): expects `TokenDecimalsReadFailure` revert.
- `testSafeDecimalsForTokenReadOnlyValidValue` (line 28): fuzz, succeeds with valid uint8 decimals.
- `testSafeDecimalsForTokenReadOnlyConsistentInconsistent` (line 34): fuzz, initialize via `decimalsForToken`, then read-only succeeds or reverts.
- `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` (line 54): fuzz, initialized then too-large, reverts ReadFailure.
- `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge` (line 67): fuzz, uninitialized, too-large, reverts ReadFailure.
- `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` (line 78): fuzz, initialized then short data, reverts ReadFailure.
- `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData` (line 98): fuzz, uninitialized, short data, reverts ReadFailure.
- `testSafeDecimalsForTokenReadOnlyContractRevertInitialized` (line 113): fuzz, initialized then etch revert, reverts ReadFailure.
- `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` (line 126): fuzz, proves read-only does not write storage.
- `testSafeDecimalsForTokenReadOnlyContractRevert` (line 136): uninitialized, etch revert, reverts ReadFailure.

### Test file: `LibTOFUTokenDecimals.realTokens.t.sol` (220 lines)
- `LibTOFUTokenDecimalsRealTokensTest` with fork + Zoltu deploy in constructor.
- Real tokens: WETH (18), USDC (6), WBTC (8), DAI (18).
- Tests `decimalsForToken` with Initial then Consistent for all 4 tokens (lines 31-72).
- Tests `decimalsForTokenReadOnly` with Initial then (after stateful init) Consistent for all 4 tokens (lines 75-124).
- Tests `safeDecimalsForToken` for all 4 tokens, two calls each (lines 127-160).
- Tests `safeDecimalsForTokenReadOnly` for all 4 tokens, read-only then stateful init then read-only (lines 163-204).
- `testRealTokenCrossTokenIsolation` (line 208): initializes WETH and USDC, verifies Consistent with correct decimals for each.

---

## Coverage Analysis by Function

### `ensureDeployed()` (line 51)

| Path | Test | Status |
|------|------|--------|
| Success (code exists, codehash matches) | `testDeployAddress` in `.t.sol`; every fork test constructor calls `ensureDeployed()` | Covered |
| Revert: no code at address | `testEnsureDeployedRevert` in `.t.sol` | Covered |
| Revert: wrong codehash | `testEnsureDeployedRevertWrongCodeHash` in `.t.sol` | Covered |
| Revert propagates through all 4 delegating functions | `testDecimalsForTokenReadOnlyRevert`, `testDecimalsForTokenRevert`, `testSafeDecimalsForTokenRevert`, `testSafeDecimalsForTokenReadOnlyRevert` in `.t.sol` | Covered |

### `decimalsForToken(address)` (line 79)

| Path | Test | Status |
|------|------|--------|
| Initial (first read, valid uint8) | `testDecimalsForTokenValidValue` | Covered (fuzz) |
| Consistent (same value on re-read) | `testDecimalsForTokenValidValue` | Covered (fuzz) |
| Inconsistent (different value on re-read) | `testDecimalsForTokenValidValue` | Covered (fuzz) |
| ReadFailure: address(0) / no code | `testDecimalsForTokenAddressZero` | Covered |
| ReadFailure: value > uint8 (uninitialized) | `testDecimalsForTokenInvalidValueTooLarge` | Covered (fuzz) |
| ReadFailure: value > uint8 (initialized) | `testDecimalsForTokenInvalidValueTooLargeInitialized` | Covered (fuzz) |
| ReadFailure: short return data (uninitialized) | `testDecimalsForTokenInvalidValueNotEnoughData` | Covered (fuzz) |
| ReadFailure: short return data (initialized) | `testDecimalsForTokenInvalidValueNotEnoughDataInitialized` | Covered (fuzz) |
| ReadFailure: contract reverts (uninitialized) | `testDecimalsForTokenTokenContractRevert` | Covered |
| ReadFailure: contract reverts (initialized) | `testDecimalsForTokenTokenContractRevertInitialized` | Covered (fuzz) |
| Real token integration | `testRealTokenWETH/USDC/WBTC/DAI` | Covered |
| Singleton not deployed revert | `testDecimalsForTokenRevert` | Covered |

### `decimalsForTokenReadOnly(address)` (line 66)

| Path | Test | Status |
|------|------|--------|
| Initial (uninitialized, valid read) | `testDecimalsForTokenReadOnlyValidValue` | Covered (fuzz) |
| Initial repeated (does not write storage) | `testDecimalsForTokenReadOnlyValidValue`, `testDecimalsForTokenReadOnlyDoesNotWriteStorage` | Covered (fuzz) |
| Consistent (after stateful init, same value) | `testDecimalsForTokenReadOnlyConsistentInconsistent` | Covered (fuzz) |
| Inconsistent (after stateful init, different value) | `testDecimalsForTokenReadOnlyConsistentInconsistent` | Covered (fuzz) |
| ReadFailure: address(0) | `testDecimalsForTokenReadOnlyAddressZero` | Covered |
| ReadFailure: value > uint8 (uninitialized) | `testDecimalsForTokenReadOnlyInvalidValueTooLarge` | Covered (fuzz) |
| ReadFailure: value > uint8 (initialized) | `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` | Covered (fuzz) |
| ReadFailure: short data (uninitialized) | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` | Covered (fuzz) |
| ReadFailure: short data (initialized) | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` | Covered (fuzz) |
| ReadFailure: contract reverts (uninitialized) | `testDecimalsForTokenReadOnlyTokenContractRevert` | Covered |
| ReadFailure: contract reverts (initialized) | `testDecimalsForTokenReadOnlyTokenContractRevertInitialized` | Covered (fuzz) |
| Real token integration | `testRealTokenDecimalsForTokenReadOnlyWETH/USDC/WBTC/DAI` | Covered |
| Singleton not deployed revert | `testDecimalsForTokenReadOnlyRevert` | Covered |

### `safeDecimalsForToken(address)` (line 89)

| Path | Test | Status |
|------|------|--------|
| Success: Initial (valid uint8) | `testSafeDecimalsForTokenValidValue` | Covered (fuzz) |
| Success: Consistent | `testSafeDecimalsForTokenConsistentInconsistent` | Covered (fuzz) |
| Revert: Inconsistent | `testSafeDecimalsForTokenConsistentInconsistent` | Covered (fuzz) |
| Revert: ReadFailure address(0) | `testSafeDecimalsForTokenAddressZero` | Covered |
| Revert: ReadFailure value > uint8 (uninitialized) | `testSafeDecimalsForTokenInvalidValueTooLarge` | Covered (fuzz) |
| Revert: ReadFailure value > uint8 (initialized) | `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` | Covered (fuzz) |
| Revert: ReadFailure short data (uninitialized) | `testSafeDecimalsForTokenInvalidValueNotEnoughData` | Covered (fuzz) |
| Revert: ReadFailure short data (initialized) | `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` | Covered (fuzz) |
| Revert: ReadFailure contract reverts (uninitialized) | `testSafeDecimalsForTokenContractRevert` | Covered |
| Revert: ReadFailure contract reverts (initialized) | `testSafeDecimalsForTokenContractRevertInitialized` | Covered (fuzz) |
| Real token integration | `testRealTokenSafeDecimalsForTokenWETH/USDC/WBTC/DAI` | Covered |
| Singleton not deployed revert | `testSafeDecimalsForTokenRevert` | Covered |

### `safeDecimalsForTokenReadOnly(address)` (line 97)

| Path | Test | Status |
|------|------|--------|
| Success: Initial (valid uint8, uninitialized) | `testSafeDecimalsForTokenReadOnlyValidValue` | Covered (fuzz) |
| Success: Consistent (after stateful init) | `testSafeDecimalsForTokenReadOnlyConsistentInconsistent` | Covered (fuzz) |
| Does not write storage | `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` | Covered (fuzz) |
| Revert: Inconsistent | `testSafeDecimalsForTokenReadOnlyConsistentInconsistent` | Covered (fuzz) |
| Revert: ReadFailure address(0) | `testSafeDecimalsForTokenReadOnlyAddressZero` | Covered |
| Revert: ReadFailure value > uint8 (uninitialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge` | Covered (fuzz) |
| Revert: ReadFailure value > uint8 (initialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` | Covered (fuzz) |
| Revert: ReadFailure short data (uninitialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData` | Covered (fuzz) |
| Revert: ReadFailure short data (initialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` | Covered (fuzz) |
| Revert: ReadFailure contract reverts (uninitialized) | `testSafeDecimalsForTokenReadOnlyContractRevert` | Covered |
| Revert: ReadFailure contract reverts (initialized) | `testSafeDecimalsForTokenReadOnlyContractRevertInitialized` | Covered (fuzz) |
| Real token integration | `testRealTokenSafeDecimalsForTokenReadOnlyWETH/USDC/WBTC/DAI` | Covered |
| Singleton not deployed revert | `testSafeDecimalsForTokenReadOnlyRevert` | Covered |

### Constants

| Property | Test | Status |
|----------|------|--------|
| `TOFU_DECIMALS_DEPLOYMENT` matches Zoltu deploy | `testDeployAddress` | Covered |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` matches deployed code | `testExpectedCodeHash` | Covered |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` matches compiled code | `testExpectedCreationCode` | Covered |
| No metamorphic opcodes | `testNotMetamorphic` | Covered |
| No CBOR metadata | `testNoCBORMetadata` | Covered |

---

## Findings

No findings.

All five source functions (`ensureDeployed`, `decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) have comprehensive test coverage across all identified paths. The test suite covers:

- **ensureDeployed**: success, no-code revert, wrong-codehash revert, and propagation of the revert through all four delegating functions.
- **All four delegating functions**: every `TOFUOutcome` path (Initial, Consistent, Inconsistent, ReadFailure) in both uninitialized and initialized states, including edge cases (address(0), value > uint8, short return data, reverting contracts).
- **Read-only semantics**: explicit tests that read-only variants do not write storage (`testDecimalsForTokenReadOnlyDoesNotWriteStorage`, `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage`).
- **Real token integration**: WETH, USDC, WBTC, DAI tested through all four function variants plus cross-token isolation.
- **Constants verification**: deployment address, codehash, creation code, metamorphic safety, and CBOR metadata absence are all verified.
- **Fuzz testing**: all parameterized paths use fuzz inputs (`uint8` for decimals values, `uint256` for overflow, `bytes` for short data).
