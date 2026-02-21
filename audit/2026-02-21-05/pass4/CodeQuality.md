# Pass 4 -- Code Quality Audit

**Agent:** A06
**Date:** 2026-02-21
**Scope:** All five source files

## Evidence of Thorough Reading

### `script/Deploy.sol` (33 lines)
- SPDX: `LicenseRef-DCL-1.0`, copyright 2020.
- Pragma: `=0.8.25` (exact).
- Imports: 4 named imports (Script, LibRainDeploy, TOFUTokenDecimals, LibTOFUTokenDecimals).
- Single `run()` function using `vm.envUint("DEPLOYMENT_KEY")`, calls `deployAndBroadcastToSupportedNetworks`.
- References `TOFU_DECIMALS_DEPLOYMENT` and `TOFU_DECIMALS_EXPECTED_CODE_HASH` from the library.
- NatSpec: `@title` and `@notice` on contract and function. No `@param` or `@return` (not applicable).

### `src/concrete/TOFUTokenDecimals.sol` (39 lines)
- SPDX: `LicenseRef-DCL-1.0`, copyright 2020.
- Pragma: `=0.8.25` (exact).
- Imports: 2 lines, named imports for ITOFUTokenDecimals, TOFUTokenDecimalsResult, TOFUOutcome, LibTOFUTokenDecimalsImplementation.
- Implements `ITOFUTokenDecimals`, has storage mapping `sTOFUTokenDecimals`.
- 4 external functions, all use `@inheritdoc ITOFUTokenDecimals`.
- forge-lint suppression: `mixed-case-variable` on storage mapping (line 15).
- slither suppressions: `unused-return` on `decimalsForTokenReadOnly` (line 20) and `decimalsForToken` (line 26).
- No explanatory comment on slither suppressions (unlike `LibTOFUTokenDecimals.sol`).

### `src/interface/ITOFUTokenDecimals.sol` (97 lines)
- SPDX: `LicenseRef-DCL-1.0`, copyright 2020.
- Pragma: `^0.8.25` (caret).
- No imports (standalone).
- Defines struct `TOFUTokenDecimalsResult`, enum `TOFUOutcome`, interface `ITOFUTokenDecimals`.
- forge-lint suppression: `pascal-case-struct` on `TOFUTokenDecimalsResult` (line 12).
- Error `TokenDecimalsReadFailure` with `@notice` and `@param` tags.
- 4 function declarations, all with `@notice`, `@param`, `@return`.
- Detailed NatSpec including `WARNING` on `safeDecimalsForTokenReadOnly`.

### `src/lib/LibTOFUTokenDecimals.sol` (101 lines)
- SPDX: `LicenseRef-DCL-1.0`, copyright 2020.
- Pragma: `^0.8.25` (caret).
- Imports: `TOFUOutcome`, `ITOFUTokenDecimals` from interface.
- Error `TOFUTokenDecimalsNotDeployed` with NatSpec.
- 3 constants: `TOFU_DECIMALS_DEPLOYMENT`, `TOFU_DECIMALS_EXPECTED_CODE_HASH`, `TOFU_DECIMALS_EXPECTED_CREATION_CODE`.
- `ensureDeployed()` internal view function.
- 4 wrapper functions that call `ensureDeployed()` then delegate to the singleton.
- slither suppressions: `too-many-digits` (line 43), `unused-return` (lines 69, 82) -- the latter two with "false positive in slither." comments.
- NatSpec uses `@notice As per ...` cross-reference pattern, then duplicates `@return` docs.

### `src/lib/LibTOFUTokenDecimalsImplementation.sol` (171 lines)
- SPDX: `LicenseRef-DCL-1.0`, copyright 2020.
- Pragma: `^0.8.25` (caret).
- Imports: `TOFUTokenDecimalsResult`, `TOFUOutcome`, `ITOFUTokenDecimals` from interface.
- Constant `TOFU_DECIMALS_SELECTOR` with `@dev` tag.
- 4 functions: `decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`.
- Assembly block with `staticcall` for reading decimals.
- forge-lint suppressions: `mixed-case-variable` on all 4 function params (lines 30, 110, 137, 161), `unsafe-typecast` (line 70).
- NatSpec includes `@notice`, `@param` (including for storage mapping param), `@return`.

