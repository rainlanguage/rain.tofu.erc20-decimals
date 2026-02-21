# Pass 4: Code Quality

Agent: A06
Date: 2026-02-21
Audit session: 2026-02-21-04

---

## Evidence of Thorough Reading

### script/Deploy.sol

- **Contract**: `Deploy` (inherits `Script` from forge-std), line 15
- **Function**: `run()` external, line 19
- **Imports**:
  - `Script` from `forge-std/Script.sol` (line 5)
  - `LibRainDeploy` from `rain.deploy/lib/LibRainDeploy.sol` (line 6)
  - `TOFUTokenDecimals` from `../src/concrete/TOFUTokenDecimals.sol` (line 7)
  - `LibTOFUTokenDecimals` from `../src/lib/LibTOFUTokenDecimals.sol` (line 8)
- **Pragma**: `=0.8.25` (exact pin)
- **SPDX**: `LicenseRef-DCL-1.0`
- **NatSpec**: `@title` on line 10, `@notice` on lines 11-14, `@notice` on line 16-18 for `run()`
- `run()` calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` passing creation code, deployment address constant, and expected code hash constant drawn from `LibTOFUTokenDecimals`

### src/concrete/TOFUTokenDecimals.sol

- **Contract**: `TOFUTokenDecimals is ITOFUTokenDecimals`, line 13
- **State variable**: `sTOFUTokenDecimals` (`mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)`, internal), line 16
- **Functions**:
  - `decimalsForTokenReadOnly(address token)` external view returns `(TOFUOutcome, uint8)`, line 19
  - `decimalsForToken(address token)` external returns `(TOFUOutcome, uint8)`, line 25
  - `safeDecimalsForToken(address token)` external returns `uint8`, line 31
  - `safeDecimalsForTokenReadOnly(address token)` external view returns `uint8`, line 36
- **Imports**:
  - `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome` from interface (line 5)
  - `LibTOFUTokenDecimalsImplementation` from lib (line 6)
- **Pragma**: `=0.8.25` (exact pin for deterministic bytecode)
- **SPDX**: `LicenseRef-DCL-1.0`
- **NatSpec**: `@title` line 8, `@notice` lines 9-12, `@notice` line 14 for storage var, `@inheritdoc` on each function
- **Lint annotations**:
  - `forge-lint: disable-next-line(mixed-case-variable)` line 15 (storage variable `sTOFUTokenDecimals`)
  - `slither-disable-next-line unused-return` lines 20, 26

### src/interface/ITOFUTokenDecimals.sol

- **Pragma**: `^0.8.25`
- **SPDX**: `LicenseRef-DCL-1.0`
- **Struct**: `TOFUTokenDecimalsResult` (fields: `bool initialized`, `uint8 tokenDecimals`), lines 13-16
- **Lint annotation on struct**: `forge-lint: disable-next-line(pascal-case-struct)` line 12
- **Enum**: `TOFUOutcome` (variants: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`), lines 19-28
- **Error**: `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`, line 33
- **Interface**: `ITOFUTokenDecimals`, lines 53-92
  - `decimalsForTokenReadOnly(address token)` external view returns `(TOFUOutcome, uint8)`, line 67
  - `decimalsForToken(address token)` external returns `(TOFUOutcome, uint8)`, line 77
  - `safeDecimalsForToken(address token)` external returns `uint8`, line 83
  - `safeDecimalsForTokenReadOnly(address token)` external view returns `uint8`, line 91
- **NatSpec**: `@notice`/`@param` on struct, bare `///` on enum and enum variants, `@notice`/`@param` on error, `@title`/`@notice` on interface, no `@notice` tag on individual interface functions (bare `///`)

### src/lib/LibTOFUTokenDecimals.sol

- **Library**: `LibTOFUTokenDecimals`, line 21
- **Pragma**: `^0.8.25`
- **SPDX**: `LicenseRef-DCL-1.0`
- **Imports**: `TOFUOutcome`, `ITOFUTokenDecimals` from interface (line 5)
- **Error**: `TOFUTokenDecimalsNotDeployed(address deployedAddress)`, lines 22-24
- **Constants**:
  - `TOFU_DECIMALS_DEPLOYMENT` (`ITOFUTokenDecimals`, `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`), lines 29-30
  - `TOFU_DECIMALS_EXPECTED_CODE_HASH` (`bytes32`), lines 36-37
  - `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (`bytes`, large hex literal), lines 44-45
- **Functions**:
  - `ensureDeployed()` internal view, lines 50-57
  - `decimalsForTokenReadOnly(address token)` internal view returns `(TOFUOutcome, uint8)`, lines 65-70
  - `decimalsForToken(address token)` internal returns `(TOFUOutcome, uint8)`, lines 78-83
  - `safeDecimalsForToken(address token)` internal returns `uint8`, lines 88-91
  - `safeDecimalsForTokenReadOnly(address token)` internal view returns `uint8`, lines 96-99
- **NatSpec**: All items use `@notice` tags except function comment headers use bare `/// As per ...`
- **Lint annotations**:
  - `slither-disable-next-line too-many-digits` line 43
  - `slither-disable-next-line unused-return` lines 68, 81 (with comment "false positive in slither")

