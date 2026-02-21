# Pass 2 – Test Coverage: LibTOFUTokenDecimalsImplementation

**Audit date:** 2026-02-21
**Auditor:** A05 (automated pass)
**Source file:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`

---

## 1. Source Functions Inventoried

| # | Function | Visibility | Mutability | Lines |
|---|----------|-----------|------------|-------|
| 1 | `decimalsForTokenReadOnly` | internal | view | 29–79 |
| 2 | `decimalsForToken` | internal | (non-view) | 108–122 |
| 3 | `safeDecimalsForToken` | internal | (non-view) | 135–145 |
| 4 | `safeDecimalsForTokenReadOnly` | internal | view | 159–169 |

One constant is also defined:

| Constant | Value | Line |
|----------|-------|------|
| `TOFU_DECIMALS_SELECTOR` | `0x313ce567` | 15 |

### Assembly paths inside `decimalsForTokenReadOnly` (shared by all four functions via delegation)

| Path | Condition | Lines |
|------|-----------|-------|
| A | `staticcall` fails (EVM-level revert / no code) | 47–50 |
| B | `returndatasize() < 0x20` (short return data) | 48–50 |
| C | `readDecimals > 0xff` (value too large for uint8) | 53–55 |
| D | Success: value fits in uint8, token uninitialized | 67–71 |
| E | Success: value fits in uint8, token initialized, consistent | 74–76 |
| F | Success: value fits in uint8, token initialized, inconsistent | 74–76 |

---

## 2. Test Files Read

### 2.1 `LibTOFUTokenDecimalsImplementation.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationTest`

| Test | Line |
|------|------|
| `testDecimalsSelector` | 14 |

### 2.2 `LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationDecimalsForTokenTest`

| Test | Line |
|------|------|
| `testDecimalsForTokenAddressZero` | 16 |
| `testDecimalsForTokenValidValue` | 29 |
| `testDecimalsForTokenInvalidValueTooLarge` | 52 |
| `testDecimalsForTokenInvalidValueNotEnoughData` | 68 |
| `testDecimalsForTokenNoStorageWriteOnNonInitial` | 95 |
| `testDecimalsForTokenNoStorageWriteOnInconsistent` | 120 |
| `testDecimalsForTokenCrossTokenIsolation` | 142 |
| `testDecimalsForTokenTokenContractRevert` | 168 |

### 2.3 `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationDecimalsForTokenReadOnlyTest`

| Test | Line |
|------|------|
| `testDecimalsForTokenReadOnlyAddressZero` | 16 |
| `testDecimalsForTokenReadOnlyValidValue` | 30 |
| `testDecimalsForTokenReadOnlyInvalidValueTooLarge` | 51 |
| `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` | 68 |
| `testDecimalsForTokenReadOnlyTokenContractRevert` | 94 |

### 2.4 `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenTest`

| Test | Line |
|------|------|
| `testSafeDecimalsForTokenAddressZeroUninitialized` | 21 |
| `testSafeDecimalsForTokenAddressZeroInitialized` | 26 |
| `testSafeDecimalsForTokenInitial` | 34 |
| `testSafeDecimalsForTokenValidValue` | 41 |
| `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized` | 60 |
| `testSafeDecimalsForTokenInvalidValueTooLargeInitialized` | 69 |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized` | 79 |
| `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized` | 95 |
| `testSafeDecimalsForTokenTokenContractRevertUninitialized` | 114 |
| `testSafeDecimalsForTokenTokenContractRevertInitialized` | 121 |

### 2.5 `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

**Contract:** `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenReadOnlyTest`

