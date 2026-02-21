# Pass 2 -- Test Coverage: `src/concrete/TOFUTokenDecimals.sol`

**Audit:** 2026-02-21-05
**Agent:** A02
**Date:** 2026-02-21

---

## 1. Source File Inventory

**File:** `src/concrete/TOFUTokenDecimals.sol` (39 lines)

**Contract:** `TOFUTokenDecimals is ITOFUTokenDecimals` (line 13)

**Storage:**
- `sTOFUTokenDecimals` -- `mapping(address => TOFUTokenDecimalsResult)` (line 16)

**Functions (4):**
| # | Function | Line | Mutability | Delegates to |
|---|----------|------|------------|--------------|
| 1 | `decimalsForTokenReadOnly(address)` | 19 | `view` | `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` |
| 2 | `decimalsForToken(address)` | 25 | non-view | `LibTOFUTokenDecimalsImplementation.decimalsForToken` |
| 3 | `safeDecimalsForToken(address)` | 31 | non-view | `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken` |
| 4 | `safeDecimalsForTokenReadOnly(address)` | 36 | `view` | `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly` |

---

## 2. Test File Inventory

### 2a. `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol`

**Contract:** `TOFUTokenDecimalsDecimalsForTokenTest is Test` (line 13)

| # | Test Function | Line | Fuzz? | Outcome Tested |
|---|--------------|------|-------|----------------|
| 1 | `testDecimalsForToken(uint8)` | 22 | yes | Initial |
| 2 | `testDecimalsForTokenConsistent(uint8)` | 33 | yes | Consistent |
| 3 | `testDecimalsForTokenInconsistent(uint8,uint8)` | 46 | yes | Inconsistent |
| 4 | `testDecimalsForTokenReadFailure()` | 62 | no | ReadFailure (uninitialized, reverting) |
| 5 | `testDecimalsForTokenReadFailureInitialized(uint8)` | 73 | yes | ReadFailure (initialized, reverting) |
| 6 | `testDecimalsForTokenCrossTokenIsolation(uint8,uint8)` | 87 | yes | Cross-token isolation |
| 7 | `testDecimalsForTokenStorageImmutableOnReadFailure(uint8)` | 107 | yes | Storage immutability after ReadFailure |
| 8 | `testDecimalsForTokenOverwideDecimals(uint256)` | 124 | yes | ReadFailure (overwide >0xff) |
| 9 | `testDecimalsForTokenNoDecimalsFunction()` | 137 | no | ReadFailure (short returndata, STOP opcode) |
| 10 | `testDecimalsForTokenStorageImmutableOnInconsistent(uint8,uint8)` | 148 | yes | Storage immutability after Inconsistent |

### 2b. `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

**Contract:** `TOFUTokenDecimalsDecimalsForTokenReadOnlyTest is Test` (line 13)

| # | Test Function | Line | Fuzz? | Outcome Tested |
|---|--------------|------|-------|----------------|
| 1 | `testDecimalsForTokenReadOnly(uint8)` | 22 | yes | Initial |
| 2 | `testDecimalsForTokenReadOnlyConsistent(uint8)` | 33 | yes | Consistent |
| 3 | `testDecimalsForTokenReadOnlyInconsistent(uint8,uint8)` | 46 | yes | Inconsistent |
| 4 | `testDecimalsForTokenReadOnlyReadFailure()` | 62 | no | ReadFailure (uninitialized, reverting) |
| 5 | `testDecimalsForTokenReadOnlyReadFailureInitialized(uint8)` | 73 | yes | ReadFailure (initialized, reverting) |
| 6 | `testDecimalsForTokenReadOnlyOverwideDecimals(uint256)` | 88 | yes | ReadFailure (overwide >0xff) |
| 7 | `testDecimalsForTokenReadOnlyNoDecimalsFunction()` | 100 | no | ReadFailure (short returndata, STOP opcode) |
| 8 | `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` | 111 | yes | View does not persist state |

### 2c. `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`

**Contract:** `TOFUTokenDecimalsSafeDecimalsForTokenTest is Test` (line 13)

| # | Test Function | Line | Fuzz? | Outcome Tested |
|---|--------------|------|-------|----------------|
| 1 | `testSafeDecimalsForToken(uint8)` | 22 | yes | Initial (success) |
| 2 | `testSafeDecimalsForTokenConsistent(uint8)` | 31 | yes | Consistent (success) |
| 3 | `testSafeDecimalsForTokenInconsistentReverts(uint8,uint8)` | 43 | yes | Inconsistent (revert) |
| 4 | `testSafeDecimalsForTokenReadFailureReverts()` | 58 | no | ReadFailure revert (uninitialized, reverting) |
| 5 | `testSafeDecimalsForTokenOverwideDecimalsReverts(uint256)` | 68 | yes | ReadFailure revert (overwide >0xff) |
| 6 | `testSafeDecimalsForTokenNoDecimalsFunctionReverts()` | 79 | no | ReadFailure revert (short returndata) |
| 7 | `testSafeDecimalsForTokenReadFailureInitializedReverts(uint8)` | 89 | yes | ReadFailure revert (initialized, reverting) |

