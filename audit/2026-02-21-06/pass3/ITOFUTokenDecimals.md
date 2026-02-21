# Audit Pass 3 (Documentation) - ITOFUTokenDecimals.sol

**Auditor:** A01
**Date:** 2026-02-21
**File:** `src/interface/ITOFUTokenDecimals.sol`

## Evidence of Reading

### Contract/Interface Name
- `ITOFUTokenDecimals` (interface, line 48)

### Types (structs, enums)
- `TOFUTokenDecimalsResult` (struct, lines 13-16) -- fields: `initialized` (bool), `tokenDecimals` (uint8)
- `TOFUOutcome` (enum, lines 19-28) -- values: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`

### Error
- `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 52)

### Functions
- `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 67)
- `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 78)
- `safeDecimalsForToken(address token) external returns (uint8)` (line 84)
- `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 96)

### Constants
- None declared in this file. (The implementation library defines `TOFU_DECIMALS_SELECTOR` but that is outside scope of this file.)

## Documentation Review

### TOFUTokenDecimalsResult (lines 5-16)
- Has `@notice` describing purpose and the initialized flag rationale. Adequate.
- Has `@param initialized` -- accurate. Adequate.
- Has `@param tokenDecimals` -- accurate. Adequate.

### TOFUOutcome (lines 18-28)
- Has `@notice` on the enum. Adequate.
- Each enum value has an inline `///` comment describing its meaning. Adequate.

### TokenDecimalsReadFailure (lines 49-52)
- Has `@notice` describing when it is thrown. Adequate.
- Has `@param token` -- accurate. Adequate.
- Has `@param tofuOutcome` -- accurate. Adequate.

### ITOFUTokenDecimals interface (lines 30-48)
- Has `@title` and extensive `@notice` describing the TOFU approach. Adequate.

### decimalsForTokenReadOnly (lines 54-67)
- Has `@notice` describing read-only behavior and caveats. Adequate.
- Has `@param token` -- accurate. Adequate.
- Has `@return tofuOutcome` -- accurate. Adequate.
- Has `@return tokenDecimals` with per-outcome semantics. Adequate.

### decimalsForToken (lines 69-78)
- Has `@notice` describing storage-on-first-read behavior. Adequate.
- Has `@param token` -- accurate. Adequate.
- Has `@return tofuOutcome` -- accurate. Adequate.
- Has `@return tokenDecimals` with per-outcome semantics. Adequate.

### safeDecimalsForToken (lines 80-84)
- Has `@notice` describing revert-on-failure behavior. Adequate.
- Has `@param token` -- accurate. Adequate.
- Has `@return tokenDecimals` -- accurate. Adequate.

### safeDecimalsForTokenReadOnly (lines 86-96)
- Has `@notice` describing read-only safe behavior with WARNING about pre-initialization caveat. Adequate.
- Has `@param token` -- accurate. Adequate.
- Has `@return tokenDecimals` -- accurate. Adequate.

## Findings

No findings. All public types, errors, and functions have complete and accurate NatSpec documentation including `@notice`, `@param`, and `@return` tags. The documentation correctly describes the behavior verified against the implementation in `LibTOFUTokenDecimalsImplementation.sol` and `TOFUTokenDecimals.sol`. The per-outcome return value semantics documented in the interface match the implementation logic exactly. The WARNING on `safeDecimalsForTokenReadOnly` correctly describes the pre-initialization limitation.
