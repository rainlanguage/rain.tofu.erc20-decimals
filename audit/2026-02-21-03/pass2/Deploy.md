# Pass 2: Test Coverage -- Deploy.sol

Agent: A01

## Evidence of Thorough Reading

### script/Deploy.sol
- **Contract**: `Deploy` (extends `Script`), lines 10-25
- **Functions**:
  - `run()` -- line 11, external. Reads `DEPLOYMENT_KEY` from environment (line 12), then calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` (line 14) passing:
    - `vm` cheatcode interface
    - `LibRainDeploy.supportedNetworks()` for the network list
    - `deployerPrivateKey` from the env var
    - `type(TOFUTokenDecimals).creationCode` as the init bytecode
    - `"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"` as the contract identifier string
    - `address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)` as the expected deployed address
    - `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` as the expected code hash
    - `new address[](0)` as an empty dependencies array

## Test Files Found

There are **no direct tests** for `script/Deploy.sol`. No test file imports the `Deploy` contract, instantiates it, or calls `run()`.

However, the following test files indirectly exercise the **same constants, creation code, and deployment logic** that `Deploy.sol` relies on:

1. `test/src/lib/LibTOFUTokenDecimals.t.sol`
   - `testDeployAddress()` (line 33): Deploys via `LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode)` on a fork and asserts the resulting address matches `TOFU_DECIMALS_DEPLOYMENT`.
   - `testExpectedCodeHash()` (line 61): Asserts the deployed runtime code hash matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.
   - `testExpectedCreationCode()` (line 67): Asserts `type(TOFUTokenDecimals).creationCode` matches `TOFU_DECIMALS_EXPECTED_CREATION_CODE`.
   - `testNotMetamorphic()` (line 47): Ensures singleton code has no metamorphic opcodes.
   - `testNoCBORMetadata()` (line 56): Ensures singleton code has no CBOR metadata.

2. Multiple test files use the same deployment pattern in their `constructor()` (fork + `deployZoltu` + `assertEq` on address + `ensureDeployed()`):
   - `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol`

Additionally, the CI workflow `.github/workflows/manual-sol-artifacts.yaml` (line 34) runs the deploy script directly via `forge script script/Deploy.sol:Deploy -vvvvv --slow --broadcast --verify`, but this is a `workflow_dispatch` (manually triggered) pipeline, not an automated CI test.

## Findings

### A01-1: No direct test for Deploy.run() [LOW]

**Description**: The `Deploy` contract's `run()` function has zero direct test coverage. No test file imports `Deploy`, calls `run()`, or exercises the script's integration with `LibRainDeploy.deployAndBroadcastToSupportedNetworks`.

**What is indirectly covered**: The individual arguments passed to `deployAndBroadcastToSupportedNetworks` are well-validated by existing tests:
- `type(TOFUTokenDecimals).creationCode` is verified in `testExpectedCreationCode()`.
- The expected deployment address is verified in `testDeployAddress()` via Zoltu deployment on a fork.
- The expected code hash is verified in `testExpectedCodeHash()`.
- The `ensureDeployed()` guard is tested for both positive and negative cases.

**What is NOT covered**:
- The `deployAndBroadcastToSupportedNetworks` call itself (multi-network iteration, broadcasting, verification flow).
- Reading `DEPLOYMENT_KEY` from the environment (the `vm.envUint` call).
- The empty dependencies array `new address[](0)`.
- The contract identifier string `"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"`.

**Mitigating factors**: Deploy scripts are conventionally not unit-tested in Foundry projects. The manual CI workflow exercises the full flow. The script is only 25 lines with a single function that delegates entirely to a library. The critical invariants (address, code hash, creation code) are all independently verified.

**Risk**: A typo in the contract identifier string would cause verification failures (not a security issue, only an operational annoyance). A change to `LibRainDeploy.supportedNetworks()` could add or remove networks silently, but this is controlled by the dependency and not this script's responsibility.

### A01-2: Deploy script only exercised via manual workflow_dispatch [INFO]

**Description**: The only CI execution of `Deploy.sol` is in `.github/workflows/manual-sol-artifacts.yaml`, which is triggered by `workflow_dispatch` (manual trigger only, line 3). This means the deploy script is never automatically tested as part of the regular CI pipeline (e.g., on push or PR).

**Impact**: If a code change breaks the deploy script's compilation or the constants it references, the failure will not be caught until someone manually triggers the deployment workflow. Since `forge build` compiles all Solidity files including scripts, compilation errors would be caught by the standard build step. However, runtime failures (e.g., mismatched constants after a redeployment) would not.

**Mitigating factors**: The `testExpectedCreationCode` and `testExpectedCodeHash` tests in the automated test suite would catch any constant drift at compile time, since they compare the same constants the deploy script uses. The `testDeployAddress` test on fork would catch address mismatches.
