<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 3 — Documentation Review: `script/Deploy.sol`

Audit date: 2026-02-21
Auditor: A01

---

## Evidence of Thorough Reading

### Contract Name

- `Deploy` (line 15), inherits `forge-std/Script.sol`

### Functions

| Function | Visibility | Line |
|----------|------------|------|
| `run()` | `external` | 19 |

No modifiers, constructors, fallback, or receive functions are present.

### Types Defined

None. No structs, enums, errors, events, or type aliases are defined in this file.

### Constants Defined

None. All constants are imported from `LibTOFUTokenDecimals` and `LibRainDeploy`.

### Imports

| Symbol | Source |
|--------|--------|
| `Script` | `forge-std/Script.sol` |
| `LibRainDeploy` | `rain.deploy/lib/LibRainDeploy.sol` |
| `TOFUTokenDecimals` | `../src/concrete/TOFUTokenDecimals.sol` |
| `LibTOFUTokenDecimals` | `../src/lib/LibTOFUTokenDecimals.sol` |

---

## Documentation Review

### Contract-Level NatSpec

```solidity
/// @title Deploy
/// @notice Deploys the `TOFUTokenDecimals` singleton via the Zoltu
/// deterministic factory across all supported networks. Requires the
/// `DEPLOYMENT_KEY` environment variable to be set to the deployer's private
/// key.
```

Both `@title` and `@notice` are present. The notice accurately describes:
- The subject (deploying the `TOFUTokenDecimals` singleton)
- The mechanism (Zoltu deterministic factory)
- The scope (all supported networks)
- The prerequisite (`DEPLOYMENT_KEY` environment variable)

No `@dev` or `@author` tag is present; neither is required by convention for this codebase.

### Function-Level NatSpec: `run()`

```solidity
/// @notice Entry point for the deploy script. Reads `DEPLOYMENT_KEY` from
/// the environment and broadcasts the `TOFUTokenDecimals` creation code to
/// all supported networks via `LibRainDeploy`.
function run() external {
```

`@notice` is present. The function has no parameters and no return value, so `@param` and `@return` tags are not applicable and their absence is correct.

---

## Findings

### FINDING D-DOC-01 — LOW — `run()` does not document the `new address[](0)` argument (no dependencies)

**Location:** `script/Deploy.sol`, line 30

**Description:**

The call to `LibRainDeploy.deployAndBroadcastToSupportedNetworks` passes `new address[](0)` as the `dependencies` argument, indicating that `TOFUTokenDecimals` has no on-chain dependencies that must be verified before deployment. The `@notice` for `run()` does not mention this fact.

While omitting mention of an empty dependencies list is not misleading, a reader unfamiliar with the `LibRainDeploy` API may not understand why the argument is there or what it controls. Adding a brief explanatory comment (even inline, not necessarily NatSpec) would aid clarity.

**Recommended addition (inline comment):**

```solidity
new address[](0) // No on-chain dependencies required before deployment
```

**Severity rationale:** The existing NatSpec is not inaccurate; the omission is a completeness gap rather than a correctness defect. Severity is LOW.

---

### FINDING D-DOC-02 — INFO — `run()` does not document idempotency behaviour

**Location:** `script/Deploy.sol`, lines 19–32

**Description:**

`LibRainDeploy.deployAndBroadcastToSupportedNetworks` is idempotent: if the contract is already deployed at the expected address, it skips the Zoltu call and proceeds with verification (see `LibRainDeploy.sol` lines 121–127). The `@notice` on `run()` does not reflect this. A deployer re-running the script on a network where the contract already exists would not trigger a second deployment.

This is not incorrect, but documenting idempotency would help operators understand safe re-execution.

**Severity rationale:** Purely informational; no correctness issue exists.

---

### FINDING D-DOC-03 — INFO — `@dev` tag absent for compile-time determinism constraints

**Location:** `script/Deploy.sol`, contract-level NatSpec (lines 10–14)

**Description:**

The CLAUDE.md project notes that bytecode determinism is critical to the Zoltu deployment address: `bytecode_hash = "none"`, `cbor_metadata = false`, exact solc `=0.8.25`, `evm_version = "cancun"`, optimizer at 1M runs. None of these constraints are mentioned anywhere in `Deploy.sol`.

An operator who modifies `foundry.toml` or calls this script with a mismatched toolchain will produce a wrong address and the script will revert at the code-hash check inside `LibRainDeploy`. A `@dev` note linking to `TOFUTokenDecimals.sol` or documenting that the creation code must come from a deterministic build would shorten the debugging loop.

**Severity rationale:** The revert from `UnexpectedDeployedCodeHash` provides a runtime safety net, so the missing documentation does not create a safety hole. Severity is INFO.

---

### FINDING D-DOC-04 — INFO — Contract `@notice` references "all supported networks" without enumerating them

**Location:** `script/Deploy.sol`, lines 11–14

**Description:**

The contract-level `@notice` states deployment targets "all supported networks" but does not list them. The actual networks are Arbitrum, Base, Flare, and Polygon, as documented in CLAUDE.md and the `LibRainDeploy.supportedNetworks()` return value. This is a completeness observation; the statement is accurate as a high-level description.

**Severity rationale:** INFO — purely a documentation completeness note.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| D-DOC-01 | LOW | `run()` does not document the empty `dependencies` argument |
| D-DOC-02 | INFO | `run()` does not document idempotent re-run behaviour |
| D-DOC-03 | INFO | No `@dev` note on compile-time determinism constraints |
| D-DOC-04 | INFO | Supported networks not enumerated in contract `@notice` |

Overall, the documentation for `script/Deploy.sol` is in good shape. The contract and sole function both carry meaningful NatSpec tags that accurately reflect the implementation. No critical or high-severity documentation defects were found. All findings are low or informational.
