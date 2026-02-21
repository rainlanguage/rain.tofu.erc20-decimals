<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 3 — Documentation Audit
## File: `src/lib/LibTOFUTokenDecimalsImplementation.sol`

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimalsImplementation` (line 13)

### Functions and Line Numbers

| Function | Visibility | Mutability | Line |
|---|---|---|---|
| `decimalsForTokenReadOnly` | internal | view | 29 |
| `decimalsForToken` | internal | (non-view) | 108 |
| `safeDecimalsForToken` | internal | (non-view) | 135 |
| `safeDecimalsForTokenReadOnly` | internal | view | 159 |

### Types, Errors, and Constants

**Constant (defined locally):**
- `TOFU_DECIMALS_SELECTOR` — `bytes4 constant`, value `0x313ce567` (line 15)

**Types imported from `ITOFUTokenDecimals`:**
- `TOFUTokenDecimalsResult` — struct with `bool initialized` and `uint8 tokenDecimals`
- `TOFUOutcome` — enum (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`)
- `TokenDecimalsReadFailure` — custom error `(address token, TOFUOutcome tofuOutcome)`

No types, errors, or events are defined locally in this library.

### NatSpec Comments Found

**Library-level:**
- Line 7: `/// @title LibTOFUTokenDecimalsImplementation`
- Lines 8–12: `/// @notice` — multi-line description of the library's purpose

**`TOFU_DECIMALS_SELECTOR` constant (line 14):**
- `/// @dev The selector for the `decimals()` function in the ERC20 standard.`

**`decimalsForTokenReadOnly` (lines 17–28):**
- Lines 17–19: `/// @notice As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`. Works as ...`
- Lines 20–23: `/// @param sTOFUTokenDecimals` — describes the storage mapping parameter
- Line 24: `/// @param token` — describes the token parameter
- Lines 25: `/// @return tofuOutcome`
- Lines 26–28: `/// @return tokenDecimals` — describes all four outcome cases

**`decimalsForToken` (lines 81–107):**
- Lines 81–98: bare `///` description block (no `@notice` tag)
- Lines 99–102: `/// @param sTOFUTokenDecimals`
- Line 103: `/// @param token`
- Lines 104–107: `/// @return tofuOutcome` and `/// @return tokenDecimals`

**`safeDecimalsForToken` (lines 124–133):**
- Lines 124–127: bare `///` description block (no `@notice` tag)
- Lines 128–131: `/// @param sTOFUTokenDecimals`
- Line 132: `/// @param token`
- Line 133: `/// @return The token's decimals.`

**`safeDecimalsForTokenReadOnly` (lines 147–157):**
- Lines 147–151: bare `///` description with embedded WARNING (no `@notice` tag)
- Lines 152–155: `/// @param sTOFUTokenDecimals`
- Line 156: `/// @param token`
- Line 157: `/// @return The token's decimals.`

---

## Findings

### FINDING 1 — HIGH: Inconsistent NatSpec Tag Usage Across Functions

**Location:** Lines 17, 81, 124, 147