### 2d. `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

**Contract:** `TOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest is Test` (line 13)

| # | Test Function | Line | Fuzz? | Outcome Tested |
|---|--------------|------|-------|----------------|
| 1 | `testSafeDecimalsForTokenReadOnly(uint8)` | 22 | yes | Consistent (initialized, success) |
| 2 | `testSafeDecimalsForTokenReadOnlyInitial(uint8)` | 35 | yes | Initial (uninitialized, success) |
| 3 | `testSafeDecimalsForTokenReadOnlyInconsistentReverts(uint8,uint8)` | 45 | yes | Inconsistent (revert) |
| 4 | `testSafeDecimalsForTokenReadOnlyOverwideDecimalsReverts(uint256)` | 60 | yes | ReadFailure revert (overwide >0xff) |
| 5 | `testSafeDecimalsForTokenReadOnlyNoDecimalsFunctionReverts()` | 71 | no | ReadFailure revert (short returndata) |
| 6 | `testSafeDecimalsForTokenReadOnlyReadFailureInitializedReverts(uint8)` | 81 | yes | ReadFailure revert (initialized, reverting) |
| 7 | `testSafeDecimalsForTokenReadOnlyReadFailureReverts()` | 95 | no | ReadFailure revert (uninitialized, reverting) |
| 8 | `testSafeDecimalsForTokenReadOnlyMultiCallUninitialized(uint8)` | 105 | yes | Multiple uninitialized reads succeed |
| 9 | `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` | 116 | yes | View does not persist state |

### 2e. `test/src/concrete/TOFUTokenDecimals.immutability.t.sol`

**Contract:** `TOFUTokenDecimalsImmutabilityTest is Test` (line 10)

| # | Test Function | Line | Fuzz? | What Tested |
|---|--------------|------|-------|-------------|
| 1 | `testNoMutableOpcodes()` | 14 | no | No SELFDESTRUCT, DELEGATECALL, CALLCODE in reachable bytecode |

---

## 3. Coverage Matrix

| Outcome / Scenario | `decimalsForToken` | `decimalsForTokenReadOnly` | `safeDecimalsForToken` | `safeDecimalsForTokenReadOnly` |
|----|----|----|----|----|
| Initial (happy path) | COVERED | COVERED | COVERED | COVERED |
| Consistent | COVERED | COVERED | COVERED | COVERED |
| Inconsistent | COVERED | COVERED | COVERED (revert) | COVERED (revert) |
| ReadFailure -- reverting token (uninitialized) | COVERED | COVERED | COVERED (revert) | COVERED (revert) |
| ReadFailure -- reverting token (initialized) | COVERED | COVERED | COVERED (revert) | COVERED (revert) |
| ReadFailure -- overwide (>0xff) | COVERED | COVERED | COVERED (revert) | COVERED (revert) |
| ReadFailure -- short returndata | COVERED | COVERED | COVERED (revert) | COVERED (revert) |
| Storage immutability on Inconsistent | COVERED | N/A (view) | -- | -- |
| Storage immutability on ReadFailure | COVERED | N/A (view) | -- | -- |
| View does not persist state | N/A | COVERED | N/A | COVERED |
| Cross-token isolation | COVERED | -- | -- | -- |
| Bytecode immutability | COVERED (immutability.t.sol) | -- | -- | -- |
| `address(0)` as token | GAP | GAP | GAP | GAP |
| EOA (no code, no mock) | GAP | GAP | GAP | GAP |
| `decimals()` returns 0 explicitly | implicit* | implicit* | implicit* | implicit* |

\* The fuzz tests with `uint8` input cover `decimals=0` probabilistically, but there is no dedicated explicit test for the `decimals=0` boundary to confirm the `initialized` flag guards against conflating uninitialized storage with stored zero.

---

## 4. Findings

### A02-1: No `address(0)` tests at the concrete contract level [LOW]

**Location:** All 4 concrete test files.

**Description:** None of the concrete contract test files exercise `address(0)` as the token parameter. The library-level tests (`LibTOFUTokenDecimalsImplementation.*.t.sol`) do test `address(0)` and confirm it produces `ReadFailure` (no code at the zero address). However, the concrete contract wiring tests do not verify this path passes through correctly.

**Risk:** Low. The concrete contract is a thin pass-through, and the library-level coverage provides confidence. However, since the concrete contract is the externally-callable entry point, a dedicated smoke test at this layer would close the gap.

**Recommendation:** Add one test per function (or a shared parameterized test) calling each function with `address(0)` and asserting `ReadFailure` / revert as appropriate.

---

### A02-2: No EOA / codeless-address tests at the concrete contract level [LOW]

**Location:** All 4 concrete test files.

**Description:** The tests for short returndata use `vm.etch(token, hex"00")` (a STOP-opcode contract), which exercises the `returndatasize < 0x20` guard. However, there is no test with a bare EOA address (an address with no code at all), which exercises the `staticcall` returning `success=false` due to calling a non-contract. In Solidity `staticcall` to an address with no code returns `success=true` and empty returndata, so the STOP-opcode test already implicitly covers the codeless case as both produce zero returndatasize. Nevertheless, an explicit EOA test would make the intent clearer.

