# Audit Pass 4 -- Code Quality

**Agent:** A05
**Date:** 2026-02-19
**Scope:** All source files in `src/`, `script/`, `foundry.toml`, submodule pinning

---

## 1. Evidence of Thorough Reading

### `src/interface/ITOFUTokenDecimals.sol` (87 lines)

- **Interface:** `ITOFUTokenDecimals` (line 53)
  - `decimalsForTokenReadOnly(address)` -- line 65
  - `decimalsForToken(address)` -- line 73
  - `safeDecimalsForToken(address)` -- line 79
  - `safeDecimalsForTokenReadOnly(address)` -- line 85
- **Struct:** `TOFUTokenDecimalsResult` (line 13) -- fields: `initialized` (bool), `tokenDecimals` (uint8)
- **Enum:** `TOFUOutcome` (line 19) -- variants: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`
- **Error:** `TokenDecimalsReadFailure(address, TOFUOutcome)` (line 33)

### `src/lib/LibTOFUTokenDecimalsImplementation.sol` (149 lines)

- **Library:** `LibTOFUTokenDecimalsImplementation` (line 18)
  - `TOFU_DECIMALS_SELECTOR` constant -- line 20
  - `decimalsForTokenReadOnly(mapping, address)` -- line 32
  - `decimalsForToken(mapping, address)` -- line 99
  - `safeDecimalsForToken(mapping, address)` -- line 121
  - `safeDecimalsForTokenReadOnly(mapping, address)` -- line 137

### `src/concrete/TOFUTokenDecimals.sol` (40 lines)

- **Contract:** `TOFUTokenDecimals is ITOFUTokenDecimals` (line 14)
  - `sTOFUTokenDecimals` storage mapping -- line 16
  - `decimalsForTokenReadOnly(address)` -- line 19
  - `decimalsForToken(address)` -- line 25
  - `safeDecimalsForToken(address)` -- line 31
  - `safeDecimalsForTokenReadOnly(address)` -- line 36

### `src/lib/LibTOFUTokenDecimals.sol` (85 lines)

- **Library:** `LibTOFUTokenDecimals` (line 21)
  - `TOFUTokenDecimalsNotDeployed(address)` error -- line 23
  - `TOFU_DECIMALS_DEPLOYMENT` constant -- line 28
  - `TOFU_DECIMALS_EXPECTED_CODE_HASH` constant -- line 35
  - `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant -- line 42
  - `ensureDeployed()` -- line 48
  - `decimalsForTokenReadOnly(address)` -- line 58
  - `decimalsForToken(address)` -- line 66
  - `safeDecimalsForToken(address)` -- line 74
  - `safeDecimalsForTokenReadOnly(address)` -- line 80

### `script/Deploy.sol` (26 lines)

- **Contract:** `Deploy is Script` (line 10)
  - `run()` -- line 11

---

## 2. Code Quality Findings

### A05-1: Unused import of `LibTOFUTokenDecimals` in concrete contract [LOW]

**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/concrete/TOFUTokenDecimals.sol`, line 6

```solidity
import {TOFUOutcome, LibTOFUTokenDecimals} from "../lib/LibTOFUTokenDecimals.sol";
```

`LibTOFUTokenDecimals` is imported but never used in the concrete contract. Only `TOFUOutcome` from this import is referenced (in return type declarations on lines 19 and 25). The `TOFUOutcome` enum could be imported directly from the interface file instead:

```solidity
import {ITOFUTokenDecimals, TOFUTokenDecimalsResult, TOFUOutcome} from "../interface/ITOFUTokenDecimals.sol";
```

This would eliminate both the unused `LibTOFUTokenDecimals` import and the need for a second import line. However, this may be intentional to ensure the convenience library is compiled alongside the concrete contract, or it may be a holdover from an earlier design. Either way, the compiler does not warn about unused library imports in Solidity, so this is cosmetic only.

**Note:** Changing imports in `TOFUTokenDecimals.sol` could potentially alter the creation code bytecode if the compiler includes the library in the output. This must be verified against `TOFU_DECIMALS_EXPECTED_CREATION_CODE` before any change is made. Given the bytecode determinism constraint, this finding is informational rather than actionable without careful verification.

---

### A05-2: Unused import of `TokenDecimalsReadFailure` in `LibTOFUTokenDecimals.sol` [LOW]

**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol`, line 5

```solidity
import {TOFUOutcome, ITOFUTokenDecimals, TokenDecimalsReadFailure} from "../interface/ITOFUTokenDecimals.sol";
```

`TokenDecimalsReadFailure` is imported but never used within this file. The error is only used in `LibTOFUTokenDecimalsImplementation.sol` (lines 128 and 144), which imports it separately. The convenience library `LibTOFUTokenDecimals` delegates to the singleton contract via external calls, so any revert with `TokenDecimalsReadFailure` would bubble up from the external call automatically without needing the import here.

However, having it imported here means that consumers who import `LibTOFUTokenDecimals` can re-use the error type without an additional import. This could be a deliberate convenience re-export pattern, but if so, it is not documented.

---

### A05-3: Unused import of `console2` in deploy script [LOW]

**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/script/Deploy.sol`, line 5

```solidity
import {Script, console2} from "forge-std/Script.sol";
```

`console2` is imported but never referenced in the deploy script. This is likely a leftover from development/debugging.

---

### A05-4: Commented-out optimizer settings in `foundry.toml` [INFO]

**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/foundry.toml`, lines 12-15

```toml
# optimizer settings for debugging
# via_ir = false
# optimizer = false
# optimizer_runs = 0
# optimizer_steps = 0
```

