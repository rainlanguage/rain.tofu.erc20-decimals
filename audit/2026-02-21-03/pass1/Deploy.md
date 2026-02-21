# Pass 1: Security — Deploy.sol

Agent: A01

## Evidence of Thorough Reading

### script/Deploy.sol
- **Contract**: `Deploy` (inherits `Script` from forge-std), lines 10-25
- **Functions**:
  - `run()` — external, line 11. Reads `DEPLOYMENT_KEY` from environment, then calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with the TOFUTokenDecimals creation code, expected deployment address, expected code hash, and an empty dependencies array.
- **Types/Errors/Constants**: None defined in this file. Uses imported constants:
  - `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT` (address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`)
  - `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` (bytes32 `0x1de7...d41`)
  - `type(TOFUTokenDecimals).creationCode` — compiler-generated creation bytecode

### Imports examined (src/ files):
- `src/concrete/TOFUTokenDecimals.sol` — contract with `sTOFUTokenDecimals` mapping, four external functions delegating to `LibTOFUTokenDecimalsImplementation`
- `src/lib/LibTOFUTokenDecimals.sol` — library with `TOFU_DECIMALS_DEPLOYMENT` constant, `TOFU_DECIMALS_EXPECTED_CODE_HASH` constant, `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant, `TOFUTokenDecimalsNotDeployed` error, and five functions (`ensureDeployed`, `decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`)
- `src/interface/ITOFUTokenDecimals.sol` — `TOFUTokenDecimalsResult` struct, `TOFUOutcome` enum, `TokenDecimalsReadFailure` error, `ITOFUTokenDecimals` interface with four functions

### External dependency examined:
- `lib/rain.deploy/src/lib/LibRainDeploy.sol` — `deployAndBroadcastToSupportedNetworks` iterates over networks, checks dependencies (Zoltu factory + any passed dependencies), then deploys via Zoltu or skips if code already exists at expected address, verifies deployed address and code hash match expectations.

## Findings

### A01-1: Private key read from environment variable [INFO]

**Location**: `script/Deploy.sol`, line 12

```solidity
uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
```

The deployment script reads a private key from the `DEPLOYMENT_KEY` environment variable. This is standard practice for Foundry deployment scripts and is the expected pattern. The key is not hardcoded in the source, which is correct. However, operators must ensure:
1. The environment variable is not logged or persisted in CI artifacts.
2. The key is not committed to `.env` files tracked by git.

This is informational only as the pattern itself is correct for Foundry scripts.

### A01-2: No access control on `run()` function [INFO]

**Location**: `script/Deploy.sol`, line 11

```solidity
function run() external {
```

The `run()` function is `external` with no access modifiers (e.g., `onlyOwner`). This is standard and expected for Foundry scripts -- `Script` contracts are never deployed on-chain; they are executed locally via `forge script`. The `vm.startBroadcast` inside `LibRainDeploy` gates the actual on-chain transaction to the deployer key holder. No issue in practice.

### A01-3: Empty dependencies array passed to deployment [INFO]

**Location**: `script/Deploy.sol`, line 22

```solidity
new address[](0)
```

The deploy call passes an empty dependencies array. This is correct for `TOFUTokenDecimals` since it has no on-chain dependencies other than the Zoltu factory (which `LibRainDeploy` checks automatically). The Zoltu factory presence is verified in `deployAndBroadcastToSupportedNetworks` at line 104 of `LibRainDeploy.sol`. No missing dependency checks.

No security findings.

The deploy script is a straightforward Foundry script that:
1. Reads a deployer private key from an environment variable (standard pattern).
2. Delegates entirely to `LibRainDeploy.deployAndBroadcastToSupportedNetworks`, which handles fork creation, dependency validation, Zoltu deployment, address verification, and code hash verification.
3. Uses compiler-derived `type(TOFUTokenDecimals).creationCode` ensuring the deployed bytecode matches the source.
4. Passes hardcoded expected address and code hash constants from `LibTOFUTokenDecimals`, providing deterministic deployment verification.

The script contains no custom logic, no assembly, no arithmetic, no reentrancy surface, no error handling gaps, and no hardcoded secrets. All validation (address matching, code hash matching, Zoltu factory existence) is handled by the deployment library.