## Findings

### A06-1: Slither suppression comment inconsistency [INFO]

**Files:** `src/concrete/TOFUTokenDecimals.sol` (lines 20, 26), `src/lib/LibTOFUTokenDecimals.sol` (lines 68-69, 81-82)

In `LibTOFUTokenDecimals.sol`, the `unused-return` slither suppressions are preceded by an explanatory comment `// false positive in slither.` In `TOFUTokenDecimals.sol`, the identical `unused-return` suppressions have no explanatory comment. Since the same false-positive rationale applies to both files, the style should be consistent.

**Recommendation:** Either add `// false positive in slither.` to `TOFUTokenDecimals.sol` lines 20 and 26, or remove the explanatory comments from `LibTOFUTokenDecimals.sol` -- whichever the project prefers.

---

### A06-2: `@return` tag naming inconsistency in `LibTOFUTokenDecimalsImplementation` [INFO]

**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`

The `decimalsForTokenReadOnly` (line 25-28) and `decimalsForToken` (line 105-108) functions use named `@return` tags:
```
/// @return tofuOutcome The outcome of the TOFU read.
/// @return tokenDecimals The token's decimals. ...
```

The `safeDecimalsForToken` (line 135) and `safeDecimalsForTokenReadOnly` (line 159) functions use unnamed `@return` tags:
```
/// @return The token's decimals.
```

This is understandable since the safe variants have only one return value and `tokenDecimals` is the actual return variable name in the interface but not in the implementation signature (`uint8` without a name). However, `LibTOFUTokenDecimals.sol` (lines 88, 96) uses the named form `/// @return tokenDecimals The token's decimals.` for the same safe functions, matching the interface. The implementation library should match.

**Recommendation:** Use `/// @return tokenDecimals The token's decimals.` in `LibTOFUTokenDecimalsImplementation.sol` at lines 135 and 159, for consistency with the interface and `LibTOFUTokenDecimals.sol`.

---

### A06-3: Pragma strategy is intentional and well-applied [INFO]

**Files:** All five source files.

The exact pragma `=0.8.25` is used in files that contribute to deterministic bytecode:
- `src/concrete/TOFUTokenDecimals.sol` (the deployed singleton)
- `script/Deploy.sol` (the deploy script)

The caret pragma `^0.8.25` is used in files that are consumed as libraries by downstream callers:
- `src/interface/ITOFUTokenDecimals.sol`
- `src/lib/LibTOFUTokenDecimals.sol`
- `src/lib/LibTOFUTokenDecimalsImplementation.sol`

This is the correct pattern. The exact pragma pins bytecode-sensitive artifacts, while the caret pragma allows downstream consumers to use newer compiler versions. No issue.

---

### A06-4: Commented-out optimizer settings in `foundry.toml` [INFO]

**File:** `foundry.toml` (lines 12-16)

```toml
# optimizer settings for debugging
# via_ir = false
# optimizer = false
# optimizer_runs = 0
# optimizer_steps = 0
```

These commented-out lines serve as a documented convenience for developers switching between debug and release optimizer settings. They do not affect the build output and are clearly labelled. This is a common Foundry pattern and is acceptable as-is, but could be moved to a `CLAUDE.md` or developer guide to keep the config file cleaner.

**Recommendation:** No action required. This is standard practice.

---

### A06-5: Named import ordering varies across files [INFO]

**Files:** `src/concrete/TOFUTokenDecimals.sol`, `src/lib/LibTOFUTokenDecimalsImplementation.sol`

