# Pass 3 (Documentation) -- LibTOFUTokenDecimalsImplementation.sol

**Auditor:** A05
**Date:** 2026-02-21
**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol` (171 lines)

---

## 1. Evidence of Thorough Reading

### Library

- `LibTOFUTokenDecimalsImplementation` (line 13)

### Constants

| Name | Line | Type | Value |
|------|------|------|-------|
| `TOFU_DECIMALS_SELECTOR` | 15 | `bytes4` | `0x313ce567` |

### Functions

| Function | Line | Visibility | Mutability |
|----------|------|------------|------------|
| `decimalsForTokenReadOnly` | 29 | `internal` | `view` |
| `decimalsForToken` | 109 | `internal` | (non-view, writes storage) |
| `safeDecimalsForToken` | 136 | `internal` | (non-view, writes storage) |
| `safeDecimalsForTokenReadOnly` | 160 | `internal` | `view` |

### forge-lint Suppression Annotations

| Annotation | Line(s) | Lint Rule |
|------------|---------|-----------|
| `disable-next-line(mixed-case-variable)` | 30, 110, 137, 161 | Mixed-case variable naming for `sTOFUTokenDecimals` parameter |
| `disable-next-line(unsafe-typecast)` | 70 | `uint256` to `uint8` cast in `decimalsForTokenReadOnly` |

---

## 2. NatSpec Coverage Inventory

### Library-Level

| Item | Tag | Present | Accurate |
|------|-----|---------|----------|
| Library title | `@title` | Yes (line 7) | Yes -- matches library name exactly |
| Library description | `@notice` | Yes (lines 8-12) | Yes -- accurately describes TOFU approach, mentions `TOFUTokenDecimals` concrete contract |

### Constant: `TOFU_DECIMALS_SELECTOR`

| Item | Tag | Present | Accurate |
|------|-----|---------|----------|
| Description | `@dev` | Yes (line 14) | Yes -- correctly states it is the `decimals()` selector. Value `0x313ce567` confirmed via `cast sig "decimals()"` |

### Function: `decimalsForTokenReadOnly` (line 29)

| Item | Tag | Present | Accurate |
|------|-----|---------|----------|
| Description | `@notice` | Yes (lines 17-19) | Yes -- references `ITOFUTokenDecimals.decimalsForTokenReadOnly` and clarifies read-only behaviour |
| `sTOFUTokenDecimals` | `@param` | Yes (lines 20-23) | Yes -- describes storage mapping purpose |
| `token` | `@param` | Yes (line 24) | Yes |
| `tofuOutcome` (return) | `@return` | Yes (line 25) | Yes |
| `tokenDecimals` (return) | `@return` | Yes (lines 26-28) | Yes -- documents behaviour per outcome |

### Function: `decimalsForToken` (line 109)

| Item | Tag | Present | Accurate |
|------|-----|---------|----------|
| Description | `@notice` | Yes (lines 81-99) | Yes -- detailed explanation of TOFU approach |
| `sTOFUTokenDecimals` | `@param` | Yes (lines 100-103) | Yes |
| `token` | `@param` | Yes (line 104) | Yes |
| `tofuOutcome` (return) | `@return` | Yes (line 105) | Yes |
| `tokenDecimals` (return) | `@return` | Yes (lines 106-108) | Yes -- matches renamed local variable |

### Function: `safeDecimalsForToken` (line 136)

| Item | Tag | Present | Accurate |
|------|-----|---------|----------|
| Description | `@notice` | Yes (lines 125-129) | Yes -- references `ITOFUTokenDecimals.safeDecimalsForToken`, describes revert-on-failure |
| `sTOFUTokenDecimals` | `@param` | Yes (lines 130-133) | Yes |
| `token` | `@param` | Yes (line 134) | Yes |
| Return value | `@return` | Yes (line 135) | See finding A05-3 below |

### Function: `safeDecimalsForTokenReadOnly` (line 160)

| Item | Tag | Present | Accurate |
|------|-----|---------|----------|
| Description | `@notice` | Yes (lines 148-153) | Yes -- includes WARNING about pre-initialization |
| `sTOFUTokenDecimals` | `@param` | Yes (lines 154-157) | Yes |
| `token` | `@param` | Yes (line 158) | Yes |
| Return value | `@return` | Yes (line 159) | See finding A05-4 below |

---

## 3. Findings

### A05-1 [INFO] -- `safeDecimalsForToken` NatSpec says "reverts if inconsistent or read fails" but does not explicitly mention `Inconsistent` outcome by name

**Location:** Lines 125-129

**Description:** The `@notice` for `safeDecimalsForToken` states it "reverts with `ITOFUTokenDecimals.TokenDecimalsReadFailure` if the token's decimals are inconsistent or the read fails." The implementation (line 142) checks `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial`, which means it reverts on both `Inconsistent` and `ReadFailure`. The NatSpec is accurate in spirit ("inconsistent or the read fails") but uses informal wording rather than referencing the enum values `TOFUOutcome.Inconsistent` and `TOFUOutcome.ReadFailure` explicitly.

The interface `ITOFUTokenDecimals.safeDecimalsForToken` (line 80-84) uses the same phrasing: "reverting if the read fails or is inconsistent with the stored value." The library and interface are consistent with each other.

**Impact:** None. The documentation is correct and understandable.

---

### A05-2 [INFO] -- `decimalsForToken` has a more detailed standalone `@notice` compared to the cross-referencing style of other functions

**Location:** Lines 81-99 vs lines 17-19, 125-127, 148-149

**Description:** `decimalsForTokenReadOnly`, `safeDecimalsForToken`, and `safeDecimalsForTokenReadOnly` all begin their `@notice` with "As per `ITOFUTokenDecimals.<functionName>`" and then add a brief clarification. In contrast, `decimalsForToken` (lines 81-99) begins with the same cross-reference pattern ("As per `ITOFUTokenDecimals.decimalsForToken`") but then includes a full 18-line standalone description of the TOFU approach. This is not a defect -- it provides useful documentation at the core function -- but creates a minor stylistic inconsistency across the four functions.

**Impact:** None. The extra detail is helpful.

---

### A05-3 [LOW] -- `safeDecimalsForToken` `@return` tag lacks a named return variable

**Location:** Line 135

**Description:** The `@return` tag reads `@return The token's decimals.` without naming the return variable. The function signature on line 140 declares an unnamed `uint8` return. By contrast, the interface at line 83 names the return `tokenDecimals`. Using `@return tokenDecimals The token's decimals.` in the library would be more precise and consistent with the interface.

**Impact:** Minor documentation inconsistency. Tooling that displays NatSpec may show less informative output.

---

### A05-4 [LOW] -- `safeDecimalsForTokenReadOnly` `@return` tag lacks a named return variable

**Location:** Line 159

**Description:** Same as A05-3 but for `safeDecimalsForTokenReadOnly`. The `@return` tag reads `@return The token's decimals.` without naming the return variable. The interface at line 95 names it `tokenDecimals`.

