<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 2 — Test Coverage: `src/interface/ITOFUTokenDecimals.sol`

**Auditor:** A03
**Date:** 2026-02-21
**Pass:** 2 (Test Coverage)

---

## 1. Source File Evidence

**File:** `src/interface/ITOFUTokenDecimals.sol`
**Interface name:** `ITOFUTokenDecimals` (line 53)

### Structs

| Name | Line | Fields |
|------|------|--------|
| `TOFUTokenDecimalsResult` | 13 | `bool initialized` (line 14), `uint8 tokenDecimals` (line 15) |

### Enums

| Name | Line | Variants |
|------|------|----------|
| `TOFUOutcome` | 19 | `Initial` (line 21), `Consistent` (line 23), `Inconsistent` (line 25), `ReadFailure` (line 27) |

### Errors

| Name | Line | Parameters |
|------|------|------------|
| `TokenDecimalsReadFailure` | 33 | `address token`, `TOFUOutcome tofuOutcome` |

### Interface Functions

| Name | Line | Mutability | Return |
|------|------|------------|--------|
| `decimalsForTokenReadOnly(address)` | 67 | `view` | `(TOFUOutcome, uint8)` |
| `decimalsForToken(address)` | 77 | (non-view) | `(TOFUOutcome, uint8)` |
| `safeDecimalsForToken(address)` | 83 | (non-view) | `uint8` |
| `safeDecimalsForTokenReadOnly(address)` | 91 | `view` | `uint8` |

---

## 2. Type Usage in Tests

The interface types are exercised via two import paths. `LibTOFUTokenDecimalsImplementation.sol` re-exports all three types from `ITOFUTokenDecimals.sol` (line 5 of the implementation). The concrete tests import `TOFUOutcome` and `TokenDecimalsReadFailure` directly from `src/interface/ITOFUTokenDecimals.sol`.

### Test files that use `TOFUOutcome`

All 16 test files exercise `TOFUOutcome` either directly or via the re-export:

- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.t.sol`
- `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

### Test files that use `TOFUTokenDecimalsResult`

- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol`

### Test files that use `TokenDecimalsReadFailure`

- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

### Test files that use `ITOFUTokenDecimals` directly

None. `ITOFUTokenDecimals` is used as a type for the `TOFU_DECIMALS_DEPLOYMENT` constant in
`src/lib/LibTOFUTokenDecimals.sol` (line 29) but the interface name itself is never imported in
any test file. This is expected: tests interact with the concrete `TOFUTokenDecimals` contract or
the library wrappers, never against the raw interface type.

---

## 3. Coverage Analysis by Item

### 3.1 `TOFUOutcome` enum variants

| Variant | Exercised? | Test locations (representative) |
|---------|-----------|--------------------------------|
| `Initial` | Yes | All `decimalsForToken`/`decimalsForTokenReadOnly` test files; first read of an uninitialized token always asserts `Initial`. |
| `Consistent` | Yes | Second read with matching decimals in all `decimalsForToken` test files; real-token integration tests (`testRealTokenWETH`, etc.). |
| `Inconsistent` | Yes | Fuzz tests with `decimalsA != decimalsB` in all `decimalsForToken`/`decimalsForTokenReadOnly`/`safeDecimalsForToken` test files. |
| `ReadFailure` | Yes | `address(0)` tests, `vm.etch(hex"fd")` (revert opcode), too-large return value, insufficient return data — all four root causes exercised across all four function variants. |

All four enum variants are thoroughly exercised. Coverage is complete.

### 3.2 `TOFUTokenDecimalsResult` struct field combinations

The struct has two fields: `initialized bool` and `tokenDecimals uint8`.

| Combination | Exercised? | Evidence |
|-------------|-----------|----------|
| `{initialized: false, tokenDecimals: 0}` (default storage) | Yes | Every first-read test starts from zero-value storage. |
| `{initialized: true, tokenDecimals: X}` for arbitrary `X` | Yes | Fuzz tests with `uint8 storedDecimals` parameter directly write this combination via `TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)})` in the implementation tests; the concrete and lib-level tests reach it via the `Initial` write path. |
| `{initialized: true, tokenDecimals: 0}` | Yes | Covered by the fuzz tests when `storedDecimals == 0` (no explicit assumption filtering it out). The `testDecimalsForTokenAddressZero` family also directly sets `{initialized: true, tokenDecimals: storedDecimals}` with an unfiltered `uint8`, which includes `0`. |

The `initialized = false` with `tokenDecimals != 0` combination is structurally unreachable: the
implementation only writes the struct when `initialized = true`. Default storage gives
`tokenDecimals = 0` when `initialized = false`. This is a design invariant, not a coverage gap.

### 3.3 `TokenDecimalsReadFailure` error

The error accepts two parameters: `address token` and `TOFUOutcome tofuOutcome`.

| `tofuOutcome` value passed to error | Exercised? | Test locations |
|-------------------------------------|-----------|----------------|
| `TOFUOutcome.ReadFailure` | Yes | `testSafeDecimalsForTokenAddressZeroUninitialized`, `testSafeDecimalsForTokenAddressZeroInitialized`, all contract-revert and bad-return-data tests. |
| `TOFUOutcome.Inconsistent` | Yes | `testSafeDecimalsForTokenValidValue` (fuzz, `decimalsA != decimalsB` branch), `testSafeDecimalsForTokenConsistentInconsistent`, concrete `testSafeDecimalsForTokenInconsistentReverts`. |
| `TOFUOutcome.Initial` | N/A — never revert path | By design: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` only revert when `tofuOutcome` is not `Initial` or `Consistent`. `Initial` is a success path. |
| `TOFUOutcome.Consistent` | N/A — never revert path | Same reasoning: `Consistent` is a success path. |

