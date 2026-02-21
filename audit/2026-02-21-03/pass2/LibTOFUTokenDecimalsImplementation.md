# Pass 2: Test Coverage -- LibTOFUTokenDecimalsImplementation.sol

Agent: A05

## Evidence of Thorough Reading

### src/lib/LibTOFUTokenDecimalsImplementation.sol

- **Library**: `LibTOFUTokenDecimalsImplementation` (lines 18-175)
- **Constants**:
  - `TOFU_DECIMALS_SELECTOR` = `0x313ce567` (line 20) -- the `decimals()` function selector
- **Functions**:
  1. `decimalsForTokenReadOnly(mapping(...) storage, address)` (lines 34-84) -- `internal view`, returns `(TOFUOutcome, uint8)`. Core read logic using inline assembly to `staticcall` the token's `decimals()`. Checks returndatasize >= 0x20, checks value <= 0xff. Returns ReadFailure on any failure, Initial if not initialized, Consistent/Inconsistent if initialized.
  2. `decimalsForToken(mapping(...) storage, address)` (lines 113-127) -- `internal`, returns `(TOFUOutcome, uint8)`. Delegates to `decimalsForTokenReadOnly`, then stores the result on `Initial` outcome only.
  3. `safeDecimalsForToken(mapping(...) storage, address)` (lines 140-150) -- `internal`, returns `uint8`. Delegates to `decimalsForToken`, reverts with `TokenDecimalsReadFailure` if outcome is not `Consistent` or `Initial`.
  4. `safeDecimalsForTokenReadOnly(mapping(...) storage, address)` (lines 164-174) -- `internal view`, returns `uint8`. Delegates to `decimalsForTokenReadOnly`, reverts with `TokenDecimalsReadFailure` if outcome is not `Consistent` or `Initial`.

### test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol

- Contract: `LibTOFUTokenDecimalsImplementationTest`
- Test functions:
  1. `testDecimalsSelector()` (line 14) -- verifies `TOFU_DECIMALS_SELECTOR` matches `IERC20.decimals.selector`

### test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol

- Contract: `LibTOFUTokenDecimalsImplementationDecimalsForTokenTest`
- Storage: `sTokenTokenDecimals` mapping (line 14)
- Test functions:
  1. `testDecimalsForTokenAddressZero(uint8)` (line 16) -- fuzz test, address(0) with no code returns ReadFailure, tests both uninitialized and initialized
  2. `testDecimalsForTokenValidValue(uint8, uint8)` (line 29) -- fuzz test, Initial then Consistent/Inconsistent based on whether decimalsA == decimalsB
  3. `testDecimalsForTokenInvalidValueTooLarge(uint256, uint8)` (line 52) -- fuzz test, value > 0xff returns ReadFailure, tests both uninitialized and initialized
  4. `testDecimalsForTokenInvalidValueNotEnoughData(bytes, uint256, uint8)` (line 68) -- fuzz test, return data < 0x20 bytes returns ReadFailure, tests both uninitialized and initialized
  5. `testDecimalsForTokenNoStorageWriteOnNonInitial(uint8, uint256)` (line 95) -- fuzz test, proves ReadFailure does not overwrite stored value
  6. `testDecimalsForTokenNoStorageWriteOnInconsistent(uint8, uint8)` (line 120) -- fuzz test, proves Inconsistent does not overwrite stored value
  7. `testDecimalsForTokenCrossTokenIsolation(uint8, uint8)` (line 142) -- fuzz test, two tokens with different decimals are stored independently
  8. `testDecimalsForTokenTokenContractRevert(uint8)` (line 168) -- fuzz test, token with revert opcode returns ReadFailure, tests both uninitialized and initialized

### test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol

- Contract: `LibTOFUTokenDecimalsImplementationDecimalsForTokenReadOnlyTest`
- Storage: `sTOFUTokenDecimals` mapping (line 14)
- Test functions:
  1. `testDecimalsForTokenReadOnlyAddressZero(uint8)` (line 16) -- fuzz test, address(0) returns ReadFailure, tests both uninitialized and initialized
  2. `testDecimalsForTokenReadOnlyValidValue(uint8, uint8)` (line 30) -- fuzz test, Initial on first read, then Consistent/Inconsistent after manual storage initialization
  3. `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256, uint8)` (line 51) -- fuzz test, value > 0xff returns ReadFailure, tests both uninitialized and initialized
  4. `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes, uint256, uint8)` (line 68) -- fuzz test, return data < 0x20 bytes returns ReadFailure, tests both uninitialized and initialized
  5. `testDecimalsForTokenReadOnlyTokenContractRevert(uint8)` (line 94) -- fuzz test, token with revert opcode returns ReadFailure, tests both uninitialized and initialized

