# Pass 3 -- Documentation Audit: `src/interface/ITOFUTokenDecimals.sol`

**Auditor:** A03
**Date:** 2026-02-21
**File:** `src/interface/ITOFUTokenDecimals.sol` (97 lines)

---

## Evidence of Thorough Reading

### Interface

- **`ITOFUTokenDecimals`** (line 48) -- the sole interface in the file.

### Types Defined (file-level, outside the interface)

| Item | Kind | Line(s) |
|------|------|---------|
| `TOFUTokenDecimalsResult` | struct | 13-16 |
| `TOFUTokenDecimalsResult.initialized` | struct field (`bool`) | 14 |
| `TOFUTokenDecimalsResult.tokenDecimals` | struct field (`uint8`) | 15 |
| `TOFUOutcome` | enum | 19-28 |
| `TOFUOutcome.Initial` | enum value | 21 |
| `TOFUOutcome.Consistent` | enum value | 23 |
| `TOFUOutcome.Inconsistent` | enum value | 25 |
| `TOFUOutcome.ReadFailure` | enum value | 27 |

### Items Defined Inside the Interface

| Item | Kind | Line(s) |
|------|------|---------|
| `TokenDecimalsReadFailure` | error | 52 |
| `decimalsForTokenReadOnly` | function | 67 |
| `decimalsForToken` | function | 78 |
| `safeDecimalsForToken` | function | 84 |
| `safeDecimalsForTokenReadOnly` | function | 96 |

---

## NatSpec Verification

### `TOFUTokenDecimalsResult` struct (lines 5-16)

- **`@notice`** (lines 5-8): Present. Explains the struct's purpose and the reason
  for the `initialized` boolean (distinguishing stored `0` from uninitialized
  storage). Accurate.
- **`@param initialized`** (lines 9-10): Present. Accurate description.
- **`@param tokenDecimals`** (line 11): Present. Accurate description.

**Verdict:** Fully documented. No issues.

### `TOFUOutcome` enum (lines 18-28)

- **`@notice`** (line 18): Present. "Outcomes for TOFU token decimals reads."
  Accurate.
- **`Initial`** (line 21): Inline `///` comment present. Accurate.
- **`Consistent`** (line 23): Inline `///` comment present. Accurate.
- **`Inconsistent`** (line 25): Inline `///` comment present. Accurate.
- **`ReadFailure`** (line 27): Inline `///` comment present. Accurate.

**Verdict:** Fully documented. No issues.

### Interface `ITOFUTokenDecimals` (lines 30-48)

- **`@title`** (line 30): Present. `ITOFUTokenDecimals`.
- **`@notice`** (lines 31-47): Present. Comprehensive description covering TOFU
  rationale, ERC20 decimal use cases, guidance on handling inconsistency, and the
  assumption that decimals do not change over time.

**Verdict:** Fully documented. No issues.

### `TokenDecimalsReadFailure` error (lines 49-52)

- **`@notice`** (line 49): Present. "Thrown when a TOFU decimals safe read fails."
- **`@param token`** (line 50): Present. Accurate.
- **`@param tofuOutcome`** (line 51): Present. Accurate.

**Verdict:** Fully documented. Verified usage in
`LibTOFUTokenDecimalsImplementation.sol` lines 143 and 167 -- the error is reverted
with `(token, tofuOutcome)` matching the documented parameters exactly.

### `decimalsForTokenReadOnly` (lines 54-67)

- **`@notice`** (lines 54-61): Present. Describes read-only behavior, warns about
  uselessness before initialization, advises callers to handle the uninitialized
  case.
- **`@param token`** (line 62): Present. Accurate.
- **`@return tofuOutcome`** (line 63): Present. Accurate.
- **`@return tokenDecimals`** (lines 64-66): Present. Documents behavior per
  outcome. Verified against `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly`:
  - `Initial` returns freshly read value (line 71 of impl). **Correct.**
  - `Consistent`/`Inconsistent` returns previously stored value (line 76 of impl).
    **Correct.**
  - `ReadFailure` returns stored value, zero if uninitialized (line 62 of impl).
    **Correct.**

**Verdict:** Fully documented. Accurate against implementation.

### `decimalsForToken` (lines 69-78)

- **`@notice`** (lines 69-72): Present. Describes storing on first read, no
  modification on subsequent calls, and the need for caller outcome handling.