### src/lib/LibTOFUTokenDecimalsImplementation.sol

- **Library**: `LibTOFUTokenDecimalsImplementation`, line 13
- **Pragma**: `^0.8.25`
- **SPDX**: `LicenseRef-DCL-1.0`
- **Imports**: `TOFUTokenDecimalsResult`, `TOFUOutcome`, `TokenDecimalsReadFailure` from interface (line 5)
- **Constant**: `TOFU_DECIMALS_SELECTOR` (`bytes4`, `0x313ce567`), line 15
- **Functions**:
  - `decimalsForTokenReadOnly(mapping(address => TOFUTokenDecimalsResult) storage, address)` internal view returns `(TOFUOutcome, uint8)`, lines 29-79
  - `decimalsForToken(mapping(address => TOFUTokenDecimalsResult) storage, address)` internal returns `(TOFUOutcome, uint8)`, lines 108-122
  - `safeDecimalsForToken(mapping(address => TOFUTokenDecimalsResult) storage, address)` internal returns `uint8`, lines 135-145
  - `safeDecimalsForTokenReadOnly(mapping(address => TOFUTokenDecimalsResult) storage, address)` internal view returns `uint8`, lines 159-169
- **NatSpec**:
  - `decimalsForTokenReadOnly`: full `@notice`, `@param`, `@return` tags (lines 17-28)
  - `decimalsForToken`: bare `///` prose description (lines 81-107), with `@param` and `@return` tags
  - `safeDecimalsForToken`: bare `///` prose (lines 124-133), with `@param` and `@return`
  - `safeDecimalsForTokenReadOnly`: bare `///` prose (lines 147-157), with `@param` and `@return`
- **Lint annotations**:
  - `forge-lint: disable-next-line(mixed-case-variable)` at lines 30, 109, 134, 136, 158, 160
  - `forge-lint: disable-next-line(unsafe-typecast)` line 70

### foundry.toml

- `src = 'src'`, `out = 'out'`, `libs = ['lib']`
- `solc = "0.8.25"`, `evm_version = "cancun"`
- `optimizer = true`, `optimizer_runs = 1000000`
- `bytecode_hash = "none"`, `cbor_metadata = false`
- Commented-out debug optimizer settings (lines 12-15): `via_ir`, `optimizer`, `optimizer_runs`, `optimizer_steps`
- `fs_permissions = []`
- Remappings: `rain.deploy/`, `rain.extrospection/`, `rain.solmem/`
- RPC endpoints and Etherscan keys for: arbitrum, base, flare, polygon

---

## Build Verification

`forge build` (forced clean rebuild): **zero solc warnings**. The only output warning is a Foundry nightly build notice unrelated to this project's code.

`forge build --deny-warnings`: passes with no compiler warnings (the deprecated flag itself emits a flag deprecation notice, but no code warnings).

The prior finding A05-4 / A06-03 regarding `incorrect-shift` forge-lint false positives in `TOFUTokenDecimals.immutability.t.sol` has been **resolved**: lines 21, 25, and 29 of that file now carry `// forge-lint: disable-next-line(incorrect-shift)` suppression comments.

The prior finding A05-1 / A06-03 regarding the unused `ITOFUTokenDecimals` import in `LibTOFUTokenDecimalsImplementation.sol` has been **resolved**: the current import on line 5 only includes `TOFUTokenDecimalsResult`, `TOFUOutcome`, and `TokenDecimalsReadFailure`.

---

## Findings

### A06-04-1: Inconsistent forge-lint Annotation Count on `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` [LOW]

