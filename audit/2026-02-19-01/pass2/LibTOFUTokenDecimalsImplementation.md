# Pass 2 -- Test Coverage Audit: LibTOFUTokenDecimalsImplementation

**Auditor:** A02
**Date:** 2026-02-19
**Source file:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`

---

## 1. Evidence of Thorough Reading

### Source File: `LibTOFUTokenDecimalsImplementation` (lines 18--148)

**Library name:** `LibTOFUTokenDecimalsImplementation`

**Constants:**
- `TOFU_DECIMALS_SELECTOR` (line 20): `bytes4` constant set to `0x313ce567` (the `decimals()` selector)

**Functions:**
| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `decimalsForTokenReadOnly` | 32 | `internal` | `view` |
| `decimalsForToken` | 99 | `internal` | (state-mutating) |
| `safeDecimalsForToken` | 121 | `internal` | (state-mutating) |
| `safeDecimalsForTokenReadOnly` | 137 | `internal` | `view` |

### Test File: `LibTOFUTokenDecimalsImplementation.t.sol`

| Test Function |
|---|
| `testDecimalsSelector` |

### Test File: `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`

| Test Function |
|---|
| `testDecimalsForTokenAddressZero` |
| `testDecimalsForTokenValidValue` |
| `testDecimalsForTokenInvalidValueTooLarge` |
| `testDecimalsForTokenInvalidValueNotEnoughData` |
| `testDecimalsForTokenTokenContractRevert` |

### Test File: `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`

| Test Function |
|---|
| `testDecimalsForTokenReadOnlyAddressZero` |
| `testDecimalsForTokenReadOnlyValidValue` |
| `testDecimalsForTokenReadOnlyInvalidValueTooLarge` |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` |
| `testDecimalsForTokenReadOnlyTokenContractRevert` |

### Test File: `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

| Test Function | Helper |
|---|---|
| `testSafeDecimalsForTokenAddressZeroUninitialized` | `externalSafeDecimalsForToken` |
| `testSafeDecimalsForTokenAddressZeroInitialized` | |
| `testSafeDecimalsForTokenValidValue` | |
| `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized` | |
| `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` | |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized` | |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` | |
| `testSafeDecimalsForTokenTokenContractRevertUninitialized` | |
| `testSafeDecimalsForTokenTokenContractRevertInitialized` | |

### Test File: `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

| Test Function | Helper |
|---|---|
| `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized` | `externalSafeDecimalsForTokenReadOnly` |
| `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized` | |
| `testSafeDecimalsForTokenReadOnlyValidValue` | |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized` | |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` | |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized` | |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` | |
| `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized` | |
| `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized` | |

---

## 2. Test Coverage Findings

### A02-1: `decimalsForTokenReadOnly` does not verify that it never writes storage [INFO]

**Description:** `decimalsForTokenReadOnly` is declared `view` and is therefore enforced at the compiler level to never modify state. This means no runtime test is needed to assert it does not write storage -- the Solidity `view` modifier provides a compile-time guarantee. The test file (`decimalsForTokenReadOnly.t.sol`) does manually set storage and confirm the read-only function does not overwrite it, which is implicit in the test flow (storage is set via direct assignment, then read-only is called, and the stored value is returned unchanged in the `ReadFailure` path).

**Verdict:** No action required. Compiler enforces the guarantee.

---

### A02-2: No dedicated test for `decimalsForToken` storage write on `Initial` outcome [INFO]

**Description:** The `decimalsForToken` function writes to storage only when `tofuOutcome == TOFUOutcome.Initial` (line 110). The test `testDecimalsForTokenValidValue` does exercise this path: it calls `decimalsForToken` once (triggering `Initial` and the storage write), then calls it again with a different mocked value and verifies the outcome is either `Consistent` or `Inconsistent` depending on the mocked value. The second call implicitly proves the first call stored the value. The storage write is therefore tested, albeit indirectly.

**Verdict:** Adequately covered through the two-call pattern.

---

### A02-3: No test that `decimalsForToken` does NOT write storage on non-Initial outcomes [LOW]

**Description:** The `decimalsForToken` function (lines 99--113) only writes storage when `tofuOutcome == TOFUOutcome.Initial`. There is no explicit test that confirms storage is NOT overwritten when the outcome is `Consistent`, `Inconsistent`, or `ReadFailure`. For example, a test could:
1. Call `decimalsForToken` with `decimalsA` (Initial, stores `decimalsA`).
2. Mock `decimals()` to return a value > 0xff (ReadFailure).
3. Call `decimalsForToken` again.
4. Restore the mock to `decimalsA`.
5. Call `decimalsForToken` and confirm the outcome is `Consistent` (proving the stored value was not corrupted by the ReadFailure call).

While the current implementation makes this obvious by inspection (storage write is gated by `if (tofuOutcome == TOFUOutcome.Initial)`), an explicit test would guard against future regressions.

