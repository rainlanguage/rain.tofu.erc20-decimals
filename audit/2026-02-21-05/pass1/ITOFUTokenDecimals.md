# Audit: `src/interface/ITOFUTokenDecimals.sol`

**Agent:** A03
**Pass:** 1 (Security)
**Date:** 2026-02-21

## Evidence of Thorough Reading

### File-Scope Types

| Name | Kind | Lines | Fields/Variants |
|------|------|-------|-----------------|
| `TOFUTokenDecimalsResult` | struct | 13-16 | `bool initialized` (L14), `uint8 tokenDecimals` (L15) |
| `TOFUOutcome` | enum | 19-28 | `Initial` (L21), `Consistent` (L23), `Inconsistent` (L25), `ReadFailure` (L27) |

### Interface: `ITOFUTokenDecimals` (L48-L97)

| Member | Kind | Line | Signature |
|--------|------|------|-----------|
| `TokenDecimalsReadFailure` | error | L52 | `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` |
| `decimalsForTokenReadOnly` | function | L67 | `function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` |
| `decimalsForToken` | function | L78 | `function decimalsForToken(address token) external returns (TOFUOutcome, uint8)` |
| `safeDecimalsForToken` | function | L84 | `function safeDecimalsForToken(address token) external returns (uint8)` |
| `safeDecimalsForTokenReadOnly` | function | L96 | `function safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` |

### Other Details

- SPDX: `LicenseRef-DCL-1.0` (L1)
- Pragma: `^0.8.25` (L3)
- NatSpec documentation present on all types, error, and functions.
- `forge-lint: disable-next-line(pascal-case-struct)` suppression at L12.

---

## Security Findings

### A03-01 [INFO] `safeDecimalsForTokenReadOnly` offers no TOFU protection before initialization

**Location:** L86-L96

**Description:** The NatSpec on `safeDecimalsForTokenReadOnly` correctly documents a WARNING that before initialization (i.e., before `decimalsForToken` has been called at least once), each call is a fresh `Initial` read with no stored value to compare against. This means a malicious or buggy token that changes its `decimals()` return value between two read-only calls will not be detected as inconsistent -- both calls will return `TOFUOutcome.Initial` with whatever value the token reports at that moment.

The interface documentation is accurate about this limitation. The function name includes "safe" which could give callers a false sense of security, but the NatSpec warning is clear.

**Impact:** Callers who rely exclusively on `safeDecimalsForTokenReadOnly` without ever calling `decimalsForToken` receive no TOFU protection. The risk is mitigated by the clear NatSpec warning, but the "safe" prefix in the function name may mislead less careful integrators who do not read documentation.

**Recommendation:** No code change required in the interface. The documentation is already correct. Implementors and integrators should be aware that `safeDecimalsForTokenReadOnly` is only truly "safe" (in the TOFU sense) after `decimalsForToken` has been called at least once for the token.

---

### A03-02 [INFO] Struct packing is optimal and type choices are appropriate

**Location:** L13-L16

**Description:** The `TOFUTokenDecimalsResult` struct uses `bool initialized` and `uint8 tokenDecimals`. Both fields fit within a single 32-byte storage slot, which is optimal for gas. The use of `uint8` for `tokenDecimals` is correct because `decimals()` in the ERC-20 standard returns `uint8`. The `initialized` boolean correctly addresses the ambiguity of uninitialized storage (default `0`) versus a legitimate decimals value of `0`.

Verified against the implementation in `LibTOFUTokenDecimalsImplementation.sol` (L53): the assembly bounds-checks `readDecimals > 0xff` before casting to `uint8`, which is consistent with the struct field type.

**Impact:** None. This is a positive observation.

---

### A03-03 [INFO] Enum ordering has implicit ABI integer mapping

**Location:** L19-L28

**Description:** The `TOFUOutcome` enum maps to `uint8` values: `Initial = 0`, `Consistent = 1`, `Inconsistent = 2`, `ReadFailure = 3`. This ordering is implicitly defined by Solidity's enum-to-integer mapping. The ordering is well-chosen:
- `Initial` (0) is the default/zero value, which is reasonable for uninitialized state.
- The error in the interface (`TokenDecimalsReadFailure`) is emitted for `Inconsistent` and `ReadFailure` outcomes (values 2 and 3), which are the "bad" outcomes.

The implementation correctly checks `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial` (L142, L166 of `LibTOFUTokenDecimalsImplementation.sol`), which rejects only values 2 and 3. If the enum were ever extended with new variants, this check pattern would need re-evaluation. However, since the enum is defined at file scope and the contract is deployed deterministically with fixed bytecode, extension is not a realistic concern.

**Impact:** None. The enum is correctly structured and its implicit integer mapping does not introduce any vulnerability.

---

### A03-04 [INFO] Error definition is well-formed and includes sufficient diagnostic data

**Location:** L49-L52

**Description:** `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` includes both the token address and the specific outcome that caused the failure. This provides sufficient information for off-chain tooling to diagnose the exact failure reason (inconsistency vs. read failure). The error selector is `0xee07877f` (verified against the creation code constant in `LibTOFUTokenDecimals.sol`).

**Impact:** None. This is a positive observation. The error is well-designed for debuggability.

---

### A03-05 [INFO] `decimalsForToken` is correctly non-view to permit state modification

**Location:** L69-L78

**Description:** `decimalsForToken` is `external` without `view` or `pure`, which is correct because the implementation stores the decimals on first read (`TOFUOutcome.Initial`). If this were accidentally marked `view`, the Solidity compiler would reject the implementation in `TOFUTokenDecimals.sol` at compile time. The `safeDecimalsForToken` variant (L80-L84) is also correctly non-view for the same reason.

**Impact:** None. The mutability modifiers are correct.

---

### A03-06 [INFO] Interface does not expose any unsafe patterns to implementers

**Location:** L48-L97

**Description:** Reviewing the interface for patterns that could lead implementers into security issues:

1. **No payable functions:** None of the four functions are payable, so implementations cannot accidentally receive ETH through this interface.
2. **No callbacks or reentrancy vectors:** The interface does not define any callback mechanisms. The only external interaction is the `staticcall` to `decimals()` in the implementation, which is read-only and cannot trigger reentrancy.
3. **No approval/allowance patterns:** The interface does not involve token transfers or approvals.
4. **Return value semantics are clear:** The `(TOFUOutcome, uint8)` return tuple forces callers to explicitly handle the outcome enum. The `safe` variants revert on failure, providing a simpler API for callers who want revert-on-error behavior.
5. **No `address(0)` validation in interface:** The interface does not specify behavior for `token = address(0)`. In the implementation, calling `decimals()` on `address(0)` would fail (no code at that address), returning `ReadFailure`. This is acceptable behavior but worth noting for implementers.

**Impact:** None. The interface is cleanly designed and does not expose unsafe patterns.

---

## Summary

No CRITICAL, HIGH, MEDIUM, or LOW findings identified in `src/interface/ITOFUTokenDecimals.sol`.

The file defines a well-structured interface with appropriate type safety, correct mutability modifiers, and a well-designed error type. The only notable point is that `safeDecimalsForTokenReadOnly` provides no TOFU protection before initialization, but this is correctly documented in the NatSpec with an explicit WARNING. The struct packing is optimal, enum ordering is reasonable, and no unsafe patterns are exposed to implementers.

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 0 |
| INFO     | 6 |