### test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol

- Contract: `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenTest`
- Storage: `sTokenDecimals` mapping (line 15)
- Helper: `externalSafeDecimalsForToken(address)` (line 17) -- external wrapper for testing reverts
- Test functions:
  1. `testSafeDecimalsForTokenAddressZeroUninitialized()` (line 21) -- reverts with ReadFailure for address(0) when uninitialized
  2. `testSafeDecimalsForTokenAddressZeroInitialized(uint8)` (line 26) -- fuzz test, reverts with ReadFailure for address(0) even when initialized
  3. `testSafeDecimalsForTokenInitial(uint8)` (line 34) -- fuzz test, Initial path succeeds and returns correct decimals
  4. `testSafeDecimalsForTokenValidValue(uint8, uint8)` (line 41) -- fuzz test, Consistent succeeds, Inconsistent reverts with correct error
  5. `testSafeDecimalsForTokenInvalidValueTooLargeUninitialized(uint256)` (line 60) -- fuzz test, reverts with ReadFailure
  6. `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint256, uint8)` (line 69) -- fuzz test, reverts with ReadFailure even when initialized
  7. `testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized(bytes, uint256)` (line 79) -- fuzz test, reverts with ReadFailure
  8. `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(bytes, uint256, uint8)` (line 95) -- fuzz test, reverts with ReadFailure even when initialized
  9. `testSafeDecimalsForTokenTokenContractRevertUninitialized()` (line 114) -- reverts with ReadFailure for reverting contract
  10. `testSafeDecimalsForTokenTokenContractRevertInitialized(uint8)` (line 121) -- fuzz test, reverts with ReadFailure for reverting contract even when initialized

### test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol

- Contract: `LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenReadOnlyTest`
- Storage: `sTokenDecimals` mapping (line 15)
- Helper: `externalSafeDecimalsForTokenReadOnly(address)` (line 17) -- external view wrapper for testing reverts
- Test functions:
  1. `testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized()` (line 21) -- reverts with ReadFailure for address(0) when uninitialized
  2. `testSafeDecimalsForTokenReadOnlyAddressZeroInitialized(uint8)` (line 26) -- fuzz test, reverts with ReadFailure for address(0) even when initialized
  3. `testSafeDecimalsForTokenReadOnlyValidValue(uint8, uint8)` (line 32) -- fuzz test, Initial succeeds, Consistent succeeds, Inconsistent reverts
  4. `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized(uint256)` (line 51) -- fuzz test, reverts with ReadFailure
  5. `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint256, uint8)` (line 60) -- fuzz test, reverts with ReadFailure even when initialized
  6. `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized(bytes, uint256)` (line 72) -- fuzz test, reverts with ReadFailure
  7. `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(bytes, uint256, uint8)` (line 88) -- fuzz test, reverts with ReadFailure even when initialized
  8. `testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized()` (line 107) -- reverts with ReadFailure for reverting contract
  9. `testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8)` (line 114) -- fuzz test, reverts with ReadFailure for reverting contract even when initialized

## Coverage Analysis

### 1. `TOFU_DECIMALS_SELECTOR` constant

**Coverage**: Tested in `LibTOFUTokenDecimalsImplementation.t.sol` by `testDecimalsSelector()` which verifies it matches `IERC20.decimals.selector`.

**Assessment**: Adequate.

### 2. `decimalsForTokenReadOnly`

**Coverage**:
- EOA / address(0) (no code): Tested (`testDecimalsForTokenReadOnlyAddressZero`) -- both uninitialized and initialized paths
- Valid uint8 value, uninitialized: Tested (`testDecimalsForTokenReadOnlyValidValue`) -- returns Initial with correct value
- Valid uint8 value, initialized, consistent: Tested (`testDecimalsForTokenReadOnlyValidValue`) -- returns Consistent with stored value
- Valid uint8 value, initialized, inconsistent: Tested (`testDecimalsForTokenReadOnlyValidValue`) -- returns Inconsistent with stored value
- Value > 0xff: Tested (`testDecimalsForTokenReadOnlyInvalidValueTooLarge`) -- returns ReadFailure, both uninitialized and initialized
- Return data < 32 bytes: Tested (`testDecimalsForTokenReadOnlyInvalidValueNotEnoughData`) -- returns ReadFailure, both uninitialized and initialized
- Token reverts: Tested (`testDecimalsForTokenReadOnlyTokenContractRevert`) -- returns ReadFailure, both uninitialized and initialized
- Zero decimals (tests initialized flag): Covered by fuzz tests since uint8 range includes 0
- Max uint8 decimals (255): Covered by fuzz tests since uint8 range includes 255

