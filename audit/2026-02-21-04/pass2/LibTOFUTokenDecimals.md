<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 2 — Test Coverage: `LibTOFUTokenDecimals`

**Auditor:** A04
**Date:** 2026-02-21
**Source file:** `src/lib/LibTOFUTokenDecimals.sol`

---

## 1. Source File Summary

**Library:** `LibTOFUTokenDecimals` (lines 21–100)

### Public API surface

| Function | Visibility | Mutability | Line |
|---|---|---|---|
| `ensureDeployed()` | internal | view | 50 |
| `decimalsForTokenReadOnly(address)` | internal | view | 65 |
| `decimalsForToken(address)` | internal | — (non-view) | 78 |
| `safeDecimalsForToken(address)` | internal | — (non-view) | 88 |
| `safeDecimalsForTokenReadOnly(address)` | internal | view | 96 |

### Constants

| Constant | Line |
|---|---|
| `TOFU_DECIMALS_DEPLOYMENT` | 29 |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | 36 |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | 44 |

### Error

| Error | Line |
|---|---|
| `TOFUTokenDecimalsNotDeployed(address)` | 24 |

### `ensureDeployed` guard logic (lines 51–56)

The condition is a short-circuit OR:

```solidity
if (
    address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0
        || address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH
) {
    revert TOFUTokenDecimalsNotDeployed(address(TOFU_DECIMALS_DEPLOYMENT));
}
```

Two distinct revert branches exist:
- **Branch A:** no code at the address (`code.length == 0`)
- **Branch B:** code present but codehash mismatch

---

## 2. Test Files Examined

### 2.1 `test/src/lib/LibTOFUTokenDecimals.t.sol`

**Contract:** `LibTOFUTokenDecimalsTest`

Helper wrappers (not test functions) declared to make internal library functions externally callable so `vm.expectRevert` works correctly:

| Wrapper | Line |
|---|---|
| `externalEnsureDeployed()` | 13 |
| `externalDecimalsForTokenReadOnly(address)` | 17 |
| `externalDecimalsForToken(address)` | 21 |
| `externalSafeDecimalsForToken(address)` | 25 |
| `externalSafeDecimalsForTokenReadOnly(address)` | 29 |

Test functions:

| Test | Line | What it covers |
|---|---|---|
| `testDeployAddress()` | 33 | Forks, deploys via Zoltu, asserts address matches constant, calls `ensureDeployed()` on happy path |
| `testNotMetamorphic()` | 47 | Singleton bytecode contains no metamorphic opcodes |
| `testNoCBORMetadata()` | 56 | Singleton has no CBOR metadata |
| `testExpectedCodeHash()` | 61 | Freshly deployed singleton codehash matches `TOFU_DECIMALS_EXPECTED_CODE_HASH` |
| `testExpectedCreationCode()` | 67 | Creation code bytes match `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant |
| `testEnsureDeployedRevert()` | 71 | `ensureDeployed()` reverts with `TOFUTokenDecimalsNotDeployed` when no contract at expected address (no fork, so address is empty) — exercises Branch A |
| `testEnsureDeployedRevertWrongCodeHash()` | 81 | `vm.etch` places different bytecode at the expected address; asserts `ensureDeployed()` reverts — exercises Branch B |
| `testDecimalsForTokenReadOnlyRevert()` | 96 | `decimalsForTokenReadOnly` propagates `TOFUTokenDecimalsNotDeployed` when not deployed |
| `testDecimalsForTokenRevert()` | 107 | `decimalsForToken` propagates `TOFUTokenDecimalsNotDeployed` when not deployed |
| `testSafeDecimalsForTokenRevert()` | 118 | `safeDecimalsForToken` propagates `TOFUTokenDecimalsNotDeployed` when not deployed |
| `testSafeDecimalsForTokenReadOnlyRevert()` | 129 | `safeDecimalsForTokenReadOnly` propagates `TOFUTokenDecimalsNotDeployed` when not deployed |

---

### 2.2 `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol`

**Contract:** `LibTOFUTokenDecimalsDecimalsForTokenTest`
**Constructor:** forks via `ETH_RPC_URL`, deploys singleton, calls `ensureDeployed()`.

| Test | Line | What it covers |
|---|---|---|
| `testDecimalsForTokenAddressZero()` | 21 | `address(0)` → `ReadFailure`, 0 decimals |
| `testDecimalsForTokenValidValue(uint8, uint8)` | 27 | Fuzz: Initial on first call; Consistent/Inconsistent on second based on equality |
| `testDecimalsForTokenInvalidValueTooLarge(uint256)` | 46 | Fuzz: returned value > 0xff → `ReadFailure` (uninitialized) |
| `testDecimalsForTokenInvalidValueTooLargeInitialized(uint8, uint256)` | 55 | Fuzz: initialized then value > 0xff → `ReadFailure`, returns stored value |
| `testDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256)` | 72 | Fuzz: return data < 32 bytes → `ReadFailure` (uninitialized) |
| `testDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 87 | Fuzz: initialized then short return data → `ReadFailure`, returns stored value |
| `testDecimalsForTokenTokenContractRevert()` | 113 | Token etched with `0xfd` → `ReadFailure` (uninitialized) |
| `testDecimalsForTokenTokenContractRevertInitialized(uint8)` | 121 | Fuzz: initialized then token reverts → `ReadFailure`, returns stored value |