**Risk:** Low. The behavior is effectively covered by the short-returndata tests, since both codeless and STOP-opcode addresses return 0 bytes of returndata. The `lt(returndatasize(), 0x20)` guard catches both.

**Note:** Actually, for a pure EOA with no code, `staticcall` returns `success=true` with 0 returndatasize, which is identical behavior to the STOP-opcode case already tested. The coverage is therefore functionally complete, but an explicit named test would improve documentation.

**Recommendation:** Consider adding an explicit test calling a plain `makeAddr("eoa")` address (without `vm.etch`) to document the EOA behavior.

---

### A02-3: No explicit `decimals=0` boundary test [LOW]

**Location:** All 4 concrete test files.

**Description:** The `initialized` boolean in `TOFUTokenDecimalsResult` exists specifically to distinguish "stored 0 decimals" from "uninitialized storage" (where `tokenDecimals` defaults to 0). The fuzz tests with `uint8` input will probabilistically cover `decimals=0`, but there is no dedicated, named test that explicitly verifies:
1. First call with `decimals=0` returns `(Initial, 0)`.
2. Second call with `decimals=0` returns `(Consistent, 0)` (not `Initial` again).
3. The `initialized` flag correctly distinguishes stored-zero from uninitialized.

**Risk:** Low. The fuzz tests cover this, but a dedicated test for this critical boundary would serve as a regression guard and make the design intent explicit.

**Recommendation:** Add a named test like `testDecimalsForTokenZeroDecimals()` that explicitly asserts the Initial-then-Consistent transition with `decimals=0`.

---

### A02-4: No cross-token isolation test for `decimalsForTokenReadOnly` [INFO]

**Location:** `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

**Description:** The `decimalsForToken` test file includes `testDecimalsForTokenCrossTokenIsolation` (line 87), confirming that initializing token A does not contaminate token B's state. No equivalent test exists for `decimalsForTokenReadOnly`. Since the read-only function does not write state, cross-contamination via write is impossible, but confirming two different tokens can be read independently through the read-only path would improve completeness.

**Risk:** Informational. The read-only function delegates to the same storage lookup, and cannot write, so cross-contamination is architecturally impossible.

---

### A02-5: No cross-token isolation test for `safeDecimalsForToken` or `safeDecimalsForTokenReadOnly` [INFO]

**Location:** `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`, `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

**Description:** Neither safe variant has a cross-token isolation test. `safeDecimalsForToken` writes state on `Initial` (via its delegation to `decimalsForToken`), so the isolation property is non-trivial for it.

**Risk:** Informational. Already covered at the `decimalsForToken` concrete level and at the library level.

---

### A02-6: No storage-immutability-on-Inconsistent or ReadFailure tests for safe variants [INFO]

**Location:** `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`

**Description:** `decimalsForToken` has explicit tests confirming that `Inconsistent` and `ReadFailure` outcomes do not overwrite the stored value (`testDecimalsForTokenStorageImmutableOnInconsistent`, `testDecimalsForTokenStorageImmutableOnReadFailure`). The safe variants revert on these outcomes, so the storage mutation question is moot (the transaction reverts). However, if a caller catches the revert in a try/catch, the storage immutability guarantee matters.

**Risk:** Informational. Since the safe functions revert, state changes are rolled back by the EVM. The underlying `decimalsForToken` tests already verify the non-reverting path does not mutate storage on bad outcomes.

---

### A02-7: Immutability test does not check for CREATE/CREATE2 opcodes [INFO]

**Location:** `test/src/concrete/TOFUTokenDecimals.immutability.t.sol` (line 14)

**Description:** The immutability test checks for `SELFDESTRUCT`, `DELEGATECALL`, and `CALLCODE`, which are the primary opcodes that allow contract mutation or destruction. It does not check for `CREATE` or `CREATE2`, which by themselves cannot mutate the contract's own storage but could be used in conjunction with other patterns. This is a very minor observation; `CREATE`/`CREATE2` alone do not enable self-mutation.

**Risk:** Informational. The three checked opcodes cover all practical mutation vectors for a storage-only contract.

---

## 5. Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| CRITICAL | 0 | -- |
| HIGH | 0 | -- |
| MEDIUM | 0 | -- |
| LOW | 3 | A02-1, A02-2, A02-3 |
| INFO | 4 | A02-4, A02-5, A02-6, A02-7 |

**Overall assessment:** The test coverage for `TOFUTokenDecimals.sol` is strong. All 4 functions have dedicated test files covering all 4 `TOFUOutcome` variants (Initial, Consistent, Inconsistent, ReadFailure) in both initialized and uninitialized states. Failure paths are well-covered including reverting tokens, overwide decimals (>0xff), and short returndata. The view functions have explicit tests confirming they do not persist state. The immutability test provides additional deployment safety.

The identified gaps are all LOW or INFO severity. The most notable gap is the absence of explicit `address(0)` and `decimals=0` boundary tests at the concrete layer, though both are covered at the library level and/or probabilistically by fuzz inputs.
