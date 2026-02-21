<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 3 – Documentation Audit: `src/lib/LibTOFUTokenDecimals.sol`

Auditor: A04
Date: 2026-02-21
Pass: 3 (Documentation)

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Functions and Their Line Numbers

| Function | Visibility | Mutability | Line |
|---|---|---|---|
| `ensureDeployed()` | `internal` | `view` | 50 |
| `decimalsForTokenReadOnly(address token)` | `internal` | `view` | 65 |
| `decimalsForToken(address token)` | `internal` | (none / state-modifying) | 78 |
| `safeDecimalsForToken(address token)` | `internal` | (none / state-modifying) | 88 |
| `safeDecimalsForTokenReadOnly(address token)` | `internal` | `view` | 96 |

### Types, Errors, and Constants Defined

| Kind | Name | Line |
|---|---|---|
| `error` | `TOFUTokenDecimalsNotDeployed(address deployedAddress)` | 24 |
| `constant` | `TOFU_DECIMALS_DEPLOYMENT` (`ITOFUTokenDecimals`) | 29–30 |
| `constant` | `TOFU_DECIMALS_EXPECTED_CODE_HASH` (`bytes32`) | 36–37 |
| `constant` | `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (`bytes`) | 44–45 |

Imports: `TOFUOutcome`, `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5).

### NatSpec Comments Found

| Location | Tag | Content |
|---|---|---|
| Library (line 7) | `@title` | `LibTOFUTokenDecimals` |
| Library (lines 8–20) | `@notice` | Multi-sentence description of TOFU approach, read-only vs read-write variants, and the caller-convenience role of the library |
| Error (line 22) | `@notice` | "Thrown when the singleton is not deployed or has an unexpected codehash." |
| Error (line 23) | `@param` | `deployedAddress` – "The address that was expected to have the singleton." |
| Constant `TOFU_DECIMALS_DEPLOYMENT` (lines 26–28) | `@notice` | Describes the deployed address and its Zoltu determinism |
| Constant `TOFU_DECIMALS_EXPECTED_CODE_HASH` (lines 32–35) | `@notice` | Describes purpose of the codehash and safety rationale |
| Constant `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (lines 39–42) | `@notice` | Describes the init bytecode and its relationship to the deployment |
| `ensureDeployed` (lines 47–49) | `@notice` | Describes guard purpose |
| `decimalsForTokenReadOnly` (line 59) | (bare `///`) | "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`." |
| `decimalsForTokenReadOnly` (lines 60–64) | `@param`, `@return` (×2) | `token`, `tofuOutcome`, `tokenDecimals` |
| `decimalsForToken` (line 72) | (bare `///`) | "As per `ITOFUTokenDecimals.decimalsForToken`." |
| `decimalsForToken` (lines 73–77) | `@param`, `@return` (×2) | `token`, `tofuOutcome`, `tokenDecimals` |
| `safeDecimalsForToken` (line 85) | (bare `///`) | "As per `ITOFUTokenDecimals.safeDecimalsForToken`." |
| `safeDecimalsForToken` (lines 86–87) | `@param`, `@return` | `token`, `tokenDecimals` |
| `safeDecimalsForTokenReadOnly` (line 93) | (bare `///`) | "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`." |
| `safeDecimalsForTokenReadOnly` (lines 94–95) | `@param`, `@return` | `token`, `tokenDecimals` |

---

## Findings

### F-01 — `ensureDeployed` has no `@notice` tag in its NatSpec block

**Severity:** LOW

**Location:** Lines 47–50

**Observation:** The `ensureDeployed` function has a comment block that starts with `/// @notice` directly (lines 47–49). On inspection this is actually fine—`@notice` is present. However, the comment block uses a `@notice` that describes the guard purpose but does **not** include a `@param` (none needed) or a `@return` (none returned). That is correct and complete given the signature.

Re-reading more carefully: no issue with missing tags here. Retracted as a finding—see F-02 below for the actual issue with this function's NatSpec pattern.

---

### F-02 — Four delegating functions use a bare `///` sentence instead of `@notice`

**Severity:** MEDIUM

**Location:** Lines 59, 72, 85, 93

**Observation:** Each of the four delegating functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) opens its NatSpec block with a bare `///` line such as:

```solidity
/// As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`.
```

This text is not tagged with `@notice` or `@dev`. Solidity NatSpec parsers treat untagged lines at the start of a doc comment as implicitly belonging to `@notice`, but this is fragile and non-standard. Tools such as `solc --userdoc`, `forge doc`, and external documentation generators may silently drop or misattribute the text. The canonical practice is to explicitly tag every top-level description line.

**Recommendation:** Replace the bare `///` opening line with `/// @notice As per ...` on all four functions.

