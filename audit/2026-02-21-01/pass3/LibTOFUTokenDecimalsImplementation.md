# Pass 3 — Documentation Audit: LibTOFUTokenDecimalsImplementation

**File:** `/src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Agent:** A04
**Date:** 2026-02-21

---

## 1. Evidence of Thorough Reading

### Library

| Item | Kind | Line(s) |
|------|------|---------|
| `LibTOFUTokenDecimalsImplementation` | library | 18 |

### Constants

| Name | Type | Line |
|------|------|------|
| `TOFU_DECIMALS_SELECTOR` | `bytes4` | 20 |

### Functions

| Name | Visibility | Mutability | Lines |
|------|-----------|-----------|-------|
| `decimalsForTokenReadOnly` | `internal` | `view` | 34-84 |
| `decimalsForToken` | `internal` | (state-changing) | 113-127 |
| `safeDecimalsForToken` | `internal` | (state-changing) | 140-150 |
| `safeDecimalsForTokenReadOnly` | `internal` | `view` | 161-171 |

### Imported Types and Errors (from `ITOFUTokenDecimals.sol`)

| Name | Kind | Lines (in interface file) |
|------|------|---------------------------|
| `ITOFUTokenDecimals` | interface | 53-92 |
| `TOFUTokenDecimalsResult` | struct | 13-16 |
| `TOFUOutcome` | enum | 19-28 |
| `TokenDecimalsReadFailure` | error | 33 |

### Errors Directly Used in This File

| Name | Used At Lines |
|------|---------------|
| `TokenDecimalsReadFailure` | 147, 168 |

---

## 2. Documentation Findings

### 2.1 Library-Level Documentation

The `@title` tag (line 12) is present and matches the library name. The `@notice` (lines 13-17) accurately describes the library's purpose: TOFU approach, reads token decimals, stores on first read, checks consistency on subsequent reads, designed for use in `TOFUTokenDecimals`. This is accurate and complete.

### 2.2 Constant: `TOFU_DECIMALS_SELECTOR` (line 20)

Has a `@dev` comment: "The selector for the `decimals()` function in the ERC20 standard." Value `0x313ce567` is verified correct against the standard ERC20 `decimals()` selector (confirmed by test at `LibTOFUTokenDecimalsImplementationTest.testDecimalsSelector` which asserts `TOFU_DECIMALS_SELECTOR == IERC20.decimals.selector`). Documentation is accurate.

### 2.3 Function: `decimalsForTokenReadOnly` (lines 34-84)

**Doc tags present:**
- `@notice` (lines 22-24): "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`. Works as `decimalsForToken` but does not store any state, simply checking for consistency if we have a stored value."
- `@param sTOFUTokenDecimals` (lines 25-28): Describes the storage mapping parameter.
- `@param token` (line 29): Describes the token address parameter.
- `@return tofuOutcome` (line 30): Describes the outcome of the TOFU read.
- `@return tokenDecimals` (lines 31-33): Describes the returned decimals value and clarifies behavior per outcome.

**Accuracy check:**
- The `@notice` says "Works as `decimalsForToken` but does not store any state." This is accurate. The read-only function performs the same logic (read from token, compare with stored) but never writes to storage.
- The `@return tokenDecimals` documentation states: "On `Initial`, the freshly read value. On `Consistent` or `Inconsistent`, the previously stored value. On `ReadFailure`, the stored value (zero if uninitialized)." Verified against implementation:
  - Line 76: On `Initial` (not initialized), returns `uint8(readDecimals)` -- the freshly read value. Correct.
  - Lines 79-82: On `Consistent`/`Inconsistent`, returns `tofuTokenDecimals.tokenDecimals` -- the stored value. Correct.
  - Line 67: On `ReadFailure`, returns `tofuTokenDecimals.tokenDecimals` -- the stored value (default zero if uninitialized). Correct.
- All documentation is accurate and complete.

### 2.4 Function: `decimalsForToken` (lines 113-127)

**Doc tags present:**
- Block comment (lines 86-103): Free-form NatSpec describing TOFU behavior in detail (Initial, Consistent, ReadFailure, Inconsistent).
- `@param sTOFUTokenDecimals` (lines 104-107).
- `@param token` (line 108).
- `@return tofuOutcome` (line 109).
- `@return tokenDecimals` (lines 110-112).

**Accuracy check:**
- The block comment accurately describes all four outcomes. Each outcome description matches the implementation:
  - "If we have nothing stored we read from the token, store and return it with TOFUOutcome.Initial." -- Line 121 calls `decimalsForTokenReadOnly`, then lines 123-124 store if `Initial`. Correct.
  - "If the stored value is consistent... TOFUOutcome.Consistent." -- Handled in the read-only function and passed through. Correct.
  - "If the call to `decimals` is not a success... TOFUOutcome.ReadFailure." -- Handled in read-only function, no storage write on non-Initial. Correct.
  - "If the stored value is inconsistent... TOFUOutcome.Inconsistent." -- Handled in read-only function, no storage write. Correct.
