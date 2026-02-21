# Audit Pass 3 (Documentation) - TOFUTokenDecimals.sol

**Agent:** A04
**Date:** 2026-02-21
**File:** `src/concrete/TOFUTokenDecimals.sol`

## Evidence of Thorough Reading

1. **Contract declaration (line 13):** `TOFUTokenDecimals is ITOFUTokenDecimals`. Confirmed the contract implements the interface.

2. **Contract-level NatSpec (lines 8-12):** Has `@title` ("TOFUTokenDecimals") and `@notice` describing it as a minimal implementation that stores the mapping and delegates logic to `LibTOFUTokenDecimalsImplementation`. Verified this is accurate: the contract contains only one state variable and four thin wrapper functions that forward to the library.

3. **State variable `sTOFUTokenDecimals` (lines 14-16):** `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals`. Has `@notice`: "Storage mapping from token address to its TOFU decimals result." Accurate and sufficient for an internal mapping.

4. **`decimalsForTokenReadOnly` (lines 18-22):** Uses `@inheritdoc ITOFUTokenDecimals`. Interface (lines 57-70) provides `@notice`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals`. Verified the return value documentation ("On `Initial`, the freshly read value. On `Consistent` or `Inconsistent`, the previously stored value. On `ReadFailure`, the stored value (zero if uninitialized)") against implementation at `LibTOFUTokenDecimalsImplementation` lines 61-78. All four cases match the code exactly.

5. **`decimalsForToken` (lines 24-28):** Uses `@inheritdoc ITOFUTokenDecimals`. Interface (lines 72-81) provides `@notice`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals`. Key claim: "Storage is written only on the `Initial` outcome; subsequent calls never modify the stored value." Confirmed at implementation lines 119-121: `if (tofuOutcome == TOFUOutcome.Initial)` is the only write path.

6. **`safeDecimalsForToken` (lines 30-33):** Uses `@inheritdoc ITOFUTokenDecimals`. Interface (lines 83-87) provides `@notice`, `@param token`, `@return tokenDecimals`. Documentation says it reverts "if the read fails or is inconsistent with the stored value." Verified at implementation lines 142-143: reverts on anything other than `Consistent` or `Initial`.

7. **`safeDecimalsForTokenReadOnly` (lines 35-38):** Uses `@inheritdoc ITOFUTokenDecimals`. Interface (lines 89-99) provides `@notice` with WARNING about pre-initialization behavior, `@param token`, `@return tokenDecimals`. The WARNING states: "Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected." Verified: the read-only path never writes storage (implementation line 165 calls `decimalsForTokenReadOnly` which has no writes), so before initialization every call is `Initial` and always succeeds, making inconsistency undetectable. This is accurately documented.

8. **Error `TokenDecimalsReadFailure` (interface lines 49-55):** Documented with `@notice` explaining it covers both `Inconsistent` and `ReadFailure` outcomes, plus `@param` tags for `token` and `tofuOutcome`. Verified the revert condition in implementation: `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial` correctly maps to `Inconsistent` and `ReadFailure` as documented.

9. **Cross-checked all four function signatures** in the concrete contract against the interface declarations. All match exactly (parameter names, types, visibility, mutability, return types).

## Findings

No findings.

All elements of `TOFUTokenDecimals.sol` are properly documented:
- The contract has accurate `@title` and `@notice` NatSpec.
- The state variable has a `@notice` tag describing its purpose.
- All four functions use `@inheritdoc ITOFUTokenDecimals`, which is appropriate since the interface provides complete and accurate NatSpec for each function including `@notice`, `@param`, and `@return` tags.
- The interface documentation accurately reflects the implementation behavior in all cases (Initial, Consistent, Inconsistent, ReadFailure).
- The WARNING on `safeDecimalsForTokenReadOnly` correctly identifies the pre-initialization limitation.
