<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 3 — Documentation Audit: `src/interface/ITOFUTokenDecimals.sol`

Auditor: A03
Date: 2026-02-21
Pass: 3 (Documentation)

---

## Evidence of Thorough Reading

### Interface Name

- `ITOFUTokenDecimals` (line 53)

### Structs

| Name | Line |
|------|------|
| `TOFUTokenDecimalsResult` | 13 |

Fields:
- `initialized` (bool) — line 14
- `tokenDecimals` (uint8) — line 15

### Enums

| Name | Line |
|------|------|
| `TOFUOutcome` | 19 |

Variants:
- `Initial` — line 21
- `Consistent` — line 23
- `Inconsistent` — line 25
- `ReadFailure` — line 27

### Errors

| Name | Line |
|------|------|
| `TokenDecimalsReadFailure` | 33 |

Parameters: `address token`, `TOFUOutcome tofuOutcome`

### Functions

| Name | Line |
|------|------|
| `decimalsForTokenReadOnly` | 67 |
| `decimalsForToken` | 77 |
| `safeDecimalsForToken` | 83 |
| `safeDecimalsForTokenReadOnly` | 91 |

### NatSpec Comments Found

**File-level / free-floating (before the interface declaration):**

- Lines 5–8: `@notice` on `TOFUTokenDecimalsResult` struct — describes purpose and the `initialized` guard.
- Lines 9–11: `@param initialized` and `@param tokenDecimals` on the struct.
- Line 18: Plain `///` comment (no `@notice` tag) on `TOFUOutcome` enum.
- Lines 20, 22, 24, 26: Plain `///` inline comments on each enum variant (no NatSpec tags).
- Lines 30–32: `@notice` and `@param token` / `@param tofuOutcome` on `TokenDecimalsReadFailure` error.

**Inside the interface:**

- Lines 35–52: `@title ITOFUTokenDecimals` and `@notice` on the interface itself.
- Lines 54–66: Plain `///` comment block (no `@notice` tag) + `@param token`, `@return tofuOutcome`, `@return tokenDecimals` on `decimalsForTokenReadOnly`.
- Lines 69–76: Plain `///` comment block (no `@notice` tag) + `@param token`, `@return tofuOutcome`, `@return tokenDecimals` on `decimalsForToken`.
- Lines 79–82: Plain `///` comment block (no `@notice` tag) + `@param token`, `@return tokenDecimals` on `safeDecimalsForToken`.
- Lines 85–90: Plain `///` comment block (no `@notice` tag) + `@param token`, `@return tokenDecimals` on `safeDecimalsForTokenReadOnly`.

---

## Findings

---

### FINDING-DOC-01 — [MEDIUM] Functions inside the interface lack `@notice` tags; use bare `///` prose instead

**Location:** Lines 54–66 (`decimalsForTokenReadOnly`), 69–76 (`decimalsForToken`), 79–82 (`safeDecimalsForToken`), 85–90 (`safeDecimalsForTokenReadOnly`)

**Description:**

All four functions in the interface document their description using plain `///` comment lines without a `@notice` tag. The `@param` and `@return` tags that follow are proper NatSpec, but the leading prose block is not tagged. Solidity/NatSpec parsers (solc, natspec-smells, forge doc) treat an untagged leading `///` line as an implicit `@notice`, so this is technically valid. However, the style is inconsistent with the rest of the file, where `@notice` is used explicitly on the struct, the error, and the interface itself.

**Evidence — inconsistency within the same file:**

- Struct `TOFUTokenDecimalsResult` (line 5): uses explicit `@notice`.
- Error `TokenDecimalsReadFailure` (line 30): uses explicit `@notice`.
- Interface `ITOFUTokenDecimals` (line 36): uses explicit `@notice`.
- All four functions: omit `@notice` on the descriptive prose block.

**Impact:** Cosmetic / tooling. `forge doc` will still pick up the prose as the notice. However, linting tools that require an explicit `@notice` tag will flag these functions. The inconsistency degrades readability and violates the implicit style guide established elsewhere in the file.

**Recommendation:** Prefix the descriptive prose of each function with `@notice`, e.g.:

```solidity
/// @notice Reads the decimals for a token in a read-only manner. This does not store
/// the decimals ...
```

