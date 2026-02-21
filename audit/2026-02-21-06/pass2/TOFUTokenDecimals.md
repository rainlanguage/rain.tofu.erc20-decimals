# Audit Pass 2 -- Test Coverage: `TOFUTokenDecimals.sol`

**Agent:** A02
**Date:** 2026-02-21
**Scope:** `/src/concrete/TOFUTokenDecimals.sol` and its five concrete test files

---

## Source Contract Inventory

**File:** `/src/concrete/TOFUTokenDecimals.sol`
**Contract:** `TOFUTokenDecimals is ITOFUTokenDecimals`

| Line | Member |
|------|--------|
| 16 | `sTOFUTokenDecimals` (storage mapping) |
| 19-22 | `decimalsForTokenReadOnly(address) external view returns (TOFUOutcome, uint8)` |
| 25-28 | `decimalsForToken(address) external returns (TOFUOutcome, uint8)` |
| 31-33 | `safeDecimalsForToken(address) external returns (uint8)` |
| 36-38 | `safeDecimalsForTokenReadOnly(address) external view returns (uint8)` |

All four functions are thin pass-through wrappers that delegate to `LibTOFUTokenDecimalsImplementation`, sharing the single `sTOFUTokenDecimals` storage mapping.

---

## Test Function Inventory

### `TOFUTokenDecimals.decimalsForToken.t.sol` (12 tests)

| # | Function |
|---|----------|
| 1 | `testDecimalsForTokenAddressZero` |
| 2 | `testDecimalsForToken(uint8)` |
| 3 | `testDecimalsForTokenDecimalsZero` |
| 4 | `testDecimalsForTokenConsistent(uint8)` |
| 5 | `testDecimalsForTokenInconsistent(uint8,uint8)` |
| 6 | `testDecimalsForTokenReadFailure` |
| 7 | `testDecimalsForTokenReadFailureInitialized(uint8)` |
| 8 | `testDecimalsForTokenCrossTokenIsolation(uint8,uint8)` |
| 9 | `testDecimalsForTokenStorageImmutableOnReadFailure(uint8)` |
| 10 | `testDecimalsForTokenOverwideDecimals(uint256)` |
| 11 | `testDecimalsForTokenNoDecimalsFunction` |
| 12 | `testDecimalsForTokenStorageImmutableOnInconsistent(uint8,uint8)` |

### `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (10 tests)

| # | Function |
|---|----------|
| 1 | `testDecimalsForTokenReadOnlyAddressZero` |
| 2 | `testDecimalsForTokenReadOnly(uint8)` |
| 3 | `testDecimalsForTokenReadOnlyDecimalsZero` |
| 4 | `testDecimalsForTokenReadOnlyConsistent(uint8)` |
| 5 | `testDecimalsForTokenReadOnlyInconsistent(uint8,uint8)` |
| 6 | `testDecimalsForTokenReadOnlyReadFailure` |
| 7 | `testDecimalsForTokenReadOnlyReadFailureInitialized(uint8)` |
| 8 | `testDecimalsForTokenReadOnlyOverwideDecimals(uint256)` |
| 9 | `testDecimalsForTokenReadOnlyNoDecimalsFunction` |
| 10 | `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` |

### `TOFUTokenDecimals.safeDecimalsForToken.t.sol` (9 tests)

| # | Function |
|---|----------|
| 1 | `testSafeDecimalsForTokenAddressZeroReverts` |
| 2 | `testSafeDecimalsForToken(uint8)` |
| 3 | `testSafeDecimalsForTokenDecimalsZero` |
| 4 | `testSafeDecimalsForTokenConsistent(uint8)` |
| 5 | `testSafeDecimalsForTokenInconsistentReverts(uint8,uint8)` |
| 6 | `testSafeDecimalsForTokenReadFailureReverts` |
| 7 | `testSafeDecimalsForTokenOverwideDecimalsReverts(uint256)` |
| 8 | `testSafeDecimalsForTokenNoDecimalsFunctionReverts` |
| 9 | `testSafeDecimalsForTokenReadFailureInitializedReverts(uint8)` |

### `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` (11 tests)

| # | Function |
|---|----------|
| 1 | `testSafeDecimalsForTokenReadOnlyAddressZeroReverts` |
| 2 | `testSafeDecimalsForTokenReadOnlyDecimalsZero` |
| 3 | `testSafeDecimalsForTokenReadOnly(uint8)` |
| 4 | `testSafeDecimalsForTokenReadOnlyInitial(uint8)` |
| 5 | `testSafeDecimalsForTokenReadOnlyInconsistentReverts(uint8,uint8)` |
| 6 | `testSafeDecimalsForTokenReadOnlyOverwideDecimalsReverts(uint256)` |
| 7 | `testSafeDecimalsForTokenReadOnlyNoDecimalsFunctionReverts` |
| 8 | `testSafeDecimalsForTokenReadOnlyReadFailureInitializedReverts(uint8)` |
| 9 | `testSafeDecimalsForTokenReadOnlyReadFailureReverts` |
| 10 | `testSafeDecimalsForTokenReadOnlyMultiCallUninitialized(uint8)` |
| 11 | `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` |

