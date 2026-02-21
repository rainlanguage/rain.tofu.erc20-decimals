# Pass 2: Test Coverage Audit -- LibTOFUTokenDecimals.sol

**Agent:** A03
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimals.sol`

---

## 1. Evidence of Thorough Reading

### 1.1 Source File Inventory (`src/lib/LibTOFUTokenDecimals.sol`)

| Item | Kind | Line(s) | Description |
|------|------|---------|-------------|
| `LibTOFUTokenDecimals` | library | 21-99 | Caller convenience library wrapping deployed singleton |
| `TOFUTokenDecimalsNotDeployed` | error | 24 | Custom error thrown when singleton is absent or has wrong codehash |
| `TOFU_DECIMALS_DEPLOYMENT` | constant (address) | 29-30 | Hard-coded singleton address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | constant (bytes32) | 36-37 | Expected codehash for verifying deployed contract identity |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | constant (bytes) | 43-44 | Init bytecode for deterministic Zoltu deployment |
| `ensureDeployed()` | function (internal view) | 49-56 | Guard: reverts if code is empty OR codehash mismatches |
| `decimalsForTokenReadOnly(address)` | function (internal view) | 64-69 | Calls `ensureDeployed()` then delegates to singleton's `decimalsForTokenReadOnly` |
| `decimalsForToken(address)` | function (internal) | 77-82 | Calls `ensureDeployed()` then delegates to singleton's `decimalsForToken` |
| `safeDecimalsForToken(address)` | function (internal) | 87-90 | Calls `ensureDeployed()` then delegates to singleton's `safeDecimalsForToken` |
| `safeDecimalsForTokenReadOnly(address)` | function (internal view) | 95-98 | Calls `ensureDeployed()` then delegates to singleton's `safeDecimalsForTokenReadOnly` |

**Imports used:**
- `TOFUOutcome` from `../interface/ITOFUTokenDecimals.sol` (line 5)
- `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

### 1.2 Test Files and Test Functions

#### File: `test/src/lib/LibTOFUTokenDecimals.t.sol`

| Test Function | Line(s) | Type | Notes |
|---------------|---------|------|-------|
| `externalEnsureDeployed()` | 13-15 | Helper (external) | Wrapper to make internal lib callable via `this` |
| `externalDecimalsForTokenReadOnly(address)` | 17-19 | Helper (external) | Wrapper for lib call |
| `externalDecimalsForToken(address)` | 21-23 | Helper (external) | Wrapper for lib call |
| `externalSafeDecimalsForToken(address)` | 25-27 | Helper (external) | Wrapper for lib call |
| `externalSafeDecimalsForTokenReadOnly(address)` | 29-31 | Helper (external) | Wrapper for lib call |
| `testDeployAddress()` | 33-40 | Fork test | Verifies Zoltu-deployed address matches constant, then calls `ensureDeployed` |
| `testNotMetamorphic()` | 47-49 | Unit test | Scans bytecode for metamorphic opcodes |
| `testNoCBORMetadata()` | 56-58 | Unit test | Checks no CBOR metadata in bytecode |
| `testExpectedCodeHash()` | 61-65 | Unit test | Verifies code hash constant matches fresh deployment |
| `testExpectedCreationCode()` | 67-69 | Pure test | Verifies creation code constant matches `type(TOFUTokenDecimals).creationCode` |
| `testEnsureDeployedRevert()` | 71-79 | Unit test | `ensureDeployed` reverts when no code at expected address |
| `testEnsureDeployedRevertWrongCodeHash()` | 81-94 | Unit test | `ensureDeployed` reverts when code exists but hash differs |
| `testDecimalsForTokenReadOnlyRevert()` | 96-105 | Unit test | `decimalsForTokenReadOnly` reverts when not deployed |
| `testDecimalsForTokenRevert()` | 107-116 | Unit test | `decimalsForToken` reverts when not deployed |
| `testSafeDecimalsForTokenRevert()` | 118-127 | Unit test | `safeDecimalsForToken` reverts when not deployed |
| `testSafeDecimalsForTokenReadOnlyRevert()` | 129-138 | Unit test | `safeDecimalsForTokenReadOnly` reverts when not deployed |

