# Audit Pass 3 (Documentation) - LibTOFUTokenDecimalsImplementation.sol

**Agent:** A02
**Date:** 2026-02-21
**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`

## Evidence of Thorough Reading

- Read full source file (171 lines), interface file `ITOFUTokenDecimals.sol` (100 lines), and concrete contract `TOFUTokenDecimals.sol` (39 lines).
- Verified constant `TOFU_DECIMALS_SELECTOR = 0x313ce567` against keccak256("decimals()") -- confirmed correct.
- Traced all four functions: `decimalsForTokenReadOnly` (lines 29-79), `decimalsForToken` (lines 109-123), `safeDecimalsForToken` (lines 136-146), `safeDecimalsForTokenReadOnly` (lines 160-170).
- Cross-referenced all NatSpec `@return` tags against actual return types and values.
- Cross-referenced library NatSpec against interface NatSpec for consistency.
- Verified inline comments in assembly block (lines 45-57) and control flow (lines 59-78) against actual behavior.
- Checked that the `@notice` references to `ITOFUTokenDecimals` interface methods are accurate.

## Findings

### A02-001: `safeDecimalsForToken` NatSpec says "reverts if ... read fails or is inconsistent" but the error name `TokenDecimalsReadFailure` may mislead readers into thinking only read failures cause the revert [INFORMATIONAL]

On line 127, the NatSpec for `safeDecimalsForToken` states:

```
/// Same as `decimalsForToken` but reverts with `ITOFUTokenDecimals.TokenDecimalsReadFailure`
/// if the token's decimals are inconsistent or the read fails.
```

The error is named `TokenDecimalsReadFailure` but is also thrown for the `Inconsistent` outcome, which is not a "read failure" in the traditional sense -- the read succeeded but returned a different value. The NatSpec correctly documents that both inconsistency and read failure trigger the revert, and the error does carry a `tofuOutcome` parameter that distinguishes the two cases, so the behavior is clear on-chain. However, the error name alone could lead a reader to expect it only covers read failures. This is documented in the interface error NatSpec (line 49-54 of ITOFUTokenDecimals.sol) which explicitly explains it covers both cases. This is purely a naming concern with no functional impact.

### A02-002: `decimalsForTokenReadOnly` NatSpec `@return tokenDecimals` description says "On `Initial`, the freshly read value" -- accurate but subtle for read-only context [INFORMATIONAL]

On lines 26-28, the `@return tokenDecimals` documentation states:

```
/// @return tokenDecimals The token's decimals. On `Initial`, the freshly
/// read value. On `Consistent` or `Inconsistent`, the previously stored
/// value. On `ReadFailure`, the stored value (zero if uninitialized).
```

This is accurate: on `Initial`, the freshly read value is returned. On `Consistent` or `Inconsistent`, the previously stored value is returned. On `ReadFailure`, the stored value (which defaults to zero if uninitialized) is returned. The documentation correctly matches lines 71, 76, and 62 respectively. No issue here; the documentation is precise.

This finding is retracted upon verification -- the documentation is correct.

### A02-003: `decimalsForToken` NatSpec duplicates the long rationale already present in the interface [INFORMATIONAL]

Lines 81-99 contain an extensive `@notice` block that largely restates what the interface NatSpec already covers. While the reference "As per `ITOFUTokenDecimals.decimalsForToken`" (line 81) is present, the function then re-documents the full behavior in detail. Compare this to `safeDecimalsForToken` (lines 125-129) and `safeDecimalsForTokenReadOnly` (lines 148-153), which take a more concise approach by primarily referencing the interface and adding only implementation-specific notes. The `decimalsForTokenReadOnly` function (lines 17-19) also uses the concise referencing style. The inconsistency in documentation style is cosmetic but notable.

### A02-004: Inline comment on line 68 says "read value fits in a uint8" -- accurate guard is on line 53-55 [INFORMATIONAL]

Line 68-70 contains:
```
// We check that the read value fits in a uint8 above, so this cast
// is safe.
```

This refers to the assembly guard on lines 53-55:
```
if gt(readDecimals, 0xff) {
    success := 0
}
```

The comment is accurate. If `readDecimals > 0xff`, `success` is set to 0, and the function returns early at line 61-63 with `ReadFailure`. So the cast on line 71 (`uint8(readDecimals)`) is indeed safe. No issue.

This finding is retracted upon verification -- the inline comment is correct.

### A02-005: No `@dev` tag on `decimalsForTokenReadOnly` assembly block explaining the memory usage pattern [INFORMATIONAL]

The assembly block in `decimalsForTokenReadOnly` (lines 45-57) uses the scratch space at memory position 0 for both the call data (writing the selector) and the return data (reading the result). While the assembly is marked `"memory-safe"`, there is no `@dev` tag or detailed inline comment explaining why this is memory-safe -- specifically that Solidity's memory-safe annotation allows use of scratch space (memory positions 0x00-0x3f) without violating memory safety guarantees. The inline comments (lines 36-41) explain the error handling rationale but not the memory layout choice. A `@dev` note would help auditors and future maintainers confirm correctness of the `"memory-safe"` annotation.

## Summary

| ID | Title | Severity |
|----|-------|----------|
| A02-001 | Error name `TokenDecimalsReadFailure` covers both read failures and inconsistencies | INFORMATIONAL |
| A02-003 | Inconsistent documentation verbosity across functions | INFORMATIONAL |
| A02-005 | No `@dev` note explaining memory-safe assembly scratch space usage | INFORMATIONAL |

All NatSpec `@notice`, `@param`, and `@return` tags are present and accurate for every function and constant. Parameter names in documentation match the code. Return value descriptions correctly describe behavior for each `TOFUOutcome` variant. The constant `TOFU_DECIMALS_SELECTOR` has a correct `@dev` tag and its value is verified correct. No missing documentation tags were found. All three findings are informational and concern style/clarity rather than correctness.