**Assessment**: Well covered. All assembly branches exercised through fuzz testing.

### 3. `decimalsForToken`

**Coverage**:
- EOA / address(0): Tested (`testDecimalsForTokenAddressZero`)
- Initial read stores value: Tested (`testDecimalsForTokenValidValue`) -- stores on Initial, subsequent read returns Consistent
- Consistent after store: Tested (`testDecimalsForTokenValidValue`)
- Inconsistent detection: Tested (`testDecimalsForTokenValidValue`) -- when decimalsB != decimalsA
- Value > 0xff: Tested (`testDecimalsForTokenInvalidValueTooLarge`)
- Return data < 32 bytes: Tested (`testDecimalsForTokenInvalidValueNotEnoughData`)
- Token reverts: Tested (`testDecimalsForTokenTokenContractRevert`)
- No storage write on ReadFailure: Tested (`testDecimalsForTokenNoStorageWriteOnNonInitial`)
- No storage write on Inconsistent: Tested (`testDecimalsForTokenNoStorageWriteOnInconsistent`)
- Cross-token isolation: Tested (`testDecimalsForTokenCrossTokenIsolation`)

**Assessment**: Excellent coverage. Key invariant that only Initial writes to storage is explicitly verified.

### 4. `safeDecimalsForToken`

**Coverage**:
- Initial path succeeds: Tested (`testSafeDecimalsForTokenInitial`)
- Consistent succeeds: Tested (`testSafeDecimalsForTokenValidValue`)
- Inconsistent reverts: Tested (`testSafeDecimalsForTokenValidValue`)
- ReadFailure reverts (address(0)): Tested both uninitialized and initialized
- ReadFailure reverts (too large): Tested both uninitialized and initialized
- ReadFailure reverts (not enough data): Tested both uninitialized and initialized
- ReadFailure reverts (contract reverts): Tested both uninitialized and initialized
- Revert error encoding: All tests verify `TokenDecimalsReadFailure(token, tofuOutcome)` with correct arguments

**Assessment**: Thorough coverage of both success and revert paths.

### 5. `safeDecimalsForTokenReadOnly`

**Coverage**:
- Initial path succeeds: Tested (`testSafeDecimalsForTokenReadOnlyValidValue`) -- first read returns Initial
- Consistent succeeds: Tested (`testSafeDecimalsForTokenReadOnlyValidValue`)
- Inconsistent reverts: Tested (`testSafeDecimalsForTokenReadOnlyValidValue`)
- ReadFailure reverts (address(0)): Tested both uninitialized and initialized
- ReadFailure reverts (too large): Tested both uninitialized and initialized
- ReadFailure reverts (not enough data): Tested both uninitialized and initialized
- ReadFailure reverts (contract reverts): Tested both uninitialized and initialized
- Revert error encoding: All tests verify `TokenDecimalsReadFailure(token, tofuOutcome)` with correct arguments

**Assessment**: Thorough coverage mirroring safeDecimalsForToken tests.

## Findings

### A05-1: No explicit test for decimalsForTokenReadOnly not modifying storage [INFO]

While `decimalsForTokenReadOnly` is marked `internal view` (so the compiler prevents state writes), there is no test that explicitly verifies the storage mapping is unchanged after a call to `decimalsForTokenReadOnly` that returns `Initial`. The `testDecimalsForTokenReadOnlyValidValue` test manually sets storage to simulate initialization rather than verifying the read-only function did not set it. The Solidity `view` modifier provides compile-time safety here, making this a documentation/belt-and-suspenders concern only, not a functional gap.

### A05-2: No dedicated test for zero decimals as a concrete value [INFO]

Zero decimals is the critical edge case that motivates the `initialized` boolean in `TOFUTokenDecimalsResult`. While the fuzz tests over `uint8` will statistically hit 0, there is no dedicated concrete test case that explicitly:
1. Initializes with decimals = 0
2. Reads again to confirm Consistent (not re-initialized as if uninitialized)
3. Verifies the returned value is 0 (not confused with default storage)

