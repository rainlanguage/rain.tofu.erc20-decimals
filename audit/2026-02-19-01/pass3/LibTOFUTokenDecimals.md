# Audit Pass 3 -- Documentation

**File:** `src/lib/LibTOFUTokenDecimals.sol`
**Agent:** A04
**Date:** 2026-02-19

---

## 1. Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Functions

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `ensureDeployed` | 48 | `internal` | `view` |
| `decimalsForTokenReadOnly` | 58 | `internal` | `view` |
| `decimalsForToken` | 66 | `internal` | (state-changing) |
| `safeDecimalsForToken` | 74 | `internal` | (state-changing) |
| `safeDecimalsForTokenReadOnly` | 80 | `internal` | `view` |

### Constants

| Constant | Line | Type | Value |
|---|---|---|---|
| `TOFU_DECIMALS_DEPLOYMENT` | 28-29 | `ITOFUTokenDecimals` | `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | 35-36 | `bytes32` | `0x1de7d71...` |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | 42-43 | `bytes` | (hex literal) |

### Errors

| Error | Line | Parameters |
|---|---|---|
| `TOFUTokenDecimalsNotDeployed` | 23 | `address deployedAddress` |

---

## 2. Documentation Findings

### A04-1: Library doc block has `@title` but no explicit `@notice` [LOW]

**Location:** Lines 7-20

The library-level NatSpec uses the `@title` tag (line 7) but the remaining description (lines 8-20) is an implicit `@notice` -- it is not explicitly tagged with `@notice`. When a doc block uses any explicit NatSpec tag, all semantic entries should be explicitly tagged for consistency and to avoid ambiguity in NatSpec tooling. Some documentation generators treat untagged text following a `@title` as part of the title rather than as a notice.

**Recommendation:** Add an explicit `@notice` tag before the description starting at line 8.

---

### A04-2: `ensureDeployed` function lacks `@param` and `@return` NatSpec tags [INFO]

**Location:** Lines 45-55

The function takes no parameters and has no return value, so `@param` and `@return` tags are not applicable. The existing comment on lines 45-47 adequately describes the function's purpose. No action needed.

---

### A04-3: `decimalsForTokenReadOnly` lacks `@param` and `@return` NatSpec tags [MEDIUM]

**Location:** Lines 57-63

The NatSpec is a single-line reference: `/// As per ITOFUTokenDecimals.decimalsForTokenReadOnly.` While this cross-reference is accurate (the interface defines this function at line 65 of `ITOFUTokenDecimals.sol` with matching signature `(address) -> (TOFUOutcome, uint8)`), the function itself lacks `@param token` and `@return` tags. Since this is an `internal` library function that callers import directly, its NatSpec is the primary documentation surface for those callers. The interface NatSpec is not automatically inherited for library functions -- `@inheritdoc` is not used and would not work here since the library does not implement the interface.

**Recommendation:** Add `@param token The token to read the decimals for.`, `@return tofuOutcome The outcome of the TOFU read.`, and `@return tokenDecimals The token's decimals.` -- or at minimum note that callers should see the interface for parameter/return documentation.

---

### A04-4: `decimalsForToken` lacks `@param` and `@return` NatSpec tags [MEDIUM]

**Location:** Lines 65-71

Same issue as A04-3. The cross-reference `As per ITOFUTokenDecimals.decimalsForToken` is accurate (interface line 73, matching signature `(address) -> (TOFUOutcome, uint8)`), but no `@param` or `@return` tags are present.

**Recommendation:** Same as A04-3.

---

### A04-5: `safeDecimalsForToken` lacks `@param` and `@return` NatSpec tags [MEDIUM]

**Location:** Lines 73-77

The cross-reference `As per ITOFUTokenDecimals.safeDecimalsForToken` is accurate (interface line 79, matching signature `(address) -> (uint8)`), but no `@param` or `@return` tags are present.

**Recommendation:** Same as A04-3.

---

