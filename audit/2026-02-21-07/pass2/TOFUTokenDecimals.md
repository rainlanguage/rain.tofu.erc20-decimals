# Audit Pass 2: Test Coverage for `src/concrete/TOFUTokenDecimals.sol`

**Auditor:** A04
**Date:** 2026-02-21

## Source Summary

`TOFUTokenDecimals.sol` (39 lines) is a minimal concrete contract with:
- 1 state variable: `sTOFUTokenDecimals` (`mapping(address => TOFUTokenDecimalsResult)`)
- 4 external functions, all delegating to `LibTOFUTokenDecimalsImplementation`:
  1. `decimalsForToken(address) returns (TOFUOutcome, uint8)` -- state-changing
  2. `decimalsForTokenReadOnly(address) view returns (TOFUOutcome, uint8)` -- read-only
  3. `safeDecimalsForToken(address) returns (uint8)` -- state-changing, reverts on failure
  4. `safeDecimalsForTokenReadOnly(address) view returns (uint8)` -- read-only, reverts on failure

## Evidence of Thorough Reading

### `TOFUTokenDecimals.decimalsForToken.t.sol` (230 lines, 14 test functions)

| Test | Scenario | Fuzzed |
|------|----------|--------|
| `testDecimalsForTokenAddressZero` | address(0) produces ReadFailure | No |
| `testDecimalsForToken(uint8)` | Uninitialized token returns Initial | Yes |
| `testDecimalsForTokenDecimalsZero` | decimals=0 boundary: Initial then Consistent | No |
| `testDecimalsForTokenConsistent(uint8)` | Second call same decimals returns Consistent | Yes |
| `testDecimalsForTokenInconsistent(uint8,uint8)` | Second call different decimals returns Inconsistent + original value | Yes |
| `testDecimalsForTokenReadFailure` | Reverting token uninitialized returns ReadFailure,0 | No |
| `testDecimalsForTokenReadFailureInitialized(uint8)` | Reverting token after init returns ReadFailure + stored value | Yes |
| `testDecimalsForTokenCrossTokenIsolation(uint8,uint8)` | Two tokens don't interfere | Yes |
| `testDecimalsForTokenStorageImmutableOnReadFailure(uint8)` | ReadFailure doesn't corrupt stored value | Yes |
| `testDecimalsForTokenNoStorageWriteOnUninitializedReadFailure(uint8)` | ReadFailure on uninitialized doesn't write storage | Yes |
| `testDecimalsForTokenOverwideDecimals(uint256)` | >uint8 return treated as ReadFailure | Yes |
| `testDecimalsForTokenNoDecimalsFunction` | STOP opcode (0-byte return) produces ReadFailure | No |
| `testDecimalsForTokenStorageImmutableOnInconsistent(uint8,uint8)` | Inconsistent doesn't overwrite stored value | Yes |
| `testDecimalsForTokenCrossFunctionInteraction(uint8)` | All 4 functions share storage; exercises in sequence | Yes |

### `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (145 lines, 11 test functions)

| Test | Scenario | Fuzzed |
|------|----------|--------|
| `testDecimalsForTokenReadOnlyAddressZero` | address(0) produces ReadFailure | No |
| `testDecimalsForTokenReadOnly(uint8)` | Uninitialized token returns Initial | Yes |
| `testDecimalsForTokenReadOnlyDecimalsZero` | decimals=0 boundary: Initial read-only then Consistent after stateful init | No |
| `testDecimalsForTokenReadOnlyConsistent(uint8)` | After init, read-only sees Consistent | Yes |
| `testDecimalsForTokenReadOnlyInconsistent(uint8,uint8)` | After init with different decimals sees Inconsistent | Yes |
| `testDecimalsForTokenReadOnlyReadFailure` | Reverting token uninitialized returns ReadFailure,0 | No |
| `testDecimalsForTokenReadOnlyReadFailureInitialized(uint8)` | Reverting token after init returns ReadFailure + stored value | Yes |
| `testDecimalsForTokenReadOnlyOverwideDecimals(uint256)` | >uint8 return treated as ReadFailure | Yes |
| `testDecimalsForTokenReadOnlyNoDecimalsFunction` | STOP opcode produces ReadFailure | No |
| `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` | Read-only call does not persist state | Yes |

### `TOFUTokenDecimals.safeDecimalsForToken.t.sol` (120 lines, 10 test functions)

| Test | Scenario | Fuzzed |
|------|----------|--------|
| `testSafeDecimalsForTokenAddressZeroReverts` | address(0) reverts with TokenDecimalsReadFailure(addr,ReadFailure) | No |
| `testSafeDecimalsForToken(uint8)` | Uninitialized token succeeds (Initial path) | Yes |
| `testSafeDecimalsForTokenDecimalsZero` | decimals=0 boundary: first and second calls both succeed | No |
| `testSafeDecimalsForTokenConsistent(uint8)` | Second call same decimals succeeds (Consistent path) | Yes |
| `testSafeDecimalsForTokenInconsistentReverts(uint8,uint8)` | Different decimals reverts with (token,Inconsistent) | Yes |
| `testSafeDecimalsForTokenReadFailureReverts` | Reverting token reverts with (token,ReadFailure) | No |
| `testSafeDecimalsForTokenOverwideDecimalsReverts(uint256)` | >uint8 return reverts with ReadFailure | Yes |
| `testSafeDecimalsForTokenNoDecimalsFunctionReverts` | STOP opcode reverts with ReadFailure | No |
| `testSafeDecimalsForTokenReadFailureInitializedReverts(uint8)` | Reverting token after init still reverts | Yes |

### `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` (148 lines, 11 test functions)