- The `@return tokenDecimals` documentation matches `decimalsForTokenReadOnly` since the return values are passed through directly (line 126). Correct.

**Style observation:** This function uses a free-form NatSpec comment block (`///`) without a `@notice` tag, while `decimalsForTokenReadOnly` uses `@notice`. This is a minor inconsistency in documentation style but does not affect tooling since both forms are valid NatSpec.

### 2.5 Function: `safeDecimalsForToken` (lines 140-150)

**Doc tags present:**
- Block comment (lines 129-132): "Trust on first use (TOFU) token decimals. Same as `decimalsForToken` but reverts with `TokenDecimalsReadFailure` if the token's decimals are inconsistent or the read fails. On the first read the decimals are never considered inconsistent."
- `@param sTOFUTokenDecimals` (lines 133-136).
- `@param token` (line 137).
- `@return` (line 138): "The token's decimals."

**Accuracy check:**
- "Same as `decimalsForToken` but reverts with `TokenDecimalsReadFailure` if the token's decimals are inconsistent or the read fails." -- Implementation at lines 145-148: calls `decimalsForToken`, checks if outcome is not `Consistent` and not `Initial`, reverts with `TokenDecimalsReadFailure`. This correctly reverts on both `Inconsistent` and `ReadFailure`. Accurate.
- "On the first read the decimals are never considered inconsistent." -- Accurate. On first read, `decimalsForToken` returns `Initial`, which passes the guard at line 146.
- `@return` says "The token's decimals." -- Single return value, `uint8`. Accurate but could be more specific (e.g., specifying it returns the stored value on `Consistent` or the freshly read value on `Initial`). This is minor since the function reverts on all other outcomes.

### 2.6 Function: `safeDecimalsForTokenReadOnly` (lines 161-171)

**Doc tags present:**
- Comment (line 152-153): "As per `safeDecimalsForToken` but read-only. Does not store the decimals on first read."
- `@param sTOFUTokenDecimals` (lines 154-157).
- `@param token` (line 158).
- `@return` (line 159): "The token's decimals."

**Accuracy check:**
- "As per `safeDecimalsForToken` but read-only." -- Implementation at lines 166-170: calls `decimalsForTokenReadOnly` (the read-only variant) instead of `decimalsForToken`, then applies the same revert guard. Correct.
- "Does not store the decimals on first read." -- Correct: `decimalsForTokenReadOnly` never writes to storage.
- The revert condition at lines 167-168 is identical to `safeDecimalsForToken` (line 146). Correct.

---

## 3. Findings

### A04-1: `decimalsForToken` uses free-form NatSpec instead of `@notice` tag [INFO]

**Location:** Lines 86-103

**Description:** The `decimalsForToken` function uses a free-form `///` comment block describing TOFU behavior without a `@notice` tag, while the other three functions in the library use `@notice` (or reference `@notice` from the interface via "As per"). This is a minor stylistic inconsistency. Both forms are valid NatSpec and will be parsed correctly by documentation generators, but using `@notice` uniformly would improve consistency.

**Severity:** INFO -- No functional impact. Documentation content is thorough and accurate.

### A04-2: `safeDecimalsForToken` doc says "reverts... if inconsistent or read fails" but does not explicitly mention that it also calls through to `decimalsForToken` and therefore writes storage on `Initial` [INFO]

**Location:** Lines 129-132

**Description:** The documentation for `safeDecimalsForToken` states it is the "Same as `decimalsForToken` but reverts..." which implicitly conveys the storage-writing behavior by reference. However, a reader who does not already know `decimalsForToken` behavior must follow the reference chain. In contrast, `safeDecimalsForTokenReadOnly` explicitly states "Does not store the decimals on first read," highlighting the difference. Adding an explicit note such as "Stores decimals on first read" to `safeDecimalsForToken` would make the distinction clearer when reading the two safe variants side by side.

**Severity:** INFO -- Documentation is technically accurate via the reference to `decimalsForToken`, but could be more self-contained.

### A04-3: `@return` tag on `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` is minimal [INFO]

**Location:** Line 138 and line 159

