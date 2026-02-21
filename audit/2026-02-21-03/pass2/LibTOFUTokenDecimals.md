# Pass 2: Test Coverage -- LibTOFUTokenDecimals.sol

Agent: A04

## Evidence of Thorough Reading

### src/lib/LibTOFUTokenDecimals.sol

- **Library**: `LibTOFUTokenDecimals` (lines 21-99)
- **Constants**:
  - `TOFU_DECIMALS_DEPLOYMENT` (line 29): `ITOFUTokenDecimals` constant, hardcoded to `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`
  - `TOFU_DECIMALS_EXPECTED_CODE_HASH` (line 36): `bytes32` constant, `0x1de7d717...`
  - `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (line 43): `bytes` constant, the full init bytecode
- **Error**:
  - `TOFUTokenDecimalsNotDeployed(address deployedAddress)` (line 24)
- **Functions**:
  - `ensureDeployed()` (line 49): `internal view` -- checks code.length > 0 AND codehash matches expected; reverts with `TOFUTokenDecimalsNotDeployed` if either fails
  - `decimalsForTokenReadOnly(address token)` (line 64): `internal view` -- calls `ensureDeployed()` then delegates to `TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token)`; returns `(TOFUOutcome, uint8)`
  - `decimalsForToken(address token)` (line 77): `internal` (state-changing) -- calls `ensureDeployed()` then delegates to `TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)`; returns `(TOFUOutcome, uint8)`
  - `safeDecimalsForToken(address token)` (line 87): `internal` (state-changing) -- calls `ensureDeployed()` then delegates to `TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForToken(token)`; returns `uint8`
  - `safeDecimalsForTokenReadOnly(address token)` (line 95): `internal view` -- calls `ensureDeployed()` then delegates to `TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForTokenReadOnly(token)`; returns `uint8`

### test/src/lib/LibTOFUTokenDecimals.t.sol

Contract: `LibTOFUTokenDecimalsTest`

- `externalEnsureDeployed()` (line 13): helper to call `ensureDeployed` externally
- `externalDecimalsForTokenReadOnly(address)` (line 17): helper wrapper
- `externalDecimalsForToken(address)` (line 21): helper wrapper
- `externalSafeDecimalsForToken(address)` (line 25): helper wrapper
- `externalSafeDecimalsForTokenReadOnly(address)` (line 29): helper wrapper
- `testDeployAddress()` (line 33): verifies Zoltu deploy matches `TOFU_DECIMALS_DEPLOYMENT` constant; also calls `ensureDeployed()`
- `testNotMetamorphic()` (line 47): checks bytecode contains no metamorphic opcodes
- `testNoCBORMetadata()` (line 56): checks bytecode has no CBOR metadata
- `testExpectedCodeHash()` (line 61): deploys `TOFUTokenDecimals` and asserts codehash matches constant
- `testExpectedCreationCode()` (line 67): pure test -- asserts creation code matches constant
- `testEnsureDeployedRevert()` (line 71): expects revert when singleton not deployed (no code at address)
- `testEnsureDeployedRevertWrongCodeHash()` (line 81): etches different code to address, expects revert (wrong codehash)
- `testDecimalsForTokenReadOnlyRevert()` (line 96): expects `TOFUTokenDecimalsNotDeployed` when calling `decimalsForTokenReadOnly` without singleton deployed
- `testDecimalsForTokenRevert()` (line 107): expects `TOFUTokenDecimalsNotDeployed` when calling `decimalsForToken` without singleton deployed
- `testSafeDecimalsForTokenRevert()` (line 118): expects `TOFUTokenDecimalsNotDeployed` when calling `safeDecimalsForToken` without singleton deployed
- `testSafeDecimalsForTokenReadOnlyRevert()` (line 129): expects `TOFUTokenDecimalsNotDeployed` when calling `safeDecimalsForTokenReadOnly` without singleton deployed

### test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol

Contract: `LibTOFUTokenDecimalsDecimalsForTokenTest` (forks in constructor)

- `testDecimalsForTokenAddressZero()` (line 21): address(0) produces ReadFailure with decimals 0
- `testDecimalsForTokenValidValue(uint8 decimalsA, uint8 decimalsB)` (line 27): fuzz -- first call is Initial, second call is Consistent (if same) or Inconsistent (if different); checks returned decimals value
- `testDecimalsForTokenInvalidValueTooLarge(uint256 decimals)` (line 46): fuzz -- values > 0xff produce ReadFailure
- `testDecimalsForTokenInvalidValueTooLargeInitialized(uint8 storedDecimals, uint256 decimals)` (line 55): fuzz -- after initialization, values > 0xff produce ReadFailure with stored decimals returned
- `testDecimalsForTokenInvalidValueNotEnoughData(bytes memory data, uint256 length)` (line 72): fuzz -- return data < 32 bytes produces ReadFailure
- `testDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8 storedDecimals, bytes memory data, uint256 length)` (line 87): fuzz -- after initialization, short return data produces ReadFailure with stored decimals returned
- `testDecimalsForTokenTokenContractRevert()` (line 113): etch revert opcode, produces ReadFailure
- `testDecimalsForTokenTokenContractRevertInitialized(uint8 storedDecimals)` (line 121): fuzz -- after initialization, reverting token produces ReadFailure with stored decimals returned

### test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol

Contract: `LibTOFUTokenDecimalsDecimalsForTokenReadOnlyTest` (forks in constructor)

- `testDecimalsForTokenReadOnlyAddressZero()` (line 21): address(0) produces ReadFailure with decimals 0
- `testDecimalsForTokenReadOnlyValidValue(uint8 decimalsA, uint8 decimalsB)` (line 27): fuzz -- both calls produce Initial (read-only doesn't persist)
- `testDecimalsForTokenReadOnlyConsistentInconsistent(uint8 decimalsA, uint8 decimalsB)` (line 43): fuzz -- after stateful init, read-only sees Consistent or Inconsistent
- `testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals)` (line 65): fuzz -- read-only then stateful still sees Initial from stateful call
- `testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256 decimals)` (line 78): fuzz -- values > 0xff produce ReadFailure
- `testDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8 storedDecimals, uint256 decimals)` (line 87): fuzz -- after stateful init, values > 0xff produce ReadFailure with stored decimals
- `testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes memory data, uint256 length)` (line 104): fuzz -- short return data produces ReadFailure
- `testDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8 storedDecimals, bytes memory data, uint256 length)` (line 118): fuzz -- after stateful init, short return data produces ReadFailure with stored decimals
- `testDecimalsForTokenReadOnlyTokenContractRevert()` (line 142): reverting token produces ReadFailure
- `testDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8 storedDecimals)` (line 150): fuzz -- after stateful init, reverting token produces ReadFailure with stored decimals

### test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol

Contract: `LibTOFUTokenDecimalsSafeDecimalsForTokenTest` (forks in constructor)

- `testSafeDecimalsForTokenAddressZero()` (line 22): address(0) reverts with TokenDecimalsReadFailure/ReadFailure
- `testSafeDecimalsForTokenValidValue(uint8 decimals)` (line 27): fuzz -- valid value returns decimals
- `testSafeDecimalsForTokenConsistentInconsistent(uint8 decimalsA, uint8 decimalsB)` (line 33): fuzz -- second call succeeds if consistent, reverts with Inconsistent if different
- `testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint8 storedDecimals, uint256 decimals)` (line 53): fuzz -- after init, values > 0xff revert with ReadFailure
- `testSafeDecimalsForTokenInvalidValueTooLarge(uint256 decimals)` (line 64): fuzz -- values > 0xff revert with ReadFailure
- `testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(uint8 storedDecimals, bytes memory data, uint256 length)` (line 74): fuzz -- after init, short data reverts with ReadFailure
- `testSafeDecimalsForTokenInvalidValueNotEnoughData(bytes memory data, uint256 length)` (line 94): fuzz -- short data reverts with ReadFailure
- `testSafeDecimalsForTokenContractRevertInitialized(uint8 storedDecimals)` (line 109): fuzz -- after init, reverting token reverts with ReadFailure
- `testSafeDecimalsForTokenContractRevert()` (line 120): reverting token reverts with ReadFailure

### test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol

Contract: `LibTOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest` (forks in constructor)

- `testSafeDecimalsForTokenReadOnlyAddressZero()` (line 22): address(0) reverts with TokenDecimalsReadFailure/ReadFailure
- `testSafeDecimalsForTokenReadOnlyValidValue(uint8 decimals)` (line 27): fuzz -- valid value returns decimals
- `testSafeDecimalsForTokenReadOnlyConsistentInconsistent(uint8 decimalsA, uint8 decimalsB)` (line 33): fuzz -- after stateful init, read-only safe succeeds if consistent, reverts with Inconsistent if different
- `testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint8 storedDecimals, uint256 decimals)` (line 53): fuzz -- after stateful init, values > 0xff revert with ReadFailure
- `testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256 decimals)` (line 66): fuzz -- values > 0xff revert with ReadFailure
- `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(uint8 storedDecimals, bytes memory data, uint256 length)` (line 77): fuzz -- after stateful init, short data reverts with ReadFailure
- `testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes memory data, uint256 length)` (line 97): fuzz -- short data reverts with ReadFailure
- `testSafeDecimalsForTokenReadOnlyContractRevertInitialized(uint8 storedDecimals)` (line 112): fuzz -- after stateful init, reverting token reverts with ReadFailure
- `testSafeDecimalsForTokenReadOnlyContractRevert()` (line 123): reverting token reverts with ReadFailure

### test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol

Contract: `LibTOFUTokenDecimalsRealTokensTest` (forks in constructor)

- `testRealTokenWETH()` (line 31): WETH returns 18 decimals, Initial then Consistent
- `testRealTokenUSDC()` (line 42): USDC returns 6 decimals, Initial then Consistent
- `testRealTokenWBTC()` (line 53): WBTC returns 8 decimals, Initial then Consistent
- `testRealTokenDAI()` (line 64): DAI returns 18 decimals, Initial then Consistent
- `testRealTokenCrossTokenIsolation()` (line 76): initializing WETH and USDC does not cross-contaminate storage

## Coverage Analysis

### `ensureDeployed()` -- WELL COVERED

- **Positive path**: `testDeployAddress()` deploys via Zoltu and then calls `ensureDeployed()` to verify it succeeds. Also implicitly tested by every fork-based test constructor.
- **No code at address**: `testEnsureDeployedRevert()` tests the revert when no contract exists at the singleton address.
- **Wrong codehash**: `testEnsureDeployedRevertWrongCodeHash()` etches different code to the address and verifies the codehash check triggers the revert.
- **Guard on each function**: `testDecimalsForTokenReadOnlyRevert()`, `testDecimalsForTokenRevert()`, `testSafeDecimalsForTokenRevert()`, and `testSafeDecimalsForTokenReadOnlyRevert()` each verify that calling the respective wrapper function reverts with `TOFUTokenDecimalsNotDeployed` when the singleton is not present.

### `TOFU_DECIMALS_DEPLOYMENT` constant -- WELL COVERED

- `testDeployAddress()` explicitly asserts the Zoltu-deployed address equals this constant.
- All fork-based test constructors assert the same.

### `TOFU_DECIMALS_EXPECTED_CODE_HASH` constant -- WELL COVERED

- `testExpectedCodeHash()` deploys a fresh `TOFUTokenDecimals` and asserts its codehash matches the constant.
- `ensureDeployed()` uses this constant and is tested in multiple paths.

### `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant -- WELL COVERED