**File**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol`

In `decimalsForTokenReadOnly` (line 29) and `decimalsForToken` (line 108), the `forge-lint: disable-next-line(mixed-case-variable)` annotation appears **once**, immediately before the `mapping(...)` storage parameter inside the function signature. This is consistent: the annotation suppresses the linter warning about the `sTOFUTokenDecimals` parameter name.

In `safeDecimalsForToken` (lines 134-137) and `safeDecimalsForTokenReadOnly` (lines 158-161), there are **two** `forge-lint: disable-next-line(mixed-case-variable)` annotations per function: one before the `function` keyword (lines 134, 158) and one before the `sTOFUTokenDecimals` parameter (lines 136, 160).

```solidity
// Lines 134-137: two annotations
// forge-lint: disable-next-line(mixed-case-variable)          <-- extra annotation
function safeDecimalsForToken(
    // forge-lint: disable-next-line(mixed-case-variable)      <-- same as other functions
    mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,

// Lines 29-31: one annotation
function decimalsForTokenReadOnly(
    // forge-lint: disable-next-line(mixed-case-variable)      <-- only annotation
    mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
```

If the annotation before `function` is required by the linter (e.g., it fires on the function name `safeDecimalsForToken` with `s` prefix), then `decimalsForTokenReadOnly` and `decimalsForToken` are missing the same annotation. If the annotation before `function` is redundant (not needed), then the extra annotations in `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` should be removed to match the pattern in the other two functions.

**Recommendation**: Determine whether the linter requires the annotation before `function` for the safe variants but not the others, and normalize the annotation count to be consistent across all four functions.

---

### A06-04-2: NatSpec Tag Inconsistency on `TOFUOutcome` Enum vs Other Types in Interface [INFO]

**File**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/interface/ITOFUTokenDecimals.sol`

The `TOFUTokenDecimalsResult` struct (line 5) uses `/// @notice` and `/// @param` NatSpec tags. The `TokenDecimalsReadFailure` error (line 30) uses `/// @notice` and `/// @param` tags. The `ITOFUTokenDecimals` interface body (line 35) uses `/// @title` and `/// @notice`.

However, the `TOFUOutcome` enum (line 18) and all four of its variants (lines 20-27) use bare `///` comments without any NatSpec tag (`@notice`, `@dev`, etc.):

```solidity
/// Outcomes for TOFU token decimals reads.
enum TOFUOutcome {
    /// Token's decimals have not been read from the external contract before.
    Initial,
    ...
}
```

This is a minor inconsistency: the struct and error use `@notice` while the enum uses untagged `///`. Both forms are valid Solidity NatSpec, but the inconsistency within the same file is a style issue. Applying `/// @notice` to the enum comment and `/// @notice` or `/// @dev` to each variant would align with the rest of the file.

---

### A06-04-3: NatSpec First-Tag Style Inconsistency Between `decimalsForTokenReadOnly` and Remaining Functions in Implementation [INFO]

**File**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol`

`decimalsForTokenReadOnly` opens its NatSpec block with a tagged `/// @notice` on line 17:

```solidity
/// @notice As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`. Works as
```

The other three functions (`decimalsForToken` line 81, `safeDecimalsForToken` line 124, `safeDecimalsForTokenReadOnly` line 147) open with bare `///` comment lines:

```solidity
/// Trust on first use (TOFU) token decimals.
/// Same as `decimalsForToken` but reverts ...
/// As per `safeDecimalsForToken` but read-only.
```

These are followed by `@param` and `@return` tags but lack a leading `@notice` tag. This creates a visible inconsistency: one function uses a structured opening tag while the other three use untagged prose descriptions. The Solidity NatSpec specification treats the first comment of a NatSpec block as the notice when untagged, so semantically they are equivalent, but the style varies.

**Recommendation**: Either add `/// @notice` to the opening line of `decimalsForToken`, `safeDecimalsForToken`, and `safeDecimalsForTokenReadOnly` to match `decimalsForTokenReadOnly`, or remove `@notice` from `decimalsForTokenReadOnly` to use the untagged style everywhere.

---

### A06-04-4: NatSpec Comment Style Inconsistency in `LibTOFUTokenDecimals` Wrappers [INFO]

**File**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol`

`ensureDeployed()` has a proper `/// @notice` opening tag (line 47). The four delegating functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) open with bare `///` lines:

```solidity
/// As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`.
```

These bare `/// As per ...` openers appear on lines 59, 72, 85, and 93. Immediately below each opener, `@param` and `@return` tags are used properly. The inconsistency is that `ensureDeployed()` uses `/// @notice` while all four wrappers use untagged `///`.

This is a minor style inconsistency within the same library, similar to A06-04-3.

---

### A06-04-5: `safeDecimalsForTokenReadOnly` NatSpec `@return` Unnamed in Implementation, Named in Caller Library [INFO]

**Files**:
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol` lines 132-133 and 156-157
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol` lines 86-87 and 94-95

In `LibTOFUTokenDecimalsImplementation`, both safe functions document their return value as:
```solidity
/// @return The token's decimals.
```

In `LibTOFUTokenDecimals`, both safe function wrappers document their return value as:
```solidity
/// @return tokenDecimals The token's decimals.
```

The caller library (`LibTOFUTokenDecimals`) uses a named `@return` parameter while the implementation library uses an unnamed one. Both forms are valid, but the inconsistency between the two libraries for the same conceptual value is a style issue.

---

### A06-04-6: Commented-Out Debug Optimizer Settings in `foundry.toml` [INFO]

**File**: `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/foundry.toml`
**Lines**: 12-15

```toml
# optimizer settings for debugging
# via_ir = false
# optimizer = false
# optimizer_runs = 0
# optimizer_steps = 0
```

These four commented-out lines provide a quick toggle for local debugging. In a project where **bytecode determinism is a hard requirement** (Zoltu deployment), uncommenting any of these lines would silently invalidate the deployed singleton address. The section is clearly labeled, which mitigates the risk, but no warning text explicitly states the consequence.

**Assessment**: Acceptable as a developer convenience pattern. Consider adding a brief inline warning comment such as `# WARNING: uncommenting these will change bytecode and break the Zoltu deployment address` to make the consequence explicit.

---

### A06-04-7: Pragma Split (`=0.8.25` vs `^0.8.25`) Is Intentional but Undocumented at Point of Use [INFO]

**Files**:
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/concrete/TOFUTokenDecimals.sol` line 3: `pragma solidity =0.8.25;`
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/script/Deploy.sol` line 3: `pragma solidity =0.8.25;`
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/interface/ITOFUTokenDecimals.sol` line 3: `pragma solidity ^0.8.25;`
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol` line 3: `pragma solidity ^0.8.25;`
- `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol` line 3: `pragma solidity ^0.8.25;`

The design is correct: the concrete contract and deploy script must use exact pinning (`=`) for Zoltu bytecode determinism, while the interface and library files use caret (`^`) so downstream callers are not forced onto the same exact compiler version. This is a well-motivated split documented in `CLAUDE.md`.

However, neither pragma line in `TOFUTokenDecimals.sol` nor `Deploy.sol` carries a comment explaining **why** `=` is used instead of `^`. A future maintainer may consider "correcting" this to `^` without realizing the consequence. A one-line comment on the pragma would make the intent clear.

---

### A06-04-8: Positive Finding -- All Previously Identified Issues Resolved [INFO]

The following findings from prior audit passes have been fully addressed in the current codebase:

1. **Unused `ITOFUTokenDecimals` import** in `LibTOFUTokenDecimalsImplementation.sol` (A05-1, A06-03 A06-1): Resolved. Current import line 5 includes only the three symbols actually used in code.

2. **`incorrect-shift` forge-lint false positives** in `TOFUTokenDecimals.immutability.t.sol` (A05-4): Resolved. Lines 21, 25, and 29 now carry `// forge-lint: disable-next-line(incorrect-shift)` annotations with explanatory comments.

3. **Build cleanliness**: Zero solc compiler warnings. All lint suppression annotations are in place and correctly scoped.

---

## Summary Table

| ID | Severity | File(s) | Description | Action |
|----|----------|---------|-------------|--------|
| A06-04-1 | LOW | `LibTOFUTokenDecimalsImplementation.sol` lines 134, 158 | Extra `forge-lint: disable-next-line(mixed-case-variable)` before `function` keyword on safe variants only; inconsistent with other two functions | Normalize annotation count across all four functions |
| A06-04-2 | INFO | `ITOFUTokenDecimals.sol` lines 18-28 | `TOFUOutcome` enum uses bare `///` while struct and error use `/// @notice` | Add `@notice` tag to enum-level comment |
| A06-04-3 | INFO | `LibTOFUTokenDecimalsImplementation.sol` lines 17, 81, 124, 147 | `decimalsForTokenReadOnly` uses `/// @notice` opener; other three functions use bare `///` prose | Normalize NatSpec opening tag across all four functions |
| A06-04-4 | INFO | `LibTOFUTokenDecimals.sol` lines 47, 59, 72, 85, 93 | `ensureDeployed` uses `/// @notice`; four wrapper functions use bare `///` | Normalize NatSpec opening tag |
| A06-04-5 | INFO | `LibTOFUTokenDecimalsImplementation.sol` lines 133, 157 vs `LibTOFUTokenDecimals.sol` lines 87, 95 | Safe function `@return` is unnamed in implementation, named in caller library | Normalize to named or unnamed consistently |
| A06-04-6 | INFO | `foundry.toml` lines 12-15 | Commented-out debug optimizer settings lack warning about bytecode impact | Add explicit warning comment |
| A06-04-7 | INFO | `TOFUTokenDecimals.sol` line 3, `Deploy.sol` line 3 | Exact-pinned pragma `=0.8.25` carries no inline rationale comment | Add comment explaining why `=` not `^` |
| A06-04-8 | INFO | All source files | All prior findings (A05-1, A05-4) fully resolved in current codebase | No action needed |