### A04-6: `safeDecimalsForTokenReadOnly` lacks `@param` and `@return` NatSpec tags [MEDIUM]

**Location:** Lines 79-83

The cross-reference `As per ITOFUTokenDecimals.safeDecimalsForTokenReadOnly` is accurate (interface line 85, matching signature `(address) -> (uint8)`), but no `@param` or `@return` tags are present.

**Recommendation:** Same as A04-3.

---

### A04-7: Error `TOFUTokenDecimalsNotDeployed` lacks `@param` NatSpec tag [LOW]

**Location:** Lines 22-23

The error has a comment (`/// Thrown when attempting to use an address that is not deployed.`) but no `@param deployedAddress` tag documenting the parameter. For consistency with the project's interface file (where `TokenDecimalsReadFailure` at line 30-33 of `ITOFUTokenDecimals.sol` has `@param` tags for both parameters), this error should also have a `@param` tag.

**Recommendation:** Add `/// @param deployedAddress The address of the expected deployment that was not found or had a mismatched codehash.`

---

### A04-8: Cross-references say "As per `ITOFUTokenDecimals`" but the library delegates to the deployed contract, not the interface [INFO]

**Location:** Lines 57, 65, 73, 79

The phrasing "As per `ITOFUTokenDecimals.functionName`" is accurate in the sense that the library's functions match the interface's function signatures and semantics. The library calls the deployed contract (`TOFU_DECIMALS_DEPLOYMENT`) which implements `ITOFUTokenDecimals`, so the behavior is indeed "as per" the interface specification. This is an acceptable documentation pattern. No action needed.

---

### A04-9: `TOFU_DECIMALS_EXPECTED_CREATION_CODE` documentation does not mention how to verify it [INFO]

**Location:** Lines 38-43

The doc comment explains what the creation code is and its relationship to the deployment address and code hash, which is sufficient. However, there is no guidance on how a reviewer could independently verify this value (e.g., by compiling `TOFUTokenDecimals.sol` with the specified compiler settings). This is informational only given the project's CLAUDE.md already documents the deterministic bytecode constraints.

---

### A04-10: Accuracy check -- cross-references verified against interface [INFO]

All four "As per `ITOFUTokenDecimals.*`" references were verified:

| Library function | Interface function | Signature match | Semantics match |
|---|---|---|---|
| `decimalsForTokenReadOnly(address) -> (TOFUOutcome, uint8)` | `ITOFUTokenDecimals.decimalsForTokenReadOnly` (line 65) | Yes | Yes -- both are view, both return outcome and decimals |
| `decimalsForToken(address) -> (TOFUOutcome, uint8)` | `ITOFUTokenDecimals.decimalsForToken` (line 73) | Yes | Yes -- both are state-changing, both return outcome and decimals |
| `safeDecimalsForToken(address) -> (uint8)` | `ITOFUTokenDecimals.safeDecimalsForToken` (line 79) | Yes | Yes -- both are state-changing, both return decimals only |
| `safeDecimalsForTokenReadOnly(address) -> (uint8)` | `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly` (line 85) | Yes | Yes -- both are view, both return decimals only |

All cross-references are accurate.

---

## Summary

| Severity | Count | IDs |
|---|---|---|
| CRITICAL | 0 | -- |
| HIGH | 0 | -- |
| MEDIUM | 4 | A04-3, A04-4, A04-5, A04-6 |
| LOW | 2 | A04-1, A04-7 |
| INFO | 4 | A04-2, A04-8, A04-9, A04-10 |

The primary documentation gap is the consistent absence of `@param` and `@return` NatSpec tags on all four delegating functions (A04-3 through A04-6). While each has a cross-reference to the interface, the library functions are the direct API surface for callers, and NatSpec tooling will not resolve cross-references in free-text comments. The library doc block's missing explicit `@notice` (A04-1) and the error's missing `@param` (A04-7) are lower severity but would improve consistency with the rest of the codebase.