---

### FINDING-DOC-02 — [MEDIUM] Enum `TOFUOutcome` lacks a `@notice` tag on the enum declaration line

**Location:** Line 18

**Description:**

The comment directly above the `TOFUOutcome` enum is:

```solidity
/// Outcomes for TOFU token decimals reads.
```

This is an untagged bare `///` comment — there is no `@notice` tag. Every other top-level item that carries a description (`TOFUTokenDecimalsResult`, `TokenDecimalsReadFailure`, and the interface itself) uses an explicit `@notice`. The enum is the sole exception.

**Recommendation:** Change to:

```solidity
/// @notice Outcomes for TOFU token decimals reads.
```

---

### FINDING-DOC-03 — [LOW] Enum variants use untagged `///` comments; NatSpec does not define a tag for enum values

**Location:** Lines 20 (`Initial`), 22 (`Consistent`), 24 (`Inconsistent`), 26 (`ReadFailure`)

**Description:**

The four enum variant comments are bare `///` prose:

```solidity
/// Token's decimals have not been read from the external contract before.
Initial,
```

NatSpec does not formally define a tag for individual enum variant documentation, so plain `///` is the pragmatic norm. This is not an error, but it is worth noting so that the style choice is recorded as intentional rather than an oversight.

**Impact:** Informational. No tooling incompatibility; the comments are still surfaced by `forge doc`.

**Recommendation:** No action required. Document in the style guide that bare `///` is the accepted form for enum variants.

---

### FINDING-DOC-04 — [LOW] `decimalsForToken` description omits mention of state-mutation behavior (writing the decimals on first use)

**Location:** Lines 69–71

**Description:**

The description for `decimalsForToken` reads:

> Reads the decimals for a token, storing them if this is the first read.

This is accurate and complete at a high level. However, it does not specify that the stored value is the value freshly read at that moment, nor does it explicitly contrast with `decimalsForTokenReadOnly` regarding state mutation. Compare with `LibTOFUTokenDecimalsImplementation.decimalsForToken` (lines 81–98 of the implementation file), which provides a much richer description including all four outcome paths.

The interface-level documentation is the primary contract for callers, yet it has less detail than the implementation's inline comments. A reader consulting only the interface has a lower-fidelity understanding of the state transitions.

**Impact:** Minor documentation gap. Callers may not understand that on `Initial` the state is written, whereas on `ReadFailure` it is not.

**Recommendation:** Expand the description to call out that state is written only on the `Initial` outcome:

```solidity
/// @notice Reads the decimals for a token, storing them on the first successful
/// read (`Initial` outcome). On subsequent reads the stored value is used for
/// consistency checks. State is not written on `ReadFailure` or when a stored
/// value already exists.
```

---

### FINDING-DOC-05 — [LOW] `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` do not name the revert error in their NatSpec

**Location:** Lines 79–82 (`safeDecimalsForToken`), 85–90 (`safeDecimalsForTokenReadOnly`)

**Description:**

Both "safe" functions revert with `TokenDecimalsReadFailure` on failure. Neither the prose description nor the `@return` tag mentions this. NatSpec supports a `@dev` tag or prose note to name the revert error. Callers cannot discover the error type from the interface documentation alone without reading the concrete implementation or the error declaration.

The implementation (`LibTOFUTokenDecimalsImplementation`, lines 124–127 and 147–151) documents this clearly:

> Same as `decimalsForToken` but reverts with `TokenDecimalsReadFailure` if the token's decimals are inconsistent or the read fails.

This information is absent from the interface.

**Impact:** Callers may not know which error to catch unless they read the implementation source. This is a usability gap for integrators relying solely on the interface.

**Recommendation:** Add a note to each function, e.g.:

```solidity
/// @notice Safely reads the decimals for a token, reverting with
/// `TokenDecimalsReadFailure` if the read fails or is inconsistent with
/// the stored value.
```

---

### FINDING-DOC-06 — [LOW] `safeDecimalsForTokenReadOnly` description does not warn about the no-TOFU-protection-before-initialization risk

**Location:** Lines 85–90

**Description:**

The interface description for `safeDecimalsForTokenReadOnly` states:

> When the token is uninitialized (no prior `decimalsForToken` call), returns the freshly read value without persisting it.