**Detail:**
`decimalsForTokenReadOnly` opens its NatSpec block with an explicit `@notice` tag (line 17), making it the only function in the library that does so. The three other functions (`decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) use bare `///` description lines with no `@notice` tag.

Solidity NatSpec treats the first paragraph of bare `///` lines as `@notice` implicitly, so tooling will render them equivalently. However, the inconsistency creates a misleading visual pattern: a reader comparing functions may think only `decimalsForTokenReadOnly` has a `@notice` while others do not. This is a documentation quality defect that affects maintainability and readability.

**Evidence:**
```solidity
// Line 17 — uses explicit @notice:
/// @notice As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`. Works as
/// `decimalsForToken` but does not store any state...

// Line 81 — bare /// with no @notice:
/// Trust on first use (TOFU) token decimals.
/// The first time we read the decimals from a token we store them in a
/// mapping.
```

**Recommendation:** Either apply `@notice` tags consistently to all four functions, or remove the explicit `@notice` from `decimalsForTokenReadOnly` so all functions use the implicit bare-`///` form.

---

### FINDING 2 — MEDIUM: `decimalsForToken` Cross-Reference to Interface Is Absent

**Location:** Lines 81–98

**Detail:**
`decimalsForTokenReadOnly` explicitly states "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`" (line 17), providing a clear link to the interface definition. `decimalsForToken` has no equivalent cross-reference despite being the primary stateful function defined in `ITOFUTokenDecimals`. A reader of the library function cannot easily navigate to the interface contract.

The same omission applies to `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly`, both of which have counterparts in `ITOFUTokenDecimals`.

**Recommendation:** Add cross-references in the style of `decimalsForTokenReadOnly`:
- `decimalsForToken`: add "As per `ITOFUTokenDecimals.decimalsForToken`."
- `safeDecimalsForToken`: add "As per `ITOFUTokenDecimals.safeDecimalsForToken`."
- `safeDecimalsForTokenReadOnly`: add "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`."

---

### FINDING 3 — MEDIUM: Duplicate `forge-lint` Suppression Comments on `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly`

**Location:** Lines 134–136, 158–160

**Detail:**
Both `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` contain two `// forge-lint: disable-next-line(mixed-case-variable)` comments each. The first comment appears on the line immediately before the `function` keyword; the second appears on the line immediately before the `sTOFUTokenDecimals` parameter.

The `disable-next-line` directive suppresses the lint warning on the very next source line. When placed before the `function` keyword line, it targets the function declaration itself — not the parameter — and is redundant (and arguably incorrect placement). The inner comment on the parameter line is the correct and sufficient suppression.

```solidity
// Line 134 — targets the function keyword line (incorrect/redundant):
// forge-lint: disable-next-line(mixed-case-variable)
function safeDecimalsForToken(
    // Line 136 — correctly targets the parameter:
    // forge-lint: disable-next-line(mixed-case-variable)
    mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
```

This pattern does not affect compilation or runtime behavior, but it indicates a copy-paste artifact that adds noise to the file and may confuse future maintainers about the intended suppression target.

**Recommendation:** Remove the outer `// forge-lint: disable-next-line(mixed-case-variable)` comment (lines 134 and 158) from both functions, keeping only the inner comment immediately before the parameter.

---

### FINDING 4 — LOW: Constant Uses `@dev` Rather Than `@notice`

**Location:** Line 14

**Detail:**
```solidity
/// @dev The selector for the `decimals()` function in the ERC20 standard.
bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567;
```

The library uses `@notice` for its own header and `@notice` on `decimalsForTokenReadOnly`, but the only internal constant uses `@dev`. This is a minor inconsistency. `@dev` is conventionally for implementation notes addressed to developers, while `@notice` is for end-user/consumer descriptions. For a selector constant that will never appear in generated ABI documentation, `@dev` is an acceptable choice, but it diverges from the otherwise `@notice`-first documentation style.

**Recommendation:** No change is strictly required. If the project adopts a consistent policy of using `@notice` for all documented items, update to `@notice`. Otherwise, document the convention explicitly.

---

### FINDING 5 — LOW: WARNING Comment Placement Inside NatSpec Block May Not Render as Expected

**Location:** Lines 148–151

**Detail:**
The WARNING comment for `safeDecimalsForTokenReadOnly` is embedded directly in the bare `///` NatSpec description block:

```solidity
/// As per `safeDecimalsForToken` but read-only. Does not store the decimals
/// on first read. WARNING: Before initialization, each call is a fresh
/// `Initial` read with no stored value to check against, so inconsistency
/// between calls cannot be detected. Callers needing TOFU protection must
/// ensure `decimalsForToken` has been called at least once for the token.
```

The WARNING is accurate and correctly describes the behavior (confirmed by inspection of `decimalsForTokenReadOnly` at lines 67–71, which returns `TOFUOutcome.Initial` whenever `!tofuTokenDecimals.initialized`, meaning every pre-initialization call is treated as a fresh first read). However, being written as prose rather than using a structured tag (e.g., a NatSpec `@dev` tag or Markdown formatting), it may be dropped or de-emphasized in generated documentation. There is no standard NatSpec `@warning` tag, but using `@dev` for the warning text would make it visually separate and less likely to be missed.

**Accuracy verdict:** The warning is factually correct.

**Recommendation:** Consider separating the WARNING into a `@dev` tag for visual distinctiveness:
```solidity
/// @notice As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`. Does not
/// store the decimals on first read.
/// @dev WARNING: Before initialization, each call is a fresh `Initial` read
/// with no stored value to check against, so inconsistency between calls
/// cannot be detected. Callers needing TOFU protection must ensure
/// `decimalsForToken` has been called at least once for the token.
```

---

### FINDING 6 — LOW: `@return` Named Parameters Do Not Match Actual Return Variable Names

**Location:** Lines 25–28, 104–107

**Detail:**
`decimalsForTokenReadOnly` and `decimalsForToken` both document their return values using named labels:

```solidity
/// @return tofuOutcome The outcome of the TOFU read.
/// @return tokenDecimals The token's decimals.
```

However, their signatures declare anonymous returns:

```solidity
) internal view returns (TOFUOutcome, uint8)
) internal returns (TOFUOutcome, uint8)
```

The named labels `tofuOutcome` and `tokenDecimals` in `@return` tags are a NatSpec documentation convention (not a Solidity language construct) and do not need to match actual variable names. However, in the function body at line 116, the local variables are also named `tofuOutcome` and `readDecimals` — note that the `@return` for the second value says `tokenDecimals` while the local variable is `readDecimals`. This is a minor documentation/code inconsistency that could mislead a reader trying to trace the documented label to the implementation variable.

**Recommendation:** Either align the `@return` label with the local variable (`readDecimals`) or rename the local variable to `tokenDecimals` for consistency with the documented API.

---

### FINDING 7 — INFO: Assembly Return-Slot Overlap Is Not Documented

**Location:** Lines 45–57

**Detail:**
The assembly block in `decimalsForTokenReadOnly` uses memory offset `0` for both writing the call selector and reading the return data:

```solidity
assembly ("memory-safe") {
    mstore(0, selector)                              // writes selector at [0, 32)
    success := staticcall(gas(), token, 0, 0x04, 0, 0x20)  // reads 4 bytes from [0,4), writes return to [0,32)
    if lt(returndatasize(), 0x20) { success := 0 }
    if success {
        readDecimals := mload(0)                     // reads return value from [0, 32)
        if gt(readDecimals, 0xff) { success := 0 }
    }
}
```

The `mstore(0, selector)` stores a left-aligned bytes4 value in the scratch space. After the `staticcall`, the output is written to `[0, 0x20)`, overwriting the selector. `mload(0)` then reads the 32-byte return value. This is a well-known EVM pattern for calling external functions in assembly but is not commented in the code. A developer unfamiliar with EVM memory layout might wonder whether the selector write interferes with the return-data read. A brief inline comment would eliminate any ambiguity.

**Recommendation:** Add a comment such as:
```solidity
// The staticcall output overwrites the scratch space used for the selector;
// mload(0) reads the full 32-byte decoded return value.
```

---

### FINDING 8 — INFO: Library `@notice` Does Not Describe the Storage-Parameter Design Pattern

**Location:** Lines 8–12

**Detail:**
The library `@notice` correctly describes the TOFU semantics and its relationship to `TOFUTokenDecimals`, but does not mention the library's key architectural property: it takes the storage mapping as a parameter rather than owning any storage itself. This is the primary reason this library exists as a separate layer from `TOFUTokenDecimals`. A one-sentence addition would make the architectural intent explicit.

**Recommendation:** Consider adding: "Functions take the storage mapping as an explicit parameter so this library owns no storage and can be reused by any contract that manages its own `mapping(address => TOFUTokenDecimalsResult)`."

---

## Summary Table

| # | Severity | Title |
|---|---|---|
| 1 | HIGH | Inconsistent NatSpec tag usage — `@notice` on one function, bare `///` on three others |
| 2 | MEDIUM | Missing interface cross-references on `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly` |
| 3 | MEDIUM | Duplicate `forge-lint` suppression comments on `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` |
| 4 | LOW | Constant documented with `@dev` rather than `@notice`, inconsistent with library-level style |
| 5 | LOW | WARNING for pre-initialization behavior embedded in prose rather than a distinct NatSpec tag |
| 6 | LOW | `@return` label `tokenDecimals` does not match local variable name `readDecimals` |
| 7 | INFO | Assembly selector/return-data memory overlap pattern is undocumented |
| 8 | INFO | Library `@notice` omits description of the storage-parameter architectural pattern |

