# Audit Pass 3 (Documentation) -- `src/concrete/TOFUTokenDecimals.sol`

**Agent:** A02
**Date:** 2026-02-21
**Audit:** 2026-02-21-05

---

## Evidence of Thorough Reading

### Contract Name

`TOFUTokenDecimals` (line 13), inheriting `ITOFUTokenDecimals`.

### State Variables

| Variable | Visibility | Type | Line |
|---|---|---|---|
| `sTOFUTokenDecimals` | `internal` | `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)` | 16 |

### Functions

| Function | Visibility | Mutability | Line |
|---|---|---|---|
| `decimalsForTokenReadOnly` | `external` | `view` | 19 |
| `decimalsForToken` | `external` | (state-changing) | 25 |
| `safeDecimalsForToken` | `external` | (state-changing) | 31 |
| `safeDecimalsForTokenReadOnly` | `external` | `view` | 36 |

### Imports (line 5-6)

- `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome` from `../interface/ITOFUTokenDecimals.sol`
- `LibTOFUTokenDecimalsImplementation` from `../lib/LibTOFUTokenDecimalsImplementation.sol`

### SPDX / Pragma

- SPDX: `LicenseRef-DCL-1.0` (line 1) -- correct per project conventions.
- Pragma: `=0.8.25` (line 3) -- exact version, required for bytecode determinism.

---

## NatSpec Audit

### Contract-Level Documentation

Lines 8-12 provide `@title` and `@notice`:

```solidity
/// @title TOFUTokenDecimals
/// @notice Minimal implementation of the ITOFUTokenDecimals interface using
/// LibTOFUTokenDecimalsImplementation for the logic. The concrete contract
/// simply stores the mapping of token addresses to TOFUTokenDecimalsResult
/// structs and delegates all logic to the library.
```

**Assessment:** Accurate. The contract does exactly this: it owns the storage mapping and delegates every function call to `LibTOFUTokenDecimalsImplementation`. The `@title` matches the contract name. The `@notice` is a correct and concise summary of purpose.

### State Variable: `sTOFUTokenDecimals` (line 14-16)

```solidity
/// @notice Storage mapping from token address to its TOFU decimals result.
// forge-lint: disable-next-line(mixed-case-variable)
mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;
```

**Assessment:** Has a `@notice` tag describing its purpose. The forge-lint suppression is correctly placed after the NatSpec `@notice` line and before the declaration. The variable is `internal` so NatSpec is not strictly required by tooling but is good practice and present here.

### Function: `decimalsForTokenReadOnly` (lines 18-22)

```solidity
/// @inheritdoc ITOFUTokenDecimals
function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8) {
```

**`@inheritdoc` verification:** `ITOFUTokenDecimals` defines `decimalsForTokenReadOnly(address)` at line 67 of the interface with full NatSpec (`@notice`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals`). The signature matches exactly. `@inheritdoc` is correct.

### Function: `decimalsForToken` (lines 24-28)

```solidity
/// @inheritdoc ITOFUTokenDecimals
function decimalsForToken(address token) external returns (TOFUOutcome, uint8) {
```

**`@inheritdoc` verification:** `ITOFUTokenDecimals` defines `decimalsForToken(address)` at line 78 of the interface with full NatSpec. The signature matches exactly. `@inheritdoc` is correct.

### Function: `safeDecimalsForToken` (lines 30-33)

```solidity
/// @inheritdoc ITOFUTokenDecimals
function safeDecimalsForToken(address token) external returns (uint8) {
```

**`@inheritdoc` verification:** `ITOFUTokenDecimals` defines `safeDecimalsForToken(address)` at line 84 of the interface with full NatSpec. The signature matches exactly. `@inheritdoc` is correct.

### Function: `safeDecimalsForTokenReadOnly` (lines 35-38)

```solidity
/// @inheritdoc ITOFUTokenDecimals
function safeDecimalsForTokenReadOnly(address token) external view returns (uint8) {
```

**`@inheritdoc` verification:** `ITOFUTokenDecimals` defines `safeDecimalsForTokenReadOnly(address)` at line 96 of the interface with full NatSpec (including the important `WARNING` about pre-initialization behavior). The signature matches exactly. `@inheritdoc` is correct.

---

## Findings

### A02-001: Missing `@dev` note about bytecode determinism [INFO]

**Location:** Lines 8-12 (contract-level NatSpec)

**Description:** The `TOFUTokenDecimals` contract is the concrete contract deployed via the Zoltu deterministic factory, and its bytecode determinism is critical to the project (exact solc `=0.8.25`, `bytecode_hash = "none"`, `cbor_metadata = false`, optimizer at 1M runs, `evm_version = "cancun"`). The contract-level NatSpec does not contain a `@dev` note documenting these constraints or warning maintainers that changes to compiler settings, pragma, or contract structure will break the deployed address on all chains.

The pragma `=0.8.25` on line 3 is itself a strong signal, but there is no accompanying NatSpec that explains *why* the exact version constraint exists. A developer unfamiliar with the project could change compiler settings in `foundry.toml` without realizing the consequences.

**Recommendation:** Consider adding a `@dev` tag to the contract-level NatSpec documenting the bytecode determinism requirements, e.g.:

```solidity
/// @dev Bytecode determinism is critical. This contract is deployed via the
/// Zoltu deterministic factory as a cross-chain singleton. Do not change the
/// solc version (=0.8.25), evm_version (cancun), optimizer settings (1M runs),
/// bytecode_hash (none), or cbor_metadata (false) without redeploying on all
/// chains.
```

**Classification:** INFO -- The constraint is enforced by `foundry.toml` and the exact pragma, and is documented in `CLAUDE.md` and likely in deployment scripts. However, a `@dev` note directly on the contract would be the most discoverable location for maintainers.

### A02-002: forge-lint suppression placement is correct [INFO]

**Location:** Line 15

**Description:** The `forge-lint: disable-next-line(mixed-case-variable)` comment on line 15 is placed between the `@notice` NatSpec (line 14) and the mapping declaration (line 16). This is the correct placement: the NatSpec is above and uninterrupted for documentation tooling, and the suppression comment immediately precedes the lint target.

**Classification:** INFO -- No issue. Documented for completeness.

### A02-003: All four `@inheritdoc` references are accurate [INFO]

**Location:** Lines 18, 24, 30, 35

**Description:** All four external functions use `@inheritdoc ITOFUTokenDecimals`. Each one was verified against the interface definition in `src/interface/ITOFUTokenDecimals.sol`:

- `decimalsForTokenReadOnly` -- interface line 67, full NatSpec present.
- `decimalsForToken` -- interface line 78, full NatSpec present.
- `safeDecimalsForToken` -- interface line 84, full NatSpec present.
- `safeDecimalsForTokenReadOnly` -- interface line 96, full NatSpec present (including WARNING about pre-initialization).

All function signatures match exactly. No discrepancies.

**Classification:** INFO -- No issue. Documented for completeness.

---

## Summary

| ID | Severity | Title |
|---|---|---|
| A02-001 | INFO | Missing `@dev` note about bytecode determinism |
| A02-002 | INFO | forge-lint suppression placement is correct |
| A02-003 | INFO | All four `@inheritdoc` references are accurate |

The file is well-documented. All public/external functions have NatSpec via `@inheritdoc`, and the referenced interface provides comprehensive documentation including parameter descriptions, return value semantics per outcome, and warnings. The state variable has a `@notice` tag. The contract-level `@title` and `@notice` are accurate. The only suggestion is an optional `@dev` note about bytecode determinism constraints directly on the contract.
