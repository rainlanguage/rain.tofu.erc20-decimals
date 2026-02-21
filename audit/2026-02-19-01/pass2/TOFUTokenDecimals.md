# Pass 2 -- Test Coverage: `TOFUTokenDecimals.sol`

**Auditor:** A03
**Date:** 2026-02-19
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/concrete/TOFUTokenDecimals.sol`

---

## 1. Evidence of Thorough Reading

### Contract Name

`TOFUTokenDecimals` (line 14), inheriting `ITOFUTokenDecimals`.

### Imports (lines 5--7)

| Import | Source |
|--------|--------|
| `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult` | `../interface/ITOFUTokenDecimals.sol` |
| `TOFUOutcome`, `LibTOFUTokenDecimals` | `../lib/LibTOFUTokenDecimals.sol` |
| `LibTOFUTokenDecimalsImplementation` | `../lib/LibTOFUTokenDecimalsImplementation.sol` |

Note: `TOFUOutcome` and `LibTOFUTokenDecimals` are imported but neither is used directly in the contract body. `LibTOFUTokenDecimals` is the caller-side convenience library (layer 3); the concrete contract uses `LibTOFUTokenDecimalsImplementation` (layer 1). These unused imports do not affect bytecode because `cbor_metadata = false` and `bytecode_hash = "none"`, but they are unnecessary.

### State Variables

| Name | Type | Visibility | Line |
|------|------|-----------|------|
| `sTOFUTokenDecimals` | `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)` | `internal` | 16 |

### Functions

| Function | Visibility | Mutability | Line | Delegates To |
|----------|-----------|------------|------|-------------|
| `decimalsForTokenReadOnly(address)` | `external` | `view` | 19 | `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` |
| `decimalsForToken(address)` | `external` | (state-changing) | 25 | `LibTOFUTokenDecimalsImplementation.decimalsForToken` |
| `safeDecimalsForToken(address)` | `external` | (state-changing) | 31 | `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken` |
| `safeDecimalsForTokenReadOnly(address)` | `external` | `view` | 36 | `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly` |

All four functions are thin wrappers: each passes `sTOFUTokenDecimals` and `token` directly to the corresponding `LibTOFUTokenDecimalsImplementation` function and returns the result without any additional logic.

---

## 2. Test Coverage Findings

### A03-1: No dedicated test file for `TOFUTokenDecimals` concrete contract [INFO]

**Observation:** There is no `test/src/concrete/TOFUTokenDecimals*.t.sol` file. The `test/src/concrete/` directory does not exist at all. All tests are organized under `test/src/lib/`.

**Mitigating factor:** The `LibTOFUTokenDecimals.*` test files (the layer-3 wrapper tests) deploy the concrete contract via the Zoltu factory in their constructor and then call its functions externally through the `LibTOFUTokenDecimals` library, which makes external calls to the concrete contract's ABI. This means every function of the concrete contract is exercised as a real external call target on a deployed instance. The delegation chain in tests is:

```
Test contract -> LibTOFUTokenDecimals.decimalsForToken(token)
  -> ensureDeployed()
  -> TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)   // external call to concrete contract
    -> LibTOFUTokenDecimalsImplementation.decimalsForToken(sTOFUTokenDecimals, token)
