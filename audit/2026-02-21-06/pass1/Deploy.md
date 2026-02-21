# Pass 1: Security — Deploy.sol (Agent A05)

## Evidence of Reading

**File**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/script/Deploy.sol` (33 lines)

**Contract**: `Deploy` (line 15), inherits `Script` (from forge-std)

**Functions**:
- `run()` — external, line 19

**Types/Errors/Constants defined in this file**: None

**Imports**:
- `Script` from `forge-std/Script.sol` (line 5)
- `LibRainDeploy` from `rain.deploy/lib/LibRainDeploy.sol` (line 6)
- `TOFUTokenDecimals` from `../src/concrete/TOFUTokenDecimals.sol` (line 7)
- `LibTOFUTokenDecimals` from `../src/lib/LibTOFUTokenDecimals.sol` (line 8)

**Key details of `run()`**:
- Line 20: Reads `DEPLOYMENT_KEY` from environment via `vm.envUint`
- Lines 22-31: Calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with:
  - `vm` (Foundry cheatcode interface)
  - `LibRainDeploy.supportedNetworks()` (hardcoded list of 4 networks)
  - `deployerPrivateKey` (from env)
  - `type(TOFUTokenDecimals).creationCode` (compile-time creation code)
  - String literal for contract path verification
  - `address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)` (expected deployed address constant)
  - `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` (expected code hash constant)
  - `new address[](0)` (empty dependencies array)

## Findings

No findings.

The script is a straightforward Foundry deployment script that:

1. Reads the private key solely from an environment variable (`DEPLOYMENT_KEY`), which is the standard and expected pattern for Foundry scripts. The key is never hardcoded or logged.
2. Delegates all deployment logic to `LibRainDeploy.deployAndBroadcastToSupportedNetworks`, which performs thorough post-deployment verification (address match check via `UnexpectedDeployedAddress`, code hash match check via `UnexpectedDeployedCodeHash`, and deployment success check via `DeployFailed`).
3. All error paths in the deployment library use custom errors (no string reverts).
4. The expected address and code hash are sourced from compile-time constants in `LibTOFUTokenDecimals`, which are the same values used by runtime callers, ensuring consistency between deployment expectations and runtime expectations.
5. The script has no access control concerns because it is an off-chain Foundry script (not a deployed contract), and the deployed `TOFUTokenDecimals` contract itself is permissionless (no owner, no admin functions).
6. The empty dependencies array is intentional since `TOFUTokenDecimals` has no on-chain dependencies beyond the Zoltu factory (which is checked by `LibRainDeploy` itself).