---

## Accuracy Verification

All NatSpec descriptions were verified against the implementation:

- **`decimalsForTokenReadOnly` `@notice`** — accurate; the function is read-only and delegates to local logic.
- **`decimalsForToken` description** — accurate; stores on `Initial`, returns stored value otherwise.
- **`safeDecimalsForToken` description** — accurate; reverts on `ReadFailure` and `Inconsistent`, accepts `Initial` and `Consistent`.
- **`safeDecimalsForTokenReadOnly` WARNING** — factually correct; before `initialized` is set, every call returns `TOFUOutcome.Initial` (line 71), so cross-call consistency cannot be detected.
- **`TOFU_DECIMALS_SELECTOR = 0x313ce567`** — correct; `keccak256("decimals()")` truncated to 4 bytes is `0x313ce567`.
- **`@return` for `ReadFailure`** on `decimalsForTokenReadOnly`: "the stored value (zero if uninitialized)" — accurate; line 62 returns `tofuTokenDecimals.tokenDecimals` which is the zero-default `uint8` if never set.
- **`@return` for `Initial`** on `decimalsForTokenReadOnly`: "the freshly read value" — accurate; line 71 returns `uint8(readDecimals)`.
- **Cross-reference `ITOFUTokenDecimals.decimalsForTokenReadOnly`** — valid; this function exists in the interface at line 67 of `ITOFUTokenDecimals.sol`.