**Impact:** If a future code change inadvertently wrote storage on non-Initial outcomes, the existing tests would not catch it.

---

### A02-4: `safeDecimalsForToken` initial read path not directly tested via the safe wrapper [LOW]

**Description:** In `testSafeDecimalsForTokenValidValue` (line 32), the initial read is performed via the non-safe `decimalsForToken` rather than via `externalSafeDecimalsForToken`. This means the `Initial` outcome through `safeDecimalsForToken` (which should succeed, returning the decimals) is never directly tested via the safe wrapper. The test initializes storage using the non-safe function first, then tests the safe function only for the Consistent/Inconsistent branches.

While the `Initial` path through `safeDecimalsForToken` is trivially correct (it passes the `tofuOutcome != Consistent && tofuOutcome != Initial` guard), a direct test would be more thorough.

**Impact:** Minor gap. If the revert condition in `safeDecimalsForToken` were accidentally changed to reject `Initial`, the existing tests would not catch it.

---

### A02-5: All four `TOFUOutcome` enum branches are tested [INFO]

**Description:** Verification that all branches of the `TOFUOutcome` enum are exercised in each function's test suite:

| Outcome | `decimalsForTokenReadOnly` | `decimalsForToken` | `safeDecimalsForToken` | `safeDecimalsForTokenReadOnly` |
|---|---|---|---|---|
| `Initial` | `testDecimalsForTokenReadOnlyValidValue` (first call, uninitialized) | `testDecimalsForTokenValidValue` (first call) | `testSafeDecimalsForTokenValidValue` (indirectly via non-safe function) | `testSafeDecimalsForTokenReadOnlyValidValue` (first call) |
| `Consistent` | `testDecimalsForTokenReadOnlyValidValue` (when `storedDecimals == decimals`) | `testDecimalsForTokenValidValue` (when `decimalsA == decimalsB`) | `testSafeDecimalsForTokenValidValue` (when `decimalsA == decimalsB`) | `testSafeDecimalsForTokenReadOnlyValidValue` (when `decimalsA == decimalsB`) |
| `Inconsistent` | `testDecimalsForTokenReadOnlyValidValue` (when `storedDecimals != decimals`) | `testDecimalsForTokenValidValue` (when `decimalsA != decimalsB`) | `testSafeDecimalsForTokenValidValue` (when `decimalsA != decimalsB`, expects revert) | `testSafeDecimalsForTokenReadOnlyValidValue` (when `decimalsA != decimalsB`, expects revert) |
| `ReadFailure` | Multiple tests (AddressZero, TooLarge, NotEnoughData, ContractRevert) | Multiple tests (AddressZero, TooLarge, NotEnoughData, ContractRevert) | Multiple tests with both Uninitialized and Initialized variants | Multiple tests with both Uninitialized and Initialized variants |

**Verdict:** All four enum variants are exercised across all four function test suites.

---

### A02-6: Assembly block error handling thoroughly tested [INFO]

**Description:** The assembly block in `decimalsForTokenReadOnly` (lines 48--60) has three failure conditions:
1. **`staticcall` failure** (the call itself reverts): Tested via `vm.etch(token, hex"fd")` in `testDecimalsForTokenReadOnlyTokenContractRevert` and `testDecimalsForTokenTokenContractRevert`.
2. **`returndatasize() < 0x20`** (insufficient return data): Tested via fuzz in `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` and `testDecimalsForTokenInvalidValueNotEnoughData`, which bound the return data length to `[0, 0x1f]`.
3. **`readDecimals > 0xff`** (return value exceeds uint8 range): Tested via `testDecimalsForTokenReadOnlyInvalidValueTooLarge` and `testDecimalsForTokenInvalidValueTooLarge`, with `vm.assume(decimals > 0xff)`.

**Verdict:** All three assembly error paths are covered.

---

### A02-7: Zero decimals (edge case) tested [INFO]

**Description:** The fuzz tests for `testDecimalsForTokenValidValue(uint8 decimalsA, uint8 decimalsB)` and `testDecimalsForTokenReadOnlyValidValue(uint8 decimals, uint8 storedDecimals)` use `uint8` inputs, which include `0` in the fuzz domain. Zero decimals is important because it overlaps with uninitialized storage (`uint8` default is `0`), and the `initialized` boolean flag exists specifically to distinguish the two cases. The fuzz inputs will cover `0` across many runs.

**Verdict:** Adequately covered by fuzz testing with uint8 range.

---

### A02-8: Max uint8 (255) decimals edge case tested [INFO]

**Description:** Similar to A02-7, the fuzz tests with `uint8` inputs cover the full `[0, 255]` range, including `255`. The boundary between valid (`0xff`) and invalid (`> 0xff`) is also tested by the `TooLarge` tests which use `vm.assume(decimals > 0xff)`.

**Verdict:** Adequately covered.

---