#### File: `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol`

| Test Function | Line(s) | Type | Notes |
|---------------|---------|------|-------|
| constructor | 12-19 | Setup (fork) | Forks mainnet, deploys via Zoltu, asserts address and calls `ensureDeployed` |
| `testDecimalsForTokenAddressZero()` | 21-25 | Unit test | ReadFailure for address(0) |
| `testDecimalsForTokenValidValue(uint8, uint8)` | 27-44 | Fuzz test | Tests Initial/Consistent/Inconsistent paths |
| `testDecimalsForTokenInvalidValueTooLarge(uint256)` | 46-53 | Fuzz test | ReadFailure when value > 0xff, uninitialized |
| `testDecimalsForTokenInvalidValueTooLargeInitialized(uint8, uint256)` | 55-70 | Fuzz test | ReadFailure when value > 0xff, already initialized |
| `testDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256)` | 72-85 | Fuzz test | ReadFailure when return data < 32 bytes, uninitialized |
| `testDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 87-111 | Fuzz test | ReadFailure when return data < 32 bytes, already initialized |
| `testDecimalsForTokenTokenContractRevert()` | 113-119 | Unit test | ReadFailure when token reverts, uninitialized |
| `testDecimalsForTokenTokenContractRevertInitialized(uint8)` | 121-137 | Fuzz test | ReadFailure when token reverts, already initialized |

#### File: `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

| Test Function | Line(s) | Type | Notes |
|---------------|---------|------|-------|
| constructor | 12-19 | Setup (fork) | Same pattern: fork + Zoltu deploy |
| `testDecimalsForTokenReadOnlyAddressZero()` | 21-25 | Unit test (view) | ReadFailure for address(0) |
| `testDecimalsForTokenReadOnlyValidValue(uint8, uint8)` | 27-41 | Fuzz test | Always returns Initial since read-only never writes |
| `testDecimalsForTokenReadOnlyConsistentInconsistent(uint8, uint8)` | 43-60 | Fuzz test | After stateful init, verifies Consistent/Inconsistent |
| `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` | 65-76 | Fuzz test | Proves read-only does not persist state |
| `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` | 78-85 | Fuzz test | ReadFailure when value > 0xff, uninitialized |
| `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8, uint256)` | 87-102 | Fuzz test | ReadFailure when value > 0xff, initialized |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256)` | 104-116 | Fuzz test | ReadFailure when < 32 bytes, uninitialized |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 118-140 | Fuzz test | ReadFailure when < 32 bytes, initialized |
| `testDecimalsForTokenReadOnlyTokenContractRevert()` | 142-148 | Unit test | ReadFailure when token reverts, uninitialized |
| `testDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` | 150-164 | Fuzz test | ReadFailure when token reverts, initialized |

#### File: `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`

| Test Function | Line(s) | Type | Notes |
|---------------|---------|------|-------|
| constructor | 13-20 | Setup (fork) | Fork + Zoltu deploy |
| `testSafeDecimalsForTokenAddressZero()` | 22-25 | Unit test | Reverts with `TokenDecimalsReadFailure(address(0), ReadFailure)` |
| `testSafeDecimalsForTokenValidValue(uint8)` | 27-31 | Fuzz test | Successful Initial read returns correct decimals |
| `testSafeDecimalsForTokenConsistentInconsistent(uint8, uint8)` | 33-48 | Fuzz test | Consistent passes, Inconsistent reverts |
| `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint8, uint256)` | 53-62 | Fuzz test | Reverts with ReadFailure when value > 0xff, initialized |
| `testSafeDecimalsForTokenInvalidValueTooLarge(uint256)` | 64-70 | Fuzz test | Reverts with ReadFailure when value > 0xff, uninitialized |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 74-92 | Fuzz test | Reverts with ReadFailure when < 32 bytes, initialized |
| `testSafeDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256)` | 94-105 | Fuzz test | Reverts with ReadFailure when < 32 bytes, uninitialized |
| `testSafeDecimalsForTokenContractRevertInitialized(uint8)` | 109-118 | Fuzz test | Reverts with ReadFailure when token starts reverting, initialized |
| `testSafeDecimalsForTokenContractRevert()` | 120-125 | Unit test | Reverts with ReadFailure when token reverts, uninitialized |

#### File: `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

