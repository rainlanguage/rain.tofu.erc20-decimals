# Audit Pass 1 (Security) -- ITOFUTokenDecimals.sol

**Agent ID:** A02
**Date:** 2026-02-21
**File:** `src/interface/ITOFUTokenDecimals.sol`

---

## Evidence of Thorough Reading

### Types Defined

| Kind | Name | Line(s) |
|------|------|---------|
| Struct | `TOFUTokenDecimalsResult` | 13-16 |
| Enum | `TOFUOutcome` | 19-28 |
| Error | `TokenDecimalsReadFailure` | 33 |
| Interface | `ITOFUTokenDecimals` | 53-92 |

### Struct Fields

- `TOFUTokenDecimalsResult.initialized` (bool) -- line 14
- `TOFUTokenDecimalsResult.tokenDecimals` (uint8) -- line 15

### Enum Variants (in order)

0. `Initial` -- line 21
1. `Consistent` -- line 23
2. `Inconsistent` -- line 25
3. `ReadFailure` -- line 27

### Error Parameters

- `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` -- line 33

### Interface Functions

| Function | Line | Mutability | Returns |
|----------|------|------------|---------|
| `decimalsForTokenReadOnly(address token)` | 67 | `view` | `(TOFUOutcome, uint8)` |
| `decimalsForToken(address token)` | 77 | non-view (state-changing) | `(TOFUOutcome, uint8)` |
| `safeDecimalsForToken(address token)` | 83 | non-view (state-changing) | `uint8` |
| `safeDecimalsForTokenReadOnly(address token)` | 91 | `view` | `uint8` |

### Additional Observations

- License: `LicenseRef-DCL-1.0` (line 1)
- Pragma: `^0.8.25` (line 3) -- note: the interface uses a caret pragma while the concrete contract uses exact `=0.8.25`
- All four interface functions accept a single `address token` parameter
- NatSpec documentation is present for all types, error, and functions

---

## Security Findings

### Finding 1: Enum Ordering Places `Initial` at Index 0 -- Default Value Coincidence

**Severity:** INFO

**Location:** Lines 19-28

**Description:** The `TOFUOutcome` enum assigns `Initial` as variant 0. In Solidity, the default value for an enum-typed variable in uninitialized storage or memory is 0, which corresponds to `Initial`. This means any uninitialized `TOFUOutcome` variable would silently carry the value `Initial` rather than a value that signals an error state.

**Analysis:** In the context of this codebase, this is not a practical vulnerability. The `TOFUOutcome` enum is only ever assigned as a return value from explicit function calls (`decimalsForToken`, `decimalsForTokenReadOnly`) -- it is never read from raw storage where default-value confusion could arise. The enum is used purely as a transient return value, not a persisted state. The design is intentional and sound: `Initial` correctly represents the "first time reading" state, and callers must handle all four outcomes. No code path relies on default-initialized enum values.

**Recommendation:** No action required. The current ordering is logical and safe within the usage context.

---

### Finding 2: `TokenDecimalsReadFailure` Error Accepts `Initial` and `Consistent` Outcomes

**Severity:** INFO

**Location:** Line 33

**Description:** The `TokenDecimalsReadFailure` error accepts any `TOFUOutcome` value, including `Initial` and `Consistent`, even though it is semantically only relevant for `Inconsistent` and `ReadFailure` outcomes. There is no type-level restriction preventing the error from being thrown with a non-failure outcome.

**Analysis:** Reviewing the implementation in `LibTOFUTokenDecimalsImplementation.sol` (lines 146-148 and 167-169), the `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` functions revert with this error only when `tofuOutcome != Consistent && tofuOutcome != Initial`, which correctly limits actual usage to `Inconsistent` and `ReadFailure`. The error type is broader than its actual usage, but this is standard Solidity practice -- error types often accept general parameters. Adding a separate error type would increase complexity without meaningful security benefit.

**Recommendation:** No action required. The implementation correctly constrains when this error is emitted.

---

### Finding 3: Struct Packing Efficiency

**Severity:** INFO

**Location:** Lines 13-16

**Description:** The `TOFUTokenDecimalsResult` struct contains `bool initialized` (1 byte) and `uint8 tokenDecimals` (1 byte). Together these occupy 2 bytes and pack into a single 32-byte storage slot, which is correct and gas-efficient. The ordering of fields (`bool` before `uint8`) is also optimal since both fit in the first slot regardless of order.

**Analysis:** The packing is correct. When used as a mapping value (`mapping(address => TOFUTokenDecimalsResult)`), each entry occupies exactly one storage slot. The `initialized` flag at the first position is appropriate since the compiler packs `bool` (1 byte) and `uint8` (1 byte) contiguously. No wasted storage.

**Recommendation:** No action required. Storage layout is optimal.

---

### Finding 4: Interface Pragma Uses Caret (`^0.8.25`) While Concrete Contract Uses Exact (`=0.8.25`)

