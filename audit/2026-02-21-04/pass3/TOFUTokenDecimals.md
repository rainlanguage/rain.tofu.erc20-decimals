<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 3 — Documentation Review: `src/concrete/TOFUTokenDecimals.sol`

Auditor: A02
Date: 2026-02-21
Pass: 3 (Documentation)

---

## Evidence of Thorough Reading

**Contract name:** `TOFUTokenDecimals` (line 13)

**Functions and their line numbers:**

| Name | Visibility | Mutability | Line |
|---|---|---|---|
| `decimalsForTokenReadOnly` | external | view | 19 |
| `decimalsForToken` | external | (non-view) | 25 |
| `safeDecimalsForToken` | external | (non-view) | 31 |
| `safeDecimalsForTokenReadOnly` | external | view | 36 |

**Types, errors, and constants defined in this file:** None. The file imports and uses the following from external files but defines none of its own:

- *Imported types*: `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome` (from `src/interface/ITOFUTokenDecimals.sol`)
- *Imported library*: `LibTOFUTokenDecimalsImplementation` (from `src/lib/LibTOFUTokenDecimalsImplementation.sol`)

**State variables:**

| Name | Type | Visibility | Line |
|---|---|---|---|
| `sTOFUTokenDecimals` | `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)` | internal | 16 |

---

## Documentation Findings

### F-01: `@inheritdoc` usage is appropriate but creates an implicit documentation dependency

**Classification: INFO**

All four external functions use `/// @inheritdoc ITOFUTokenDecimals` (lines 18, 24, 30, 35). This is the correct and conventional Solidity NatSpec pattern for implementations: it pulls all `@notice`, `@param`, and `@return` tags from the interface, avoiding duplication and reducing the risk of stale copied text.

The documentation on the interface (`src/interface/ITOFUTokenDecimals.sol`) is complete for all four functions: `@param token` and `@return` tags are present on each function. There is nothing missing in the inheritance chain for a documentation tool (e.g., `forge doc`) to resolve.

No action required. Noted for completeness.

---

### F-02: Contract-level `@title` and `@notice` are present and accurate

**Classification: INFO**

Lines 8–12 provide:

```solidity
/// @title TOFUTokenDecimals
/// @notice Minimal implementation of the ITOFUTokenDecimals interface using
/// LibTOFUTokenDecimalsImplementation for the logic. The concrete contract
/// simply stores the mapping of token addresses to TOFUTokenDecimalsResult
/// structs and delegates all logic to the library.
```

This accurately describes the contract's role: it owns storage and delegates all logic. No inaccuracy detected.

---

### F-03: Storage variable has `@notice` but no `@dev` or `@param` for named mapping keys

**Classification: LOW**

The storage variable `sTOFUTokenDecimals` at line 14–16 has a `@notice` tag:

```solidity
/// @notice Storage mapping from token address to its TOFU decimals result.
// forge-lint: disable-next-line(mixed-case-variable)
mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;
```

The named mapping parameters (`token`, `tofuTokenDecimals`) are self-documenting and the `@notice` is brief but sufficient. However, the `@notice` tag is placed on a `// forge-lint` suppression line intervenes between the NatSpec comment and the variable declaration. The forge-lint suppression uses `//` (non-NatSpec), which is placed between the `///` NatSpec block and the variable itself. Some documentation tooling may fail to attach the `@notice` to the variable correctly depending on how they handle mixed `//` and `///` lines.

This is a minor tooling-compatibility concern, not a security issue. The human-readable documentation is clear.

---

### F-04: No `@dev` tag on the contract explaining deployment/singleton constraints

**Classification: LOW**

The contract-level NatSpec does not mention:

- That this contract is intended to be deployed as a singleton via the Zoltu deterministic factory.
- That bytecode determinism is critical (exact compiler version, optimizer settings, etc.).
- That the deployed address is hardcoded into `LibTOFUTokenDecimals` (the caller convenience library).

A developer reading only `TOFUTokenDecimals.sol` in isolation has no indication that this file must not be recompiled with different settings, or that its address is embedded elsewhere. The CLAUDE.md captures this constraint at the project level, but no in-file `@dev` documents it.

This is particularly relevant because a maintainer who modifies compiler settings would not receive any warning from the file itself that doing so breaks the deployed singleton address used by `LibTOFUTokenDecimals`.

Suggested addition:

```solidity
/// @dev This contract is deployed as a singleton via the Zoltu deterministic
/// factory. Its bytecode is intentionally reproducible: exact solc version
/// `=0.8.25`, `evm_version = "cancun"`, `bytecode_hash = "none"`,
/// `cbor_metadata = false`, and optimizer at 1,000,000 runs. Changing any
/// of these settings changes the deployed address, breaking
/// `LibTOFUTokenDecimals` which hard-codes the expected address and codehash.
```

---

### F-05: `safeDecimalsForTokenReadOnly` — interface doc says "returns freshly read value" but does not call out the security caveat present in the implementation library

**Classification: MEDIUM**

The interface documentation for `safeDecimalsForTokenReadOnly` (lines 85–91 of `ITOFUTokenDecimals.sol`) reads:

> When the token is uninitialized (no prior `decimalsForToken` call), returns the freshly read value without persisting it.

This is accurate but omits a critical security nuance that is documented in the library implementation (`LibTOFUTokenDecimalsImplementation.sol` lines 147–151):

> WARNING: Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected. Callers needing TOFU protection must ensure `decimalsForToken` has been called at least once for the token.

Because `TOFUTokenDecimals.safeDecimalsForTokenReadOnly` uses `@inheritdoc`, it inherits the interface documentation which lacks this warning. A caller who reads only the interface or the concrete contract NatSpec will not see this important behavioural caveat.

The warning exists in the library but is one layer removed from the public API surface. It should be present at the interface level so that `@inheritdoc` propagates it to all implementations and callers.

**Recommendation:** Add the warning to `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`'s NatSpec. The concrete contract's `@inheritdoc` will then automatically inherit it.

---

### F-06: `decimalsForTokenReadOnly` interface doc describes `ReadFailure` return semantics but does not mention the edge case of a pre-initialization `ReadFailure`

**Classification: LOW**

The interface documents the `@return tokenDecimals` for `decimalsForTokenReadOnly` and `decimalsForToken` as:

> On `ReadFailure`, the stored value (zero if uninitialized).

This correctly states that zero is returned when uninitialized, but does not highlight that this zero is the Solidity default — not a meaningful decimal value. A caller might interpret `(ReadFailure, 0)` as "the token has 0 decimals and the read failed" rather than "the storage slot is empty and the read failed."

The `TOFUTokenDecimalsResult.initialized` field exists precisely to avoid this misinterpretation in storage, but the external callers using only the returned `uint8` have no equivalent disambiguation. A `@dev` note clarifying this edge case would reduce caller confusion.

---

### F-07: No constructor, receive, or fallback — absence is not documented

**Classification: INFO**

The contract has no constructor, `receive`, or `fallback` functions. This is intentional — the singleton is deployed by factory with no initializer arguments and should not accept Ether. The absence of `receive`/`fallback` is correct for this design but is not documented. A brief `@dev` note on the contract stating "No constructor arguments, no Ether acceptance" would clarify intent for maintainers.

This is an informational observation; the absence itself is not a defect.

---

### F-08: `slither-disable-next-line unused-return` comments are unexplained

**Classification: INFO**

Lines 20 and 26 carry `// slither-disable-next-line unused-return` comments. These suppress Slither's warning that the return value of the library call is not explicitly named or discarded. The concrete functions do return the values (the `return` statement is the library call result), so the suppression appears to be a false positive from Slither's perspective.

No NatSpec `@dev` explains why these suppressions are present. Adding a brief inline comment (or confirming the Slither version producing the false positive) would help future auditors understand that this is not hiding a real unused-return defect.

---

## Summary Table

| ID | Severity | Title |
|---|---|---|
| F-01 | INFO | `@inheritdoc` usage is correct; no missing NatSpec in resolution chain |
| F-02 | INFO | Contract `@title` and `@notice` are present and accurate |
| F-03 | LOW | `forge-lint` suppression comment between NatSpec and storage variable may confuse doc tooling |
| F-04 | LOW | No `@dev` documenting singleton/deterministic-bytecode deployment constraint |
| F-05 | MEDIUM | `safeDecimalsForTokenReadOnly` security warning absent from interface NatSpec; not propagated via `@inheritdoc` |
| F-06 | LOW | `ReadFailure` pre-initialization zero-return edge case not called out for external callers |
| F-07 | INFO | Absence of constructor/receive/fallback not documented |
| F-08 | INFO | `slither-disable-next-line unused-return` suppressions unexplained |
