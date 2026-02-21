# Audit Pass 2 (Test Coverage) -- TOFUTokenDecimals.sol

**Agent ID:** A01
**Date:** 2026-02-21
**Source file:** `src/concrete/TOFUTokenDecimals.sol`

---

## Evidence of Thorough Reading

### Source File: `TOFUTokenDecimals.sol`

- **Contract name:** `TOFUTokenDecimals` (line 13), inherits `ITOFUTokenDecimals`
- **Storage:**
  - `sTOFUTokenDecimals` -- `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)` (line 16)
- **Functions:**
  - `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 19)
  - `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 25)
  - `safeDecimalsForToken(address token) external returns (uint8)` (line 31)
  - `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 36)
- **Types/errors/constants used (from interface `ITOFUTokenDecimals.sol`):**
  - `ITOFUTokenDecimals` (interface)
  - `TOFUTokenDecimalsResult` (struct: `bool initialized`, `uint8 tokenDecimals`)
  - `TOFUOutcome` (enum: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`)
  - `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (error)
- **Dependency:** `LibTOFUTokenDecimalsImplementation` (all four functions delegate to it)

### Test File: `TOFUTokenDecimals.decimalsForToken.t.sol`

- **Contract name:** `TOFUTokenDecimalsDecimalsForTokenTest` (line 13), inherits `Test`
- **State:** `concrete` -- `TOFUTokenDecimals` (line 14)
- **Functions:**
  - `setUp()` (line 16) -- deploys fresh `TOFUTokenDecimals`
  - `testDecimalsForToken(uint8 decimals)` (line 20) -- fuzz test, mocks `decimals()`, asserts `Initial` outcome and correct value

### Test File: `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

- **Contract name:** `TOFUTokenDecimalsDecimalsForTokenReadOnlyTest` (line 13), inherits `Test`
- **State:** `concrete` -- `TOFUTokenDecimals` (line 14)
- **Functions:**
  - `setUp()` (line 16) -- deploys fresh `TOFUTokenDecimals`
  - `testDecimalsForTokenReadOnly(uint8 decimals)` (line 20) -- fuzz test, mocks `decimals()`, asserts `Initial` outcome and correct value

### Test File: `TOFUTokenDecimals.safeDecimalsForToken.t.sol`

- **Contract name:** `TOFUTokenDecimalsSafeDecimalsForTokenTest` (line 12), inherits `Test`
- **State:** `concrete` -- `TOFUTokenDecimals` (line 13)
- **Functions:**
  - `setUp()` (line 15) -- deploys fresh `TOFUTokenDecimals`
  - `testSafeDecimalsForToken(uint8 decimals)` (line 19) -- fuzz test, mocks `decimals()`, asserts correct return value on initial call

### Test File: `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

- **Contract name:** `TOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest` (line 12), inherits `Test`
- **State:** `concrete` -- `TOFUTokenDecimals` (line 13)
- **Functions:**
  - `setUp()` (line 15) -- deploys fresh `TOFUTokenDecimals`
  - `testSafeDecimalsForTokenReadOnly(uint8 decimals)` (line 19) -- fuzz test, initializes state via `decimalsForToken`, then reads via `safeDecimalsForTokenReadOnly`, asserts correct value

### Test File: `TOFUTokenDecimals.immutability.t.sol`

- **Contract name:** `TOFUTokenDecimalsImmutabilityTest` (line 10), inherits `Test`
- **Functions:**
  - `testNoMutableOpcodes()` (line 14) -- deploys `TOFUTokenDecimals`, scans bytecode for reachable `SELFDESTRUCT`, `DELEGATECALL`, `CALLCODE` opcodes, asserts none are present

---

## Test Coverage Analysis

### Coverage by Function

| Source Function | Has Concrete-Level Test? | Outcomes Tested at Concrete Level | Outcomes Tested at Library Level |
|---|---|---|---|
| `decimalsForToken` | Yes | `Initial` only | `Initial`, `Consistent`, `Inconsistent`, `ReadFailure` |
| `decimalsForTokenReadOnly` | Yes | `Initial` only | `Initial`, `Consistent`, `Inconsistent`, `ReadFailure` |
| `safeDecimalsForToken` | Yes | `Initial` only (happy path) | `Initial`, `Consistent`, `Inconsistent` (revert), `ReadFailure` (revert) |
| `safeDecimalsForTokenReadOnly` | Yes | `Consistent` only (happy path after init) | `Initial`, `Consistent`, `Inconsistent` (revert), `ReadFailure` (revert) |

### Coverage by Error/Failure Path

| Error/Failure Path | Tested at Concrete Level? | Tested at Library Level? |
|---|---|---|
| `TokenDecimalsReadFailure` on `ReadFailure` | No | Yes |
| `TokenDecimalsReadFailure` on `Inconsistent` | No | Yes |
| Token contract reverts (`vm.etch` with `hex"fd"`) | No | Yes |
| Return data too short (< 32 bytes) | No | Yes |
| Return value > `0xff` (not valid uint8) | No | Yes |
| `address(0)` as token | No | Yes |

---

## Findings

### A01-1: Concrete-Level Tests Only Cover the Initial/Happy Path [LOW]

All four concrete-level test files (`decimalsForToken.t.sol`, `decimalsForTokenReadOnly.t.sol`, `safeDecimalsForToken.t.sol`, `safeDecimalsForTokenReadOnly.t.sol`) only test the `Initial` outcome (or `Consistent` in the case of `safeDecimalsForTokenReadOnly` after manual initialization). None of the concrete tests exercise:

- The `Consistent` outcome path (second call with matching decimals) -- except `safeDecimalsForTokenReadOnly`
- The `Inconsistent` outcome path (second call with differing decimals)
- The `ReadFailure` outcome path (reverting token, invalid return data, address(0))
- The `TokenDecimalsReadFailure` revert for `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly`

**Mitigation:** These paths are all thoroughly covered at the `LibTOFUTokenDecimalsImplementation` library level. Since `TOFUTokenDecimals.sol` is a pure pass-through contract (each function is a single-line delegation to the library with no additional logic), the library-level tests provide effective coverage of all code paths. The concrete tests serve as smoke tests to verify correct wiring.

### A01-2: No Concrete-Level Test for `ReadFailure` Wiring [LOW]

No concrete-level test verifies that the `ReadFailure` outcome propagates correctly through the concrete contract. For example, no test calls `concrete.decimalsForToken(address(0))` or `concrete.decimalsForToken(revertingAddress)` and asserts `TOFUOutcome.ReadFailure`.

**Mitigation:** The library tests cover this extensively (`testDecimalsForTokenAddressZero`, `testDecimalsForTokenTokenContractRevert`, etc.). The concrete contract has zero conditional logic -- it delegates directly to the library. A wiring error here would also be caught by the existing `Initial` path tests failing (if the delegation were broken).

### A01-3: No Concrete-Level Test for `Inconsistent` Outcome Wiring [LOW]

No concrete-level test calls `decimalsForToken` twice with different mocked decimals values to verify the `Inconsistent` outcome propagates through the concrete contract.

**Mitigation:** Covered by `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol` at `testDecimalsForTokenValidValue` and `testDecimalsForTokenNoStorageWriteOnInconsistent`.

### A01-4: No Concrete-Level Test for `TokenDecimalsReadFailure` Error Propagation [LOW]

No concrete-level test verifies that the `TokenDecimalsReadFailure` error reverts correctly when called via `concrete.safeDecimalsForToken()` or `concrete.safeDecimalsForTokenReadOnly()` with a failing token.

**Mitigation:** The library tests thoroughly cover this with both uninitialized and initialized storage states. The concrete contract adds no logic that could interfere with error propagation.

### A01-5: No Concrete-Level Test for Cross-Token Storage Isolation [LOW]

No concrete-level test verifies that calling `decimalsForToken` for token A does not affect the stored result for token B. This is tested at the library level by `testDecimalsForTokenCrossTokenIsolation`.

**Mitigation:** Storage isolation is a property of the Solidity `mapping` type and the library implementation, both of which are tested. The concrete contract introduces no additional storage manipulation.

### A01-6: No Concrete-Level Test for Storage Immutability After Non-Initial Outcomes [LOW]

No concrete-level test verifies that a `ReadFailure` or `Inconsistent` outcome does not corrupt the stored value in the concrete contract's `sTOFUTokenDecimals` mapping. This is tested at the library level by `testDecimalsForTokenNoStorageWriteOnNonInitial` and `testDecimalsForTokenNoStorageWriteOnInconsistent`.

**Mitigation:** The library tests verify this property directly on the same code path that the concrete contract invokes.

### A01-7: `decimalsForTokenReadOnly` Concrete Test Does Not Verify Read-Only Semantics [INFO]

The concrete test for `decimalsForTokenReadOnly` only verifies a single call returns `Initial`. It does not verify that calling `decimalsForTokenReadOnly` does NOT persist state (i.e., that a subsequent call still returns `Initial` rather than `Consistent`). The library-level tests for the read-only function do cover the non-persistence behavior implicitly (they manually set storage to test `Consistent`/`Inconsistent` rather than relying on the function to persist).

**Mitigation:** The function is declared `view` in both the interface and concrete contract. The Solidity compiler enforces that `view` functions cannot write state, so the read-only property is guaranteed at the language level.

### A01-8: Immutability Test Provides Good Bytecode-Level Security Coverage [INFO]

The `TOFUTokenDecimalsImmutabilityTest` verifies that the deployed bytecode contains no reachable `SELFDESTRUCT`, `DELEGATECALL`, or `CALLCODE` opcodes. This is excellent coverage for a singleton contract that must be immutable after deployment.

### A01-9: Fuzz Testing Provides Implicit Boundary Coverage [INFO]

All concrete-level tests use `uint8` fuzz inputs for decimals values. Foundry's fuzzer will naturally exercise boundary values including `0` (zero decimals) and `255` (max uint8). The library-level tests additionally use `uint256` inputs with `vm.assume(decimals > 0xff)` to test the overflow boundary.

---

## Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| CRITICAL | 0 | -- |
| HIGH | 0 | -- |
| MEDIUM | 0 | -- |
| LOW | 6 | A01-1 through A01-6 |
| INFO | 3 | A01-7, A01-8, A01-9 |

The `TOFUTokenDecimals.sol` concrete contract is a minimal pass-through wrapper with zero conditional logic. All four functions delegate to `LibTOFUTokenDecimalsImplementation` in a single line. The library-level tests provide thorough coverage of all code paths, outcomes, error conditions, boundary values, and storage properties. The concrete-level tests serve as appropriate smoke tests confirming correct wiring. No CRITICAL or HIGH severity coverage gaps were identified.