- `testExpectedCreationCode()` is a pure test that asserts `type(TOFUTokenDecimals).creationCode` matches the constant exactly.

### `TOFUTokenDecimalsNotDeployed` error -- WELL COVERED

- Tested in `testEnsureDeployedRevert()`, `testEnsureDeployedRevertWrongCodeHash()`, and the four function-specific revert tests (`testDecimalsForTokenReadOnlyRevert`, `testDecimalsForTokenRevert`, `testSafeDecimalsForTokenRevert`, `testSafeDecimalsForTokenReadOnlyRevert`).

### `decimalsForToken(address)` -- WELL COVERED

- Initial read with valid value (fuzz)
- Consistent re-read (fuzz)
- Inconsistent re-read (fuzz)
- ReadFailure on address(0) / no code
- ReadFailure on value > 0xff (uninitialized and initialized)
- ReadFailure on short return data (uninitialized and initialized)
- ReadFailure on reverting contract (uninitialized and initialized)
- Real token integration tests (WETH, USDC, WBTC, DAI)

### `decimalsForTokenReadOnly(address)` -- WELL COVERED

- Uninitialized always returns Initial (fuzz)
- After stateful init, returns Consistent or Inconsistent (fuzz)
- Proves read-only does not write storage (`testDecimalsForTokenReadOnlyDoesNotWriteStorage`)
- ReadFailure on address(0)
- ReadFailure on value > 0xff (uninitialized and initialized)
- ReadFailure on short return data (uninitialized and initialized)
- ReadFailure on reverting contract (uninitialized and initialized)

