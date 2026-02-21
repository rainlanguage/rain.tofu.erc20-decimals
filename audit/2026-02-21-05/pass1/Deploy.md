# Audit Pass 1 (Security) - `script/Deploy.sol`

**Auditor:** A01
**Date:** 2026-02-21
**File:** `script/Deploy.sol` (33 lines)

## Evidence of Thorough Reading

### Contract

- **`Deploy`** (line 15) -- inherits `Script` from `forge-std`

### Functions

| Function | Line | Visibility | Mutability |
|----------|------|------------|------------|
| `run()` | 19 | `external` | non-view (state-changing via broadcast) |

### Imports (lines 5-8)

- `Script` from `forge-std/Script.sol`
- `LibRainDeploy` from `rain.deploy/lib/LibRainDeploy.sol`
- `TOFUTokenDecimals` from `../src/concrete/TOFUTokenDecimals.sol`
- `LibTOFUTokenDecimals` from `../src/lib/LibTOFUTokenDecimals.sol`

### Types / Errors / Constants Referenced

- No custom errors, events, or constants defined within this file.
- Uses `type(TOFUTokenDecimals).creationCode` (compile-time constant).
- References `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT` (the expected deployed address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`).
- References `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` (the expected runtime code hash `0x1de7d71...`).

### Pragma

- `pragma solidity =0.8.25;` (line 3) -- exact version pin, matching the concrete contract and `foundry.toml`.

### License

<!-- REUSE-IgnoreStart -->
- `SPDX-License-Identifier: LicenseRef-DCL-1.0` (line 1) -- compliant with project requirements.
<!-- REUSE-IgnoreEnd -->

## Security Review

### Checklist Results

#### Memory Safety
No direct memory manipulation in this file. The `run()` function allocates only a `uint256` on the stack and passes compile-time constants and an empty dynamic array (`new address[](0)`) to `LibRainDeploy`. The underlying `deployZoltu` in `LibRainDeploy` uses assembly marked `memory-safe`, which was reviewed for correctness during this pass. No issues found.

#### Input Validation
The script reads `DEPLOYMENT_KEY` via `vm.envUint("DEPLOYMENT_KEY")` (line 20). Foundry's `vm.envUint` will revert if the environment variable is unset or not parseable as a `uint256`. This is adequate validation for a deployment script context. No additional input is accepted.

#### Access Controls
This is a Foundry script, not a deployed contract. Access control is enforced externally by whoever holds the `DEPLOYMENT_KEY`. The script itself has no on-chain access control, which is correct for a deploy script -- the Zoltu factory is permissionless and anyone can deploy.

#### Reentrancy
Not applicable. The script makes a single external call flow via `LibRainDeploy.deployAndBroadcastToSupportedNetworks`, which interacts only with the Zoltu factory. No callback vectors exist.

#### Arithmetic Safety
Only a `uint256` private key is used. No arithmetic operations are performed in this file.

#### Error Handling
Error handling is delegated to `LibRainDeploy`, which defines and uses custom errors (`DeployFailed`, `MissingDependency`, `UnexpectedDeployedAddress`, `UnexpectedDeployedCodeHash`). The script itself has no revert statements, which is appropriate since the library handles all failure modes. No revert strings are used anywhere -- custom errors only.

#### Assembly Safety
No assembly in this file. The downstream `LibRainDeploy.deployZoltu` uses assembly to call the Zoltu factory, annotated as `memory-safe`, and was reviewed. The assembly writes the return data (deployed address) to scratch space and reads it back correctly.

#### Bytecode Determinism (Project-Specific)

This is the most critical concern for this file. Analysis:

1. **Pragma pin:** `=0.8.25` matches both the concrete contract and `foundry.toml` setting (`solc = "0.8.25"`). Correct.
2. **Creation code source:** Uses `type(TOFUTokenDecimals).creationCode` which is derived at compile time from the concrete contract. This is the standard Foundry/Solidity way to get deterministic creation code.
3. **Expected address and code hash:** Passed from `LibTOFUTokenDecimals` constants. `LibRainDeploy.deployAndBroadcastToSupportedNetworks` verifies both post-deployment (lines 129-135 of LibRainDeploy.sol), reverting with `UnexpectedDeployedAddress` or `UnexpectedDeployedCodeHash` on mismatch.
4. **Compiler settings in foundry.toml:** `bytecode_hash = "none"`, `cbor_metadata = false`, `optimizer_runs = 1000000`, `evm_version = "cancun"` -- all match CLAUDE.md requirements.
5. **Idempotent deployment:** `LibRainDeploy` checks if code already exists at the expected address before deploying (line 121), skipping the Zoltu call if so. This is safe and prevents double-deploy errors.

No bytecode determinism issues found.

#### Dependency Verification
The script passes `new address[](0)` as the dependencies array (line 30), meaning no on-chain dependencies are checked beyond the Zoltu factory itself. This is correct because `TOFUTokenDecimals` is a standalone contract with no external dependencies at deployment time.

## Findings

### A01-1: No findings of severity CRITICAL, HIGH, or MEDIUM

The deploy script is minimal, well-structured, and delegates all complex logic to the audited `LibRainDeploy` library. It correctly:
- Pins the exact Solidity version for deterministic compilation.
- Uses compile-time creation code.
- Validates expected address and code hash post-deployment.
- Handles the already-deployed (idempotent) case.
- Reads the private key securely from the environment.

### A01-2: Private key exposure via environment variable (INFO)

**Severity:** INFO

**Location:** `script/Deploy.sol`, line 20

```solidity
uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
```

**Description:** The deployer private key is read from the `DEPLOYMENT_KEY` environment variable. This is standard practice for Foundry deploy scripts and is not a vulnerability in the code itself. However, operational security depends on the CI/CD environment properly securing this variable (e.g., using GitHub Actions secrets, not logging it). This is purely an operational concern, not a code-level issue.

**Recommendation:** No code change needed. Ensure CI/CD pipelines treat `DEPLOYMENT_KEY` as a masked secret.

### A01-3: `vm.rememberKey` stores key in Foundry's wallet for session duration (INFO)

**Severity:** INFO

**Location:** `lib/rain.deploy/src/lib/LibRainDeploy.sol`, line 93 (called from Deploy.sol)

```solidity
address deployer = vm.rememberKey(deployerPrivateKey);
```

**Description:** `vm.rememberKey` adds the private key to Foundry's in-memory wallet for the duration of the script execution. The key is used for `vm.startBroadcast(deployer)`. This is the standard Foundry pattern. The key persists only in memory for the script's lifetime and is not written to disk. No issue, noted for completeness.

### A01-4: No explicit gas limit or value controls on Zoltu factory call (INFO)

**Severity:** INFO

**Location:** `lib/rain.deploy/src/lib/LibRainDeploy.sol`, line 53 (downstream of Deploy.sol)

```solidity
success := call(gas(), zoltuFactory, 0, add(creationCode, 0x20), mload(creationCode), 12, 20)
```

**Description:** The Zoltu factory call forwards all remaining gas via `gas()` and sends zero value. Forwarding all gas is appropriate here since the factory needs enough gas to deploy the contract, and the call sends no ETH (value = 0). The return data is read from offset 12 for length 20 (an address), which matches the Zoltu factory's return format. No issue, noted for completeness.

## Summary

The `script/Deploy.sol` file is a clean, minimal Foundry deployment script with no security vulnerabilities. It correctly delegates to `LibRainDeploy` which provides robust post-deployment verification (address match, code hash match, dependency checks). Bytecode determinism constraints are satisfied through the exact pragma pin and `foundry.toml` settings. All findings are informational.

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |
| INFO | 3 |