| Test Function | Line(s) | Type | Notes |
|---------------|---------|------|-------|
| constructor | 13-20 | Setup (fork) | Fork + Zoltu deploy |
| `testSafeDecimalsForTokenReadOnlyAddressZero()` | 22-25 | Unit test | Reverts with `TokenDecimalsReadFailure(address(0), ReadFailure)` |
| `testSafeDecimalsForTokenReadOnlyValidValue(uint8)` | 27-31 | Fuzz test | Successful Initial read returns correct decimals |
| `testSafeDecimalsForTokenReadOnlyConsistentInconsistent(uint8, uint8)` | 33-48 | Fuzz test | After stateful init, Consistent passes, Inconsistent reverts |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8, uint256)` | 53-64 | Fuzz test | Reverts with ReadFailure when > 0xff, initialized |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` | 66-72 | Fuzz test | Reverts with ReadFailure when > 0xff, uninitialized |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 77-95 | Fuzz test | Reverts with ReadFailure when < 32 bytes, initialized |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256)` | 97-108 | Fuzz test | Reverts with ReadFailure when < 32 bytes, uninitialized |
| `testSafeDecimalsForTokenReadOnlyContractRevertInitialized(uint8)` | 112-121 | Fuzz test | Reverts with ReadFailure when token starts reverting, initialized |
| `testSafeDecimalsForTokenReadOnlyContractRevert()` | 123-128 | Unit test | Reverts with ReadFailure when token reverts, uninitialized |

#### File: `test/src/concrete/TOFUTokenDecimals.immutability.t.sol`

| Test Function | Line(s) | Type | Notes |
|---------------|---------|------|-------|
| `testNoMutableOpcodes()` | 14-28 | Unit test | Scans for SELFDESTRUCT, DELEGATECALL, CALLCODE in deployed bytecode |

---

## 2. Test Coverage Analysis

### 2.1 `ensureDeployed()` (lines 49-56)

| Scenario | Test(s) | Status |
|----------|---------|--------|
| Reverts when no code deployed at address | `testEnsureDeployedRevert` | COVERED |
| Reverts when code exists but codehash differs | `testEnsureDeployedRevertWrongCodeHash` | COVERED |
| Succeeds when correctly deployed (fork) | `testDeployAddress` | COVERED |
| Called as guard by every public function | `testDecimalsForTokenReadOnlyRevert`, `testDecimalsForTokenRevert`, `testSafeDecimalsForTokenRevert`, `testSafeDecimalsForTokenReadOnlyRevert` | COVERED |

### 2.2 `decimalsForTokenReadOnly(address)` (lines 64-69)

| Scenario | Test(s) | Status |
|----------|---------|--------|
| Reverts when not deployed | `testDecimalsForTokenReadOnlyRevert` | COVERED |
| ReadFailure for address(0) | `testDecimalsForTokenReadOnlyAddressZero` | COVERED |
| Initial outcome (uninitialized) | `testDecimalsForTokenReadOnlyValidValue` | COVERED |
| Consistent outcome (after init) | `testDecimalsForTokenReadOnlyConsistentInconsistent` | COVERED |
| Inconsistent outcome (after init) | `testDecimalsForTokenReadOnlyConsistentInconsistent` | COVERED |
| Does not write storage | `testDecimalsForTokenReadOnlyDoesNotWriteStorage` | COVERED |
| ReadFailure for value > 0xff (uninitialized) | `testDecimalsForTokenReadOnlyInvalidValueTooLarge` | COVERED |
| ReadFailure for value > 0xff (initialized) | `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` | COVERED |
| ReadFailure for insufficient data (uninitialized) | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` | COVERED |
| ReadFailure for insufficient data (initialized) | `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` | COVERED |
| ReadFailure for reverting token (uninitialized) | `testDecimalsForTokenReadOnlyTokenContractRevert` | COVERED |
| ReadFailure for reverting token (initialized) | `testDecimalsForTokenReadOnlyTokenContractRevertInitialized` | COVERED |

