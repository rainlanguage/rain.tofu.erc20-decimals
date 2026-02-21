# Audit Pass 2 -- Test Coverage: ITOFUTokenDecimals.sol

**Auditor:** A01
**Date:** 2026-02-19
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/interface/ITOFUTokenDecimals.sol`

---

## 1. Evidence of Thorough Reading

### Interface

- **`ITOFUTokenDecimals`** (line 53)

### Functions (all in `ITOFUTokenDecimals`)

| Function | Line | Mutability |
|---|---|---|
| `decimalsForTokenReadOnly(address)` | 65 | `view` |
| `decimalsForToken(address)` | 73 | non-view |
| `safeDecimalsForToken(address)` | 79 | non-view |
| `safeDecimalsForTokenReadOnly(address)` | 85 | `view` |

### Struct

- **`TOFUTokenDecimalsResult`** (line 13) -- fields: `bool initialized`, `uint8 tokenDecimals`

### Enum

- **`TOFUOutcome`** (line 19) -- variants: `Initial` (0), `Consistent` (1), `Inconsistent` (2), `ReadFailure` (3)

### Error

- **`TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`** (line 33)

### Events

None defined.

---

## 2. Test Coverage Findings

### 2.1 `TOFUTokenDecimalsResult` struct

**Coverage status: COVERED**

The struct is exercised extensively across both `LibTOFUTokenDecimalsImplementation` and `LibTOFUTokenDecimals` test files. Tests construct it with `initialized: true` and various `tokenDecimals` values. The uninitialized (`initialized: false`) default state is exercised implicitly by every test that calls `decimalsForToken` or `decimalsForTokenReadOnly` on a fresh mapping entry (the Solidity default zero-value for the struct has `initialized == false`).

### 2.2 `TOFUOutcome` enum

**Coverage status: ALL VARIANTS COVERED**

| Variant | Tested In |
|---|---|
| `Initial` | `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`, `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`, `LibTOFUTokenDecimals.decimalsForToken.t.sol`, `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` |
| `Consistent` | Same files as above (fuzz tests where `decimalsA == decimalsB`) |
| `Inconsistent` | Same files as above (fuzz tests where `decimalsA != decimalsB`) |
| `ReadFailure` | All test files -- address(0), `vm.etch(hex"fd")`, too-large values, insufficient data |

### 2.3 `TokenDecimalsReadFailure` error

**Coverage status: COVERED**

Tested in all four `safe*` test files at both the `Implementation` and `LibTOFUTokenDecimals` layers:
- `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` -- reverts with `ReadFailure` and `Inconsistent`
- `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` -- reverts with `ReadFailure` and `Inconsistent`
- `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` -- reverts with `ReadFailure` and `Inconsistent`
- `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` -- reverts with `ReadFailure` and `Inconsistent`

The error is verified with `vm.expectRevert(abi.encodeWithSelector(...))` confirming both the error selector and its parameters.

### 2.4 Interface functions

All four interface functions are tested indirectly. The `TOFUTokenDecimals` concrete contract implements `ITOFUTokenDecimals` and delegates to `LibTOFUTokenDecimalsImplementation`. The `LibTOFUTokenDecimals` convenience library calls through to the deployed concrete contract. Test coverage exists at both layers:

| Function | Implementation-level tests | Singleton-level tests (fork) |
|---|---|---|
| `decimalsForTokenReadOnly` | `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol` | `LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` |
| `decimalsForToken` | `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol` | `LibTOFUTokenDecimals.decimalsForToken.t.sol` |
| `safeDecimalsForToken` | `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` | `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` |
| `safeDecimalsForTokenReadOnly` | `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` | `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` |

---

## 3. Findings

### A01-1: No direct interface-level tests for `ITOFUTokenDecimals` [INFO]

**Severity:** INFO

There is no test file that casts the `TOFUTokenDecimals` concrete contract as `ITOFUTokenDecimals` and calls functions through the interface. All tests call either the `LibTOFUTokenDecimalsImplementation` internal functions directly (passing a storage mapping) or the `LibTOFUTokenDecimals` convenience library (which calls the singleton externally).

The concrete contract `TOFUTokenDecimals` is a trivial pass-through to `LibTOFUTokenDecimalsImplementation`, and the `LibTOFUTokenDecimals` tests do exercise the concrete contract externally via the deployed singleton (fork tests). The singleton implements `ITOFUTokenDecimals`, so the interface ABI is exercised in practice. This is informational only, since a dedicated interface-cast test would be redundant given the thin concrete implementation.

### A01-2: No test for `TOFUTokenDecimals` concrete contract in isolation [LOW]

**Severity:** LOW

There is no `test/src/concrete/TOFUTokenDecimals*.t.sol` test file. The concrete contract is only tested indirectly: once in `LibTOFUTokenDecimals.t.sol` (via `new TOFUTokenDecimals()` for code hash verification), and then through the fork-deployed singleton in the `LibTOFUTokenDecimals.*.t.sol` files.

While the concrete contract is a trivial delegator, having at least one direct test that instantiates `TOFUTokenDecimals` and calls all four functions on it would confirm the pass-through wiring is correct independent of the singleton deployment. The fork tests effectively serve this purpose, but they are conditional on `ETH_RPC_URL` being available.

### A01-3: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` do not test the `Initial` success path at the singleton level [INFO]

**Severity:** INFO

At the `LibTOFUTokenDecimals` (singleton) level, the `safeDecimalsForToken` tests call the function and assert the return value equals the expected decimals, but do not explicitly verify that the underlying `TOFUOutcome` was `Initial` on the first call. This is inherent to the `safe*` API which does not expose the outcome enum (it only returns `uint8`). The `Initial` success path is implicitly tested because the function does not revert and returns the correct value.

At the `LibTOFUTokenDecimalsImplementation` level, the `safeDecimalsForToken` test in `testSafeDecimalsForTokenValidValue` does explicitly verify the `Initial` outcome via a separate call to `decimalsForToken` before calling `safeDecimalsForToken`. This is adequate.

---

## 4. Summary

The test coverage for types, errors, and functions defined in `ITOFUTokenDecimals.sol` is thorough. All four `TOFUOutcome` variants are exercised. The `TokenDecimalsReadFailure` error is tested with both `ReadFailure` and `Inconsistent` outcomes at both the implementation and singleton levels. The `TOFUTokenDecimalsResult` struct is constructed and used extensively.

The findings are all informational or low severity, reflecting minor gaps in test organization rather than missing functional coverage.