These commented-out alternative optimizer settings exist for developer convenience when debugging. The comment on line 11 documents their purpose ("optimizer settings for debugging"). This is a standard Foundry pattern and is acceptable as-is. No action needed.

---

### A05-5: Pragma solidity version split -- `=0.8.25` vs `^0.8.25` [INFO]

**Observation:**

| File | Pragma |
|------|--------|
| `src/interface/ITOFUTokenDecimals.sol` | `^0.8.25` |
| `src/lib/LibTOFUTokenDecimalsImplementation.sol` | `^0.8.25` |
| `src/lib/LibTOFUTokenDecimals.sol` | `^0.8.25` |
| `src/concrete/TOFUTokenDecimals.sol` | `=0.8.25` |
| `script/Deploy.sol` | `=0.8.25` |
| All test files | `=0.8.25` |

**Assessment:** This split is intentional and correct. The interface, implementation library, and convenience library use `^0.8.25` so that downstream consumers can compile them with any Solidity 0.8.x version >= 0.8.25. The concrete contract uses `=0.8.25` because its bytecode must be deterministic for Zoltu deployment. The deploy script and tests pin to `=0.8.25` since they compile alongside the concrete contract. The `foundry.toml` also pins `solc = "0.8.25"`. This is a well-considered design.

---

<!-- REUSE-IgnoreStart -->
### A05-6: All SPDX license identifiers are `LicenseRef-DCL-1.0` [INFO]

All four source files, the deploy script, and all ten test files use `// SPDX-License-Identifier: LicenseRef-DCL-1.0`. This is consistent and matches the project requirement.
<!-- REUSE-IgnoreEnd -->

---

### A05-7: Submodule pinning [INFO]

Both submodules are pinned to specific commits:

| Submodule | Commit | Tag/Branch |
|-----------|--------|------------|
| `lib/forge-std` | `1801b054...` | `v1.14.0` (tagged release) |
| `lib/rain.deploy` | `e419a46e...` | `remotes/origin/HEAD` |

`forge-std` is pinned to a stable tagged release, which is best practice. `rain.deploy` is pinned to a specific commit but reported as tracking `remotes/origin/HEAD` rather than a tagged release. Since this is an internal Rain dependency, tracking HEAD of the default branch is acceptable, but tagging a specific release version would be more robust for long-term reproducibility.

---

### A05-8: Style consistency -- forge-lint and slither suppression comments [INFO]

The codebase uses lint suppression comments consistently:

- `// forge-lint: disable-next-line(pascal-case-struct)` for `TOFUTokenDecimalsResult` (interface, line 12)
- `// forge-lint: disable-next-line(mixed-case-variable)` for all `sTOFUTokenDecimals` parameters and the storage variable (implementation lines 33, 100, 120-122, 136-138; concrete line 15)
- `// forge-lint: disable-next-line(unsafe-typecast)` for the `uint8(readDecimals)` cast (implementation line 73)
- `// slither-disable-next-line unused-return` for delegated calls returning tuples (concrete lines 20, 26; convenience lib lines 61, 69)
- `// slither-disable-next-line too-many-digits` for the creation code hex literal (convenience lib line 41)

All suppressions are justified and consistently applied. The naming convention for the storage variable (`sTOFUTokenDecimals` with the `s` prefix) is applied uniformly across the codebase.

---

### A05-9: No leaky abstractions detected [INFO]

The three-layer architecture maintains clean separation:

1. The implementation library (`LibTOFUTokenDecimalsImplementation`) operates on an injected storage mapping and has no knowledge of the singleton address or deployment details.
2. The concrete contract (`TOFUTokenDecimals`) owns the storage and delegates purely to the implementation library.
3. The convenience library (`LibTOFUTokenDecimals`) encapsulates the singleton address, expected codehash, and deployment verification, presenting a clean internal-function API to callers.

Internal storage layout (the `sTOFUTokenDecimals` mapping) is `internal` visibility in the concrete contract and is not exposed through the interface. The `TOFUTokenDecimalsResult` struct is publicly visible through the interface but this is necessary for callers to understand the data model.

---

### A05-10: No direct tests for the concrete `TOFUTokenDecimals` contract [INFO]

There are no test files under `test/` that directly test `TOFUTokenDecimals.sol` as a standalone unit. The `LibTOFUTokenDecimals` tests exercise the concrete contract indirectly by deploying it via the Zoltu factory and calling through the convenience library. The `LibTOFUTokenDecimalsImplementation` tests exercise the core logic directly with local storage. This provides adequate coverage since the concrete contract is a thin delegation layer, but dedicated concrete contract tests could catch issues with storage layout or interface compliance.

---

### A05-11: Build warnings [INFO]

`forge build` produces **no compiler warnings**. The only output is a Foundry nightly build notice (`Warning: This is a nightly build of Foundry`), which is an environment configuration message, not a code quality issue.

---

### A05-12: No dead code detected in source files [INFO]

All functions in all source files are either:
- Called by higher layers in the architecture, or
- Exposed through the public interface

The `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant in `LibTOFUTokenDecimals.sol` is used by the deploy script and verified in tests (`testExpectedCreationCode`). No unreachable code paths were identified.

---

## Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| CRITICAL | 0 | -- |
| HIGH | 0 | -- |
| MEDIUM | 0 | -- |
| LOW | 3 | A05-1, A05-2, A05-3 |
| INFO | 9 | A05-4 through A05-12 |

The codebase demonstrates high code quality with consistent style, well-justified lint suppressions, intentional pragma version splits, correct SPDX licensing, and clean build output. The only actionable findings are three unused imports (all LOW severity), none of which affect correctness or security. The `TOFUTokenDecimals.sol` unused import (A05-1) should be evaluated carefully before changing due to bytecode determinism constraints.
