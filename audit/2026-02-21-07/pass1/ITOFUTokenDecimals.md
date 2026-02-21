# Audit Pass 1 (Security) -- ITOFUTokenDecimals.sol

**Agent:** A01
**File:** `src/interface/ITOFUTokenDecimals.sol`
**Date:** 2026-02-21

## Evidence of thorough reading

### Pragma

- Line 3: `pragma solidity ^0.8.25;`

### Struct definitions

- Lines 13--16: `TOFUTokenDecimalsResult` with fields `bool initialized` and `uint8 tokenDecimals`.

### Enum definitions

- Lines 19--28: `TOFUOutcome` with variants `Initial` (0), `Consistent` (1), `Inconsistent` (2), `ReadFailure` (3).

### Interface

- Line 48: `interface ITOFUTokenDecimals`

### Custom errors

- Line 55: `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`

### Function signatures

- Line 70: `function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)`
- Line 81: `function decimalsForToken(address token) external returns (TOFUOutcome, uint8)`
- Line 87: `function safeDecimalsForToken(address token) external returns (uint8)`
- Line 99: `function safeDecimalsForTokenReadOnly(address token) external view returns (uint8)`

### Constants

- None defined.

## Security review

This file is a pure interface definition: it contains no executable code, no assembly blocks, no arithmetic, no state mutations, and no access control logic. All items defined are type declarations (struct, enum), a custom error, and function signatures.

Checklist evaluation:

| Concern | Applicable? | Notes |
|---|---|---|
| Memory safety in assembly blocks | No | No assembly in this file. |
| Input validation | No | No function bodies; validation is an implementation concern. |
| Reentrancy and state consistency | No | No state or logic. |
| Arithmetic safety | No | No arithmetic. |
| Error handling | N/A | Error is declared correctly as a custom error (not a string revert). |
| Access controls | No | No function bodies; access control is an implementation concern. |
| Custom errors only | Pass | The sole error `TokenDecimalsReadFailure` uses the custom error pattern. No string reverts. |

## Findings

No findings.
