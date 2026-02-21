# Pass 3: Documentation -- LibTOFUTokenDecimals.sol

Agent: A04

## Evidence of Thorough Reading

**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol` (99 lines)

**Library:** `LibTOFUTokenDecimals` (line 21)

**Error:**
- `TOFUTokenDecimalsNotDeployed(address deployedAddress)` (line 24)

**Constants:**
- `TOFU_DECIMALS_DEPLOYMENT` -- `ITOFUTokenDecimals` typed constant, address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` (lines 29-30)
- `TOFU_DECIMALS_EXPECTED_CODE_HASH` -- `bytes32` constant (lines 36-37)
- `TOFU_DECIMALS_EXPECTED_CREATION_CODE` -- `bytes` constant, full init bytecode (lines 43-44)

**Functions:**
- `ensureDeployed()` -- `internal view`, line 49
- `decimalsForTokenReadOnly(address token)` -- `internal view returns (TOFUOutcome, uint8)`, line 64
- `decimalsForToken(address token)` -- `internal returns (TOFUOutcome, uint8)`, line 77
- `safeDecimalsForToken(address token)` -- `internal returns (uint8)`, line 87
- `safeDecimalsForTokenReadOnly(address token)` -- `internal view returns (uint8)`, line 95

**Imports:** `TOFUOutcome` and `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

## Findings

### A04-1: Library-level NatSpec is present and accurate [INFO]

The library has a `@title` tag (line 7) and a detailed `@notice` comment (lines 8-20) explaining the TOFU approach, the distinction between read/write and read-only versions, and the role of this library as a convenience wrapper around the deployed singleton. The documentation accurately describes the library's purpose.

### A04-2: Error `TOFUTokenDecimalsNotDeployed` has complete NatSpec [INFO]

The error on line 22-24 has both a `@notice` tag explaining when it is thrown ("when the singleton is not deployed or has an unexpected codehash") and a `@param deployedAddress` tag. Both are accurate: `ensureDeployed()` checks both `code.length == 0` and codehash mismatch before reverting with this error.

### A04-3: Constants lack `@notice` or `@dev` NatSpec tags [LOW]

All three constants (`TOFU_DECIMALS_DEPLOYMENT` at line 26, `TOFU_DECIMALS_EXPECTED_CODE_HASH` at line 32, and `TOFU_DECIMALS_EXPECTED_CREATION_CODE` at line 39) use plain `///` comments rather than `@notice` or `@dev` NatSpec tags. While the prose descriptions are accurate and informative, they will not be emitted as NatSpec metadata by the Solidity compiler. Tooling that relies on NatSpec JSON output (e.g. documentation generators, etherscan auto-doc) will not capture these descriptions.

**Recommendation:** Prefix each constant's documentation block with `@notice` or `@dev` to ensure NatSpec tooling picks it up. This is a stylistic/tooling concern, not a correctness issue.

### A04-4: `ensureDeployed` lacks `@notice`/`@dev` NatSpec tag [LOW]

The `ensureDeployed()` function (line 46-56) has a plain `///` comment on line 46-48 that explains its purpose clearly ("Ensures that the TOFUTokenDecimals contract is deployed. Having an explicit guard prevents silent call failures..."). However, it does not use a `@notice` or `@dev` tag, so it will not appear in NatSpec JSON output. It also has no `@param` or `@return` tags, which is correct since the function takes no parameters and returns nothing.

**Recommendation:** Add `@notice` or `@dev` prefix for NatSpec compliance.

### A04-5: `decimalsForTokenReadOnly` has complete and accurate NatSpec [INFO]

The function (line 58-69) documents:
- A reference to the interface: "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`" (line 58)
- `@param token` (line 59) -- accurate
- `@return tofuOutcome` (line 60) -- accurate
- `@return tokenDecimals` (lines 61-63) -- accurately describes behavior per outcome

Cross-referencing with the interface documentation at `ITOFUTokenDecimals.sol` lines 62-66: the `@return` documentation in the library exactly matches the interface's return value descriptions. The implementation delegates to `TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token)`, which is correct.

### A04-6: `decimalsForToken` has complete and accurate NatSpec [INFO]

The function (line 71-82) documents:
- A reference to the interface: "As per `ITOFUTokenDecimals.decimalsForToken`" (line 71)
- `@param token` (line 72) -- accurate
- `@return tofuOutcome` (line 73) -- accurate
- `@return tokenDecimals` (lines 74-76) -- accurately describes behavior per outcome

The documentation matches the interface definition at `ITOFUTokenDecimals.sol` lines 72-76. The function correctly delegates to `TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)` and calls `ensureDeployed()` first.

### A04-7: `safeDecimalsForToken` has complete and accurate NatSpec [INFO]

The function (line 84-90) documents:
- A reference to the interface: "As per `ITOFUTokenDecimals.safeDecimalsForToken`" (line 84)
- `@param token` (line 85) -- accurate
- `@return tokenDecimals` (line 86) -- accurate

This matches the interface definition at `ITOFUTokenDecimals.sol` lines 82-83. Implementation correctly delegates after `ensureDeployed()`.

### A04-8: `safeDecimalsForTokenReadOnly` has complete and accurate NatSpec [INFO]

The function (line 92-98) documents:
- A reference to the interface: "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`" (line 92)
- `@param token` (line 93) -- accurate
- `@return tokenDecimals` (line 94) -- accurate

This matches the interface definition at `ITOFUTokenDecimals.sol` lines 89-91. Implementation correctly delegates after `ensureDeployed()`.

### A04-9: `@return` documentation for `decimalsForTokenReadOnly` and `decimalsForToken` slightly diverges from actual singleton behavior on `ReadFailure` [INFO]

The `@return tokenDecimals` documentation for both `decimalsForTokenReadOnly` (line 63) and `decimalsForToken` (line 76) states: "On `ReadFailure`, the stored value (zero if uninitialized)." This documentation is inherited from the interface and accurately describes what the underlying `LibTOFUTokenDecimalsImplementation` does (line 67 of that file: `return (TOFUOutcome.ReadFailure, tofuTokenDecimals.tokenDecimals)`).

However, this library (`LibTOFUTokenDecimals`) calls the singleton *externally*, meaning the returned value flows through the external interface. The semantics remain the same because the concrete contract (`TOFUTokenDecimals.sol`) delegates directly to the implementation library, so the documentation is accurate.

No action needed.

### A04-10: Documentation references interface but does not use `@inheritdoc` [INFO]

All four public functions use the pattern "As per `ITOFUTokenDecimals.<functionName>`" instead of `@inheritdoc`. This is a reasonable choice since these are library functions (not contract functions implementing an interface), so `@inheritdoc` is not syntactically applicable. The cross-reference approach is appropriate and the duplicated `@param`/`@return` tags ensure documentation is available directly on the library functions.

No action needed.

### A04-11: `TOFU_DECIMALS_EXPECTED_CREATION_CODE` documentation does not note the relationship between creation code and the other two constants [INFO]

The comment for `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (lines 39-41) explains that deploying this bytecode via Zoltu produces the contract at `TOFU_DECIMALS_DEPLOYMENT` with `TOFU_DECIMALS_EXPECTED_CODE_HASH`. This correctly documents the relationship between all three constants. No issue.

## Summary

The documentation in `LibTOFUTokenDecimals.sol` is thorough and accurate. All functions have `@param` and `@return` NatSpec tags. The return value semantics are correctly documented and match the underlying implementation. The only minor findings are that two items (three constants and one function) use plain `///` comments instead of `@notice`/`@dev` NatSpec tags, which means NatSpec tooling may not capture those descriptions. These are LOW severity stylistic concerns.