Error encoding is validated with `vm.expectRevert(abi.encodeWithSelector(...))` confirming both
the selector and the ABI-encoded parameters are correct.

### 3.4 Interface functions

All four `ITOFUTokenDecimals` functions are exercised at every layer:

| Function | Implementation layer | Lib-convenience layer | Concrete layer |
|----------|---------------------|----------------------|----------------|
| `decimalsForToken` | Yes | Yes (fork) | Yes (no-fork) |
| `decimalsForTokenReadOnly` | Yes | Yes (fork) | Yes (no-fork) |
| `safeDecimalsForToken` | Yes | Yes (fork) | Yes (no-fork) |
| `safeDecimalsForTokenReadOnly` | Yes | Yes (fork) | Yes (no-fork) |

---

## 4. Findings

### F-01 — No direct import of `ITOFUTokenDecimals` in tests

**Severity:** INFO
**Location:** All test files
**Description:** No test file imports `ITOFUTokenDecimals` by name. All tests interact with the
concrete `TOFUTokenDecimals` contract or the `LibTOFUTokenDecimalsImplementation` / `LibTOFUTokenDecimals` wrappers. The interface itself is exercised only through its implementations. This is entirely normal for a pure interface definition and does not represent a coverage gap.
**Recommendation:** No action required. Testing the concrete and library layers provides equivalent coverage.

### F-02 — `initialized = false, tokenDecimals != 0` struct combination is untested

**Severity:** INFO
**Location:** `src/interface/ITOFUTokenDecimals.sol` line 13-16; `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Description:** The `TOFUTokenDecimalsResult` struct can theoretically represent `{initialized: false, tokenDecimals: 5}`, but the implementation never produces this state — it only writes the struct as `{initialized: true, tokenDecimals: X}`. Default storage always gives `{initialized: false, tokenDecimals: 0}`. No test manually constructs or tests this logically unreachable state.
**Recommendation:** No action required. This is a structural invariant, not a bug. A note in the struct documentation clarifying the invariant (that `tokenDecimals` is only meaningful when `initialized = true`) would improve clarity but is not a correctness issue.

### F-03 — `TokenDecimalsReadFailure` with `TOFUOutcome.Initial` or `TOFUOutcome.Consistent` is never emitted or tested as a revert

**Severity:** INFO
**Location:** `src/interface/ITOFUTokenDecimals.sol` line 33
**Description:** The error type accepts any `TOFUOutcome` value as its second parameter, but the
implementation only reverts with `TOFUOutcome.ReadFailure` or `TOFUOutcome.Inconsistent`. The
variants `Initial` and `Consistent` are defined success paths and are not tested as error
parameters. This is correct by design.
**Recommendation:** No action required. The test suite correctly exercises all reachable error paths. The unused parameter space reflects the generality of the error type, not a missing case.

### F-04 — `safeDecimalsForTokenReadOnly` Initial path coverage (concrete layer is thin)

**Severity:** LOW
**Location:** `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
**Description:** The concrete-layer smoke test for `safeDecimalsForTokenReadOnly` does test the
`Initial` path (`testSafeDecimalsForTokenReadOnlyInitial`), but the `ReadFailure` path after initialization (i.e., when storage is already initialized and a subsequent read-only call fails) is not tested at the concrete layer. This case is tested at the implementation layer (`testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized`, etc.) and the lib-convenience layer (`testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized`). The concrete layer's smoke test relies on those layers for this coverage.
**Recommendation:** Consider adding a concrete-layer test for `safeDecimalsForTokenReadOnly` after initialization with a reverting token, mirroring `testSafeDecimalsForTokenReadFailureInitializedReverts` in the `safeDecimalsForToken` concrete test. This would close a minor consistency gap in smoke-test parity across the four function variants.

### F-05 — No negative test for `TokenDecimalsReadFailure` ABI encoding correctness

**Severity:** INFO
**Location:** All safe-read test files
**Description:** Tests use `vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.X))` which validates the full ABI-encoded revert payload. This is correct and thorough. There is no scenario where the ABI encoding could silently differ because Solidity's `revert ErrorType(args)` uses standard ABI encoding. Coverage is complete.
**Recommendation:** No action required.

---

## 5. Summary

| Severity | Count | Items |
|----------|-------|-------|
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 0 | — |
| LOW | 1 | F-04: Missing concrete-layer initialized+ReadFailure test for `safeDecimalsForTokenReadOnly` |
| INFO | 4 | F-01, F-02, F-03, F-05 |

Overall, test coverage for the types defined in `ITOFUTokenDecimals.sol` is excellent. All four `TOFUOutcome` enum variants are exercised. Both `initialized` field states of `TOFUTokenDecimalsResult` are covered. `TokenDecimalsReadFailure` is triggered with both of its reachable `tofuOutcome` values (`ReadFailure` and `Inconsistent`). All four interface functions are tested at three independent layers (implementation, lib-convenience, concrete). The single LOW finding (F-04) is a minor smoke-test parity gap, not a correctness risk.
