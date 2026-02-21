# Audit Pass 3 (Documentation) - LibTOFUTokenDecimals.sol

**Agent:** A03
**Date:** 2026-02-21
**File:** `src/lib/LibTOFUTokenDecimals.sol`
**Cross-reference:** `src/interface/ITOFUTokenDecimals.sol`

## Evidence of Thorough Reading

**Library name:** `LibTOFUTokenDecimals` (line 21)

### Declarations with Line Numbers

| Kind     | Name                                | Line(s) |
|----------|-------------------------------------|---------|
| error    | `TOFUTokenDecimalsNotDeployed`      | 24      |
| constant | `TOFU_DECIMALS_DEPLOYMENT`          | 29-30   |
| constant | `TOFU_DECIMALS_EXPECTED_CODE_HASH`  | 36-37   |
| constant | `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | 44-45 |
| function | `ensureDeployed()`                  | 51-58   |
| function | `decimalsForTokenReadOnly(address)` | 66-71   |
| function | `decimalsForToken(address)`         | 79-84   |
| function | `safeDecimalsForToken(address)`     | 89-92   |
| function | `safeDecimalsForTokenReadOnly(address)` | 97-100 |

## Documentation Checks

### NatSpec Coverage

All functions, constants, and the error have `@notice` documentation. The library itself has a `@title` and `@notice` block (lines 7-20).

### @param and @return Tags

- `TOFUTokenDecimalsNotDeployed`: has `@param expectedAddress` -- accurate, matches the single parameter.
- `ensureDeployed()`: no params, no returns -- no tags needed, none present. Correct.
- `decimalsForTokenReadOnly(address token)`: has `@param token`, `@return tofuOutcome`, `@return tokenDecimals` -- all accurate.
- `decimalsForToken(address token)`: has `@param token`, `@return tofuOutcome`, `@return tokenDecimals` -- all accurate.
- `safeDecimalsForToken(address token)`: has `@param token`, `@return tokenDecimals` -- accurate (single return).
- `safeDecimalsForTokenReadOnly(address token)`: has `@param token`, `@return tokenDecimals` -- accurate (single return).

### Cross-Reference Accuracy

Each of the four main functions uses "As per `ITOFUTokenDecimals.<functionName>`" in its `@notice`:

- Line 60: "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`" -- verified against interface line 54-67. Accurate.
- Line 73: "As per `ITOFUTokenDecimals.decimalsForToken`" -- verified against interface line 69-78. Accurate.
- Line 86: "As per `ITOFUTokenDecimals.safeDecimalsForToken`" -- verified against interface line 80-84. Accurate.
- Line 94: "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`" -- verified against interface line 86-96. Accurate.

### Documentation vs. Implementation Accuracy

The `@return tokenDecimals` descriptions for `decimalsForTokenReadOnly` and `decimalsForToken` state:
> On `Initial`, the freshly read value. On `Consistent` or `Inconsistent`, the previously stored value. On `ReadFailure`, the stored value (zero if uninitialized).

Verified against `LibTOFUTokenDecimalsImplementation.sol`:
- `ReadFailure` (line 62): returns `tofuTokenDecimals.tokenDecimals` (stored value). Correct.
- `Initial` (line 71): returns `uint8(readDecimals)` (freshly read value). Correct.
- `Consistent`/`Inconsistent` (lines 74-77): returns `tofuTokenDecimals.tokenDecimals` (stored value). Correct.

The library delegates to the singleton (`TOFU_DECIMALS_DEPLOYMENT`) via external calls after calling `ensureDeployed()`, so the documented behavior is governed by the implementation library and is accurately described.

The `ensureDeployed` NatSpec (lines 47-50) states it reverts with `TOFUTokenDecimalsNotDeployed` when code is missing or codehash mismatches. The implementation (lines 52-57) checks `code.length == 0` and `codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH`, reverting with that error. Accurate.

## Findings

No findings. All documentation in this file is accurate, complete, and consistent with both the interface definitions and the underlying implementation.