**Description:** Both safe variants document their return as simply "The token's decimals." The non-safe variants (`decimalsForToken`, `decimalsForTokenReadOnly`) provide detailed per-outcome return descriptions (e.g., "On `Initial`, the freshly read value. On `Consistent` or `Inconsistent`, the previously stored value."). Since the safe variants revert on `Inconsistent` and `ReadFailure`, only `Initial` and `Consistent` outcomes can produce a return. A more precise `@return` could state: "The token's decimals -- the freshly read value on `Initial`, or the previously stored value on `Consistent`." This would parallel the more detailed documentation in the non-safe variants.

**Severity:** INFO -- The current documentation is not incorrect since the function does return the token's decimals. The suggestion is purely about precision.

### A04-4: `TOFUOutcome` enum members in interface file lack `@notice` tags [INFO]

**Location:** `/src/interface/ITOFUTokenDecimals.sol`, lines 19-28

**Description:** The `TOFUOutcome` enum has free-form `///` comments on each member (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`) but these do not use `@notice` or `@dev` NatSpec tags. The struct `TOFUTokenDecimalsResult` (lines 5-16) does use `@notice` and `@param` tags properly. While enum member NatSpec tags are not universally supported by all tooling, using `///` without a tag is standard practice for enum variants in Solidity. This is included for completeness but is not a real issue.

**Severity:** INFO -- Standard Solidity enum documentation practice; no action needed.

### A04-5: `decimalsForTokenReadOnly` comment block references `ITOFUTokenDecimals.decimalsForTokenReadOnly` but does not use `@inheritdoc` [INFO]

**Location:** Line 22

**Description:** The `@notice` on `decimalsForTokenReadOnly` begins with "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`." This is a manual cross-reference rather than using `@inheritdoc`. Since this is a library function (not an interface implementation), `@inheritdoc` is not semantically applicable -- only contract functions overriding an interface can use `@inheritdoc`. The manual reference is therefore the correct approach. No action needed. Noted for completeness.

**Severity:** INFO -- Correct use of manual cross-reference given Solidity NatSpec constraints.

### A04-6: `safeDecimalsForTokenReadOnly` doc omits warning about lack of TOFU protection before initialization [MEDIUM]

**Location:** Lines 152-153

**Description:** The comment reads: "As per `safeDecimalsForToken` but read-only. Does not store the decimals on first read."

This description omits an important behavioral nuance. On the `Initial` outcome (first read, no stored value), `safeDecimalsForTokenReadOnly` will succeed and return the freshly read value without persisting it. This means successive calls to `safeDecimalsForTokenReadOnly` for an uninitialized token will each make a fresh `staticcall` to the token and could return different values if the token's `decimals()` changes between calls -- without ever detecting inconsistency. The interface doc in `ITOFUTokenDecimals.sol` (lines 85-91) does mention this nuance ("When the token is uninitialized... returns the freshly read value without persisting it"), but the implementation doc does not.

This is a documentation gap: the implementation-level comment should warn callers that read-only usage before initialization provides no TOFU protection, as each call is treated as a fresh `Initial` read.

**Severity:** MEDIUM -- The missing warning could lead callers to use `safeDecimalsForTokenReadOnly` as if it provides TOFU guarantees before initialization, when it does not.

### A04-7: No documentation inaccuracies found [INFO]

**Description:** All doc comments were verified against the implementation line by line. Every `@param`, `@return`, and `@notice` accurately describes the actual behavior. The return value semantics per `TOFUOutcome` branch are correctly documented for all four functions. The constant `TOFU_DECIMALS_SELECTOR` value is verified correct. No misleading, incorrect, or outdated documentation was found.

**Severity:** INFO -- Positive finding confirming documentation accuracy.

---

## Summary

| ID | Severity | Summary |
|----|----------|---------|
| A04-1 | INFO | `decimalsForToken` uses free-form NatSpec instead of `@notice` |
| A04-2 | INFO | `safeDecimalsForToken` doc does not explicitly state it writes storage on `Initial` |
| A04-3 | INFO | `@return` on safe variants is minimal compared to non-safe variants |
| A04-4 | INFO | `TOFUOutcome` enum members lack formal NatSpec tags (standard practice) |
| A04-5 | INFO | Manual cross-reference instead of `@inheritdoc` is correct for library functions |
| A04-6 | MEDIUM | `safeDecimalsForTokenReadOnly` doc omits warning about lack of TOFU protection before initialization |
| A04-7 | INFO | No documentation inaccuracies found -- all docs verified correct |

**Overall assessment:** The documentation in `LibTOFUTokenDecimalsImplementation.sol` is thorough, accurate, and well-structured. All four functions have complete `@param` and `@return` documentation. The return value semantics per TOFU outcome are explicitly documented and verified correct against the implementation. One MEDIUM finding was identified: `safeDecimalsForTokenReadOnly` should warn callers that read-only usage before initialization provides no TOFU protection.