The fuzz tests provide probabilistic coverage (0 is in the uint8 domain), but a named concrete test would make the coverage of this design-critical edge case explicit and self-documenting.

### A05-3: No dedicated test for max uint8 decimals (255) [INFO]

Similarly to zero decimals, the boundary value of 255 (0xff) is important because the assembly uses `gt(readDecimals, 0xff)` as the cutoff. A value of exactly 255 should succeed while 256 should fail. The fuzz tests cover this implicitly (uint8 includes 255, and `vm.assume(decimals > 0xff)` ensures the too-large tests start at 256), but a concrete test explicitly asserting `decimals = 255` succeeds and `decimals = 256` fails would document this boundary behavior.

### A05-4: No test for exactly 32 bytes of return data at the boundary [INFO]

The assembly checks `lt(returndatasize(), 0x20)` to reject responses shorter than 32 bytes. Tests cover the "not enough data" case with data lengths 0 through 31 bytes via fuzzing. However, there is no explicit test verifying that exactly 32 bytes of return data (the minimum valid response) succeeds. This boundary is implicitly covered by the `testDecimalsForToken(ReadOnly)ValidValue` tests (since `abi.encode(uint8)` produces 32 bytes), but it is not explicitly documented as a boundary test.

### A05-5: No test for token with code but no decimals function (fallback/receive only) [LOW]

The tests cover: (a) EOA with no code (address(0)), (b) contract that always reverts (hex"fd"), and (c) contract with mocked `decimals()` returning various values. However, there is no test for a contract that has code but lacks a `decimals()` function -- i.e., a contract whose fallback or receive function succeeds and returns unexpected data, or returns empty data. While `vm.mockCall` overlays behavior on top of contract code, a test using `vm.etch` with a contract that has a fallback returning non-standard data (e.g., returns success but zero bytes, or returns success with arbitrary bytes) would more accurately test the assembly's handling of real-world non-ERC20 contracts. The `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData` fuzz test partially covers this by testing short return data, but the mock mechanism may not perfectly replicate the staticcall behavior of a real contract without a matching function selector.

### A05-6: No test for token returning exactly 0x100 (boundary of too-large check) [INFO]

The assembly check is `gt(readDecimals, 0xff)`, meaning exactly 256 (0x100) should trigger ReadFailure. While `vm.assume(decimals > 0xff)` in fuzz tests will include this value, a concrete test for `decimals = 256` would explicitly document the off-by-one boundary. The current fuzz assumption `decimals > 0xff` correctly excludes 255 and includes 256, so there is no logical error, but the boundary is not explicitly highlighted.

### A05-7: Memory safety of assembly block is not adversarially tested [INFO]

The assembly block writes selector bytes to memory offset 0 (`mstore(0, selector)`) and reads the return value from offset 0 (`mload(0)`). This overwrites the free memory pointer scratch space. The `"memory-safe"` annotation tells the compiler this is safe, which is correct because offsets 0x00-0x3f are designated as scratch space in the Solidity memory layout. While this is architecturally correct and well-understood, there is no test that verifies memory integrity after the call (e.g., confirming the free memory pointer is not corrupted, or that ABI-encoded data before/after the call is not corrupted). This is extremely unlikely to be an issue given the EVM memory model, and is noted purely for completeness.

### A05-8: ReadOnly functions do not test the view modifier enforcement [INFO]

`decimalsForTokenReadOnly` and `safeDecimalsForTokenReadOnly` are `internal view` functions. The tests call them through contracts that use local storage, but do not verify that these functions cannot modify state. This is enforced at the compiler level by the `view` modifier and at the EVM level by `STATICCALL`, so runtime testing is unnecessary. Noted for completeness only.

### A05-9: safeDecimalsForTokenReadOnly Initial path returns read value but does not persist it [INFO]

The `testSafeDecimalsForTokenReadOnlyValidValue` test verifies that calling `safeDecimalsForTokenReadOnly` on an uninitialized token returns the freshly-read decimals value. However, there is no test confirming that after this call, the storage remains uninitialized (i.e., a subsequent call with a different mock value would again return Initial rather than Consistent/Inconsistent). This behavior is guaranteed by the `view` modifier, but the lack of an explicit test means the documented warning in the NatSpec ("Before initialization, each call is a fresh Initial read") is not directly validated in tests.
