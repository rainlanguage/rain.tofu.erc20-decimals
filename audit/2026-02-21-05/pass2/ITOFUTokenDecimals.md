# Audit Pass 2 -- Test Coverage for `src/interface/ITOFUTokenDecimals.sol`

**Agent:** A03
**Date:** 2026-02-21
**Audit:** 2026-02-21-05
**Pass:** 2 (Test Coverage)

## Source File Summary

`src/interface/ITOFUTokenDecimals.sol` defines:

1. **`TOFUTokenDecimalsResult` struct** -- `{ bool initialized; uint8 tokenDecimals; }` -- encodes a stored decimals value with an `initialized` flag to disambiguate stored `0` from uninitialized storage.
2. **`TOFUOutcome` enum** -- four values: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`.
3. **`ITOFUTokenDecimals` interface** -- declares:
   - `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`
   - `function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)`
   - `function decimalsForToken(address token) external returns (TOFUOutcome, uint8)`
   - `function safeDecimalsForToken(address token) external returns (uint8)`
   - `function safeDecimalsForTokenReadOnly(address token) external view returns (uint8)`

## Evidence of Thorough Reading

### Test files examined

| Test File | Layer Tested |
|-----------|-------------|
| `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol` | Concrete contract: `decimalsForToken` |
| `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` | Concrete contract: `decimalsForTokenReadOnly` |
| `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol` | Concrete contract: `safeDecimalsForToken` |
| `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` | Concrete contract: `safeDecimalsForTokenReadOnly` |
| `test/src/concrete/TOFUTokenDecimals.immutability.t.sol` | Concrete contract: immutability/opcode scanning |
| `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol` | Implementation lib: `decimalsForToken` |
| `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol` | Implementation lib: `decimalsForTokenReadOnly` |
| `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` | Implementation lib: `safeDecimalsForToken` |
| `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` | Implementation lib: `safeDecimalsForTokenReadOnly` |
| `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol` | Implementation lib: selector constant |
| `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol` | Convenience lib (fork): `decimalsForToken` |
| `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` | Convenience lib (fork): `decimalsForTokenReadOnly` |
| `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` | Convenience lib (fork): `safeDecimalsForToken` |
| `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` | Convenience lib (fork): `safeDecimalsForTokenReadOnly` |
| `test/src/lib/LibTOFUTokenDecimals.t.sol` | Convenience lib: deployment, codehash, creation code |
| `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol` | Integration: real mainnet tokens (WETH, USDC, WBTC, DAI) |

## Checklist Analysis

### 1. Is `TokenDecimalsReadFailure` tested for both `ReadFailure` and `Inconsistent` outcomes?

**Yes -- well covered.**

- **`ReadFailure` outcome:** Tested extensively across all three layers. Examples:
  - Concrete: `testSafeDecimalsForTokenReadFailureReverts` (line 58, `TOFUTokenDecimals.safeDecimalsForToken.t.sol`), `testSafeDecimalsForTokenReadOnlyReadFailureReverts` (line 95, `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`).
  - Implementation lib: `testSafeDecimalsForTokenAddressZeroUninitialized` (line 21, `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`), and many more.
  - Convenience lib (fork): `testSafeDecimalsForTokenAddressZero` (line 23, `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`).

- **`Inconsistent` outcome:** Tested at all three layers:
  - Concrete: `testSafeDecimalsForTokenInconsistentReverts` (line 43, `TOFUTokenDecimals.safeDecimalsForToken.t.sol`), `testSafeDecimalsForTokenReadOnlyInconsistentReverts` (line 45, `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`).
  - Implementation lib: `testSafeDecimalsForTokenInconsistent` (line 37, `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`), `testSafeDecimalsForTokenReadOnlyInconsistent` (line 34, `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`).
  - Convenience lib (fork): `testSafeDecimalsForTokenConsistentInconsistent` (line 34, `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`).

### 2. Are all 4 `TOFUOutcome` enum values exercised in tests?

**Yes -- all four are exercised.**

| Outcome | Test Evidence |
|---------|--------------|
| `Initial` | `testDecimalsForToken` (concrete, line 22); `testDecimalsForTokenValidValue` (impl lib, line 35); `testDecimalsForTokenReadOnly` (concrete, line 27); real tokens test (line 33). |
| `Consistent` | `testDecimalsForTokenConsistent` (concrete, line 40); `testDecimalsForTokenValidValue` (impl lib, line 44); real tokens cross-isolation (line 115). |
| `Inconsistent` | `testDecimalsForTokenInconsistent` (concrete, line 56); `testDecimalsForTokenReadOnlyInconsistent` (concrete, line 56); `testDecimalsForTokenValidValue` (impl lib, line 47). |
| `ReadFailure` | `testDecimalsForTokenReadFailure` (concrete, line 67); `testDecimalsForTokenAddressZero` (impl lib, line 19); overwide-decimals tests; reverting token tests. |

### 3. Is the `initialized` flag logic tested (stored 0 decimals vs uninitialized)?

**Partially covered -- fuzz ranges include 0 but no dedicated explicit test exists at the concrete layer.**

- Fuzz tests with `uint8 decimals` parameters include `0` in the fuzz range. For example, `testDecimalsForToken(uint8 decimals)` in the concrete test will receive `0` as a fuzz input. When `decimals == 0`, the flow exercises: mock returns 0 -> Initial outcome -> value stored as `TOFUTokenDecimalsResult({initialized: true, tokenDecimals: 0})`. A subsequent call would then distinguish stored `0` from uninitialized `0` via the `initialized` flag, returning `Consistent` rather than `Initial`.
- At the implementation lib level, tests directly construct `TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)})` with fuzzed `storedDecimals` values (which include 0).
- The `ReadFailure` tests for uninitialized tokens (`testDecimalsForTokenReadFailure` at concrete line 62) assert `result == 0`, confirming the returned value for an uninitialized mapping slot is 0. This implicitly verifies that the struct's default `initialized == false` prevents confusion with a stored `0`.

However, there is no explicit, targeted test that:
  1. Initializes a token with `decimals == 0` specifically (not as a fuzz input).
  2. Reads again and asserts `Consistent` (not `Initial`), proving the `initialized` flag distinguishes stored 0 from uninitialized.

The fuzz coverage makes this statistically very likely to be exercised, but a dedicated concrete test would add clarity and auditability.

### 4. Are all 4 interface functions exercised via the concrete contract tests?

**Yes -- all four are exercised.**

| Interface Function | Concrete Test File |
|---|---|
| `decimalsForTokenReadOnly` | `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` -- 8 test functions |
| `decimalsForToken` | `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol` -- 9 test functions |
| `safeDecimalsForToken` | `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol` -- 7 test functions |
| `safeDecimalsForTokenReadOnly` | `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` -- 9 test functions |

Each function is additionally tested at both the implementation library layer (local state, no fork) and the convenience library layer (forked, via singleton deployment).

## Findings

### A03-01 [INFO] -- Excellent three-layer test coverage for all interface types

All four `TOFUOutcome` enum values, the `TokenDecimalsReadFailure` error (with both `ReadFailure` and `Inconsistent` payloads), and all four interface functions are exercised at three independent test layers:
1. `LibTOFUTokenDecimalsImplementation` (direct library, local state)
2. `LibTOFUTokenDecimals` (convenience library, fork deployment via Zoltu)
3. `TOFUTokenDecimals` concrete contract (direct instantiation, no fork)

Additionally, the `LibTOFUTokenDecimals.realTokens.t.sol` integration test validates behavior against real mainnet tokens (WETH, USDC, WBTC, DAI).

### A03-02 [INFO] -- `initialized` flag logic is implicitly covered by fuzz tests

The `initialized` flag's purpose -- disambiguating stored `tokenDecimals == 0` from uninitialized storage (where `tokenDecimals` is also `0` by default) -- is covered by fuzz tests whose `uint8 decimals` parameter includes `0` in the fuzz range. At the implementation lib level, `TOFUTokenDecimalsResult` structs are directly constructed with `{initialized: true, tokenDecimals: uint8(storedDecimals)}` where `storedDecimals` is fuzzed across the full `uint8` range. No explicit, dedicated test for `decimals == 0` initialization-then-consistency exists at the concrete layer, but the fuzz coverage makes this edge case statistically well-exercised. A dedicated test could improve auditability but is not a gap.

### A03-03 [INFO] -- `TokenDecimalsReadFailure` error payload includes correct `TOFUOutcome` discriminant

Tests consistently verify the error payload encodes the correct `TOFUOutcome` value:
- `Inconsistent` when stored decimals differ from the live read.
- `ReadFailure` when the `staticcall` fails, returns insufficient data, or returns a value exceeding `uint8` range.

The error is never emitted with `Initial` or `Consistent` outcomes, which aligns with the implementation's guard: `if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial)`.

### A03-04 [INFO] -- Storage immutability on non-Initial outcomes is well tested

Tests at both the implementation lib and concrete layers verify that:
- `ReadFailure` does not corrupt stored values (`testDecimalsForTokenStorageImmutableOnReadFailure`, `testDecimalsForTokenNoStorageWriteOnNonInitial`).
- `Inconsistent` does not overwrite stored values (`testDecimalsForTokenStorageImmutableOnInconsistent`, `testDecimalsForTokenNoStorageWriteOnInconsistent`).
- `decimalsForTokenReadOnly` does not write storage (`testDecimalsForTokenReadOnlyDoesNotWriteStorage` at both concrete and lib layers).

### A03-05 [LOW] -- No explicit test for `decimals == 0` round-trip through the concrete contract

While fuzz tests statistically cover `decimals == 0`, there is no explicit, non-fuzz test that:
1. Calls `concrete.decimalsForToken(token)` with a mock returning `0`.
2. Asserts the outcome is `Initial` with `result == 0`.
3. Calls `concrete.decimalsForToken(token)` again.
4. Asserts the outcome is `Consistent` with `result == 0` (not `Initial`).

This would serve as a concrete regression test proving the `initialized` flag works correctly for the critical `0`-decimals edge case. The risk is low because fuzz coverage handles this, but a named test improves long-term auditability and prevents regression if the fuzz seed changes.

**Affected files:**
- `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

### A03-06 [INFO] -- Cross-token isolation tested at all layers

The concrete layer (`testDecimalsForTokenCrossTokenIsolation`), the implementation lib (`testDecimalsForTokenCrossTokenIsolation`), and the real-tokens integration test (`testRealTokenCrossTokenIsolation`) all verify that initializing one token does not affect another token's stored state.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 1 |
| INFO     | 5 |

The interface types defined in `ITOFUTokenDecimals.sol` enjoy thorough test coverage across three independent layers, with all enum values, error payloads, and interface functions exercised. The single LOW finding recommends adding a dedicated explicit test for the `decimals == 0` edge case to complement the existing fuzz coverage.