**Impact:** Minor documentation inconsistency.

---

### A05-5 [INFO] -- NatSpec tag style is consistent throughout the file

**Description:** All documentation comments use the `///` style with proper `@title`, `@notice`, `@dev`, `@param`, and `@return` tags. No bare `///` comments are used for NatSpec documentation of public API elements. Internal inline comments (e.g., lines 36-41, 59-60, 65-66, 68-69, 73) use `//` appropriately. The forge-lint suppression annotations consistently use the `// forge-lint: disable-next-line(...)` format.

**Impact:** None. Good practice.

---

### A05-6 [INFO] -- Interface cross-references are accurate

**Description:** All four functions cross-reference their corresponding interface method in `ITOFUTokenDecimals` using the "As per `ITOFUTokenDecimals.<functionName>`" pattern. Verified that:
- `decimalsForTokenReadOnly` references `ITOFUTokenDecimals.decimalsForTokenReadOnly` (interface line 67)
- `decimalsForToken` references `ITOFUTokenDecimals.decimalsForToken` (interface line 78)
- `safeDecimalsForToken` references `ITOFUTokenDecimals.safeDecimalsForToken` (interface line 84)
- `safeDecimalsForTokenReadOnly` references `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly` (interface line 96)

All references resolve correctly and the library functions match the interface signatures (with the addition of the `sTOFUTokenDecimals` storage mapping parameter).

**Impact:** None. Cross-references are correct.

---

### A05-7 [INFO] -- `safeDecimalsForTokenReadOnly` WARNING about pre-initialization is present and matches the interface

**Location:** Lines 150-153 (library), lines 90-93 (interface)

**Description:** Both the library and the interface include a `WARNING` about the pre-initialization behavior of `safeDecimalsForTokenReadOnly`: before `decimalsForToken` has been called for a token, each call returns a fresh `Initial` read and cannot detect inconsistency between calls. The library's wording is a close paraphrase of the interface's wording. Both correctly advise callers to ensure `decimalsForToken` has been called at least once.

**Impact:** None. Important safety documentation is present and accurate.

---

### A05-8 [INFO] -- NatSpec accuracy verified against implementation for all functions

**Description:** Verified each function's NatSpec claims against the actual code:

1. **`decimalsForTokenReadOnly`**: Claims read-only behavior -- confirmed by `view` modifier and no storage writes. Claims it returns stored value on ReadFailure -- confirmed at line 62. Claims it returns freshly read value on Initial -- confirmed at line 71. Claims consistency check uses stored value -- confirmed at lines 74-77.

2. **`decimalsForToken`**: Claims it stores on first read only -- confirmed by the `if (tofuOutcome == TOFUOutcome.Initial)` guard at line 119. Claims it delegates to `decimalsForTokenReadOnly` -- confirmed at line 117.

3. **`safeDecimalsForToken`**: Claims it reverts on inconsistent or read failure -- confirmed by the condition at line 142 which allows only `Consistent` and `Initial` to pass. Claims it reverts with `TokenDecimalsReadFailure` -- confirmed at line 143.

4. **`safeDecimalsForTokenReadOnly`**: Claims read-only and same revert behavior -- confirmed by `view` modifier and identical revert logic at lines 166-167.

**Impact:** None. All NatSpec claims are accurate.

---

## 4. Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 2 |
| INFO | 6 |

The documentation in `LibTOFUTokenDecimalsImplementation.sol` is thorough and accurate. All four functions and the constant have complete NatSpec coverage. The two LOW findings (A05-3, A05-4) relate to unnamed return variables in `@return` tags for the two `safe*` functions, where the interface names them `tokenDecimals`. All NatSpec claims were verified against the implementation and found to be accurate. Interface cross-references are correct and the WARNING about pre-initialization on `safeDecimalsForTokenReadOnly` is present and matches the interface.
