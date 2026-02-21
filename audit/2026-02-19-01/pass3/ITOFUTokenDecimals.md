# Audit Pass 3 -- Documentation

**File:** `src/interface/ITOFUTokenDecimals.sol`
**Auditor:** A01
**Date:** 2026-02-19

## 1. Evidence of Thorough Reading

### Interface

- **`ITOFUTokenDecimals`** (line 53)

### Functions (all within `ITOFUTokenDecimals`)

| Function | Line |
|---|---|
| `decimalsForTokenReadOnly(address token)` | 65 |
| `decimalsForToken(address token)` | 73 |
| `safeDecimalsForToken(address token)` | 79 |
| `safeDecimalsForTokenReadOnly(address token)` | 85 |

### Struct

- **`TOFUTokenDecimalsResult`** (line 13) -- fields: `initialized` (bool), `tokenDecimals` (uint8)

### Enum

- **`TOFUOutcome`** (line 19) -- variants: `Initial` (line 21), `Consistent` (line 23), `Inconsistent` (line 25), `ReadFailure` (line 27)

### Error

- **`TokenDecimalsReadFailure`** (line 33) -- parameters: `token` (address), `tofuOutcome` (TOFUOutcome)

### Events

None defined.

---

## 2. Documentation Findings

### A01-1: Interface doc block uses `@title` but has no explicit `@notice` [LOW]

**Location:** Lines 35-52

The `ITOFUTokenDecimals` doc block opens with `@title ITOFUTokenDecimals` on line 35, then continues with untagged prose on lines 36-52. When a doc block contains an explicit tag such as `@title`, all semantic entries should also be explicitly tagged. The descriptive text on lines 36-52 is implicitly treated as a continuation of `@title` by NatSpec parsers, but the author clearly intends it as a `@notice`. An explicit `@notice` tag should be added to the beginning of line 36.

**Recommendation:** Add `@notice` before "Interface for a contract that reads..." on line 36.

---

### A01-2: Struct `TOFUTokenDecimalsResult` doc block has no explicit `@notice` or `@dev` tag for the main description [LOW]

**Location:** Lines 5-11

The doc block for the struct has untagged prose on lines 5-8, then transitions to `@param` tags on lines 9-11. While NatSpec treats leading untagged lines as an implicit `@notice`, the presence of explicit `@param` tags means the block mixes tagged and untagged styles. For consistency and to avoid parser ambiguity, an explicit `@notice` tag should precede the description on line 5.

**Recommendation:** Change line 5 to `/// @notice Encodes the token's decimals for a token. Includes a bool to indicate if`.

---

### A01-3: Error `TokenDecimalsReadFailure` doc block has no explicit `@notice` for the main description [LOW]

**Location:** Lines 30-33

The doc block has an untagged description on line 30 ("Thrown when a TOFU decimals safe read fails.") followed by `@param` tags on lines 31-32. As with A01-2, the mixture of untagged prose with explicit tags is inconsistent. An explicit `@notice` should precede the description.

**Recommendation:** Change line 30 to `/// @notice Thrown when a TOFU decimals safe read fails.`

---

### A01-4: `decimalsForTokenReadOnly` doc says "relatively useless until after `decimalsForToken` has been called" -- accurate but could be clearer [INFO]

**Location:** Lines 58-59

The NatSpec states the function is "relatively useless" before `decimalsForToken` is called. Examining the implementation (`LibTOFUTokenDecimalsImplementation.sol` line 70-74), when `initialized` is false, the function returns `TOFUOutcome.Initial` with the freshly read decimals. This is not "useless" -- it still returns a valid read; it just cannot confirm consistency since there is no stored baseline. The word "useless" is slightly misleading; the function still provides a valid decimals read, it simply cannot provide a `Consistent` outcome. The documentation is imprecise but not incorrect.

**Recommendation:** Consider rewording to clarify that the function can still read decimals, but cannot confirm consistency, until `decimalsForToken` has initialized storage.

---

### A01-5: All four interface functions have complete `@param` and `@return` NatSpec [INFO]

**Location:** Lines 54-85

All four functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) have:
- `@param token` documented
- `@return` tags matching all return values

The return tag names (`tofuOutcome`, `tokenDecimals`) match the documented names. The descriptions accurately reflect the implementation behavior. No issues found.

---

### A01-6: All struct fields have `@param` documentation [INFO]

**Location:** Lines 9-11

Both fields of `TOFUTokenDecimalsResult` (`initialized` and `tokenDecimals`) have `@param` tags with accurate descriptions. The `initialized` description correctly explains it guards against default `0` being misinterpreted. Verified against the implementation at `LibTOFUTokenDecimalsImplementation.sol` line 70 where `initialized` is checked before treating `tokenDecimals` as a valid stored value.

---

### A01-7: All enum variants have documentation [INFO]

**Location:** Lines 20-28

All four `TOFUOutcome` variants have inline doc comments:
- `Initial` (line 20): "Token's decimals have not been read from the external contract before." -- Accurate per implementation line 70-74 of `LibTOFUTokenDecimalsImplementation.sol`.
- `Consistent` (line 22): "Token's decimals are consistent with the stored value." -- Accurate per implementation line 78.
- `Inconsistent` (line 24): "Token's decimals are inconsistent with the stored value." -- Accurate per implementation line 78.
- `ReadFailure` (line 26): "Token's decimals could not be read from the external contract." -- Accurate per implementation lines 64-66.

---

### A01-8: Error parameters have `@param` documentation [INFO]

**Location:** Lines 31-32

Both parameters of `TokenDecimalsReadFailure` (`token` and `tofuOutcome`) have `@param` tags. The descriptions are accurate: `token` is the token address, and `tofuOutcome` is the outcome of the TOFU read. Verified that the error is only reverted with `ReadFailure` or `Inconsistent` outcomes in the implementation (lines 127-128 and 143-144 of `LibTOFUTokenDecimalsImplementation.sol`).

---

### A01-9: `safeDecimalsForToken` docs say "reverting if the read fails or is inconsistent" -- verify accuracy [INFO]

**Location:** Lines 75-78

The NatSpec states the function reverts "if the read fails or is inconsistent with the stored value." Checking the implementation at `LibTOFUTokenDecimalsImplementation.sol` line 127: `if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial)` -- this reverts on both `Inconsistent` and `ReadFailure`, which matches the documentation. The function allows `Initial` and `Consistent` through. Documentation is accurate.

---

### A01-10: `safeDecimalsForTokenReadOnly` docs say "reverting if the read fails or is inconsistent" -- verify accuracy [INFO]

**Location:** Lines 81-84

Same revert condition as `safeDecimalsForToken`, verified at `LibTOFUTokenDecimalsImplementation.sol` line 143. Documentation is accurate.

---

## Summary

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 3 |
| INFO | 7 |

The interface file is well-documented overall. All functions, struct fields, error parameters, and enum variants have documentation. The three LOW findings (A01-1, A01-2, A01-3) relate to inconsistent NatSpec tagging style where doc blocks mix untagged prose with explicit tags -- adding explicit `@notice` tags would improve consistency and prevent NatSpec parser ambiguity. The single substantive documentation accuracy concern (A01-4, INFO) is about slightly imprecise language ("relatively useless") that could be clarified but is not materially wrong.