---

### 2.3 `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

**Contract:** `LibTOFUTokenDecimalsDecimalsForTokenReadOnlyTest`
**Constructor:** forks, deploys singleton, calls `ensureDeployed()`.

| Test | Line | What it covers |
|---|---|---|
| `testDecimalsForTokenReadOnlyAddressZero()` | 21 | `address(0)` → `ReadFailure`, 0 decimals |
| `testDecimalsForTokenReadOnlyValidValue(uint8, uint8)` | 27 | Fuzz: always `Initial` (no storage write), reads current mock value each call |
| `testDecimalsForTokenReadOnlyConsistentInconsistent(uint8, uint8)` | 43 | Initializes via stateful call, then read-only sees Consistent/Inconsistent |
| `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` | 65 | Fuzz: read-only does not initialize storage; subsequent stateful call still sees `Initial` |
| `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` | 78 | Fuzz: value > 0xff → `ReadFailure` (uninitialized) |
| `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8, uint256)` | 87 | Fuzz: initialized (via stateful call), then value > 0xff → `ReadFailure`, stored value returned |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256)` | 104 | Fuzz: short return data → `ReadFailure` (uninitialized) |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 118 | Fuzz: initialized then short data → `ReadFailure`, stored value returned |
| `testDecimalsForTokenReadOnlyTokenContractRevert()` | 142 | Token etched with `0xfd` → `ReadFailure` (uninitialized) |
| `testDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` | 150 | Fuzz: initialized then token reverts → `ReadFailure`, stored value returned |

---

### 2.4 `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`

**Contract:** `LibTOFUTokenDecimalsSafeDecimalsForTokenTest`
**Constructor:** forks, deploys singleton, calls `ensureDeployed()`.

| Test | Line | What it covers |
|---|---|---|
| `testSafeDecimalsForTokenAddressZero()` | 22 | `address(0)` → reverts `TokenDecimalsReadFailure(address(0), ReadFailure)` |
| `testSafeDecimalsForTokenValidValue(uint8)` | 27 | Fuzz: returns decimals on success |
| `testSafeDecimalsForTokenConsistentInconsistent(uint8, uint8)` | 33 | Fuzz: success if consistent; reverts `TokenDecimalsReadFailure(token, Inconsistent)` if not |
| `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint8, uint256)` | 53 | Fuzz: initialized then value > 0xff → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenInvalidValueTooLarge(uint256)` | 64 | Fuzz: value > 0xff uninitialized → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 74 | Fuzz: initialized then short data → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256)` | 94 | Fuzz: short data uninitialized → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenContractRevertInitialized(uint8)` | 109 | Fuzz: initialized then token reverts → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenContractRevert()` | 120 | Token etched with `0xfd` uninitialized → reverts with `ReadFailure` |

---

### 2.5 `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

**Contract:** `LibTOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest`
**Constructor:** forks, deploys singleton, calls `ensureDeployed()`.

