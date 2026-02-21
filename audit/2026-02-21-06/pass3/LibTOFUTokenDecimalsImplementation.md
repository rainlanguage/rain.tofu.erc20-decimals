# Audit: LibTOFUTokenDecimalsImplementation.sol - Pass 3 (Documentation)

**Agent:** A04
**Date:** 2026-02-21
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Cross-reference:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/interface/ITOFUTokenDecimals.sol`

## Evidence of Thorough Reading

**Library name:** `LibTOFUTokenDecimalsImplementation` (line 13)

### Constants

| Name | Line | Type | Value |
|------|------|------|-------|
| `TOFU_DECIMALS_SELECTOR` | 15 | `bytes4` | `0x313ce567` |

### Functions

| Name | Lines | Visibility | Mutability | Returns |
|------|-------|------------|------------|---------|
| `decimalsForTokenReadOnly` | 29-79 | `internal` | `view` | `(TOFUOutcome, uint8)` |
| `decimalsForToken` | 109-123 | `internal` | (none/state-changing) | `(TOFUOutcome, uint8)` |
| `safeDecimalsForToken` | 136-146 | `internal` | (none/state-changing) | `uint8` |
| `safeDecimalsForTokenReadOnly` | 160-170 | `internal` | `view` | `uint8` |

### Types Referenced (from ITOFUTokenDecimals.sol)

| Name | Line (interface file) | Kind |
|------|----------------------|------|
| `TOFUTokenDecimalsResult` | 13-16 | struct |
| `TOFUOutcome` | 19-28 | enum |
| `ITOFUTokenDecimals` | 48-97 | interface |
| `TokenDecimalsReadFailure` | 52 | error |

## Documentation Audit

### Constant: TOFU_DECIMALS_SELECTOR (line 14-15)

Has `@dev` tag explaining it is the selector for `decimals()`. Verified that `keccak256("decimals()")` produces `0x313ce567...`. Documentation is accurate.

### Function: decimalsForTokenReadOnly (lines 17-79)

- `@notice`: Cross-references `ITOFUTokenDecimals.decimalsForTokenReadOnly` -- verified this exists at interface line 67. Accurate.
- `@param sTOFUTokenDecimals`: Documented. Accurate.
- `@param token`: Documented. Accurate.
- `@return tofuOutcome`: Documented. Accurate.
- `@return tokenDecimals`: Documented with per-outcome descriptions. Accurate.

No issues found.

### Function: decimalsForToken (lines 81-123)

- `@notice`: Cross-references `ITOFUTokenDecimals.decimalsForToken` -- verified this exists at interface line 78. Accurate.
- `@param sTOFUTokenDecimals`: Documented. Accurate.
- `@param token`: Documented. Accurate.
- `@return tofuOutcome`: Documented. Accurate.
- `@return tokenDecimals`: Documented with per-outcome descriptions. Accurate.

No issues found.

### Function: safeDecimalsForToken (lines 125-146)

- `@notice`: Cross-references `ITOFUTokenDecimals.safeDecimalsForToken` -- verified this exists at interface line 84. Accurate.
- `@param sTOFUTokenDecimals`: Documented. Accurate.
- `@param token`: Documented. Accurate.
- `@return tokenDecimals`: Documented. Accurate.

See Finding 1 below regarding description accuracy.

### Function: safeDecimalsForTokenReadOnly (lines 148-170)

- `@notice`: Cross-references `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly` -- verified this exists at interface line 96. Accurate.
- `@param sTOFUTokenDecimals`: Documented. Accurate.
- `@param token`: Documented. Accurate.
- `@return tokenDecimals`: Documented. Accurate.

No issues found.

## Findings

### Finding 1: safeDecimalsForToken NatSpec says "inconsistent or the read fails" but the error is named TokenDecimalsReadFailure for both cases

**Severity:** LOW

**Location:** Line 127-128

**Description:** The NatSpec for `safeDecimalsForToken` states:

> Same as `decimalsForToken` but reverts with `ITOFUTokenDecimals.TokenDecimalsReadFailure` if the token's decimals are inconsistent or the read fails.

The actual implementation at lines 142-143 reverts when the outcome is neither `Consistent` nor `Initial`:
```solidity
if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
    revert ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome);
}
```

This means it reverts on both `Inconsistent` and `ReadFailure` outcomes, which matches what the documentation says. However, the documentation describes the revert as occurring when "the token's decimals are inconsistent or the read fails", which could be read as describing two separate conditions, when in fact the error type `TokenDecimalsReadFailure` is used for both. The naming conflates the two failure modes under a single "read failure" label -- the error is called `TokenDecimalsReadFailure` but it is also raised for `Inconsistent`, which is not a "read failure" in the strict sense. This is arguably a naming concern at the interface level rather than a documentation inaccuracy in the library, so it is noted at LOW severity. The library documentation itself is accurate in describing the behavior.

**Recommendation:** This is a minor naming observation. The documentation in the library accurately describes the behavior. No change needed in this file. If the error name is considered misleading, it would need to be addressed in `ITOFUTokenDecimals.sol`.

## Summary

The documentation in `LibTOFUTokenDecimalsImplementation.sol` is thorough and well-structured:

- All four functions have complete NatSpec with `@notice`, `@param`, and `@return` tags.
- All cross-references to `ITOFUTokenDecimals` are verified accurate.
- The `@return` documentation for both-return-value functions correctly describes the semantics for each `TOFUOutcome` variant.
- The constant has appropriate `@dev` documentation.
- The library-level `@title` and `@notice` are accurate and informative.
- The `safeDecimalsForTokenReadOnly` function includes an important WARNING about the pre-initialization behavior, which matches the interface documentation.

One LOW-severity finding was identified, relating to the naming of the `TokenDecimalsReadFailure` error being used for inconsistency as well as actual read failures. This is an interface-level concern rather than a documentation inaccuracy in the library itself.
