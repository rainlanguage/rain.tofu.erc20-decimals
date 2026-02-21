<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Security Audit Pass 1 — `script/Deploy.sol`

**Auditor:** A01
**Date:** 2026-02-21
**Pass:** 1 (Security)
**File:** `script/Deploy.sol`

---

## Evidence of Thorough Reading

### Contract / Library Names

| Name | Kind | File |
|------|------|------|
| `Deploy` | `contract` (extends `Script`) | `script/Deploy.sol` line 15 |

### Functions / Methods with Line Numbers

| Name | Visibility | Mutability | Line |
|------|-----------|------------|------|
| `run` | `external` | (none, state-mutating) | 19 |

### Types Defined in This File

None — no custom types, structs, or enums are defined in `script/Deploy.sol` itself.

### Errors Defined in This File

None.

### Constants Defined in This File

None.

### Imported Symbols Used

| Symbol | Source |
|--------|--------|
| `Script` | `forge-std/Script.sol` |
| `LibRainDeploy` | `rain.deploy/lib/LibRainDeploy.sol` |
| `TOFUTokenDecimals` | `src/concrete/TOFUTokenDecimals.sol` |
| `LibTOFUTokenDecimals` | `src/lib/LibTOFUTokenDecimals.sol` |

### Referenced Identifiers from `LibRainDeploy`

| Symbol | Value / Purpose |
|--------|----------------|
| `LibRainDeploy.deployAndBroadcastToSupportedNetworks` | Core deployment dispatcher |
| `LibRainDeploy.supportedNetworks()` | Returns `["arbitrum","base","flare","polygon"]` |

### Referenced Identifiers from `LibTOFUTokenDecimals`

| Symbol | Value / Purpose |
|--------|----------------|
| `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT` | Hard-coded singleton address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` |
| `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH` | `0x1de7d717...` — expected runtime codehash |

---

## Security Findings

### F-01 — Private Key Sourced from Environment Variable Without Validation

**Severity:** INFO

**Location:** `script/Deploy.sol` line 20

```solidity
uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
```

**Description:**
`vm.envUint` will revert if `DEPLOYMENT_KEY` is not set or cannot be parsed as a `uint256`. This is correct defensive behaviour for a Foundry script and is expected. However, there is no validation that the value is non-zero or that it lies in the valid secp256k1 scalar range (1 to n-1). A value of `0` would map to the zero private key and `vm.rememberKey` / `vm.startBroadcast` inside `LibRainDeploy` would use an address derived from it. In practice `vm.rememberKey(0)` in forge will typically revert or produce an unexpected address, so exploitation requires misconfiguration rather than an attack by an adversary.

**Recommendation:**
This is a deployment script, not a production contract, so the risk is limited. The current behaviour is acceptable. An optional defensive check `require(deployerPrivateKey != 0, "zero key")` would make the failure mode explicit, but it is not strictly necessary.

---

### F-02 — No Findings Beyond INFO

No CRITICAL, HIGH, MEDIUM, or LOW security issues were identified in `script/Deploy.sol`.

**Rationale:**

1. **Scope is a Foundry `Script`, not a production contract.** The file is only executed by a trusted operator via `forge script`; it never runs on-chain. There are no user-facing entry points, no on-chain state owned by this contract, and no assets held here.

2. **Access control.** There is exactly one function (`run`), it is `external` (required by Foundry's Script runner), and the private key is read from the local environment — not from calldata or storage. An adversary who can call this function on-chain would be running it in an invalid context (no `vm` cheatcodes available) and the call would revert immediately.

3. **Memory safety.** No assembly is present in `script/Deploy.sol` itself. The assembly in the transitively called `LibRainDeploy.deployZoltu` is annotated `memory-safe` and uses only scratch-space slot 0 for the 20-byte return address (written at offset 12 into a 32-byte word, then read back at slot 0 — correct).

4. **Reentrancy.** Not applicable. No ETH is held; no callbacks are possible from within a Foundry script execution.

5. **Arithmetic.** No arithmetic is performed in `script/Deploy.sol`.

6. **Error handling.** Failure propagation is handled inside `LibRainDeploy` (reverts on deploy failure, address mismatch, and codehash mismatch). `script/Deploy.sol` itself does not suppress or swallow errors.

7. **Codehash verification.** `LibRainDeploy.deployAndBroadcastToSupportedNetworks` verifies both the deployed address and the runtime codehash against the constants in `LibTOFUTokenDecimals`. This prevents silent deployment to a wrong address or with wrong bytecode.

8. **Re-deployment idempotency.** `LibRainDeploy` skips re-deployment if code already exists at the expected address, which prevents bricking existing users of the singleton.

9. **SPDX header.** Present and correct (`LicenseRef-DCL-1.0`).

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 0 |
| INFO     | 1 (F-01: unvalidated private key value — deployment script only) |
