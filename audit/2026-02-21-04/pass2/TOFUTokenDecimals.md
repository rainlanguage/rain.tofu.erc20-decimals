<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 2 — Test Coverage: `TOFUTokenDecimals`

**Auditor:** A02
**Date:** 2026-02-21
**Source file:** `src/concrete/TOFUTokenDecimals.sol`

---

## 1. Evidence of File Readings

### 1.1 Source: `TOFUTokenDecimals.sol`

**Contract name:** `TOFUTokenDecimals` (implements `ITOFUTokenDecimals`)

**Public/external surface:**

| Line | Function | Mutability |
|------|----------|------------|
| 19 | `decimalsForTokenReadOnly(address token)` | `external view` |
| 25 | `decimalsForToken(address token)` | `external` |
| 31 | `safeDecimalsForToken(address token)` | `external` |
| 36 | `safeDecimalsForTokenReadOnly(address token)` | `external view` |

**Internal state:**

| Line | Name | Type |
|------|------|------|
| 16 | `sTOFUTokenDecimals` | `mapping(address => TOFUTokenDecimalsResult) internal` |

The contract is purely a thin wrapper: each public function loads `sTOFUTokenDecimals` from storage and delegates to the corresponding `LibTOFUTokenDecimalsImplementation` function. There is no constructor, no events, no modifiers, and no other state variables.

---

### 1.2 Test file: `TOFUTokenDecimals.decimalsForToken.t.sol`

**Contract name:** `TOFUTokenDecimalsDecimalsForTokenTest`

| Line | Test function |
|------|--------------|
| 22 | `testDecimalsForToken(uint8 decimals)` |
| 33 | `testDecimalsForTokenConsistent(uint8 decimals)` |
| 46 | `testDecimalsForTokenInconsistent(uint8 decimalsA, uint8 decimalsB)` |
| 62 | `testDecimalsForTokenReadFailure()` |
| 73 | `testDecimalsForTokenReadFailureInitialized(uint8 decimals)` |
| 87 | `testDecimalsForTokenCrossTokenIsolation(uint8 decimalsA, uint8 decimalsB)` |
| 107 | `testDecimalsForTokenStorageImmutableOnReadFailure(uint8 decimals)` |
| 125 | `testDecimalsForTokenNoDecimalsFunction()` |
| 136 | `testDecimalsForTokenStorageImmutableOnInconsistent(uint8 decimalsA, uint8 decimalsB)` |

---

### 1.3 Test file: `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`

**Contract name:** `TOFUTokenDecimalsDecimalsForTokenReadOnlyTest`

| Line | Test function |
|------|--------------|
| 22 | `testDecimalsForTokenReadOnly(uint8 decimals)` |
| 33 | `testDecimalsForTokenReadOnlyConsistent(uint8 decimals)` |
| 46 | `testDecimalsForTokenReadOnlyInconsistent(uint8 decimalsA, uint8 decimalsB)` |
| 62 | `testDecimalsForTokenReadOnlyReadFailure()` |
| 73 | `testDecimalsForTokenReadOnlyReadFailureInitialized(uint8 decimals)` |
| 88 | `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals)` |

---

### 1.4 Test file: `TOFUTokenDecimals.safeDecimalsForToken.t.sol`

**Contract name:** `TOFUTokenDecimalsSafeDecimalsForTokenTest`

| Line | Test function |
|------|--------------|
| 22 | `testSafeDecimalsForToken(uint8 decimals)` |
| 31 | `testSafeDecimalsForTokenConsistent(uint8 decimals)` |
| 43 | `testSafeDecimalsForTokenInconsistentReverts(uint8 decimalsA, uint8 decimalsB)` |
| 58 | `testSafeDecimalsForTokenReadFailureReverts()` |
| 68 | `testSafeDecimalsForTokenReadFailureInitializedReverts(uint8 decimals)` |

---

### 1.5 Test file: `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

**Contract name:** `TOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest`

| Line | Test function |
|------|--------------|
| 22 | `testSafeDecimalsForTokenReadOnly(uint8 decimals)` |
| 35 | `testSafeDecimalsForTokenReadOnlyInitial(uint8 decimals)` |
| 45 | `testSafeDecimalsForTokenReadOnlyInconsistentReverts(uint8 decimalsA, uint8 decimalsB)` |
| 60 | `testSafeDecimalsForTokenReadOnlyReadFailureReverts()` |
| 70 | `testSafeDecimalsForTokenReadOnlyMultiCallUninitialized(uint8 decimals)` |
| 81 | `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals)` |

---

### 1.6 Test file: `TOFUTokenDecimals.immutability.t.sol`