This is accurate, but it does not warn about the security implication: before initialization, every call is a fresh `Initial` read with no anchor value, so the read-only function cannot detect inconsistency between successive calls. The implementation library (`LibTOFUTokenDecimalsImplementation`, lines 147–151) carries an explicit `WARNING`:

> WARNING: Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected. Callers needing TOFU protection must ensure `decimalsForToken` has been called at least once for the token.

This warning is omitted from the interface NatSpec, which is the primary documentation surface for integrators.

**Impact:** An integrator who reads only the interface may not realise that `safeDecimalsForTokenReadOnly` provides no TOFU guarantee before initialization, leading to a false sense of security.

**Recommendation:** Surface the warning in the interface NatSpec, e.g.:

```solidity
/// @notice Safely reads the decimals for a token in a read-only manner, reverting
/// if the read fails or is inconsistent with the stored value. When the
/// token is uninitialized (no prior `decimalsForToken` call), returns the
/// freshly read value without persisting it.
/// @dev WARNING: Before initialization, each call is a fresh read with no
/// anchor value to check against. Inconsistency between successive calls
/// cannot be detected until `decimalsForToken` has been called at least once.
```

---

### FINDING-DOC-07 — [INFO] Return parameter names are not declared in the function signatures but are named in `@return` tags

**Location:** Lines 67, 77, 83, 91

**Description:**

The function signatures declare unnamed return values:

```solidity
function decimalsForToken(address token) external returns (TOFUOutcome, uint8);
```

The `@return` tags then use names (`tofuOutcome`, `tokenDecimals`) that do not correspond to any declared return variable name in the signature. This is valid NatSpec practice — names in `@return` tags are purely for documentation — but it means there is a subtle asymmetry: readers of the ABI/signature alone cannot see the names without consulting the NatSpec.

This is a style observation and not an error. Naming the return variables in the signature (e.g. `returns (TOFUOutcome tofuOutcome, uint8 tokenDecimals)`) would align signature and documentation.

**Impact:** Informational. No functional impact.

**Recommendation:** Consider naming the return variables in the function signatures to be self-documenting at the ABI level, consistent with how the implementation library does it.

---

### FINDING-DOC-08 — [INFO] `@param` names on `TokenDecimalsReadFailure` use informal names inconsistent with the error parameter names

**Location:** Lines 30–33

**Description:**

The error declaration is:

```solidity
error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome);
```

The NatSpec tags are:

```solidity
/// @param token The token that failed to read decimals.
/// @param tofuOutcome The outcome of the TOFU read.
```

The names match the parameter names exactly. This is correct. No issue — listed for completeness.

---

## Summary Table

| ID | Severity | Title |
|----|----------|-------|
| FINDING-DOC-01 | MEDIUM | Functions inside the interface lack `@notice` tags; use bare `///` prose |
| FINDING-DOC-02 | MEDIUM | `TOFUOutcome` enum declaration lacks `@notice` tag |
| FINDING-DOC-03 | LOW | Enum variants use untagged `///` comments (intentional, not a NatSpec tag) |
| FINDING-DOC-04 | LOW | `decimalsForToken` description omits state-mutation detail |
| FINDING-DOC-05 | LOW | Safe functions do not name `TokenDecimalsReadFailure` revert error in NatSpec |
| FINDING-DOC-06 | LOW | `safeDecimalsForTokenReadOnly` omits the pre-initialization TOFU-risk warning |
| FINDING-DOC-07 | INFO | Return variables unnamed in signatures but named in `@return` tags |
| FINDING-DOC-08 | INFO | `@param` names on error match parameters — no issue (completeness note) |

---

## Overall Assessment

The interface is well-structured and the most critical facts (struct field semantics, enum variant meanings, error parameters, and the interface-level rationale) are documented. The main recurring weakness is **inconsistent NatSpec tag usage**: the struct, error, and interface block use explicit `@notice` tags, while all four function descriptions rely on bare `///` prose. The most impactful gap for integrators is the omission of the pre-initialization TOFU-risk warning on `safeDecimalsForTokenReadOnly` (FINDING-DOC-06) and the missing revert-error identification on the safe functions (FINDING-DOC-05). No documentation was found to be factually inaccurate against the implementation.