### `TOFUTokenDecimals.immutability.t.sol` (1 test)

| # | Function |
|---|----------|
| 1 | `testNoMutableOpcodes` |

**Total: 43 test functions across 5 files.**

---

## Coverage Assessment

All four external functions have direct test coverage for every `TOFUOutcome` path (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`). Edge cases covered include: `address(0)`, `decimals=0` boundary, overwide return data (`> 0xff`), empty/no return data (STOP opcode), cross-token isolation, storage immutability on failure/inconsistency, and read-only non-persistence.

---

## Findings

### Finding 1 -- No explicit `decimals=255` (max uint8) boundary test at concrete level

**Severity:** INFO

**Description:**
The overwide-decimals fuzz tests use `vm.assume(decimals > 0xff)`, covering 256 and above. The standard fuzz tests accept `uint8 decimals` which naturally includes 255 in some runs. However, there is no explicit, deterministic test that verifies `decimals=255` is accepted as a valid value and not incorrectly caught by the `gt(readDecimals, 0xff)` guard.

While the fuzz harness will statistically exercise this value, and the `gt` (strict greater-than) vs. `gte` distinction is obvious from the assembly, a deterministic boundary test at `decimals=255` would provide clearer regression protection against a future change that accidentally shifts the boundary (e.g., replacing `gt` with `slt` or `ge`).

**Location:** All four concrete test files (applies to `decimalsForToken`, `decimalsForTokenReadOnly`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`).

**Recommendation:** Add a deterministic test per function that mocks `decimals()` to return `uint256(255)` as a full 32-byte word (not just `uint8(255)` which Solidity ABI-encodes identically) and asserts it produces the expected outcome (not `ReadFailure`). This mirrors the overwide test structure but at the exact boundary.

### Finding 2 -- No cross-function interaction tests at the concrete contract level

**Severity:** LOW

**Description:**
The concrete test files test each function in isolation or use `decimalsForToken` to initialize state for the read-only variants. However, there are no concrete-level tests that:

1. Initialize via `safeDecimalsForToken`, then verify correctness via `decimalsForToken` or `decimalsForTokenReadOnly`.
2. Initialize via `decimalsForToken`, then verify via `safeDecimalsForToken`.
3. Mix all four functions in a single test to confirm they share state correctly through the concrete contract's single storage mapping.

The implementation library tests do cover `safeDecimalsForTokenReadOnlyAfterDecimalsForToken` at the library level, confirming shared state. But the concrete contract is the actual deployed artifact, and verifying that its external functions correctly share the same `sTOFUTokenDecimals` mapping is a worthwhile integration-level concern.

Since the concrete contract is a trivially thin wrapper (each function is a single line delegating to the library with the same storage reference), the risk of a wiring bug here is minimal. The read-only tests already demonstrate cross-function interaction by calling `decimalsForToken` to initialize before testing read-only paths.

**Location:** `/test/src/concrete/` -- no dedicated cross-function test file exists.

**Recommendation:** Consider adding a single integration test that exercises all four functions on the same token address in sequence (e.g., `decimalsForToken` -> `decimalsForTokenReadOnly` -> `safeDecimalsForToken` -> `safeDecimalsForTokenReadOnly`) to confirm shared-state wiring at the concrete level.

### Finding 3 -- No `safeDecimalsForToken` cross-token isolation or storage immutability tests

**Severity:** LOW

**Description:**
The `decimalsForToken` test file includes `testDecimalsForTokenCrossTokenIsolation`, `testDecimalsForTokenStorageImmutableOnReadFailure`, and `testDecimalsForTokenStorageImmutableOnInconsistent`. These tests verify that:
- Two different tokens do not contaminate each other's stored decimals.
- A `ReadFailure` after initialization does not corrupt stored state.
- An `Inconsistent` outcome does not overwrite stored state.

The `safeDecimalsForToken` test file has none of these. Since `safeDecimalsForToken` calls `decimalsForToken` internally, the behavior is identical, but the concrete-level assertion of these invariants through the safe API is absent.

**Location:** `/test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`

**Recommendation:** Consider adding at minimum a cross-token isolation test for `safeDecimalsForToken` to mirror the `decimalsForToken` test suite's coverage.

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 2 |
| INFO | 1 |

Overall, the test coverage for `TOFUTokenDecimals.sol` is thorough. All four external functions have tests covering every `TOFUOutcome` variant, major edge cases (zero decimals, address zero, overwide values, no-code addresses, reverting tokens), and key invariants (storage immutability, read-only non-persistence). The three findings are minor gaps reflecting the thin-wrapper nature of the concrete contract, where the underlying implementation library tests provide the primary depth of coverage.
