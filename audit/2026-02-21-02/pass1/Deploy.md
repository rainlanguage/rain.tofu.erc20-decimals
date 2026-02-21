# Security Audit: `script/Deploy.sol`

**Audit ID:** 2026-02-21-02, Pass 1 (Security)
**Agent:** A01
**File:** `script/Deploy.sol`

---

## Evidence of Thorough Reading

### Contract/Library

- **Contract:** `Deploy` (inherits `Script` from forge-std), lines 10-25

### Functions

| Function | Line |
|----------|------|
| `run()` (external) | 11 |

### Imports

| Import | Source | Line |
|--------|--------|------|
| `Script` | `forge-std/Script.sol` | 5 |
| `LibRainDeploy` | `rain.deploy/lib/LibRainDeploy.sol` | 6 |
| `TOFUTokenDecimals` | `../src/concrete/TOFUTokenDecimals.sol` | 7 |
| `LibTOFUTokenDecimals` | `../src/lib/LibTOFUTokenDecimals.sol` | 8 |

### Types/Errors/Constants Referenced

- `LibRainDeploy.deployAndBroadcastToSupportedNetworks` (from `rain.deploy`)
- `LibRainDeploy.supportedNetworks()` (from `rain.deploy`)
- `type(TOFUTokenDecimals).creationCode` (compile-time creation code)
- `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT` (constant: `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`)
- `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` (constant: `0x1de7d717...`)

### Imported File Analysis

- **`LibRainDeploy.sol`**: Reviewed `deployAndBroadcastToSupportedNetworks` (lines 83-145), `deployZoltu` (lines 48-63), `supportedNetworks` (lines 67-74). The deploy library reads the deployer key via `vm.rememberKey`, checks dependencies exist on each network, deploys via the Zoltu factory (or skips if already deployed), then verifies the deployed address and code hash match expectations.
- **`LibTOFUTokenDecimals.sol`**: Reviewed constants `TOFU_DECIMALS_DEPLOYMENT` (line 29-30) and `TOFU_DECIMALS_EXPECTED_CODE_HASH` (line 36-37).
- **`TOFUTokenDecimals.sol`**: The concrete contract whose `creationCode` is used for deployment.
- **`foundry.toml`**: Verified bytecode determinism settings: `solc = "0.8.25"`, `evm_version = "cancun"`, `optimizer = true`, `optimizer_runs = 1000000`, `bytecode_hash = "none"`, `cbor_metadata = false`.

---

## Findings

### LOW-01: Private key read from environment variable without zeroing

**Severity:** LOW
**Location:** Line 12

```solidity
uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
```

The deployer private key is read from the `DEPLOYMENT_KEY` environment variable and stored in a local `uint256`. There is no mechanism to zero or clear this value after use. In the context of a Foundry script, this is the standard pattern and the private key will also persist in the Foundry VM's internal state via `vm.rememberKey` (called inside `LibRainDeploy`). While this is expected behavior for Foundry deployment scripts, it means the key persists in process memory for the lifetime of the script execution.

This is noted as LOW because: (1) this is the standard Foundry pattern with no practical alternative within Solidity, and (2) deployment scripts are typically run in controlled environments. However, operators should be aware that the key remains in process memory and should ensure the execution environment is appropriately secured.

---

### INFO-01: Script relies entirely on `LibRainDeploy` for deployment integrity checks

**Severity:** INFO
**Location:** Lines 14-23

The `Deploy` script delegates all deployment logic -- including address verification, code hash verification, dependency checking, and Zoltu factory interaction -- to `LibRainDeploy.deployAndBroadcastToSupportedNetworks`. The review of `LibRainDeploy` confirms it performs the following checks:

1. Verifies the Zoltu factory exists on each target network (line 104 of LibRainDeploy)
2. Verifies all dependencies exist on each target network (lines 108-113 of LibRainDeploy)
3. Skips deployment if code already exists at the expected address (line 121 of LibRainDeploy)
4. Verifies the deployed address matches `expectedAddress` (lines 129-131 of LibRainDeploy)
5. Verifies the deployed code hash matches `expectedCodeHash` (lines 133-135 of LibRainDeploy)

These are appropriate checks. The script correctly passes `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT` and `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` as the expected values, ensuring consistency between the deployment script and the library that consumers use.

---

### INFO-02: Empty dependencies array is correct for this contract

**Severity:** INFO
**Location:** Line 22

```solidity
new address[](0)
```

The script passes an empty dependencies array. This is correct because `TOFUTokenDecimals` has no external contract dependencies -- it is a self-contained contract that only uses internal library logic and its own storage. It does not call any other deployed contracts.

---

### INFO-03: `foundry.toml` bytecode determinism settings are consistent with `CLAUDE.md` requirements

**Severity:** INFO
**Location:** `foundry.toml` lines 8-9, 18-19, 21-22

Verified that all bytecode determinism settings match the documented requirements:
- `solc = "0.8.25"` (matches `=0.8.25` pragma in `TOFUTokenDecimals.sol`)
- `evm_version = "cancun"` (documented in CLAUDE.md)
- `optimizer = true` with `optimizer_runs = 1000000` (documented as 1M runs)
- `bytecode_hash = "none"` (documented)
- `cbor_metadata = false` (documented)

Note: `foundry.toml` uses `solc = "0.8.25"` (without the `=` prefix), which Foundry interprets as an exact version specifier. The `Deploy.sol` script itself also uses `pragma solidity =0.8.25;` on line 3, which is consistent. The concrete contract `TOFUTokenDecimals.sol` uses the same exact pragma. These are all aligned.

---

## Summary

`script/Deploy.sol` is a minimal 25-line Foundry deployment script with a single external function `run()`. It reads a deployer private key from the environment and delegates to `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with the correct creation code, expected address, expected code hash, and an empty dependencies array.

No CRITICAL, HIGH, or MEDIUM findings were identified. The script correctly leverages the existing deployment infrastructure and passes the appropriate constants from `LibTOFUTokenDecimals` to ensure the deployed contract matches what consumers of the library expect. The bytecode determinism settings in `foundry.toml` are verified to be consistent with the project's documented requirements.

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 1 |
| INFO     | 3 |