| Test | Line |
|------|------|
| `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized` | 21 |
| `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized` | 26 |
| `testSafeDecimalsForTokenReadOnlyValidValue` | 32 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized` | 51 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized` | 60 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized` | 72 |
| `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized` | 88 |
| `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized` | 107 |
| `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized` | 114 |

---

## 3. Coverage Matrix

The table below maps each assembly path and higher-level branch against every function.

| Path / Branch | `decimalsForTokenReadOnly` | `decimalsForToken` | `safeDecimalsForToken` | `safeDecimalsForTokenReadOnly` |
|---|---|---|---|---|
| A – staticcall reverts (vm.etch hex"fd") | COVERED | COVERED | COVERED (x2: uninit/init) | COVERED (x2: uninit/init) |
| B – returndatasize < 0x20 | COVERED (fuzz) | COVERED (fuzz) | COVERED (fuzz x2) | COVERED (fuzz x2) |
| C – readDecimals > 0xff | COVERED (fuzz) | COVERED (fuzz) | COVERED (fuzz x2) | COVERED (fuzz x2) |
| D – Initial (uninitialized, valid read) | COVERED | COVERED | COVERED | COVERED |
| E – Consistent (initialized, matching) | COVERED | COVERED | COVERED | COVERED |
| F – Inconsistent (initialized, mismatch) | COVERED | COVERED | COVERED (revert checked) | COVERED (revert checked) |
| address(0) token | COVERED (fuzz) | COVERED (fuzz) | COVERED (x2) | COVERED (x2) |
| Storage not written on ReadFailure | N/A (read-only) | COVERED | N/A (delegates) | N/A (delegates) |
| Storage not written on Inconsistent | N/A (read-only) | COVERED | N/A (delegates) | N/A (delegates) |
| Cross-token isolation | N/A (stateless) | COVERED | not tested directly | not tested directly |
| TOFU_DECIMALS_SELECTOR value | COVERED (exact match to IERC20.decimals.selector) | — | — | — |

---

## 4. Findings

### FINDING-P2-01 — `returndatasize() < 0x20` path uses mock that silently pads

**Severity:** LOW

**Location:** All four functions, assembly lines 48–50.
**Test files:**
- `decimalsForToken.t.sol` line 68: `testDecimalsForTokenInvalidValueNotEnoughData`
- `decimalsForTokenReadOnly.t.sol` line 68: `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData`
- `safeDecimalsForToken.t.sol` lines 79, 95
- `safeDecimalsForTokenReadOnly.t.sol` lines 72, 88

**Observation:** The tests truncate in-memory `bytes` via inline assembly then pass the result to `vm.mockCall`. However, `vm.mockCall` in Foundry intercepts the call at the Solidity level and returns the provided bytes verbatim as returndata. When the provided mock data has fewer than 32 bytes, `returndatasize()` in the assembly block will indeed be less than `0x20`, triggering `success := 0` correctly.

The specific sub-case of `returndatasize() == 0` (empty returndata — typical for EOA calls or contracts that return nothing) is included in the fuzz range (`bound(length, 0, 0x1f)` includes `0`), so it is probabilistically exercised but not deterministically isolated as a named test.

**Recommendation:** Add a dedicated unit test for `returndatasize() == 0` (zero-length returndata) across all four functions to make this edge case explicit and non-reliant on the fuzzer hitting it. This is common for EOA tokens and contracts that implement `decimals()` with a bare `return` statement.

---

### FINDING-P2-02 — No test for EOA (non-contract) address other than `address(0)`

**Severity:** LOW

**Location:** All four functions.

**Observation:** EVM `staticcall` to an EOA (externally owned account, i.e., no code at the target address) succeeds at the EVM level (`success == 1`) but returns zero bytes (`returndatasize() == 0`). The assembly correctly handles this via the `returndatasize() < 0x20` check. However, all tests for this scenario either:
- Use `address(0)` (which is special-cased by most EVM implementations)
- Use `vm.etch(token, hex"fd")` which gives the address code (a reverting contract)
- Use `vm.mockCall` which gives the address a mock implementation

No test calls a plain EOA address (one derived via `makeAddr` but never etched or mocked). The distinction matters because staticcall to a no-code address is handled differently than staticcall to a reverting contract at the EVM level, even though both ultimately produce `success = 0` in the assembly due to the `returndatasize()` check.

**Recommendation:** Add a test that calls each of the four functions with a plain EOA address (address with no code, no mock). Verify the result is `ReadFailure` with the stored decimals (or zero if uninitialized).

---

### FINDING-P2-03 — `decimalsForTokenReadOnly` read-only semantic not tested to confirm no state change

**Severity:** LOW

**Location:** `decimalsForTokenReadOnly` (lines 29–79).

**Observation:** The test for `decimalsForTokenReadOnly` does not explicitly confirm that repeated calls to the read-only function do NOT initialize storage, even after a valid `Initial` read. The test at line 30 (`testDecimalsForTokenReadOnlyValidValue`) reads a valid value (getting `Initial`), then manually sets `sTOFUTokenDecimals[token]` via direct storage write and re-reads. It never checks that the first `Initial` read left the mapping empty.

The `view` modifier enforces this at the compiler level, so storage mutation is impossible. This is an inherent property of `view` and is correctly enforced. This finding is informational rather than a gap requiring a fix.

**Recommendation (INFO):** The `view` modifier provides a compile-time guarantee. No additional test is strictly required. A comment in the test explaining this invariant would improve clarity for future auditors.

---

### FINDING-P2-04 — No test for `safeDecimalsForTokenReadOnly` "Initial" path when storage is initialized

**Severity:** LOW

**Location:** `safeDecimalsForTokenReadOnly` (lines 159–169).
**Test file:** `safeDecimalsForTokenReadOnly.t.sol` line 32.

**Observation:** `testSafeDecimalsForTokenReadOnlyValidValue` tests the `Initial` path (no prior storage) and then tests `Consistent`/`Inconsistent` by manually initializing storage with `decimalsA` and re-reading with `decimalsB`. This is correct.

However, the test manually sets the stored value to `decimalsA` (not `decimalsB`), so only the case where the stored and live values are compared is tested. There is no dedicated test that:
1. Calls `decimalsForToken` (state-writing) to initialize storage.
2. Then calls `safeDecimalsForTokenReadOnly` to confirm it sees `Consistent`.

This is a very minor gap: the underlying delegation to `decimalsForTokenReadOnly` is well tested, and the manual storage write accomplishes the same setup. The gap is purely at the integration level for `safeDecimalsForTokenReadOnly`.

**Recommendation:** Add a test that initializes via `decimalsForToken` and then reads via `safeDecimalsForTokenReadOnly` to exercise the full integration path at the `safe` wrapper level.

---

### FINDING-P2-05 — No test for `safeDecimalsForToken` / `safeDecimalsForTokenReadOnly` cross-token isolation

**Severity:** INFO

**Location:** `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`.

**Observation:** `testDecimalsForTokenCrossTokenIsolation` in `decimalsForToken.t.sol` (line 142) verifies that different tokens maintain independent storage slots, but this test only covers the raw `decimalsForToken` function. The `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` wrappers are not tested for cross-token isolation. Since both wrappers delegate entirely to `decimalsForToken` / `decimalsForTokenReadOnly`, the isolation guarantee is inherited and the gap is low risk.

**Recommendation:** Not required, but a mirrored isolation test for the `safe` wrappers would make coverage symmetric.

---

### FINDING-P2-06 — Assembly uses `mstore(0, selector)` but output slot overlaps selector word; no test probes dirty high bits

**Severity:** INFO

**Location:** `decimalsForTokenReadOnly`, assembly lines 46–52.

**Observation:** The assembly stores a 4-byte selector at memory word 0 (`mstore(0, selector)`, right-padded), then writes the 32-byte return value at address 0 (`staticcall(..., 0, 0x20)`), overwriting the selector word. The subsequent `mload(0)` reads the return value. If the token returns a value that is exactly 32 bytes and has non-zero bits in the upper 31 bytes (e.g., `readDecimals > 0xff`), the `gt(readDecimals, 0xff)` check marks success as 0. This is well-tested via `testDecimalsForTokenInvalidValueTooLarge`.

The gap is that no test checks the boundary value `readDecimals == 0x100` (i.e., the smallest value exceeding uint8). The fuzz range `vm.assume(decimals > 0xff)` covers this, but the boundary is only reached probabilistically by the fuzzer. A deterministic unit test for `decimals == 0x100` would pin the boundary explicitly.

**Recommendation:** Add a unit test that mocks `decimals()` to return exactly `0x100` (256) across all four functions and asserts `ReadFailure`.

---

### FINDING-P2-07 — No test verifies `TokenDecimalsReadFailure` error payload includes correct `tofuOutcome` value for `Inconsistent`

**Severity:** INFO

**Location:** `safeDecimalsForToken` (line 142), `safeDecimalsForTokenReadOnly` (line 166).

**Observation:** `testSafeDecimalsForTokenValidValue` uses `vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.Inconsistent))` which verifies the full ABI-encoded revert data including the `tofuOutcome` argument. This is correctly specified.

However, the test is a fuzz test where `decimalsA != decimalsB` is not guaranteed (it uses an `if/else` branch). When `decimalsA == decimalsB`, the revert branch is skipped entirely and only the success path is tested in that run. The fuzzer will exercise both, but a deterministic test with `decimalsA != decimalsB` pinned would guarantee the revert path is always exercised.

**Recommendation:** Add a deterministic unit test (e.g., `decimalsA = 6, decimalsB = 18`) that always reaches the revert branch for both `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` to ensure the error encoding is always checked, independent of fuzzer seed.

---

## 5. Coverage Summary

| Category | Status |
|----------|--------|
| All four public functions have direct test files | PASS |
| All three assembly failure modes tested (revert, short data, oversized value) | PASS |
| `address(0)` tested for all four functions | PASS |
| `Initial` outcome tested for all four functions | PASS |
| `Consistent` outcome tested for all four functions | PASS |
| `Inconsistent` outcome tested for all four functions | PASS |
| `ReadFailure` outcome (all three causes) tested for all four functions | PASS |
| Storage immutability on `ReadFailure` / `Inconsistent` verified | PASS (for `decimalsForToken`) |
| TOFU_DECIMALS_SELECTOR constant verified against ERC20 ABI | PASS |
| EOA (no-code address, not address(0)) tested | GAP (LOW) |
| Deterministic boundary test for `readDecimals == 0x100` | GAP (INFO) |
| Deterministic Inconsistent revert test (non-fuzz) | GAP (INFO) |
| Cross-token isolation at `safe*` wrapper level | GAP (INFO) |

---

## 6. Final Severity Summary

| ID | Severity | Title |
|----|----------|-------|
| P2-01 | LOW | Zero-length returndata sub-case not deterministically isolated |
| P2-02 | LOW | No test for plain EOA (non-contract, non-zero) address |
| P2-03 | INFO | read-only semantic relies on `view` compiler enforcement, no explicit state-change check |
| P2-04 | LOW | `safeDecimalsForTokenReadOnly` not integration-tested via `decimalsForToken` initializer |
| P2-05 | INFO | Cross-token isolation not mirrored at `safe*` wrapper level |
| P2-06 | INFO | Boundary value `readDecimals == 0x100` not deterministically pinned |
| P2-07 | INFO | Inconsistent revert path only exercised probabilistically in fuzz, not by a pinned unit test |

Overall the test suite is thorough. All assembly branches are covered by at least one test. The gaps are minor (missing deterministic edge-case pins and the EOA address scenario) and do not represent untested logic in the production code paths. No CRITICAL or HIGH coverage gaps were found.
