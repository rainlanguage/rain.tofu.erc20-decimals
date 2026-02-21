# Pass 3: Documentation -- ITOFUTokenDecimals.sol

Agent: A03

## Evidence of Thorough Reading

File: `src/interface/ITOFUTokenDecimals.sol` (93 lines)

### Struct

- **`TOFUTokenDecimalsResult`** (line 13): Two fields:
  - `bool initialized` (line 14)
  - `uint8 tokenDecimals` (line 15)

### Enum

- **`TOFUOutcome`** (line 19): Four variants:
  - `Initial` (line 21)
  - `Consistent` (line 23)
  - `Inconsistent` (line 25)
  - `ReadFailure` (line 27)

### Error

- **`TokenDecimalsReadFailure`** (line 33): Two parameters:
  - `address token`
  - `TOFUOutcome tofuOutcome`

### Interface

- **`ITOFUTokenDecimals`** (line 53): Four functions:
  - `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 67)
  - `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 77)
  - `safeDecimalsForToken(address token) external returns (uint8)` (line 83)
  - `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 91)

## Findings

### A03-1: TOFUOutcome enum lacks @notice NatSpec tag [INFO]

The `TOFUOutcome` enum at line 18 uses a plain `///` comment ("Outcomes for TOFU token decimals reads.") but does not use the `@notice` NatSpec tag. All other top-level documentation elements in the file (`TOFUTokenDecimalsResult`, `TokenDecimalsReadFailure`, `ITOFUTokenDecimals`) use `@notice`. While Solidity NatSpec does not strictly require `@notice` for enums (and Solidity compilers may not process enum-level NatSpec tags uniformly), using the tag would be consistent with the rest of the file.

Similarly, the four enum variant comments (lines 20, 22, 24, 26) use plain `///` comments rather than any NatSpec tag. This is the standard convention for enum variants, as Solidity NatSpec does not define tags for enum members. No change needed for variant comments.

**Location:** `src/interface/ITOFUTokenDecimals.sol`, line 18

### A03-2: Interface function NatSpec uses plain comments instead of @notice [INFO]

The four interface functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) have detailed leading `///` comments describing their behavior, but none of these comments use the `@notice` tag. Their `@param` and `@return` tags are present and correct, but the descriptive text preceding the tags is plain comment text rather than `@notice`-tagged NatSpec.

This means documentation generators that rely on `@notice` may not capture the function descriptions. The struct, error, and interface-level comments all use `@notice`, so using it on function descriptions as well would improve consistency.

**Location:** `src/interface/ITOFUTokenDecimals.sol`, lines 54, 69, 79, 85

### A03-3: @return tags on decimalsForTokenReadOnly and decimalsForToken are accurate [INFO]

Verified the `@return` documentation against the implementation in `LibTOFUTokenDecimalsImplementation.sol`:

For `decimalsForTokenReadOnly` and `decimalsForToken`, the docs state:
> "On `Initial`, the freshly read value. On `Consistent` or `Inconsistent`, the previously stored value. On `ReadFailure`, the stored value (zero if uninitialized)."

This matches the implementation:
- `ReadFailure`: returns `tofuTokenDecimals.tokenDecimals` (stored value, zero if uninitialized) -- line 67 of implementation
- `Initial`: returns `uint8(readDecimals)` (freshly read) -- line 76 of implementation
- `Consistent`/`Inconsistent`: returns `tofuTokenDecimals.tokenDecimals` (stored value) -- line 81 of implementation

No inaccuracy found.

### A03-4: @param and @return tags are present and correct for all interface functions [INFO]

Verified all four interface functions:

1. **`decimalsForTokenReadOnly`** (line 67): `@param token` present and correct. `@return tofuOutcome` and `@return tokenDecimals` present and accurate.
2. **`decimalsForToken`** (line 77): `@param token` present and correct. `@return tofuOutcome` and `@return tokenDecimals` present and accurate.
3. **`safeDecimalsForToken`** (line 83): `@param token` present and correct. `@return tokenDecimals` present and accurate.
4. **`safeDecimalsForTokenReadOnly`** (line 91): `@param token` present and correct. `@return tokenDecimals` present and accurate.

No missing or incorrect tags.

### A03-5: Struct NatSpec @param tags are present and accurate [INFO]

The `TOFUTokenDecimalsResult` struct has a `@notice` tag explaining its purpose and two `@param` tags:
- `@param initialized` (line 9): Accurately describes the field's purpose as guarding against uninitialized zero.
- `@param tokenDecimals` (line 11): Accurately describes the field.

Both match the actual struct fields at lines 14-15. No issues found.

### A03-6: Error NatSpec @param tags are present and accurate [INFO]

The `TokenDecimalsReadFailure` error has a `@notice` tag and two `@param` tags:
- `@param token` (line 31): Accurately describes "The token that failed to read decimals."
- `@param tofuOutcome` (line 32): Accurately describes "The outcome of the TOFU read."

Both match the error parameters at line 33. No issues found.

### A03-7: safeDecimalsForTokenReadOnly documents uninitialized behavior [INFO]

The interface documentation for `safeDecimalsForTokenReadOnly` (lines 85-91) states: "When the token is uninitialized (no prior `decimalsForToken` call), returns the freshly read value without persisting it."

This is accurate. The implementation calls `decimalsForTokenReadOnly`, which returns `TOFUOutcome.Initial` with the freshly read value for uninitialized tokens. The safe wrapper permits `Initial` outcomes (line 170 of implementation: `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial`), so it does not revert. Being a `view` function, nothing is persisted.

However, the documentation does not explicitly warn that repeated read-only calls before initialization cannot detect inconsistency between calls (each call is a fresh `Initial`). The implementation library's NatSpec does include this warning (lines 152-156 of `LibTOFUTokenDecimalsImplementation.sol`), but the interface-level NatSpec omits it. This is a minor gap since the interface is the primary consumer-facing documentation.

**Location:** `src/interface/ITOFUTokenDecimals.sol`, lines 85-91

## Summary

The file is well-documented overall. The struct, error, enum, and all interface functions have NatSpec comments. `@param` and `@return` tags are present, correctly named, and accurate against the implementation. The main observations are:

- Minor inconsistency in NatSpec tag usage: the enum and interface function descriptions use plain `///` comments instead of `@notice` tags (findings A03-1 and A03-2).
- The `safeDecimalsForTokenReadOnly` interface NatSpec could benefit from the pre-initialization inconsistency detection limitation warning that exists in the library implementation's NatSpec (finding A03-7).

No CRITICAL, HIGH, or MEDIUM severity documentation issues were found.