**Severity:** INFO

**Location:** Line 3

**Description:** The interface file uses `pragma solidity ^0.8.25;`, allowing compilation with any 0.8.x compiler >= 0.8.25. The concrete `TOFUTokenDecimals.sol` uses `pragma solidity =0.8.25;`, pinning to an exact version. The implementation library `LibTOFUTokenDecimalsImplementation.sol` also uses `^0.8.25`.

**Analysis:** This is an intentional and correct design. The caret pragma on the interface and library allows downstream consumers to compile against them with newer 0.8.x versions. The exact pragma on the concrete contract ensures bytecode determinism, which is critical for the Zoltu deterministic deployment address. The interface file is purely abstract (no bytecode), so its pragma does not affect deployed bytecode.

**Recommendation:** No action required. The pragma strategy is sound and correctly separates consumer-facing flexibility from deployment determinism.

---

### Finding 5: No Access Control in Interface

**Severity:** INFO

**Location:** Lines 53-92

**Description:** All four functions in `ITOFUTokenDecimals` are `external` with no access control modifiers. Any address can call `decimalsForToken` to initialize and store the decimals for any token.

**Analysis:** This is intentional by design. The TOFU contract is a shared singleton that anyone can use. The trust model is that the first reader of a token's decimals sets the stored value. Since `decimalsForToken` reads directly from the token contract via `staticcall` to `decimals()`, the stored value reflects the actual on-chain state at the time of the first call. A malicious actor cannot inject arbitrary values -- they can only trigger a read at a particular moment in time. An attacker deploying a malicious token that later changes its decimals would be caught by the `Inconsistent` outcome on subsequent reads, which is the entire purpose of the TOFU scheme.

**Recommendation:** No action required. Permissionless access is the intended design for a shared singleton.

---

### Finding 6: No Event Emission Defined in Interface

**Severity:** LOW

**Location:** Lines 53-92

**Description:** The `ITOFUTokenDecimals` interface does not define any events. In particular, there is no event emitted when decimals are first stored (`Initial` outcome) or when an inconsistency is detected (`Inconsistent` outcome). This limits off-chain observability -- indexers and monitoring tools cannot easily track when tokens are first registered or when inconsistencies are detected without tracing calls.

**Analysis:** Events are not strictly required for correctness. The return values provide all necessary information to callers. However, for a singleton contract intended to serve many downstream protocols, event emission on `Initial` and `Inconsistent` outcomes would enable off-chain monitoring systems to detect inconsistencies across all consumers. This is a defense-in-depth consideration rather than a direct vulnerability.

**Recommendation:** Consider adding events for `Initial` and `Inconsistent` outcomes to improve off-chain observability. This is a quality-of-life improvement for integrators, not a security requirement.

---

### Finding 7: `decimalsForTokenReadOnly` Returns Stored Value (Possibly Zero) on `ReadFailure`

**Severity:** INFO

**Location:** Lines 64-66 (interface NatSpec)

**Description:** The NatSpec for `decimalsForTokenReadOnly` and `decimalsForToken` documents that on `ReadFailure`, the returned `tokenDecimals` is "the stored value (zero if uninitialized)." This means if a token has never been initialized and its `decimals()` call fails, the return is `(ReadFailure, 0)`. A careless caller that ignores the `TOFUOutcome` and only uses the `uint8` return could treat `0` as a valid decimals value.

**Analysis:** Reviewing the implementation confirms this behavior (line 67 of the implementation). The interface NatSpec correctly documents this edge case. The `safe*` variants mitigate this by reverting on `ReadFailure`. For the non-safe variants, the responsibility is explicitly on the caller to check the `TOFUOutcome`, which is the documented API contract. This is by design.

**Recommendation:** No action required. The NatSpec accurately documents the behavior, and the `safe*` variants exist precisely to protect callers who want automatic revert behavior.

---

## Summary Table

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | Enum ordering places `Initial` at index 0 (default value) | INFO | No action required |
| 2 | Error type accepts semantically non-failure outcomes | INFO | No action required |
| 3 | Struct packing is optimal | INFO | No action required |
| 4 | Caret vs exact pragma is intentional | INFO | No action required |
| 5 | No access control (intentional for singleton) | INFO | No action required |
| 6 | No events defined for state changes | LOW | Consider adding events |
| 7 | `ReadFailure` returns possibly-zero stored value | INFO | Documented behavior |

**Overall Assessment:** The `ITOFUTokenDecimals.sol` interface file is well-designed with no critical, high, or medium severity findings. The type definitions are appropriate, struct packing is efficient, enum ordering is logical within the usage context, and the error type is correctly constrained by implementation logic. The only actionable finding (LOW) is the absence of event definitions, which would improve off-chain monitoring but does not constitute a security vulnerability. The interface correctly separates read-only from state-changing operations and provides both safe (reverting) and unsafe (outcome-returning) variants for caller flexibility.
