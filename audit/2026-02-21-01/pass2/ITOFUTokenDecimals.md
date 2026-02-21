# Pass 2: Test Coverage -- `src/interface/ITOFUTokenDecimals.sol`

**Auditor:** A02
**Date:** 2026-02-21

## 1. Source File Inventory

File: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/interface/ITOFUTokenDecimals.sol`

### Struct

| Item | Type | Line(s) |
|------|------|---------|
| `TOFUTokenDecimalsResult` | struct | 13-16 |
| `TOFUTokenDecimalsResult.initialized` | `bool` field | 14 |
| `TOFUTokenDecimalsResult.tokenDecimals` | `uint8` field | 15 |

### Enum

| Item | Type | Line(s) |
|------|------|---------|
| `TOFUOutcome` | enum | 19-28 |
| `TOFUOutcome.Initial` | variant (0) | 21 |
| `TOFUOutcome.Consistent` | variant (1) | 23 |
| `TOFUOutcome.Inconsistent` | variant (2) | 25 |
| `TOFUOutcome.ReadFailure` | variant (3) | 27 |

### Error

| Item | Type | Line(s) |
|------|------|---------|
| `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` | error | 33 |

### Interface: `ITOFUTokenDecimals` (lines 53-92)

| Function | Mutability | Return | Line |
|----------|-----------|--------|------|
| `decimalsForTokenReadOnly(address token)` | `view` | `(TOFUOutcome, uint8)` | 67 |
| `decimalsForToken(address token)` | non-view | `(TOFUOutcome, uint8)` | 77 |
| `safeDecimalsForToken(address token)` | non-view | `uint8` | 83 |
| `safeDecimalsForTokenReadOnly(address token)` | `view` | `uint8` | 91 |

No constants, no modifiers, no events, no constructor logic.

## 2. Test Coverage Findings

Since `ITOFUTokenDecimals.sol` is a pure interface file (no executable code), coverage is measured by how thoroughly the types, error, and function signatures it defines are exercised through implementations. The file is tested at three levels:

1. **`LibTOFUTokenDecimalsImplementation` tests** -- direct unit tests against the core logic library
2. **`TOFUTokenDecimals` (concrete) tests** -- smoke tests against the deployed contract implementing the interface
3. **`LibTOFUTokenDecimals` tests** -- integration tests via the convenience library against a fork-deployed singleton

### 2.1 `TOFUOutcome` Enum Coverage

All four variants are extensively tested across all three test layers:

| Variant | Tested At Implementation Level | Tested At Concrete Level | Tested At Library Level |
|---------|-------------------------------|--------------------------|------------------------|
| `Initial` | Yes (multiple fuzz tests) | Yes (smoke tests) | Yes (fork tests) |
| `Consistent` | Yes (fuzz: `decimalsA == decimalsB`) | Not directly (smoke only tests Initial) | Yes (fork tests) |
| `Inconsistent` | Yes (fuzz: `decimalsA != decimalsB`) | Not directly (smoke only tests Initial) | Yes (fork tests) |
| `ReadFailure` | Yes (address(0), too-large, short data, reverting contract) | Not directly | Yes (fork tests) |

### 2.2 `TOFUTokenDecimalsResult` Struct Coverage

The struct is used directly in `LibTOFUTokenDecimalsImplementation` tests where test contracts declare their own `mapping(address => TOFUTokenDecimalsResult)` storage. Both fields are tested:

- **`initialized` field**: Tested by manually setting `initialized: true` to simulate pre-initialized storage in 20+ test locations across 4 test files. The distinction between `initialized == false` (default/uninitialized) and `initialized == true` is a core test axis in every `decimalsForToken` and `decimalsForTokenReadOnly` test.
- **`tokenDecimals` field**: Tested via fuzz inputs (`uint8 storedDecimals`) across all test files. Return value assertions confirm stored decimals are returned correctly on `Consistent`, `Inconsistent`, and `ReadFailure` outcomes.

### 2.3 `TokenDecimalsReadFailure` Error Coverage

The custom error is tested in the following files:

| Test File | Scenarios Covered |
|-----------|-------------------|
| `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` | `address(0)` (uninitialized + initialized), inconsistent, too-large (uninitialized + initialized), short data (uninitialized + initialized), reverting contract (uninitialized + initialized) -- 10 test functions |
| `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` | Same pattern as above -- 10 test functions |
| `LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` | `address(0)`, inconsistent, too-large (uninitialized + initialized), short data (uninitialized + initialized), reverting contract (uninitialized + initialized) -- 9 test functions |
| `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` | Same pattern -- 9 test functions |

All tests assert both `TokenDecimalsReadFailure.selector` and the correct `TOFUOutcome` parameter (`ReadFailure` or `Inconsistent`).

### 2.4 Interface Function Signature Coverage

Each of the four interface functions is tested through the concrete `TOFUTokenDecimals` contract (which `is ITOFUTokenDecimals`):

| Interface Function | Concrete Test File | Test Type |
|--------------------|--------------------|-----------|
| `decimalsForTokenReadOnly` | `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` | Fuzz (uint8 decimals), Initial only |
| `decimalsForToken` | `TOFUTokenDecimals.decimalsForToken.t.sol` | Fuzz (uint8 decimals), Initial only |
| `safeDecimalsForToken` | `TOFUTokenDecimals.safeDecimalsForToken.t.sol` | Fuzz (uint8 decimals), Initial only |
| `safeDecimalsForTokenReadOnly` | `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` | Fuzz (uint8 decimals), Consistent path only |

## 3. Findings

### A02-1: Concrete contract tests only cover happy-path/Initial outcome [LOW]

**Location:** `test/src/concrete/TOFUTokenDecimals.*.t.sol` (all four files)

**Description:** The four concrete contract test files (`TOFUTokenDecimals.decimalsForToken.t.sol`, `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`, `TOFUTokenDecimals.safeDecimalsForToken.t.sol`, `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`) each contain a single fuzz test that only verifies the `Initial` outcome (or, for `safeDecimalsForTokenReadOnly`, the `Consistent` path after a prior initialization call). None of them test `Consistent`, `Inconsistent`, `ReadFailure`, or error-revert paths through the concrete contract.

This gap is partially mitigated by the thorough coverage at both the `LibTOFUTokenDecimalsImplementation` level (direct unit tests covering all outcomes) and the `LibTOFUTokenDecimals` level (fork-based integration tests covering all outcomes). Since the concrete contract is a thin pass-through to the implementation library, the risk is low. However, a defect in the concrete contract's storage wiring (e.g., accidentally passing a different mapping slot) would only manifest in multi-call sequences that exercise `Consistent`/`Inconsistent` outcomes.

**Severity:** LOW -- The concrete contract is trivially thin (4 one-liner functions) and thoroughly auditable by inspection. The wiring is verified indirectly through the `LibTOFUTokenDecimals` fork tests, which deploy the same concrete contract via Zoltu and test all outcome paths through it. However, having at least one concrete-level test for the `Consistent` and `Inconsistent` paths would provide a stronger safety net against storage layout bugs.

### A02-2: No test directly asserts `ITOFUTokenDecimals` as an interface type [INFO]

**Location:** `test/` (all files)

**Description:** No test file imports or references the `ITOFUTokenDecimals` interface type itself (only `TOFUOutcome` is imported from the interface file in two concrete test files). The interface conformance is verified implicitly because `TOFUTokenDecimals is ITOFUTokenDecimals` compiles successfully, and the Solidity compiler enforces that all interface functions are implemented with matching signatures. This is a compile-time guarantee and does not need a runtime test.

**Severity:** INFO -- This is expected for Solidity interfaces. The compiler enforces conformance at build time. No action needed.

### A02-3: `TokenDecimalsReadFailure` error is imported via re-export, not directly from interface [INFO]

**Location:** Multiple test files import `TokenDecimalsReadFailure` from `src/lib/LibTOFUTokenDecimalsImplementation.sol` rather than from `src/interface/ITOFUTokenDecimals.sol`.

**Description:** The `TokenDecimalsReadFailure` error is defined in `ITOFUTokenDecimals.sol` (line 33) but tests import it via `LibTOFUTokenDecimalsImplementation.sol`, which re-exports it. This is functionally equivalent since Solidity error selectors are global and not scoped to the importing file. The concrete test files do not test the error at all (they only test the happy path).

**Severity:** INFO -- No functional impact. The error selector is identical regardless of import path.

### A02-4: No explicit test for `TOFUOutcome` enum ordering/values [INFO]

**Location:** `src/interface/ITOFUTokenDecimals.sol` lines 19-28

**Description:** The numeric values of the `TOFUOutcome` enum variants (`Initial=0`, `Consistent=1`, `Inconsistent=2`, `ReadFailure=3`) are implicitly tested through the `uint256(tofuOutcome) == uint256(TOFUOutcome.XXX)` assertions found throughout tests. However, no test explicitly asserts the numeric values (e.g., `assertEq(uint256(TOFUOutcome.Initial), 0)`). If the enum order were accidentally changed, the existing tests would still catch the behavioral consequence because they compare against the named enum variants, not raw integers.

**Severity:** INFO -- The Solidity compiler assigns sequential values starting from 0, and tests compare against named variants, so this is inherently safe.

## 4. Summary Table

| ID | Finding | Severity | Tested? | Mitigation |
|----|---------|----------|---------|------------|
| A02-1 | Concrete contract tests only cover Initial/happy-path | LOW | Partial | Covered at implementation and fork-integration levels; concrete layer is trivially thin |
| A02-2 | No test directly asserts `ITOFUTokenDecimals` type | INFO | N/A (compile-time) | Compiler enforces interface conformance |
| A02-3 | Error imported via re-export rather than from interface | INFO | Yes (indirectly) | No functional impact |
| A02-4 | No explicit test for enum numeric ordering | INFO | Implicit | Named variant comparisons catch ordering bugs |

## 5. Overall Assessment

The types and error defined in `ITOFUTokenDecimals.sol` are **thoroughly covered** through indirect testing. Every `TOFUOutcome` variant is exercised in multiple test scenarios across three testing layers. The `TOFUTokenDecimalsResult` struct fields (`initialized` and `tokenDecimals`) are central test axes with fuzz coverage. The `TokenDecimalsReadFailure` error is tested with every failure mode (address zero, too-large return, short data, reverting contract) in both initialized and uninitialized states. All four interface functions are tested through the concrete implementation and integration layers.

The only substantive gap (A02-1) is that the concrete contract's test files are minimal smoke tests covering only the Initial path, but this is adequately mitigated by the implementation-level and fork-integration-level tests that exercise the same concrete contract through all outcomes.
