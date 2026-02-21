# Audit Pass 3 (Documentation) -- `script/Deploy.sol`

**Auditor:** A01
**Date:** 2026-02-21
**Audit ID:** 2026-02-21-05

## Evidence of Thorough Reading

**File:** `script/Deploy.sol` (33 lines)

### Contract

- `Deploy` (line 15) -- inherits `Script` from `forge-std/Script.sol`

### Functions

| Function | Visibility | Line | NatSpec Present |
|----------|-----------|------|-----------------|
| `run()`  | external  | 19   | Yes (`@notice` at lines 16-18) |

### Types / Errors / Constants

None declared in this file. All types and constants are imported:
- `Script` from `forge-std/Script.sol` (line 5)
- `LibRainDeploy` from `rain.deploy/lib/LibRainDeploy.sol` (line 6)
- `TOFUTokenDecimals` from `../src/concrete/TOFUTokenDecimals.sol` (line 7)
- `LibTOFUTokenDecimals` from `../src/lib/LibTOFUTokenDecimals.sol` (line 8)

### State Variables

None.

## NatSpec Coverage

### Contract-Level Documentation

- `@title Deploy` (line 10): Present.
- `@notice` (lines 11-14): Present. Describes the contract as deploying the `TOFUTokenDecimals` singleton via the Zoltu deterministic factory across all supported networks, requiring `DEPLOYMENT_KEY`.

### Function-Level Documentation

#### `run()` (line 19)

- `@notice` (lines 16-18): Present. Describes reading `DEPLOYMENT_KEY` from the environment and broadcasting `TOFUTokenDecimals` creation code to all supported networks via `LibRainDeploy`.
- `@param`: N/A (no parameters).
- `@return`: N/A (no return value).

## Findings

### A01-P3-DEPLOY-01 [INFO] -- `run()` NatSpec says "broadcasts the `TOFUTokenDecimals` creation code" but the function also passes verification parameters

**Location:** Lines 16-18 (NatSpec), lines 22-31 (implementation)

**Description:** The `@notice` on `run()` states it "broadcasts the `TOFUTokenDecimals` creation code to all supported networks via `LibRainDeploy`." While accurate at a high level, this omits the fact that the call also passes the expected deployment address (`LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT`), expected code hash (`LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH`), the contract path for verification, and an empty dependencies array. The `deployAndBroadcastToSupportedNetworks` function uses these to verify the deployment address and code hash match expectations, and to skip deployment if the contract already exists at the expected address. These are meaningful behaviors not captured in the NatSpec.

This is purely informational since deploy scripts are operational tooling and the NatSpec gives a reasonable summary for its intended audience. No action required.

### A01-P3-DEPLOY-02 [INFO] -- No `@dev` tag documenting the specific `deployAndBroadcastToSupportedNetworks` arguments

**Location:** Lines 22-31

**Description:** The eight arguments passed to `deployAndBroadcastToSupportedNetworks` are:
1. `vm` -- the Foundry VM cheatcode instance
2. `LibRainDeploy.supportedNetworks()` -- the list of supported networks
3. `deployerPrivateKey` -- read from `DEPLOYMENT_KEY` env var
4. `type(TOFUTokenDecimals).creationCode` -- the contract's init code
5. `"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"` -- the contract path for `forge verify-contract`
6. `address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)` -- expected deployment address
7. `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` -- expected runtime code hash
8. `new address[](0)` -- empty dependencies array

A `@dev` block explaining these parameters (especially the empty dependencies and the idempotent skip-if-deployed behavior) could be helpful for operators maintaining the deploy script. However, the code is self-documenting and the function is straightforward, so this is purely informational.

### A01-P3-DEPLOY-03 [INFO] -- Contract-level `@notice` accurately documents the `DEPLOYMENT_KEY` requirement

**Location:** Lines 11-14

**Description:** The `@notice` states the script "Requires the `DEPLOYMENT_KEY` environment variable to be set to the deployer's private key." This is confirmed at line 20: `uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");`. The documentation is accurate.

No issues found.

## Documentation Accuracy Verification

| Claim in NatSpec | Verification | Accurate? |
|------------------|-------------|-----------|
| "Deploys the `TOFUTokenDecimals` singleton" | Line 26: `type(TOFUTokenDecimals).creationCode` is passed as the creation code | Yes |
| "via the Zoltu deterministic factory" | `LibRainDeploy.deployAndBroadcastToSupportedNetworks` internally calls `deployZoltu` which uses `ZOLTU_FACTORY` (confirmed in `LibRainDeploy.sol` line 30) | Yes |
| "across all supported networks" | Line 24: `LibRainDeploy.supportedNetworks()` returns Arbitrum, Base, Flare, Polygon (confirmed in `LibRainDeploy.sol` lines 67-74) | Yes |
| "Requires the `DEPLOYMENT_KEY` environment variable" | Line 20: `vm.envUint("DEPLOYMENT_KEY")` | Yes |
| "Reads `DEPLOYMENT_KEY` from the environment" | Line 20: `vm.envUint("DEPLOYMENT_KEY")` | Yes |
| "broadcasts the `TOFUTokenDecimals` creation code to all supported networks" | Lines 22-31: calls `deployAndBroadcastToSupportedNetworks` with creation code and supported networks | Yes |

## Summary

`script/Deploy.sol` is a minimal 33-line Foundry deploy script with a single external function `run()`. NatSpec coverage is adequate for a deploy script: both the contract and function have `@notice` tags that accurately describe the behavior. All factual claims in the documentation are verified correct against the implementation. The only findings are informational suggestions for additional detail that is not strictly necessary given the script's operational nature and self-documenting code.

**Total findings: 3 (all INFO)**
- 0 CRITICAL
- 0 HIGH
- 0 MEDIUM
- 0 LOW
- 3 INFO