```

**Assessment:** While dedicated concrete-contract-level tests would be a belt-and-suspenders approach, the existing integration test path through `LibTOFUTokenDecimals` does exercise the concrete contract's external functions on a real deployed instance. The contract's functions are pure pass-through wrappers with no additional logic, so the risk of untested behavior in the thin wrapper is minimal.

**Severity:** INFO

---

### A03-2: All four external function wrappers are tested for correct delegation [INFO]

**Observation:** Each of the four external functions on `TOFUTokenDecimals` is exercised transitively:

| Concrete Function | Tested Via (Library Test File) | Test Count |
|---|---|---|
| `decimalsForToken` | `LibTOFUTokenDecimals.decimalsForToken.t.sol` | 8 tests (incl. fuzz) |
| `decimalsForTokenReadOnly` | `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` | 9 tests (incl. fuzz) |
| `safeDecimalsForToken` | `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` | 6 tests (incl. fuzz) |
| `safeDecimalsForTokenReadOnly` | `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` | 6 tests (incl. fuzz) |

Each test file deploys the concrete contract in its constructor via `LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode)` on a mainnet fork and asserts the deployed address matches the expected singleton address. The tests then call through `LibTOFUTokenDecimals` which makes real external calls to the deployed concrete contract.

Test scenarios covered per function include:
- Address zero (EOA, no code) -> `ReadFailure`
- Valid `uint8` decimals -> `Initial` on first call, `Consistent`/`Inconsistent` on second
- Return data too large (> `0xff`) -> `ReadFailure`
- Return data too short (< 32 bytes) -> `ReadFailure`
- Token contract reverts (`vm.etch` with `0xfd`) -> `ReadFailure`
- Initialized storage + read failure -> returns stored value with `ReadFailure`
- Safe variants revert on `Inconsistent` and `ReadFailure`

**Assessment:** The delegation from concrete contract to `LibTOFUTokenDecimalsImplementation` is well-tested. Return values and outcomes are validated for all four `TOFUOutcome` enum states across both initialized and uninitialized paths.

**Severity:** INFO

---

### A03-3: No explicit test for storage mapping isolation between different token addresses [LOW]

**Observation:** No test in the entire suite explicitly verifies that calling `decimalsForToken` for token A does not affect the stored result for token B. Within individual test functions, different token addresses are used (e.g., `makeAddr("TokenA")`, `makeAddr("TokenB")`), but these address different failure modes rather than asserting cross-token storage isolation.

A storage isolation test would look like:
1. Call `decimalsForToken(tokenA)` with mocked decimals 6 -> assert `Initial`, 6
2. Call `decimalsForToken(tokenB)` with mocked decimals 18 -> assert `Initial`, 18
3. Call `decimalsForToken(tokenA)` with mocked decimals 6 -> assert `Consistent`, 6 (not 18)
4. Call `decimalsForToken(tokenB)` with mocked decimals 18 -> assert `Consistent`, 18 (not 6)

**Mitigating factor:** The storage is a standard Solidity `mapping(address => ...)`, so isolation is guaranteed by the language semantics. There is no custom assembly for storage access in the concrete contract. The risk of a mapping collision bug in the Solidity compiler is negligible for this straightforward pattern.

**Assessment:** While the Solidity compiler guarantees mapping isolation, an explicit test would serve as a regression guard and documentation of the expected behavior, especially given that this is a singleton contract shared across all callers and tokens.

**Severity:** LOW

---

### A03-4: Implementation library has independent unit-level test coverage [INFO]

**Observation:** In addition to the integration tests through the deployed singleton, `LibTOFUTokenDecimalsImplementation` has its own dedicated unit tests that operate on local storage (no fork required):

| Test File | Focus |
|-----------|-------|
| `LibTOFUTokenDecimalsImplementation.t.sol` | Selector constant correctness |
| `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol` | All `decimalsForToken` paths with local mapping |
| `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol` | All `decimalsForTokenReadOnly` paths with local mapping |
| `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` | All `safeDecimalsForToken` paths incl. revert |
| `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` | All `safeDecimalsForTokenReadOnly` paths incl. revert |

These tests directly manipulate the storage mapping (e.g., `sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: ...})`) to independently test both uninitialized and pre-initialized states without needing to rely on the `decimalsForToken` call to set up state.

**Assessment:** The two-layer testing strategy (unit tests on the implementation library + integration tests through the deployed singleton) provides comprehensive coverage. The concrete contract's thin-wrapper nature means the implementation tests are highly relevant.

**Severity:** INFO

---

### A03-5: Code hash and creation code determinism are tested [INFO]

**Observation:** `LibTOFUTokenDecimals.t.sol` includes:

- `testExpectedCodeHash()` (line 40): Deploys a fresh `TOFUTokenDecimals` instance via `new` and asserts its `codehash` matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.
- `testExpectedCreationCode()` (line 46): Asserts `type(TOFUTokenDecimals).creationCode` matches `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (a pure/compile-time check).
- `testDeployAddress()` (line 31): Deploys via Zoltu factory on a fork and asserts the resulting address matches `TOFU_DECIMALS_DEPLOYMENT`.
- `testEnsureDeployedRevert()` and `testEnsureDeployedRevertWrongCodeHash()`: Verify the guard reverts when the contract is missing or has wrong code.

**Assessment:** This is critical for the TOFU singleton model and is well covered. Any change to the contract that affects bytecode will be caught by these tests.

**Severity:** INFO

---

## Summary

| Finding | Severity | Description |
|---------|----------|-------------|
| A03-1 | INFO | No dedicated `test/src/concrete/` test file; all testing is transitive through library tests |
| A03-2 | INFO | All four external functions are tested via integration calls through the deployed singleton |
| A03-3 | LOW | No explicit cross-token storage isolation test |
| A03-4 | INFO | Implementation library has independent unit-level test coverage at both layers |
| A03-5 | INFO | Bytecode determinism (code hash, creation code, deploy address) is well tested |

**Overall assessment:** The concrete contract `TOFUTokenDecimals` has good transitive test coverage. All four external functions are exercised as real external calls on a fork-deployed singleton through the `LibTOFUTokenDecimals` wrapper tests. The implementation library has independent unit-level tests covering all code paths. The only gap identified is the absence of an explicit cross-token storage isolation test (A03-3), which is low severity given Solidity's mapping semantics.
