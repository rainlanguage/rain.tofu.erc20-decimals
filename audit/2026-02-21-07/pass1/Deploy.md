# Audit Pass 1 (Security) -- script/Deploy.sol

**Agent:** A05
**Date:** 2026-02-21

## Evidence of thorough reading

**Contract name:** `Deploy` (line 15), inherits `Script` from forge-std.

**Functions:**
- `run()` -- line 19 (external, entry point for the deploy script)

**Imports (lines 5-8):**
1. `{Script}` from `"forge-std/Script.sol"` (line 5)
2. `{LibRainDeploy}` from `"rain.deploy/lib/LibRainDeploy.sol"` (line 6)
3. `{TOFUTokenDecimals}` from `"../src/concrete/TOFUTokenDecimals.sol"` (line 7)
4. `{LibTOFUTokenDecimals}` from `"../src/lib/LibTOFUTokenDecimals.sol"` (line 8)

**File structure:**
- SPDX license: `LicenseRef-DCL-1.0` (line 1)
- Pragma: `=0.8.25` (line 3)
- Single function `run()` reads `DEPLOYMENT_KEY` via `vm.envUint` (line 20), then calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` (lines 22-31) passing: `vm`, `supportedNetworks()`, the private key, `TOFUTokenDecimals` creation code, contract path string, the expected deployed address from `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT`, the expected code hash from `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH`, and an empty dependencies array.

## Security checklist review

### Private key handling

The private key is read from the `DEPLOYMENT_KEY` environment variable via `vm.envUint("DEPLOYMENT_KEY")` at line 20. This is the standard Foundry pattern for deploy scripts. The key is passed to `LibRainDeploy.deployAndBroadcastToSupportedNetworks`, which internally calls `vm.rememberKey(deployerPrivateKey)` and then `vm.startBroadcast(deployer)`. The key is never logged, stored on-chain, or emitted. The CI workflow (`manual-sol-artifacts.yaml`) sets `DEPLOYMENT_KEY` from GitHub secrets (`secrets.PRIVATE_KEY` or `secrets.PRIVATE_KEY_DEV` depending on the branch), which is the expected secure approach.

### Custom errors only

The `Deploy.sol` file itself contains no `revert` statements at all. All error handling is delegated to `LibRainDeploy`, which uses custom errors exclusively: `DeployFailed`, `MissingDependency`, `UnexpectedDeployedAddress`, `UnexpectedDeployedCodeHash`. No string-based reverts are present.

### Hardcoded secrets

No hardcoded secrets, keys, or credentials exist in the file. The only hardcoded values are the expected deployment address and code hash, which are public on-chain constants sourced from `LibTOFUTokenDecimals`.

## Findings

No findings.

The deploy script is minimal and delegates all logic to `LibRainDeploy`. It follows the standard Foundry deploy script pattern, reads the private key exclusively from environment variables (sourced from GitHub secrets in CI), contains no string reverts, and has no hardcoded secrets. The post-deployment verification of address and code hash in `LibRainDeploy.deployAndBroadcastToSupportedNetworks` (lines 129-135 of `LibRainDeploy.sol`) provides defence-in-depth against deployment anomalies. The workflow is gated behind `workflow_dispatch`, preventing accidental automated deployments.