| Test | Scenario | Fuzzed |
|------|----------|--------|
| `testSafeDecimalsForTokenReadOnlyAddressZeroReverts` | address(0) reverts | No |
| `testSafeDecimalsForTokenReadOnlyDecimalsZero` | decimals=0 boundary: succeeds read-only then Consistent after init | No |
| `testSafeDecimalsForTokenReadOnly(uint8)` | After init, read-only safe succeeds | Yes |
| `testSafeDecimalsForTokenReadOnlyInitial(uint8)` | Uninitialized token succeeds (Initial path) | Yes |
| `testSafeDecimalsForTokenReadOnlyInconsistentReverts(uint8,uint8)` | After init with different decimals reverts | Yes |
| `testSafeDecimalsForTokenReadOnlyOverwideDecimalsReverts(uint256)` | >uint8 return reverts | Yes |
| `testSafeDecimalsForTokenReadOnlyNoDecimalsFunctionReverts` | STOP opcode reverts | No |
| `testSafeDecimalsForTokenReadOnlyReadFailureInitializedReverts(uint8)` | Reverting after init reverts | Yes |
| `testSafeDecimalsForTokenReadOnlyReadFailureReverts` | Reverting uninitialized reverts | No |
| `testSafeDecimalsForTokenReadOnlyMultiCallUninitialized(uint8)` | Multiple uninitialized calls all succeed independently | Yes |
| `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8)` | Read-only safe does not persist state | Yes |

### `TOFUTokenDecimals.immutability.t.sol` (32 lines, 1 test function)

| Test | Scenario | Fuzzed |
|------|----------|--------|
| `testNoMutableOpcodes` | Bytecode scan: no SELFDESTRUCT, DELEGATECALL, CALLCODE reachable | No |

## Coverage Matrix

| Scenario | decimalsForToken | decimalsForTokenReadOnly | safeDecimalsForToken | safeDecimalsForTokenReadOnly |
|----------|:---:|:---:|:---:|:---:|
| Initial outcome | Yes (fuzz) | Yes (fuzz) | Yes (fuzz) | Yes (fuzz) |
| Consistent outcome | Yes (fuzz) | Yes (fuzz) | Yes (fuzz) | Yes (fuzz) |
| Inconsistent outcome | Yes (fuzz) | Yes (fuzz) | Yes (fuzz, reverts) | Yes (fuzz, reverts) |
| ReadFailure (uninitialized) | Yes | Yes | Yes (reverts) | Yes (reverts) |
| ReadFailure (initialized) | Yes (fuzz) | Yes (fuzz) | Yes (fuzz, reverts) | Yes (fuzz, reverts) |
| address(0) | Yes | Yes | Yes (reverts) | Yes (reverts) |
| decimals=0 boundary | Yes | Yes | Yes | Yes |
| decimals=255 (max uint8) | Covered by fuzz | Covered by fuzz | Covered by fuzz | Covered by fuzz |
| Overwide (>uint8) return | Yes (fuzz) | Yes (fuzz) | Yes (fuzz, reverts) | Yes (fuzz, reverts) |
| No decimals() function | Yes | Yes | Yes (reverts) | Yes (reverts) |
| Cross-token isolation | Yes (fuzz) | -- | -- | -- |
| Storage immutable on ReadFailure | Yes (fuzz) | -- | -- | -- |
| Storage immutable on Inconsistent | Yes (fuzz) | -- | -- | -- |
| No storage write on uninitialized ReadFailure | Yes (fuzz) | -- | -- | -- |
| Read-only does not write storage | -- | Yes (fuzz) | -- | Yes (fuzz) |
| Cross-function interaction | Yes (fuzz, exercises all 4) | Yes (via cross-function test) | Yes (via cross-function test) | Yes (via cross-function test) |
| Bytecode immutability | Yes (opcode scan) | -- | -- | -- |

## Findings

No findings.

The test coverage for `TOFUTokenDecimals.sol` is thorough and complete across all dimensions:

1. **All 4 TOFU outcomes** (Initial, Consistent, Inconsistent, ReadFailure) are tested for each of the 4 external functions, with appropriate fuzz testing on the decimals values.

2. **Cross-function interaction** is explicitly tested in `testDecimalsForTokenCrossFunctionInteraction`, which exercises all 4 functions in sequence on the same token to verify shared-state wiring through the concrete contract.

3. **Storage immutability** is tested from multiple angles: ReadFailure does not corrupt stored values (`testDecimalsForTokenStorageImmutableOnReadFailure`), Inconsistent does not overwrite stored values (`testDecimalsForTokenStorageImmutableOnInconsistent`), ReadFailure on uninitialized does not write storage (`testDecimalsForTokenNoStorageWriteOnUninitializedReadFailure`), and read-only functions do not write storage (`testDecimalsForTokenReadOnlyDoesNotWriteStorage`, `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage`).

4. **Cross-token isolation** is tested with `testDecimalsForTokenCrossTokenIsolation`, using fuzzed decimals for two independent tokens.

5. **Edge cases** are well-covered: decimals=0 boundary has explicit tests for all 4 functions; decimals=255 is implicitly covered by uint8 fuzz ranges; overwide (>uint8) decimals returns are tested; tokens with no `decimals()` function (STOP opcode via `vm.etch`) are tested; address(0) is tested.

6. **Revert behavior** of safe variants is tested with exact error selector and parameter matching (`TokenDecimalsReadFailure(token, tofuOutcome)`) for both `Inconsistent` and `ReadFailure` outcomes.

7. **Bytecode immutability** is verified by scanning for dangerous opcodes (SELFDESTRUCT, DELEGATECALL, CALLCODE).

Total: 47 test functions across 5 test files providing comprehensive coverage of the 39-line concrete contract.