### `safeDecimalsForToken(address)` -- WELL COVERED

- Valid value returns correctly (fuzz)
- Consistent value succeeds, inconsistent value reverts (fuzz)
- address(0) reverts
- value > 0xff reverts (uninitialized and initialized)
- Short data reverts (uninitialized and initialized)
- Reverting contract reverts (uninitialized and initialized)

### `safeDecimalsForTokenReadOnly(address)` -- WELL COVERED

- Valid value returns correctly (fuzz)
- After stateful init, consistent succeeds, inconsistent reverts (fuzz)
- address(0) reverts
- value > 0xff reverts (uninitialized and initialized)
- Short data reverts (uninitialized and initialized)
- Reverting contract reverts (uninitialized and initialized)

## Findings

### A04-1: No test for safeDecimalsForTokenReadOnly proving it does not write storage [LOW]

The `decimalsForTokenReadOnly` test file includes `testDecimalsForTokenReadOnlyDoesNotWriteStorage` which explicitly proves the read-only variant does not persist state (calls read-only then stateful, and the stateful call still sees `Initial`). There is no equivalent test for `safeDecimalsForTokenReadOnly`. While the underlying implementation is the same (both delegate to the `view` function on the singleton), an explicit test would strengthen the guarantee at the library wrapper level that `safeDecimalsForTokenReadOnly` also does not write storage. This is low severity because the Solidity compiler enforces the `view` modifier, making unintended state writes a compiler error, not just a test gap.

