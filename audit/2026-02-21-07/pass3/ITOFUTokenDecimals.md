# Audit Pass 3 (Documentation) - ITOFUTokenDecimals.sol

**Agent:** A01
**File:** `src/interface/ITOFUTokenDecimals.sol`
**Date:** 2026-02-21

## Evidence of Thorough Reading

The file is 100 lines long and contains:

1. **`TOFUTokenDecimalsResult` struct** (lines 5-16): Two fields (`initialized`, `tokenDecimals`). Has `@notice` explaining purpose and guarding against default zero. Has `@param` for both fields.
2. **`TOFUOutcome` enum** (lines 18-28): Four variants (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`). Has `@notice` at enum level plus inline `///` comments on each variant.
3. **`ITOFUTokenDecimals` interface** (lines 30-100): Has `@title` and `@notice` explaining the TOFU approach, rationale, and caller guidance.
4. **`TokenDecimalsReadFailure` error** (lines 49-55): Has `@notice` and `@param` for both parameters (`token`, `tofuOutcome`).
5. **`decimalsForTokenReadOnly` function** (lines 57-70): Has `@notice`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals` with per-outcome semantics.
6. **`decimalsForToken` function** (lines 72-81): Has `@notice`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals` with per-outcome semantics.
7. **`safeDecimalsForToken` function** (lines 83-87): Has `@notice`, `@param token`, `@return tokenDecimals`.
8. **`safeDecimalsForTokenReadOnly` function** (lines 89-99): Has `@notice` with WARNING about pre-initialization behavior, `@param token`, `@return tokenDecimals`.

## Item-by-Item Documentation Verification

### `TOFUTokenDecimalsResult` struct

| Check | Status |
|-------|--------|
| `@notice` present | Yes (lines 5-8) |
| `@param initialized` present and accurate | Yes (lines 9-10) |
| `@param tokenDecimals` present and accurate | Yes (line 11) |
| Documentation matches definition | Yes |

### `TOFUOutcome` enum

| Check | Status |
|-------|--------|
| `@notice` present | Yes (line 18) |
| All variants documented | Yes: `Initial` (line 20), `Consistent` (line 22), `Inconsistent` (line 24), `ReadFailure` (line 27) |
| Documentation matches definition | Yes |

### `ITOFUTokenDecimals` interface

| Check | Status |
|-------|--------|
| `@title` present | Yes (line 30) |
| `@notice` present | Yes (lines 31-47) |

### `TokenDecimalsReadFailure` error

| Check | Status |
|-------|--------|
| `@notice` present | Yes (lines 49-52) |
| `@param token` present and accurate | Yes (line 53) |
| `@param tofuOutcome` present and accurate | Yes (line 54) |
| Documentation matches definition | Yes |

### `decimalsForTokenReadOnly` function

| Check | Status |
|-------|--------|
| `@notice` present | Yes (lines 57-64) |
| `@param token` present and accurate | Yes (line 65) |
| `@return tofuOutcome` present and accurate | Yes (line 66) |
| `@return tokenDecimals` present and accurate | Yes (lines 67-69) |
| Documentation matches definition | Yes |

### `decimalsForToken` function

| Check | Status |
|-------|--------|
| `@notice` present | Yes (lines 72-75) |
| `@param token` present and accurate | Yes (line 76) |
| `@return tofuOutcome` present and accurate | Yes (line 77) |
| `@return tokenDecimals` present and accurate | Yes (lines 78-80) |
| Documentation matches definition | Yes |

### `safeDecimalsForToken` function

| Check | Status |
|-------|--------|
| `@notice` present | Yes (lines 83-84) |
| `@param token` present and accurate | Yes (line 85) |
| `@return tokenDecimals` present and accurate | Yes (line 86) |
| Documentation matches definition | Yes |

### `safeDecimalsForTokenReadOnly` function

| Check | Status |
|-------|--------|
| `@notice` present with WARNING | Yes (lines 89-96) |
| `@param token` present and accurate | Yes (line 97) |
| `@return tokenDecimals` present and accurate | Yes (line 98) |
| Documentation matches definition | Yes |

## Accuracy Cross-Check Against Implementation

I verified the documentation claims against `LibTOFUTokenDecimalsImplementation.sol`:

- **`decimalsForToken` "Storage is written only on the `Initial` outcome"** (line 73): Confirmed at implementation line 119-121, only writes when `tofuOutcome == TOFUOutcome.Initial`.
- **`decimalsForToken` "subsequent calls never modify the stored value"** (lines 73-74): Confirmed; the only write path is guarded by `tofuOutcome == TOFUOutcome.Initial`.
- **`decimalsForTokenReadOnly` return semantics** (lines 67-69): Confirmed at implementation lines 62-78. On `ReadFailure`, returns `tofuTokenDecimals.tokenDecimals` (stored value, zero if uninitialized). On `Initial`, returns `uint8(readDecimals)` (freshly read). On `Consistent`/`Inconsistent`, returns `tofuTokenDecimals.tokenDecimals` (stored value).
- **`safeDecimalsForToken` reverts on non-Initial/non-Consistent**: Confirmed at implementation lines 142-143.
- **`safeDecimalsForTokenReadOnly` WARNING about pre-initialization**: Confirmed; the read-only path never writes storage, so repeated calls on an uninitialized token each return `Initial` with the fresh read, unable to detect changes between calls.
- **Error `TokenDecimalsReadFailure` documentation says it covers both `Inconsistent` and `ReadFailure`**: Confirmed at implementation lines 142 and 166; the check is `tofuOutcome != Consistent && tofuOutcome != Initial`, which indeed triggers on both `Inconsistent` and `ReadFailure`.

## Findings

No findings.

All public items (1 struct, 1 enum, 1 interface, 1 error, 4 functions) have complete and accurate NatSpec documentation including `@notice`, `@param`, and `@return` tags. The documentation correctly describes the behavior as verified against the implementation. The per-outcome return value semantics are consistently and accurately documented across both the interface and the implementation library.