**Example fix for `decimalsForTokenReadOnly`:**
```solidity
/// @notice As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`.
/// @param token The token to read the decimals for.
```

---

### F-03 — `decimalsForTokenReadOnly` and `decimalsForToken` have two `@return` values but only one named return variable in the signature

**Severity:** LOW

**Location:** Lines 60–64 (`decimalsForTokenReadOnly`), lines 73–77 (`decimalsForToken`)

**Observation:** Both functions declare two `@return` tags with names `tofuOutcome` and `tokenDecimals`:

```solidity
/// @return tofuOutcome The outcome of the TOFU read.
/// @return tokenDecimals The token's decimals. ...
function decimalsForTokenReadOnly(address token) internal view returns (TOFUOutcome, uint8) {
```

However, the Solidity return list uses unnamed types (`TOFUOutcome, uint8`). While `@return` names in NatSpec do not have to match Solidity named returns, some NatSpec parsers key on position rather than name when returns are unnamed. This is a minor style inconsistency but is not incorrect per the NatSpec specification; it is an accepted pattern for multi-return functions. Marking as INFO.

**Severity reclassified:** INFO

---

### F-04 — `ensureDeployed` `@notice` description does not mention the codehash mismatch case explicitly

**Severity:** LOW

**Location:** Lines 47–49

**Observation:** The `@notice` for `ensureDeployed` reads:

> "Ensures that the TOFUTokenDecimals contract is deployed. Having an explicit guard prevents silent call failures and gives a clear error message for easier debugging."

The function actually checks **two** conditions: (1) that `code.length != 0` and (2) that `codehash == TOFU_DECIMALS_EXPECTED_CODE_HASH`. The second condition catches a scenario where *some* contract is deployed at that address but is not the expected singleton (e.g. a replacement with different bytecode). The `@notice` only describes the first scenario ("is deployed") and omits the codehash mismatch case entirely. A caller reading only the NatSpec may not understand that the function also guards against a wrong contract at the address.

**Recommendation:** Extend the `@notice` to mention the codehash verification:

```solidity
/// @notice Ensures that the TOFUTokenDecimals singleton is deployed at the
/// expected address and matches the expected codehash. An explicit guard
/// prevents silent failures and distinguishes "not deployed" from
/// "wrong contract deployed at that address".
```

---

### F-05 — Delegating-function `@notice` text is minimal and does not provide standalone context

**Severity:** LOW

**Location:** Lines 59, 72, 85, 93

**Observation:** The descriptions "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`." and similar are cross-references rather than self-contained documentation. A user of the library reading generated docs (e.g. `forge doc` output) will see only the cross-reference and must navigate to the interface to understand the function's behaviour. The interface functions themselves also lack `@notice` tags (they use bare `///` descriptions), so the cross-reference leads to another under-tagged location.

This is a documentation completeness gap. The NatSpec standard recommends that `@notice` describe the function to end users in a standalone manner. The current text does not meet that bar.

**Recommendation:** Either (a) copy the interface's description text into a `@notice` on each wrapper, or (b) supplement the cross-reference with a one-sentence summary of behaviour, e.g.:

```solidity
/// @notice Wraps `ITOFUTokenDecimals.decimalsForTokenReadOnly`; reads
/// the stored decimals for `token` without writing state.
```

---

### F-06 — `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant has no `@dev` rationale for why callers might need it

**Severity:** INFO

**Location:** Lines 39–45

**Observation:** The `@notice` for `TOFU_DECIMALS_EXPECTED_CREATION_CODE` explains what the constant *is* but does not explain why it is exposed as a public constant on the library rather than kept private or moved to tests. Callers might wonder whether they are expected to use this constant directly (e.g. for their own deployment verification) or whether it is purely for internal/test use. A `@dev` note clarifying the intended consumer of this constant would eliminate ambiguity.

**Recommendation:** Add a `@dev` line:

```solidity
/// @dev Exposed so callers can verify the expected bytecode off-chain or in
/// tests without re-deriving it; not required for normal usage.
```

---

### F-07 — `TOFUTokenDecimalsNotDeployed` error's `@param` name `deployedAddress` is misleading

**Severity:** LOW

**Location:** Lines 22–24

**Observation:** The error is defined as:

```solidity
/// @param deployedAddress The address that was expected to have the singleton.
error TOFUTokenDecimalsNotDeployed(address deployedAddress);
```

The parameter name `deployedAddress` implies that something has been deployed there, but the error is thrown precisely when *nothing* (or the wrong contract) is at that address. A more accurate name would be `expectedAddress` or `singletonAddress`. The `@param` description ("The address that was expected to have the singleton") is accurate, but the parameter name itself contradicts both the description and the error name.

**Recommendation:** Rename `deployedAddress` to `expectedAddress` (or `singletonAddress`) in both the error definition and the `@param` tag, and update the revert site at line 55 accordingly.

---

### F-08 — Library-level `@notice` mentions "read-only version" but does not name it

**Severity:** INFO

**Location:** Lines 8–20

**Observation:** The library-level `@notice` states:

> "...there is a read-only version of the logic to simply check that decimals are either uninitialized or consistent, without storing anything."

It correctly describes the split between read-only and read-write variants, but does not name the specific functions (`decimalsForTokenReadOnly`, `safeDecimalsForTokenReadOnly`). Adding function name references (using backticks) would make the notice more directly useful as cross-linked documentation.

**Recommendation:** Minor wording improvement to reference the functions by name.

---

## Summary Table

| ID | Severity | Description |
|---|---|---|
| F-02 | MEDIUM | Four functions open NatSpec with bare `///` instead of `@notice` |
| F-04 | LOW | `ensureDeployed` `@notice` omits codehash-mismatch case |
| F-05 | LOW | Delegating-function descriptions are cross-references only, not standalone |
| F-07 | LOW | `TOFUTokenDecimalsNotDeployed` parameter name `deployedAddress` is misleading |
| F-03 | INFO | Named `@return` tags on unnamed return tuple (style, not incorrect) |
| F-06 | INFO | `TOFU_DECIMALS_EXPECTED_CREATION_CODE` lacks `@dev` rationale for exposure |
| F-08 | INFO | Library `@notice` does not name the read-only functions it references |

No CRITICAL or HIGH documentation findings. The library is reasonably well documented; the main actionable issues are the missing `@notice` tags on delegating function descriptions (F-02) and the incomplete `ensureDeployed` notice (F-04).