### 2.3 `decimalsForToken(address)` (lines 77-82)

| Scenario | Test(s) | Status |
|----------|---------|--------|
| Reverts when not deployed | `testDecimalsForTokenRevert` | COVERED |
| ReadFailure for address(0) | `testDecimalsForTokenAddressZero` | COVERED |
| Initial outcome stores value | `testDecimalsForTokenValidValue` | COVERED |
| Consistent outcome | `testDecimalsForTokenValidValue` | COVERED |
| Inconsistent outcome | `testDecimalsForTokenValidValue` | COVERED |
| ReadFailure for value > 0xff (uninitialized) | `testDecimalsForTokenInvalidValueTooLarge` | COVERED |
| ReadFailure for value > 0xff (initialized) | `testDecimalsForTokenInvalidValueTooLargeInitialized` | COVERED |
| ReadFailure for insufficient data (uninitialized) | `testDecimalsForTokenInvalidValueNotEnoughData` | COVERED |
| ReadFailure for insufficient data (initialized) | `testDecimalsForTokenInvalidValueNotEnoughDataInitialized` | COVERED |
| ReadFailure for reverting token (uninitialized) | `testDecimalsForTokenTokenContractRevert` | COVERED |
| ReadFailure for reverting token (initialized) | `testDecimalsForTokenTokenContractRevertInitialized` | COVERED |

### 2.4 `safeDecimalsForToken(address)` (lines 87-90)

| Scenario | Test(s) | Status |
|----------|---------|--------|
| Reverts when not deployed | `testSafeDecimalsForTokenRevert` | COVERED |
| Reverts for address(0) (ReadFailure) | `testSafeDecimalsForTokenAddressZero` | COVERED |
| Returns decimals on Initial | `testSafeDecimalsForTokenValidValue` | COVERED |
| Returns decimals on Consistent | `testSafeDecimalsForTokenConsistentInconsistent` | COVERED |
| Reverts on Inconsistent | `testSafeDecimalsForTokenConsistentInconsistent` | COVERED |
| Reverts on ReadFailure (value too large, uninitialized) | `testSafeDecimalsForTokenInvalidValueTooLarge` | COVERED |
| Reverts on ReadFailure (value too large, initialized) | `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` | COVERED |
| Reverts on ReadFailure (insufficient data, uninitialized) | `testSafeDecimalsForTokenInvalidValueNotEnoughData` | COVERED |
| Reverts on ReadFailure (insufficient data, initialized) | `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` | COVERED |
| Reverts on ReadFailure (reverting token, uninitialized) | `testSafeDecimalsForTokenContractRevert` | COVERED |
| Reverts on ReadFailure (reverting token, initialized) | `testSafeDecimalsForTokenContractRevertInitialized` | COVERED |

### 2.5 `safeDecimalsForTokenReadOnly(address)` (lines 95-98)