| Test | Line | What it covers |
|---|---|---|
| `testSafeDecimalsForTokenReadOnlyAddressZero()` | 22 | `address(0)` → reverts `TokenDecimalsReadFailure(address(0), ReadFailure)` |
| `testSafeDecimalsForTokenReadOnlyValidValue(uint8)` | 27 | Fuzz: returns decimals on success (no state initialized) |
| `testSafeDecimalsForTokenReadOnlyConsistentInconsistent(uint8, uint8)` | 33 | Fuzz: state initialized via stateful call; read-only succeeds if consistent or reverts if inconsistent |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8, uint256)` | 53 | Fuzz: initialized then value > 0xff → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256)` | 66 | Fuzz: value > 0xff uninitialized → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8, bytes, uint256)` | 77 | Fuzz: initialized then short data → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256)` | 97 | Fuzz: short data uninitialized → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenReadOnlyContractRevertInitialized(uint8)` | 112 | Fuzz: initialized then token reverts → reverts with `ReadFailure` |
| `testSafeDecimalsForTokenReadOnlyContractRevert()` | 123 | Token etched with `0xfd` uninitialized → reverts with `ReadFailure` |

---

### 2.6 `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol`

**Contract:** `LibTOFUTokenDecimalsRealTokensTest`
**Constructor:** forks mainnet via `ETH_RPC_URL`, deploys singleton.

| Test | Line | What it covers |
|---|---|---|
| `testRealTokenWETH()` | 31 | WETH: Initial (18 decimals), then Consistent (18 decimals) |
| `testRealTokenUSDC()` | 42 | USDC: Initial (6 decimals), then Consistent (6 decimals) |
| `testRealTokenWBTC()` | 53 | WBTC: Initial (8 decimals), then Consistent (8 decimals) |
| `testRealTokenDAI()` | 64 | DAI: Initial (18 decimals), then Consistent (18 decimals) |
| `testRealTokenCrossTokenIsolation()` | 76 | WETH and USDC do not contaminate each other's storage slots |

---

## 3. Coverage Analysis

### 3.1 Function-level coverage

| Function | Tested? | Notes |
|---|---|---|
| `ensureDeployed()` | Yes | Both Branch A (no code) and Branch B (wrong codehash) covered |
| `decimalsForTokenReadOnly()` | Yes | Full suite including failure propagation and not-deployed revert |
| `decimalsForToken()` | Yes | Full suite including failure propagation and not-deployed revert |
| `safeDecimalsForToken()` | Yes | Full suite covering all error outcomes |
| `safeDecimalsForTokenReadOnly()` | Yes | Full suite covering all error outcomes |

### 3.2 `ensureDeployed` branch analysis

The condition `code.length == 0 || codehash != EXPECTED` has two distinct internal branches:

| Branch | Triggered by | Test that covers it |
|---|---|---|
| Branch A: `code.length == 0` | No fork, address has no code | `testEnsureDeployedRevert()` (line 71) |
| Branch B: `codehash != expected` | `vm.etch` with wrong bytecode | `testEnsureDeployedRevertWrongCodeHash()` (line 81) |

Both branches are exercised. Because the condition is `A || B`, Branch B is only reachable when Branch A is false (i.e., code is present). The test correctly ensures code is present (via `vm.etch`) before testing the codehash mismatch path, so the codehash branch is genuinely exercised. This is correct.

### 3.3 `TOFUTokenDecimalsNotDeployed` error propagation

The error is tested as the revert outcome for all four public functions when the singleton is not deployed:

- `decimalsForTokenReadOnly` — `testDecimalsForTokenReadOnlyRevert()` (line 96)
- `decimalsForToken` — `testDecimalsForTokenRevert()` (line 107)
- `safeDecimalsForToken` — `testSafeDecimalsForTokenRevert()` (line 118)
- `safeDecimalsForTokenReadOnly` — `testSafeDecimalsForTokenReadOnlyRevert()` (line 129)

All four wrappers call their corresponding library function through `this.external*()` so that `vm.expectRevert` can capture the revert. Coverage is complete.

---

## 4. Findings

### FINDING-P2-LIB-01 — `testEnsureDeployedRevert` does not distinguish Branch A from Branch B in the error payload

**Severity:** LOW
**Location:** `test/src/lib/LibTOFUTokenDecimals.t.sol`, lines 71–79 and 81–94

**Description:**
Both `testEnsureDeployedRevert` (Branch A: zero code length) and `testEnsureDeployedRevertWrongCodeHash` (Branch B: wrong codehash) revert with the same error selector and the same `deployedAddress` argument. The error type itself carries no information about *which* sub-condition fired. This is by design in the source code, but the test does not include an assertion or comment that confirms the caller cannot distinguish the two cases from the error payload alone.

This is not a defect in the tests themselves, but the test names and comments could mislead a future maintainer into thinking the two paths are independently distinguishable at the ABI level — they are not.

**Recommendation:** Add a comment in both tests clarifying that `TOFUTokenDecimalsNotDeployed` is deliberately unified across both sub-conditions, so future maintainers do not add an "error reason" parameter that breaks the ABI.

---

### FINDING-P2-LIB-02 — No test for `ensureDeployed` called directly in a fork context where the contract is correctly deployed

**Severity:** LOW
**Location:** `test/src/lib/LibTOFUTokenDecimals.t.sol`, line 33 (`testDeployAddress`)

**Description:**
`testDeployAddress` does call `LibTOFUTokenDecimals.ensureDeployed()` after forking and deploying (line 39), which is the happy path for Branch A+B both passing. However, `ensureDeployed()` is called as a bare internal library call (not through `this.externalEnsureDeployed()`). This means if `ensureDeployed()` unexpectedly reverts on the happy path, the test will fail with a generic revert rather than a named expectation. This pattern is consistent across all fork-based test constructors.

This is a very minor readability/diagnostic issue, not a coverage gap, since the test will still fail on a broken `ensureDeployed()`.

**Recommendation:** No change strictly required, but noting for completeness.

---

### FINDING-P2-LIB-03 — No isolation test for `safeDecimalsForTokenReadOnly` not writing storage

**Severity:** LOW
**Location:** `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

