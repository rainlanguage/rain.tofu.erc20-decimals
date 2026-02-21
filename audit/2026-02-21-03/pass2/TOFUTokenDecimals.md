# Pass 2: Test Coverage -- TOFUTokenDecimals.sol

Agent: A02

## Evidence of Thorough Reading

### src/concrete/TOFUTokenDecimals.sol
- Contract: `TOFUTokenDecimals is ITOFUTokenDecimals`
- Storage: `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals` (line 16)
- Functions (4 total, all external, all delegate to `LibTOFUTokenDecimalsImplementation`):
  1. `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 19)
  2. `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 25)
  3. `safeDecimalsForToken(address token) external returns (uint8)` (line 31)
  4. `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 36)

### test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol
- Contract: `TOFUTokenDecimalsDecimalsForTokenTest is Test`
- Test functions (8 total):
  1. `testDecimalsForToken(uint8 decimals)` -- line 22 (fuzz: Initial outcome)
  2. `testDecimalsForTokenConsistent(uint8 decimals)` -- line 33 (fuzz: Consistent outcome)
  3. `testDecimalsForTokenInconsistent(uint8 decimalsA, uint8 decimalsB)` -- line 46 (fuzz: Inconsistent outcome, returns stored value)
  4. `testDecimalsForTokenReadFailure()` -- line 62 (concrete: ReadFailure when uninitialized)
  5. `testDecimalsForTokenReadFailureInitialized(uint8 decimals)` -- line 73 (fuzz: ReadFailure when initialized, returns stored value)
  6. `testDecimalsForTokenCrossTokenIsolation(uint8 decimalsA, uint8 decimalsB)` -- line 87 (fuzz: two tokens do not cross-contaminate)
  7. `testDecimalsForTokenStorageImmutableOnReadFailure(uint8 decimals)` -- line 107 (fuzz: ReadFailure does not corrupt stored value)
  8. `testDecimalsForTokenStorageImmutableOnInconsistent(uint8 decimalsA, uint8 decimalsB)` -- line 124 (fuzz: Inconsistent does not overwrite stored value)

### test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol
- Contract: `TOFUTokenDecimalsDecimalsForTokenReadOnlyTest is Test`
- Test functions (5 total):
  1. `testDecimalsForTokenReadOnly(uint8 decimals)` -- line 22 (fuzz: Initial outcome on uninitialized)
  2. `testDecimalsForTokenReadOnlyConsistent(uint8 decimals)` -- line 33 (fuzz: Consistent after stateful init)
  3. `testDecimalsForTokenReadOnlyInconsistent(uint8 decimalsA, uint8 decimalsB)` -- line 46 (fuzz: Inconsistent returns stored value)
  4. `testDecimalsForTokenReadOnlyReadFailure()` -- line 62 (concrete: ReadFailure returns 0 on uninitialized)
  5. `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals)` -- line 73 (fuzz: verifies view does not persist state)

### test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol
- Contract: `TOFUTokenDecimalsSafeDecimalsForTokenTest is Test`
- Test functions (4 total):
  1. `testSafeDecimalsForToken(uint8 decimals)` -- line 22 (fuzz: Initial path succeeds)
  2. `testSafeDecimalsForTokenConsistent(uint8 decimals)` -- line 31 (fuzz: Consistent path succeeds)
  3. `testSafeDecimalsForTokenInconsistentReverts(uint8 decimalsA, uint8 decimalsB)` -- line 43 (fuzz: Inconsistent reverts with correct error)
  4. `testSafeDecimalsForTokenReadFailureReverts()` -- line 58 (concrete: ReadFailure reverts with correct error)

### test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol
- Contract: `TOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest is Test`
- Test functions (4 total):
  1. `testSafeDecimalsForTokenReadOnly(uint8 decimals)` -- line 22 (fuzz: Consistent after stateful init succeeds)
  2. `testSafeDecimalsForTokenReadOnlyInconsistentReverts(uint8 decimalsA, uint8 decimalsB)` -- line 35 (fuzz: Inconsistent reverts with correct error)
  3. `testSafeDecimalsForTokenReadOnlyReadFailureReverts()` -- line 50 (concrete: ReadFailure reverts with correct error)
  4. `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals)` -- line 60 (fuzz: verifies view does not persist state)

### test/src/concrete/TOFUTokenDecimals.immutability.t.sol
- Contract: `TOFUTokenDecimalsImmutabilityTest is Test`
- Test functions (1 total):
  1. `testNoMutableOpcodes()` -- line 14 (concrete: scans deployed bytecode for SELFDESTRUCT, DELEGATECALL, CALLCODE)

## Coverage Analysis

### decimalsForToken (line 25)
**Coverage: STRONG.** The test file covers all four `TOFUOutcome` paths:
- `Initial` (first call): fuzz tested across all uint8 values
- `Consistent` (second call, same decimals): fuzz tested
- `Inconsistent` (second call, different decimals): fuzz tested, confirms stored value returned
- `ReadFailure` (reverting token): tested both uninitialized and initialized cases
- Cross-token isolation: fuzz tested for two different tokens
- Storage immutability after ReadFailure and Inconsistent: both fuzz tested

### decimalsForTokenReadOnly (line 19)
**Coverage: GOOD.** Covers:
- `Initial` outcome on uninitialized token: fuzz tested
- `Consistent` after stateful initialization: fuzz tested
- `Inconsistent` after stateful initialization with changed decimals: fuzz tested
- `ReadFailure` on uninitialized: tested
- Verifies view semantics (no storage write): tested

### safeDecimalsForToken (line 31)
**Coverage: GOOD.** Covers:
- Initial path succeeds: fuzz tested
- Consistent path succeeds: fuzz tested
- Inconsistent reverts with `TokenDecimalsReadFailure`: fuzz tested with error selector check
- ReadFailure reverts with `TokenDecimalsReadFailure`: tested with error selector check

### safeDecimalsForTokenReadOnly (line 36)
**Coverage: GOOD.** Covers:
- Consistent after initialization: fuzz tested
- Inconsistent after initialization reverts: fuzz tested
- ReadFailure reverts: tested
- View semantics (no storage write): tested

### Immutability (bytecode analysis)
**Coverage: GOOD.** Opcode scanning test verifies no SELFDESTRUCT, DELEGATECALL, or CALLCODE in reachable bytecode.

## Findings

### A02-1: Missing ReadFailure test for decimalsForTokenReadOnly when initialized [LOW]
The `decimalsForTokenReadOnly` test file covers `ReadFailure` only for the uninitialized case (`testDecimalsForTokenReadOnlyReadFailure` at line 62). There is no test that initializes a token via `decimalsForToken`, then triggers a read failure, and verifies that `decimalsForTokenReadOnly` returns `(ReadFailure, storedDecimals)`. While the analogous case is covered for `decimalsForToken` (via `testDecimalsForTokenReadFailureInitialized`), the read-only variant should also verify that the stored value is returned on read failure after initialization.

### A02-2: Missing test for safeDecimalsForTokenReadOnly on uninitialized Initial path [LOW]
The `safeDecimalsForTokenReadOnly` test file does not test the `Initial` outcome on an uninitialized token (calling `safeDecimalsForTokenReadOnly` without prior `decimalsForToken`). Test `testSafeDecimalsForTokenReadOnly` (line 22) always initializes via `decimalsForToken` first, so it only exercises the `Consistent` path. While the `Initial` path succeeds (it does not revert), there is no test confirming that `safeDecimalsForTokenReadOnly` returns the correct decimals value on first use without prior initialization. This matters because the interface documentation explicitly warns about this case ("Before initialization, each call is a fresh Initial read").

### A02-3: No test for safeDecimalsForToken ReadFailure after initialization [LOW]
The `safeDecimalsForToken` test file tests `ReadFailure` only for the uninitialized case (`testSafeDecimalsForTokenReadFailureReverts` at line 58). There is no test that first initializes a token, then causes a read failure, and confirms the revert contains the stored decimals in the error. This is a minor gap since the revert behavior is the same regardless, but it would increase confidence that the error path after initialization is correct.

### A02-4: No test for address(0) as token [INFO]
None of the concrete contract tests exercise the edge case where `address(0)` is passed as the token argument. Calling `staticcall` on `address(0)` has defined EVM behavior (precompile at address 0 does not implement `decimals()`), and should produce a `ReadFailure`. This is an edge case that would be good to verify explicitly.

### A02-5: No test for token returning oversized decimals value [INFO]
The underlying `LibTOFUTokenDecimalsImplementation` includes a guard (`if gt(readDecimals, 0xff) { success := 0 }`) to handle tokens that return a value larger than `uint8` from `decimals()`. None of the concrete contract tests exercise this path. While this is tested at the library level, the concrete contract tests do not verify that a token returning e.g. `uint256(256)` for `decimals()` is correctly treated as a `ReadFailure`. This validation occurs in the assembly block and is a defense against malicious tokens.

### A02-6: No test for token returning less than 32 bytes [INFO]
The assembly guard `if lt(returndatasize(), 0x20) { success := 0 }` handles tokens that return fewer than 32 bytes from `decimals()`. None of the concrete contract tests exercise this path. While `vm.mockCallRevert` tests the revert path, the short-return-data path is distinct (call succeeds but returns too little data). This would require `vm.mockCall` with a short return value or `vm.etch` with custom bytecode.

### A02-7: No multi-caller or reentrancy test [INFO]
The concrete contract has no access control, so any address can call any function. There are no tests verifying behavior when multiple callers interact with the same token's decimals in the same or different transactions. Since the contract only writes on `Initial` and the storage is append-only (never overwritten after initialization), this is low risk, but a test confirming that two different callers both see `Consistent` after one caller initializes would strengthen confidence.

### A02-8: No test exercising EIP-165 or fallback behavior [INFO]
The concrete contract does not implement `receive()` or `fallback()`. There are no tests confirming that sending ETH or calling non-existent selectors on the concrete contract reverts. This is default Solidity behavior and not a gap per se, but explicit tests would document the contract's surface area.