| Scenario | Test(s) | Status |
|----------|---------|--------|
| Reverts when not deployed | `testSafeDecimalsForTokenReadOnlyRevert` | COVERED |
| Reverts for address(0) (ReadFailure) | `testSafeDecimalsForTokenReadOnlyAddressZero` | COVERED |
| Returns decimals on Initial | `testSafeDecimalsForTokenReadOnlyValidValue` | COVERED |
| Returns decimals on Consistent | `testSafeDecimalsForTokenReadOnlyConsistentInconsistent` | COVERED |
| Reverts on Inconsistent | `testSafeDecimalsForTokenReadOnlyConsistentInconsistent` | COVERED |
| Reverts on ReadFailure (value too large, uninitialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge` | COVERED |
| Reverts on ReadFailure (value too large, initialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` | COVERED |
| Reverts on ReadFailure (insufficient data, uninitialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData` | COVERED |
| Reverts on ReadFailure (insufficient data, initialized) | `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` | COVERED |
| Reverts on ReadFailure (reverting token, uninitialized) | `testSafeDecimalsForTokenReadOnlyContractRevert` | COVERED |
| Reverts on ReadFailure (reverting token, initialized) | `testSafeDecimalsForTokenReadOnlyContractRevertInitialized` | COVERED |

### 2.6 Constants

| Constant | Test(s) | Status |
|----------|---------|--------|
| `TOFU_DECIMALS_DEPLOYMENT` | `testDeployAddress` (fork, verifies Zoltu result == constant) | COVERED |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `testExpectedCodeHash` (fresh deploy, verifies codehash == constant) | COVERED |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `testExpectedCreationCode` (pure, verifies creationCode == constant) | COVERED |

### 2.7 Error

| Error | Test(s) | Status |
|-------|---------|--------|
| `TOFUTokenDecimalsNotDeployed(address)` | `testEnsureDeployedRevert`, `testEnsureDeployedRevertWrongCodeHash`, `testDecimalsForTokenReadOnlyRevert`, `testDecimalsForTokenRevert`, `testSafeDecimalsForTokenRevert`, `testSafeDecimalsForTokenReadOnlyRevert` | COVERED |

### 2.8 Security Properties

| Property | Test(s) | Status |
|----------|---------|--------|
| Singleton has no metamorphic opcodes | `testNotMetamorphic` | COVERED |
| Singleton has no CBOR metadata | `testNoCBORMetadata` | COVERED |
| Singleton has no SELFDESTRUCT/DELEGATECALL/CALLCODE | `testNoMutableOpcodes` (immutability test) | COVERED |

---

## 3. Coverage Gap Findings

### A03-1: No test that `safeDecimalsForTokenReadOnly` does not write storage (LOW)

**Severity: LOW**

The `decimalsForTokenReadOnly` test file includes `testDecimalsForTokenReadOnlyDoesNotWriteStorage` which explicitly proves the read-only variant does not persist state. However, there is no analogous test for `safeDecimalsForTokenReadOnly`. While `safeDecimalsForTokenReadOnly` is declared `view` in both the library and the interface (meaning the compiler enforces it cannot write state), an explicit integration test that calls `safeDecimalsForTokenReadOnly` and then proves a subsequent `decimalsForToken` still returns `Initial` would provide defense-in-depth at the test level, mirroring the approach already taken for `decimalsForTokenReadOnly`.

**Location:** Missing from `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

**Suggested test:**
```solidity
function testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals) external {
    address token = makeAddr("TokenRO");
    vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));
    LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(token);
    // Stateful call must still see Initial.
    (TOFUOutcome tofuOutcome,) = LibTOFUTokenDecimals.decimalsForToken(token);
    assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
}
```

### A03-2: No negative test for `ensureDeployed` with correct code length but zero-length edge case (INFO)

**Severity: INFO**

The `ensureDeployed` function checks two conditions: `code.length == 0` (no code at address) and `codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` (wrong code). Both branches are tested:
- `testEnsureDeployedRevert` tests the case where no code is deployed (empty address).
- `testEnsureDeployedRevertWrongCodeHash` tests code present but wrong hash.

This is complete coverage of the guard's two-condition OR. No gap here, just documenting that both branches are exercised.

### A03-3: No test exercising `decimalsForToken` after read-only does not corrupt state (INFO)

**Severity: INFO**

While `testDecimalsForTokenReadOnlyDoesNotWriteStorage` in the read-only test file proves that calling `decimalsForTokenReadOnly` followed by `decimalsForToken` still yields `Initial`, there is no test doing the reverse: calling `decimalsForToken` (which initializes) then calling `decimalsForTokenReadOnly` and then calling `decimalsForToken` again to confirm the read-only call in between did not disrupt the stored value. This is implicitly covered by the `testDecimalsForTokenReadOnlyConsistentInconsistent` test (which initializes via `decimalsForToken` then reads via `decimalsForTokenReadOnly`), but a three-call sequence test would make the non-corruption property more explicit. Since `decimalsForTokenReadOnly` is `view`, this is compiler-enforced and purely informational.

### A03-4: No explicit test for return value of `decimalsForToken` on `ReadFailure` when uninitialized confirming `tokenDecimals == 0` (INFO)

**Severity: INFO**

For `decimalsForToken`, when an uninitialized token encounters a `ReadFailure`, the returned `tokenDecimals` should be `0` (the default uninitialized value). The tests `testDecimalsForTokenAddressZero`, `testDecimalsForTokenInvalidValueTooLarge`, `testDecimalsForTokenInvalidValueNotEnoughData`, and `testDecimalsForTokenTokenContractRevert` all assert `readDecimals == 0`, so this IS in fact covered. Documenting for completeness that these assertions exist and are correct.

### A03-5: No test exercising the library functions against a real mainnet token (e.g., USDC, WETH) (LOW)

**Severity: LOW**

All tests use `vm.mockCall` to simulate token behavior. While the fork tests deploy the singleton via Zoltu on a mainnet fork, no test actually calls `LibTOFUTokenDecimals.decimalsForToken` or any variant against a real mainnet token contract (e.g., USDC at `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` with 6 decimals, or WETH with 18 decimals). Such integration tests would provide confidence that the inline assembly `staticcall` works correctly against real-world ERC20 implementations, catching edge cases like non-standard ABI encoding that mocks cannot surface.

**Note:** The concrete contract tests (`test/src/concrete/`) may cover real token integration, but from the `LibTOFUTokenDecimals` test files specifically, this is absent.

### A03-6: No test for gas consumption or out-of-gas behavior on `staticcall` (INFO)

**Severity: INFO**

The implementation passes `gas()` to the `staticcall` in `decimalsForTokenReadOnly`. There is no test verifying behavior when the external call runs out of gas (e.g., a token with an extremely expensive `decimals()` function). In practice, this is a pathological case and the `ReadFailure` path would handle it, but it is not explicitly tested. This is informational only, as the code correctly treats any `staticcall` failure as a `ReadFailure`.

---

## 4. Summary Table

| ID | Finding | Severity | Category |
|----|---------|----------|----------|
| A03-1 | No explicit test proving `safeDecimalsForTokenReadOnly` does not write storage | LOW | Missing test |
| A03-2 | Both branches of `ensureDeployed` guard are tested (no gap) | INFO | Observation |
| A03-3 | No three-call sequence test for read-only non-corruption of state | INFO | Test completeness |
| A03-4 | Return value assertions for `ReadFailure` when uninitialized are present | INFO | Observation |
| A03-5 | No integration test against real mainnet tokens via the library functions | LOW | Missing test |
| A03-6 | No test for out-of-gas behavior on external `staticcall` | INFO | Missing test |

**Overall Assessment:** Test coverage for `LibTOFUTokenDecimals.sol` is **excellent**. Every function, constant, and error in the source file has dedicated test coverage. All four TOFU outcome branches (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`) are exercised for every public function, both in uninitialized and initialized states. The `ensureDeployed` guard is tested for both failure conditions (no code and wrong codehash), and all four wrapper functions are tested to revert when the singleton is not deployed. Fuzz testing is used extensively for decimals values. The two LOW findings are minor improvements to an already thorough test suite; no CRITICAL or HIGH coverage gaps were identified.