The import from the interface file orders its named imports differently:
- `TOFUTokenDecimals.sol` (line 5): `{ITOFUTokenDecimals, TOFUTokenDecimalsResult, TOFUOutcome}`
- `LibTOFUTokenDecimalsImplementation.sol` (line 5): `{TOFUTokenDecimalsResult, TOFUOutcome, ITOFUTokenDecimals}`

Both import the same three symbols from the same file. The ordering is inconsistent. `LibTOFUTokenDecimals.sol` imports only two symbols (`TOFUOutcome`, `ITOFUTokenDecimals`) so is not directly comparable.

**Recommendation:** Adopt a consistent ordering convention (e.g., alphabetical, or interface first then types) across all files.

---

### A06-6: forge-lint `mixed-case-variable` suppressions are necessary and consistent [INFO]

**Files:** `src/concrete/TOFUTokenDecimals.sol` (line 15), `src/lib/LibTOFUTokenDecimalsImplementation.sol` (lines 30, 110, 137, 161)

The storage mapping variable `sTOFUTokenDecimals` uses an `s` prefix followed by all-caps `TOFU`, triggering forge-lint's `mixed-case-variable` rule. All five occurrences are suppressed with the same `// forge-lint: disable-next-line(mixed-case-variable)` comment. This is consistent and justified: the naming convention uses `s` for storage and preserves the `TOFU` acronym.

**Recommendation:** No action required.

---

### A06-7: `forge-lint: pascal-case-struct` suppression for `TOFUTokenDecimalsResult` is justified [INFO]

**File:** `src/interface/ITOFUTokenDecimals.sol` (line 12)

The struct name `TOFUTokenDecimalsResult` starts with the all-caps acronym `TOFU`, which forge-lint flags as violating PascalCase. The suppression is correct and necessary.

**Recommendation:** No action required.

---

### A06-8: Build compiles cleanly with no warnings [INFO]

`forge build` output:
```
Compiling 1 files with Solc 0.8.25
Solc 0.8.25 finished in 502.26ms
Compiler run successful!
```

No Solidity compiler warnings. No unused variable warnings. No dead code detected by the compiler.

**Recommendation:** No action required.

---

### A06-9: No dead code, unused imports, TODO/FIXME markers, or commented-out Solidity code [INFO]

**Scope:** All five source files.

Searches confirm:
- All imports are used in their respective files.
- No `TODO`, `FIXME`, `HACK`, or `XXX` comments exist.
- No commented-out Solidity code exists (only TOML config comments in `foundry.toml`).
- No dead/unreachable code paths.

**Recommendation:** No action required.

---

### A06-10: NatSpec cross-reference pattern ("As per") is consistent but duplicates documentation [LOW]

**Files:** `src/lib/LibTOFUTokenDecimals.sol`, `src/lib/LibTOFUTokenDecimalsImplementation.sol`

Both library files use the pattern `/// @notice As per \`ITOFUTokenDecimals.xxx\`.` to reference the interface, then duplicate `@param` and `@return` tags. The concrete contract uses `@inheritdoc ITOFUTokenDecimals` which avoids duplication.

The library functions cannot use `@inheritdoc` because they have different signatures (extra `sTOFUTokenDecimals` storage parameter in the implementation, or different visibility). The "As per" cross-reference is the correct approach for library functions. However, the duplicated `@return` documentation risks diverging from the interface over time.

**Recommendation:** Accept as-is. The duplication is unavoidable for library functions with different signatures. Monitor for drift when the interface NatSpec is updated.

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 0     |
| MEDIUM   | 0     |
| LOW      | 1     |
| INFO     | 9     |

The codebase demonstrates high code quality. All files follow consistent SPDX licensing, use appropriate pragma strategies for their role in the architecture, employ named imports exclusively, and maintain thorough NatSpec documentation. Lint suppressions are justified and mostly consistent. The only substantive findings are minor style inconsistencies (slither comment style, `@return` naming, import ordering) that do not affect correctness or security.