- **`@param token`** (line 73): Present. Accurate.
- **`@return tofuOutcome`** (line 74): Present. Accurate.
- **`@return tokenDecimals`** (lines 75-77): Present. Same per-outcome semantics as
  `decimalsForTokenReadOnly`. Verified against implementation: `decimalsForToken`
  delegates to `decimalsForTokenReadOnly` and only additionally writes storage on
  `Initial` (impl line 119-121). Return values are identical. **Correct.**

**Verdict:** Fully documented. Accurate against implementation.

### `safeDecimalsForToken` (lines 80-84)

- **`@notice`** (lines 80-81): Present. "Safely reads the decimals for a token,
  reverting if the read fails or is inconsistent with the stored value."
- **`@param token`** (line 82): Present. Accurate.
- **`@return tokenDecimals`** (line 83): Present. Accurate.

Verified against implementation (impl lines 141-145): reverts when outcome is
neither `Consistent` nor `Initial`, i.e., reverts on `Inconsistent` and
`ReadFailure`. This matches "reverting if the read fails or is inconsistent."
**Correct.**

**Verdict:** Fully documented. Accurate against implementation.

### `safeDecimalsForTokenReadOnly` (lines 86-96)

- **`@notice`** (lines 86-93): Present. Describes read-only safe read, behavior
  when uninitialized (returns freshly read value without persisting), and includes
  the `WARNING` about pre-initialization behavior.
- **`@param token`** (line 94): Present. Accurate.
- **`@return tokenDecimals`** (line 95): Present. Accurate.

Verified against implementation (impl lines 165-169): same revert logic as
`safeDecimalsForToken` but delegates to `decimalsForTokenReadOnly` instead.
When uninitialized, `decimalsForTokenReadOnly` returns `Initial` with the freshly
read value, and the safe wrapper passes `Initial` through without reverting -- so
"returns the freshly read value without persisting it" is **correct.**

The `WARNING` (lines 90-93) accurately describes that before initialization, each
call is a fresh `Initial` read with no stored baseline, so inconsistency cannot be
detected across calls. This is verified: `decimalsForTokenReadOnly` never writes
storage, so repeated calls on an uninitialized token always return `Initial` with
whatever the token currently reports, with no cross-call consistency check.

**Verdict:** Fully documented. Accurate against implementation.

---

## Findings

### A03-001 [INFO] -- Enum value comments lack `@notice` tag

**Location:** Lines 21, 23, 25, 27

The four `TOFUOutcome` enum values use bare `///` doc-comments (e.g.,
`/// Token's decimals have not been read from the external contract before.`)
rather than `/// @notice ...`. While Solidity's NatSpec specification does not
formally require `@notice` on enum values, and many toolchains treat bare `///`
as implicit `@notice`, adding explicit `@notice` tags would be consistent with
the style used on every other documented item in this file (struct, error,
functions, interface).

This is purely a stylistic consistency observation and has no functional impact.

### A03-002 [INFO] -- No NatSpec inconsistencies found

All NatSpec documentation in `ITOFUTokenDecimals.sol` was verified against the
implementation in `LibTOFUTokenDecimalsImplementation.sol`, the concrete contract
`TOFUTokenDecimals.sol`, and the caller convenience library
`LibTOFUTokenDecimals.sol`. The `@return` tag documentation for all four outcome
cases (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`) accurately describes
which value is returned (freshly read vs. stored) in each case. The `WARNING` on
`safeDecimalsForTokenReadOnly` correctly identifies the pre-initialization gap in
TOFU protection. The `TokenDecimalsReadFailure` error parameters match usage. All
`@param` and `@return` tags are present and correctly named.

### A03-003 [INFO] -- Struct `@notice` uses "token's decimals" phrasing redundantly

**Location:** Lines 5-8

The struct `@notice` says "Encodes the token's decimals for a token." The phrase
"for a token" is redundant given "the token's decimals" already implies a specific
token. A minor phrasing improvement could be "Encodes a token's decimals result."
This has no functional impact.

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 0 |
| INFO     | 3 |

The interface file is thoroughly and accurately documented. All NatSpec tags are
present on all public items (struct, struct fields, enum, enum values, error, error
parameters, interface title/notice, all four functions with their parameters and
return values). Documentation is accurate when cross-referenced against the
implementation. The `WARNING` on `safeDecimalsForTokenReadOnly` correctly captures
a real semantic subtlety. The only observations are minor stylistic points with no
functional or security impact.