**Description:**
`testDecimalsForTokenReadOnlyDoesNotWriteStorage` (line 65) exists in the `decimalsForTokenReadOnly` test file and explicitly proves that the read-only variant does not write storage. No analogous test exists for `safeDecimalsForTokenReadOnly`. Because `safeDecimalsForTokenReadOnly` delegates to the same underlying `decimalsForTokenReadOnly` on the singleton (which is itself `view`), the absence of such a test for the `safe*` variant leaves the no-write guarantee untested at the wrapper level for `safeDecimalsForTokenReadOnly`.

In practice this is covered transitively (the singleton's `decimalsForTokenReadOnly` is `view` and Solidity enforces this at the EVM level), but explicit test documentation of the invariant is missing for the safe variant.

**Recommendation (optional):** Add `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` mirroring the existing test for the non-safe variant.

---

### FINDING-P2-LIB-04 — `testEnsureDeployedRevert` tests only the zero-code-length path indirectly

**Severity:** INFO
**Location:** `test/src/lib/LibTOFUTokenDecimals.t.sol`, line 71

**Description:**
`testEnsureDeployedRevert` does not fork (`vm.createSelectFork` is absent), so the expected address holds no code. This correctly exercises Branch A. However, the test also implicitly passes through the `|| codehash != EXPECTED` clause: when `code.length == 0`, `codehash` is `bytes32(0)`, which is not equal to the expected hash. So both sides of the `||` are individually true. Due to short-circuit evaluation, Branch B is never independently evaluated in this test. Branch B is exercised separately in `testEnsureDeployedRevertWrongCodeHash`. This is correct and the separation is intentional.

No action required. Noted for completeness.

---

### FINDING-P2-LIB-05 — Real-token tests use only `decimalsForToken`; no real-token tests for `decimalsForTokenReadOnly`, `safeDecimalsForToken`, or `safeDecimalsForTokenReadOnly`

**Severity:** LOW
**Location:** `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol`

**Description:**
All five integration tests in `LibTOFUTokenDecimalsRealTokensTest` exclusively call `LibTOFUTokenDecimals.decimalsForToken`. There are no real-token integration tests for:
- `decimalsForTokenReadOnly`
- `safeDecimalsForToken`
- `safeDecimalsForTokenReadOnly`

While the other three functions are thoroughly covered by mock-based fuzz tests, the absence of real-token integration tests for them means that any ABI-encoding issue specific to the `view` external call path or to the `safe*` revert-on-failure path would not be caught against actual mainnet ERC20 contracts. The `vm.mockCall` path exercises different EVM code (the mock intercept), not the real token's `decimals()` response.

**Recommendation:** Add at least one integration test per remaining function against a real token (e.g., USDC or WETH), checking `Initial` outcome on first call and (for `safe*`) that the return value equals the known decimals.

---

## 5. Summary Table

| Finding | Severity | Category | Short Description |
|---|---|---|---|
| FINDING-P2-LIB-01 | LOW | Documentation / test clarity | `TOFUTokenDecimalsNotDeployed` error does not distinguish sub-conditions; tests should note this |
| FINDING-P2-LIB-02 | LOW | Test diagnostic quality | `ensureDeployed()` happy path not tested via external wrapper with explicit expectation |
| FINDING-P2-LIB-03 | LOW | Coverage gap | No explicit "does not write storage" test for `safeDecimalsForTokenReadOnly` |
| FINDING-P2-LIB-04 | INFO | Coverage clarification | Branch A test implicitly also satisfies Branch B; separation is correct and intentional |
| FINDING-P2-LIB-05 | LOW | Integration coverage gap | Real-token tests cover only `decimalsForToken`; three other functions have no real-token test |

---

## 6. Overall Assessment

Test coverage for `LibTOFUTokenDecimals` is thorough. All five library functions have dedicated test files. The `ensureDeployed` guard is tested for both revert sub-conditions (zero code length and codehash mismatch) and for all four wrapper functions when not deployed. Fuzz testing covers the full range of `uint8` decimals values and all `TOFUOutcome` variants (Initial, Consistent, Inconsistent, ReadFailure). The `Initialized` variants (where storage already holds a value) are tested separately from the uninitialized variants for every failure mode. The `testDecimalsForTokenReadOnlyDoesNotWriteStorage` test explicitly proves the no-write invariant.

The identified gaps are low-severity: absence of real-token integration tests for three of the four public functions, absence of a no-write-storage test for `safeDecimalsForTokenReadOnly`, and minor test clarity issues. No critical or high-severity coverage gaps were found.
