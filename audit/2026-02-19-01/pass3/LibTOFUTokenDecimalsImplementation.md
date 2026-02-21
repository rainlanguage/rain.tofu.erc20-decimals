# Pass 3 -- Documentation Audit: LibTOFUTokenDecimalsImplementation

**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Auditor:** A02
**Date:** 2026-02-19

---

## 1. Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimalsImplementation` (line 18)

### Constants

| Name | Line | Type | Value |
|---|---|---|---|
| `TOFU_DECIMALS_SELECTOR` | 20 | `bytes4` | `0x313ce567` |

### Functions

| Name | Line | Visibility | Mutability | Returns |
|---|---|---|---|---|
| `decimalsForTokenReadOnly` | 32 | `internal` | `view` | `(TOFUOutcome, uint8)` |
| `decimalsForToken` | 99 | `internal` | (non-view) | `(TOFUOutcome, uint8)` |
| `safeDecimalsForToken` | 121 | `internal` | (non-view) | `uint8` |
| `safeDecimalsForTokenReadOnly` | 137 | `internal` | `view` | `uint8` |

---

## 2. Documentation Findings

### A02-1: Library doc block has `@title` but no explicit `@notice` [LOW]

**Lines:** 12-17

The library-level doc block uses the `@title` tag on line 12 but the descriptive text on lines 13-17 is not preceded by an explicit `@notice` tag. Per NatSpec conventions, when a doc block contains any explicit tag (e.g., `@title`), all entries should be explicitly tagged. Without an explicit `@notice`, the descriptive lines are parsed as continuation of `@title` rather than as the intended notice.

```solidity
/// @title LibTOFUTokenDecimalsImplementation
/// This library contains the implementation logic for reading token decimals
/// with a trust on first use (TOFU) approach. ...
```

**Recommendation:** Add `@notice` before line 13:

```solidity
/// @title LibTOFUTokenDecimalsImplementation
/// @notice This library contains the implementation logic for reading token decimals
/// with a trust on first use (TOFU) approach. ...
```

---

### A02-2: Constant `TOFU_DECIMALS_SELECTOR` uses `@dev` but has no `@notice` [INFO]

**Line:** 19-20

The constant is documented with `@dev` only, which is acceptable for an internal-facing implementation detail. The documentation accurately describes the constant as "The selector for the `decimals()` function in the ERC20 standard." The value `0x313ce567` is correct (`keccak256("decimals()")` truncated to 4 bytes).

No issue -- documentation is accurate and the tag choice is appropriate for an internal constant.

---

### A02-3: `decimalsForTokenReadOnly` missing `@notice` or `@dev` tag for primary description [LOW]

**Lines:** 22-31

The function doc block begins with an untagged description "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`..." on line 22, which is followed by `@param` and `@return` tags. Since explicit NatSpec tags are present (`@param`, `@return`), the opening lines should have an explicit `@notice` or `@dev` tag. As written, the NatSpec compiler treats the untagged opening lines as `@notice` by default, which happens to produce the intended result, but best practice when mixing with explicit tags is to be explicit throughout.

The `@param` tags (lines 25-29) and `@return` tags (lines 30-31) are present and correctly named (`sTOFUTokenDecimals`, `token`, `tofuOutcome`, `tokenDecimals`).

**Recommendation:** Add an explicit `@notice` tag on line 22.

---

### A02-4: `decimalsForTokenReadOnly` return value documentation is incomplete regarding which value is returned per outcome [MEDIUM]

**Lines:** 22-31

The `@return` tags state:
- `tofuOutcome` -- "The outcome of the TOFU read."
- `tokenDecimals` -- "The token's decimals."

However, the return value for `tokenDecimals` varies significantly by outcome:

| `TOFUOutcome` | `tokenDecimals` value returned |
|---|---|
| `ReadFailure` | The **stored** value (may be zero/uninitialized if never initialized) |
| `Initial` | The **freshly read** value from the token |
| `Consistent` | The **stored** value (which equals the read value) |
| `Inconsistent` | The **stored** value (not the freshly read value) |

This distinction is critical for callers. The doc block's inline comments (lines 62-63, 68-69, 76) do describe this behavior, but the `@return` tags themselves do not. The inline comments accurately match the implementation, but the formal NatSpec return documentation is too vague. Since `@return` tags are what tooling (e.g., Etherscan, documentation generators) surfaces, callers relying only on NatSpec output would miss the nuanced return behavior.

**Recommendation:** Expand the `@return tokenDecimals` tag to document the per-outcome semantics, e.g.:
```
/// @return tokenDecimals The token's decimals. On Initial, the freshly read
/// value. On Consistent or Inconsistent, the previously stored value. On
/// ReadFailure, the stored value (which may be uninitialized zero).
```

---

### A02-5: `decimalsForToken` missing `@param` and `@return` NatSpec tags [MEDIUM]

**Lines:** 84-98

The `decimalsForToken` function has a prose doc block (lines 84-98) that describes the TOFU semantics. However, it has **no** `@param` tags for `sTOFUTokenDecimals` or `token`, and **no** `@return` tags for the returned `(TOFUOutcome, uint8)` tuple.

The prose description is accurate: it correctly states the Initial, ReadFailure, and Inconsistent behavior. Notably, the prose on lines 97-98 says "we return the stored value and TOFUOutcome.Inconsistent" -- this is accurate per the implementation, which delegates to `decimalsForTokenReadOnly` and that function returns the stored value on inconsistency (line 79).