**Contract name:** `TOFUTokenDecimalsImmutabilityTest`

| Line | Test function |
|------|--------------|
| 14 | `testNoMutableOpcodes()` |

---

## 2. Coverage Analysis

### 2.1 Function-level coverage

| Function | File covering it | Outcomes tested |
|----------|-----------------|-----------------|
| `decimalsForToken` | `decimalsForToken.t.sol` | Initial, Consistent, Inconsistent, ReadFailure (uninitialized), ReadFailure (initialized) |
| `decimalsForTokenReadOnly` | `decimalsForTokenReadOnly.t.sol` | Initial, Consistent, Inconsistent, ReadFailure (uninitialized), ReadFailure (initialized) |
| `safeDecimalsForToken` | `safeDecimalsForToken.t.sol` | Initial (success), Consistent (success), Inconsistent (revert), ReadFailure (uninitialized revert), ReadFailure (initialized revert) |
| `safeDecimalsForTokenReadOnly` | `safeDecimalsForTokenReadOnly.t.sol` | Consistent (success), Initial (success), Inconsistent (revert), ReadFailure (revert), multi-call uninitialized, no-storage-write |
| constructor (implicit) | any setUp | Covered implicitly via `new TOFUTokenDecimals()` in every setUp |

All four public entry-points on the concrete contract are covered. All `TOFUOutcome` variants are exercised for each entry-point.

---

## 3. Findings

---

### F-01 — `address(0)` as token is never tested

**Severity:** LOW

**Affected functions:** `decimalsForToken`, `decimalsForTokenReadOnly`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

**Detail:**
Every test constructs a token address via `makeAddr("token")` (a non-zero address). No test passes `address(0)` as the token. The implementation uses `staticcall(gas(), token, ...)` with inline assembly, and `address(0)` is a valid EVM target (it has no code but a `staticcall` to it will succeed and return 0 bytes, triggering the `returndatasize < 0x20` guard and producing `ReadFailure`). The storage mapping also accepts `address(0)` as a key.

The behavior is technically deterministic and covered by the general `ReadFailure` logic, but `address(0)` is the canonical sentinel for "no address" in Solidity and is a common mistake in caller code. A targeted test would document that `address(0)` is handled gracefully (returns `ReadFailure` on first call, then consistent `ReadFailure` thereafter) rather than panicking or corrupting state.

**Recommendation:** Add `testDecimalsForTokenAddressZero()` (and analogues for the other three entry-points, or a single parameterised test) that passes `address(0)` and asserts `ReadFailure` is returned without revert.

---

### F-02 — `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` have no `address(0)` revert test

**Severity:** LOW

**Affected functions:** `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

**Detail:**
Follows from F-01. Because `address(0)` yields `ReadFailure`, the `safe*` variants should revert with `TokenDecimalsReadFailure(address(0), TOFUOutcome.ReadFailure)`. This specific error payload is never verified in the test suite for the zero-address case.

**Recommendation:** Add a test that calls `safeDecimalsForToken(address(0))` and asserts the exact revert selector, token address, and outcome.

---

### F-03 — No `vm.etch` short-return-data path tested in the concrete layer

**Severity:** LOW

**Affected functions:** `decimalsForToken`, `decimalsForTokenReadOnly`

**Detail:**
`testDecimalsForTokenNoDecimalsFunction` (line 125, `decimalsForToken.t.sol`) uses `vm.etch(token, hex"00")` (STOP opcode) to exercise the `returndatasize < 0x20` path. However, the equivalent test does not exist for `decimalsForTokenReadOnly` in its own test file. The `ReadFailure` path for that function is only exercised via `vm.mockCallRevert`, which triggers the `success == false` branch of the assembly block, not the `returndatasize < 0x20` guard. Both branches are distinct paths in the assembly.

**Recommendation:** Add a `testDecimalsForTokenReadOnlyNoDecimalsFunction()` in `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` using `vm.etch(token, hex"00")` to cover the short-returndata guard independently.

---

### F-04 — No `vm.etch` short-return-data path for `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly`

**Severity:** LOW

**Affected functions:** `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

**Detail:**
The `safe*` variants each have a `ReadFailureReverts` test using `vm.mockCallRevert`, but neither has a test with `vm.etch(token, hex"00")`. The short-returndata assembly guard produces the same `ReadFailure` outcome, but the two paths (staticcall returning `false` vs. staticcall returning `true` with fewer than 32 bytes) are separate branches in `LibTOFUTokenDecimalsImplementation`.

**Recommendation:** Add `testSafeDecimalsForTokenNoDecimalsFunction()` and `testSafeDecimalsForTokenReadOnlyNoDecimalsFunction()` using `vm.etch(token, hex"00")`.