### A04-2: No test for ensureDeployed when address has code but extcodehash returns zero-length hash [INFO]

The `ensureDeployed` function checks both `code.length == 0` and `codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH`. The test `testEnsureDeployedRevertWrongCodeHash` covers the case where code exists but the codehash is wrong. However, there is no test for a self-destructed contract where `code.length == 0` but the address slot still exists (post-Cancun, `SELFDESTRUCT` only sends ETH). This is purely informational because on Cancun+ the first condition (`code.length == 0`) covers this case, and the test `testEnsureDeployedRevert` already covers the no-code scenario generically.

### A04-3: Real token tests only exercise decimalsForToken, not other function variants [INFO]

The `realTokens.t.sol` file only tests `LibTOFUTokenDecimals.decimalsForToken` against real mainnet tokens (WETH, USDC, WBTC, DAI). It does not exercise `decimalsForTokenReadOnly`, `safeDecimalsForToken`, or `safeDecimalsForTokenReadOnly` against real tokens. Since these functions all delegate to the same singleton, the real-token validation technically applies transitively. However, adding a single real-token test for each variant would confirm end-to-end behavior through the full library-to-singleton path for all four function signatures.

### A04-4: No test for multiple sequential Inconsistent reads via decimalsForToken [INFO]

The fuzz tests verify that after an Initial read, a second read with a different value returns `Inconsistent`. However, no test verifies what happens when `decimalsForToken` is called a third (or Nth) time with yet another different value. The expected behavior is that the stored value remains the first-read value and all subsequent mismatches return `Inconsistent`, but this is not explicitly tested at the library wrapper level. This is informational because the behavior is a property of the underlying implementation, which has its own test suite.

### A04-5: No negative test for ensureDeployed accepting a correctly-deployed singleton [INFO]

While the constructor of every fork-based test calls `ensureDeployed()` and implicitly asserts it does not revert, there is no explicit test that asserts `ensureDeployed()` succeeds ONLY when both conditions are met (correct code length AND correct codehash). The existing `testDeployAddress` test does call `ensureDeployed()` after a successful Zoltu deployment, which serves as the positive path test. This is purely informational as the positive path is covered, just not with an isolated assertion.

### A04-6: safeDecimalsForTokenReadOnly not tested for behavior when uninitialized (always returns Initial) [LOW]

The `testSafeDecimalsForTokenReadOnlyValidValue` test calls `safeDecimalsForTokenReadOnly` on an uninitialized token and verifies it returns the correct decimals value. However, it does not verify what happens when you call `safeDecimalsForTokenReadOnly` twice without stateful initialization in between -- the second call with a different mock should still succeed (since the token is uninitialized each time, the outcome is `Initial`, which the safe wrapper permits). In contrast, the `decimalsForTokenReadOnly` test file has `testDecimalsForTokenReadOnlyValidValue` that explicitly tests two successive read-only calls and verifies both return `Initial`. Adding a similar multi-call test for `safeDecimalsForTokenReadOnly` would confirm the read-only-safe wrapper does not accidentally reject subsequent uninitialized reads.