However, the prose omits the `Consistent` outcome case. While this can be inferred (if not Initial, ReadFailure, or Inconsistent, then Consistent), an explicit mention would improve completeness.

**Recommendation:** Add `@param` and `@return` tags. Add an explicit mention of the `Consistent` outcome.

---

### A02-6: `decimalsForToken` prose description accuracy -- ReadFailure return on uninitialized state [INFO]

**Lines:** 94-95

The prose states: "If the call to `decimals` is not a success that deserializes cleanly to a `uint8` we return the stored value and TOFUOutcome.ReadFailure."

This is accurate. If no value has been stored (uninitialized), `decimalsForTokenReadOnly` returns `tofuTokenDecimals.tokenDecimals` which defaults to `0`. `decimalsForToken` does NOT store anything on `ReadFailure` (line 109 only stores on `Initial`), so the uninitialized state is preserved. The description correctly says "stored value" without claiming it is meaningful.

No issue.

---

### A02-7: `safeDecimalsForToken` missing `@param` tags [MEDIUM]

**Lines:** 115-119

The function has a prose description and a `@return` tag (line 119), but no `@param` tags for `sTOFUTokenDecimals` or `token`. The description references `decimalsForToken` and accurately states it "reverts with a standard error if the token's decimals are inconsistent."

Checking accuracy against implementation (lines 126-130): the function reverts if `tofuOutcome` is neither `Consistent` nor `Initial`. This means it reverts on both `Inconsistent` AND `ReadFailure`. The doc says "reverts with a standard error if the token's decimals are inconsistent" which only mentions the Inconsistent case and omits the ReadFailure revert case.

Wait -- the doc also says "Same as `decimalsForToken` but reverts with a standard error." This is ambiguous. Reading it more carefully: "reverts with a standard error if the token's decimals are inconsistent" -- this could be read as covering only `Inconsistent`, not `ReadFailure`. But the implementation reverts on both.

This is partially addressed by the fact that `safeDecimalsForToken` uses `TokenDecimalsReadFailure` as the error name, which implies read failures are covered. But the prose should be explicit.

**Recommendation:** Add `@param` tags. Clarify that the function reverts on both `Inconsistent` and `ReadFailure` outcomes.

---

### A02-8: `safeDecimalsForToken` doc says "On the first read the decimals are never considered inconsistent" [INFO]

**Line:** 118

The statement "On the first read the decimals are never considered inconsistent" is accurate. On first read with a successful `decimals()` call, the outcome is `Initial`, which passes the guard condition on line 127. This is a correct and useful clarification.

No issue.

---

### A02-9: `safeDecimalsForTokenReadOnly` missing `@param` tags [MEDIUM]

**Lines:** 133-135

The function doc says "As per `safeDecimalsForToken` but read only. Does not store the decimals on first read." It has a `@return` tag but no `@param` tags for `sTOFUTokenDecimals` or `token`.

Checking accuracy: The implementation (lines 142-146) calls `decimalsForTokenReadOnly` instead of `decimalsForToken`, so it truly does not store state. It applies the same revert guard (`!= Consistent && != Initial`). The description is accurate.

However, the same issue from A02-7 applies: the doc does not explicitly mention that `ReadFailure` also causes a revert; it only inherits the description from `safeDecimalsForToken` which itself is unclear about `ReadFailure`.

**Recommendation:** Add `@param` tags. Consider making the revert conditions explicit rather than relying on cross-reference to `safeDecimalsForToken`.

---

### A02-10: `@return` tag on `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` lacks a name [INFO]

**Lines:** 119, 135

Both `@return` tags say `@return The token's decimals.` without a named return variable. The function signatures do not name return values either (`returns (uint8)`). This is acceptable per Solidity NatSpec conventions when there is a single unnamed return. However, the `decimalsForTokenReadOnly` function (line 30-31) does name its returns (`tofuOutcome`, `tokenDecimals`), creating a minor style inconsistency within the file.

No issue -- this is a style observation, not a defect.

---

## Summary

| ID | Severity | Summary |
|---|---|---|
| A02-1 | LOW | Library doc block has `@title` but no explicit `@notice` |
| A02-2 | INFO | Constant `TOFU_DECIMALS_SELECTOR` documentation is accurate |
| A02-3 | LOW | `decimalsForTokenReadOnly` description lacks explicit `@notice`/`@dev` tag |
| A02-4 | MEDIUM | `decimalsForTokenReadOnly` `@return` tags do not document per-outcome return value semantics |
| A02-5 | MEDIUM | `decimalsForToken` missing `@param` and `@return` NatSpec tags |
| A02-6 | INFO | `decimalsForToken` prose on ReadFailure behavior is accurate |
| A02-7 | MEDIUM | `safeDecimalsForToken` missing `@param` tags; docs omit `ReadFailure` as a revert trigger |
| A02-8 | INFO | "On the first read the decimals are never considered inconsistent" is accurate |
| A02-9 | MEDIUM | `safeDecimalsForTokenReadOnly` missing `@param` tags; inherits unclear revert semantics |
| A02-10 | INFO | Minor style inconsistency in `@return` tag naming across functions |

**Totals:** 0 CRITICAL, 0 HIGH, 4 MEDIUM, 2 LOW, 4 INFO