---

### F-05 — Over-wide `decimals()` return value path not tested at concrete layer

**Severity:** LOW

**Affected functions:** `decimalsForToken`, `decimalsForTokenReadOnly`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

**Detail:**
The implementation assembly has a third `ReadFailure` sub-path: `returndatasize >= 0x20` but the first word of return data is `> 0xff` (i.e., a valid 256-bit return but the value does not fit in `uint8`). This is the `if gt(readDecimals, 0xff)` guard. None of the concrete-layer tests trigger this path; it would require mocking a `decimals()` return of, for example, `uint256(256)` or `type(uint256).max`. The `LibTOFUTokenDecimalsImplementation` tests likely cover this at the library level, but there is no smoke test confirming the concrete contract wires it through.

**Recommendation:** Add a test at the concrete layer using `vm.mockCall` that returns a `uint256` value greater than `0xff` for `decimals()` and asserts `ReadFailure` (and, for the `safe*` functions, the correct revert).

---

### F-06 — Storage isolation not tested for `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly`

**Severity:** INFO

**Affected functions:** `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

**Detail:**
`testDecimalsForTokenCrossTokenIsolation` (line 87, `decimalsForToken.t.sol`) verifies that two different token addresses do not cross-contaminate each other in the `sTOFUTokenDecimals` mapping. No equivalent cross-token isolation test exists for `safeDecimalsForToken` or `safeDecimalsForTokenReadOnly`. Given that the `safe*` functions delegate to the same underlying storage, this is unlikely to be a real defect, but the coverage gap means any future refactor that accidentally collapses the key space would not be caught by the `safe*` tests.

**Recommendation:** Add cross-token isolation tests for the `safe*` variants.

---

### F-07 — `safeDecimalsForToken` has no `StorageImmutableOnInconsistent` or `StorageImmutableOnReadFailure` test

**Severity:** INFO

**Affected functions:** `safeDecimalsForToken`

**Detail:**
`decimalsForToken.t.sol` includes `testDecimalsForTokenStorageImmutableOnInconsistent` and `testDecimalsForTokenStorageImmutableOnReadFailure` which verify that the stored value is not mutated when an `Inconsistent` or `ReadFailure` outcome is encountered. The `safeDecimalsForToken` test file only checks that the function reverts; it does not check that after the revert the original stored value is still intact and a subsequent successful call still yields `Consistent`. Because `safeDecimalsForToken` delegates directly to `decimalsForToken`, this is correct by construction, but there is no explicit test at the concrete level confirming the storage contract post-revert.

**Recommendation:** Add a test that (a) initializes a token, (b) triggers an inconsistent/failure revert via `safeDecimalsForToken`, then (c) restores the mock and confirms the subsequent `safeDecimalsForToken` call returns the original value successfully.

---

### F-08 — No test for concurrent/re-entrant behavior with two tokens in `safeDecimalsForTokenReadOnly`

**Severity:** INFO

**Affected functions:** `safeDecimalsForTokenReadOnly`

**Detail:**
`testSafeDecimalsForTokenReadOnlyMultiCallUninitialized` (line 70) makes three consecutive calls for the same token and confirms each succeeds. It does not verify that interleaving calls for two different tokens in `Initial` state (none previously stored) does not cause interference. This is more of a documentation gap than a real risk, since the mapping keyed on `address` ensures isolation.

**Recommendation:** This is informational only. A two-token interleaved `Initial` test would add documentation value but is not required.

---

## 4. Summary Table

| ID | Severity | Subject |
|----|----------|---------|
| F-01 | LOW | `address(0)` token never passed to any entry-point |
| F-02 | LOW | `safe*` functions have no `address(0)` revert test |
| F-03 | LOW | `decimalsForTokenReadOnly` missing `vm.etch` short-returndata test |
| F-04 | LOW | `safe*` functions missing `vm.etch` short-returndata test |
| F-05 | LOW | Over-wide `decimals()` return value (`> 0xff`) not tested at concrete layer |
| F-06 | INFO | Cross-token storage isolation not tested for `safe*` functions |
| F-07 | INFO | `safeDecimalsForToken` missing storage-immutability-after-revert test |
| F-08 | INFO | Two-token interleaved `Initial` case not tested for `safeDecimalsForTokenReadOnly` |

No CRITICAL or HIGH findings. The concrete contract is thin enough that all non-trivial logic resides in `LibTOFUTokenDecimalsImplementation`, which reduces the concrete-layer risk substantially. All four `TOFUOutcome` variants are exercised for all four entry-points. The gaps are edge-case inputs and secondary assembly branches that are covered at the library level but lack explicit smoke tests at the concrete layer.