### A02-9: `ReadFailure` path returns stored value when initialized -- tested for all failure modes [INFO]

**Description:** Each failure-mode test for both `decimalsForToken` and `decimalsForTokenReadOnly` tests the path both without and with a pre-initialized stored value. When a stored value exists, the tests verify the returned decimals match the stored value (not `0`). This confirms the `ReadFailure` path at line 65 (`return (TOFUOutcome.ReadFailure, tofuTokenDecimals.tokenDecimals)`) correctly returns the stored value.

**Verdict:** Thoroughly covered.

---

### A02-10: No test for EOA (externally owned account) as token address [INFO]

**Description:** When `decimalsForTokenReadOnly` calls `staticcall` on an address with no code (an EOA), the EVM returns `success = true` with `returndatasize() == 0`. The `returndatasize() < 0x20` check (line 51) catches this and sets `success := 0`, producing a `ReadFailure`. The `testDecimalsForTokenAddressZero` test uses `address(0)` which is an EOA-like address with no code, so this path is exercised. There is no separate test for a non-zero EOA address, but the behavior is identical since the EVM treats all codeless addresses the same for `staticcall`.

**Verdict:** Implicitly covered by address(0) tests. No additional test needed.

---

### A02-11: `safeDecimalsForToken` revert condition covers both `ReadFailure` and `Inconsistent` but tests verify specific outcomes [INFO]

**Description:** The `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` functions revert when `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial` (lines 127, 143). This means they revert on both `ReadFailure` and `Inconsistent`. The tests verify the exact revert data including the specific `TOFUOutcome` variant in the error payload:
- `ReadFailure` is verified in all the failure-mode tests (AddressZero, TooLarge, NotEnoughData, ContractRevert).
- `Inconsistent` is verified in `testSafeDecimalsForTokenValidValue` and `testSafeDecimalsForTokenReadOnlyValidValue` when `decimalsA != decimalsB`.

**Verdict:** Both revert paths are tested with correct error payload verification.

---

### A02-12: No test for `decimalsForToken` called multiple times after Initial (idempotent storage write guard) [LOW]

**Description:** Once `decimalsForToken` stores a value (on `Initial`), subsequent calls that produce `Consistent`, `Inconsistent`, or `ReadFailure` should not trigger another storage write. While A02-3 noted the absence of an explicit no-write-on-non-Initial test, there is a related subtlety: if someone calls `decimalsForToken` three times -- first `Initial` (writes), second `ReadFailure` (should not write), third with the original value (should be `Consistent`, not `Initial`) -- this multi-step flow is not explicitly tested. The `testDecimalsForTokenValidValue` test does cover a two-step flow (Initial -> Consistent/Inconsistent), but does not interleave failure modes.

**Impact:** Low. The implementation is simple and correct by inspection, but an interleaved test would provide stronger regression protection.

---

### A02-13: `TOFU_DECIMALS_SELECTOR` constant correctness verified [INFO]

**Description:** The test `testDecimalsSelector` in `LibTOFUTokenDecimalsImplementation.t.sol` explicitly verifies that `TOFU_DECIMALS_SELECTOR` equals `IERC20.decimals.selector`. This ensures the constant matches the ERC20 standard.

**Verdict:** Covered.

---

## Summary

| ID | Severity | Description |
|---|---|---|
| A02-1 | INFO | Read-only guarantee enforced by compiler (`view` modifier) |
| A02-2 | INFO | Storage write on `Initial` adequately tested via two-call pattern |
| A02-3 | LOW | No explicit test that storage is NOT written on non-Initial outcomes |
| A02-4 | LOW | `safeDecimalsForToken` Initial path not directly tested via safe wrapper |
| A02-5 | INFO | All four `TOFUOutcome` enum branches tested across all functions |
| A02-6 | INFO | All three assembly error paths (staticcall fail, short returndata, oversized value) tested |
| A02-7 | INFO | Zero decimals edge case covered by uint8 fuzz |
| A02-8 | INFO | Max uint8 (255) edge case covered by uint8 fuzz |
| A02-9 | INFO | ReadFailure returns stored value when initialized -- tested for all failure modes |
| A02-10 | INFO | EOA token address implicitly tested via address(0) |
| A02-11 | INFO | Both revert conditions (ReadFailure, Inconsistent) tested with exact error payload |
| A02-12 | LOW | No interleaved multi-call test (Initial -> ReadFailure -> Consistent) |
| A02-13 | INFO | Selector constant correctness verified against IERC20 |

**Overall assessment:** Test coverage for `LibTOFUTokenDecimalsImplementation` is thorough. All functions are tested. All `TOFUOutcome` branches are exercised. All assembly error paths are covered. The fuzz testing with `uint8` inputs provides good boundary coverage including zero and max values. The three LOW findings are defensive-testing suggestions that would strengthen regression protection but do not indicate missing coverage of existing behavior. No CRITICAL, HIGH, or MEDIUM findings.
