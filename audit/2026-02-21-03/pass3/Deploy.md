# Pass 3: Documentation — Deploy.sol

Agent: A01

## Evidence of Thorough Reading

**File**: `script/Deploy.sol` (25 lines)

**License header**: `LicenseRef-DCL-1.0` (line 1), copyright notice (line 2)

**Pragma**: `=0.8.25` (line 3) -- exact version, consistent with bytecode determinism requirement

**Imports** (lines 5-8):
- `Script` from `forge-std/Script.sol`
- `LibRainDeploy` from `rain.deploy/lib/LibRainDeploy.sol`
- `TOFUTokenDecimals` from `../src/concrete/TOFUTokenDecimals.sol`
- `LibTOFUTokenDecimals` from `../src/lib/LibTOFUTokenDecimals.sol`

**Contract**: `Deploy` (line 10), inherits `Script`

**Functions**:
- `run()` (line 11) -- `external`, no parameters, no return value

**Types/Errors/Constants**: None declared in this file. References external constants:
- `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT` (the singleton address)
- `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` (expected codehash)

**Implementation details** (lines 12-23):
- Reads `DEPLOYMENT_KEY` from environment via `vm.envUint` (line 12)
- Calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with 8 arguments:
  1. `vm` -- the Foundry VM cheatcode interface
  2. `LibRainDeploy.supportedNetworks()` -- list of target networks
  3. `deployerPrivateKey` -- from env
  4. `type(TOFUTokenDecimals).creationCode` -- init bytecode
  5. `"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"` -- contract path for verification
  6. `address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)` -- expected deployed address
  7. `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` -- expected codehash
  8. `new address[](0)` -- empty dependencies array

## Findings

### A01-1: No NatSpec on Deploy contract or run() function [LOW]

The `Deploy` contract (line 10) has no `@title` or `@notice` NatSpec comment. The `run()` function (line 11) has no NatSpec documentation whatsoever -- no `@notice`, no description of what it does, no mention of the required `DEPLOYMENT_KEY` environment variable, and no documentation of its side effects (deploying `TOFUTokenDecimals` to all supported networks via Zoltu).

For a deployment script, the environment variable requirement (`DEPLOYMENT_KEY`) is particularly important to document since a missing or incorrect key will cause runtime failure. While deployment scripts are less critical than library code for NatSpec, this is an operational script that operators need to understand.

**Recommendation**: Add at minimum a `@title` and `@notice` to the contract, and a `@notice` to `run()` that documents:
- The purpose (deploy `TOFUTokenDecimals` singleton to all supported networks)
- The required environment variable (`DEPLOYMENT_KEY`)
- That it uses the Zoltu deterministic factory for reproducible addresses

### A01-2: Return value of deployAndBroadcastToSupportedNetworks is silently discarded [INFO]

The call to `LibRainDeploy.deployAndBroadcastToSupportedNetworks` (line 14) returns `address deployedAddress` but this return value is silently discarded. While this is not a bug (the function internally validates the deployed address matches `expectedAddress` and reverts on mismatch), the discarded return value is undocumented. A brief inline comment explaining why the return value is intentionally ignored would improve clarity, or the function could capture and log the deployed address for operator visibility.
