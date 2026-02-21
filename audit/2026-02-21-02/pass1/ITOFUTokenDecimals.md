# Security Audit: `src/interface/ITOFUTokenDecimals.sol`

**Audit ID:** 2026-02-21-02, Pass 1 (Security)
**Agent:** A03
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/interface/ITOFUTokenDecimals.sol`

## Evidence of Thorough Reading

### File-level items
- **SPDX License:** `LicenseRef-DCL-1.0` (line 1)
- **Pragma:** `^0.8.25` (line 3)

### Struct: `TOFUTokenDecimalsResult` (line 13)
- Field `initialized` (`bool`, line 14)
- Field `tokenDecimals` (`uint8`, line 15)

### Enum: `TOFUOutcome` (line 19)
- `Initial` (value 0, line 21)
- `Consistent` (value 1, line 23)
- `Inconsistent` (value 2, line 25)
- `ReadFailure` (value 3, line 27)

### Error: `TokenDecimalsReadFailure` (line 33)
- Parameter `token` (`address`)
- Parameter `tofuOutcome` (`TOFUOutcome`)

### Interface: `ITOFUTokenDecimals` (line 53)
- `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 67)
- `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 77)
- `safeDecimalsForToken(address token) external returns (uint8)` (line 83)
- `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 91)

---

## Findings

### INFO-01: No events defined for state-changing operations

**Severity:** INFO

**Location:** Interface `ITOFUTokenDecimals`, lines 53-92

**Description:** The interface defines `decimalsForToken` and `safeDecimalsForToken` as state-mutating functions (they store the first-read decimals value), but the interface does not declare any events. When a token's decimals are stored for the first time (`Initial` outcome) or when an inconsistency is detected, no event is emitted by the contract.

While not a security vulnerability, this is a design consideration. Off-chain monitoring tools (block explorers, indexers, security dashboards) cannot observe when a token's decimals are first locked in, or when an inconsistency is detected, without tracing internal state changes. For a singleton contract shared across many callers, event emission on `Initial` and `Inconsistent` outcomes would significantly improve observability and incident response.

**Recommendation:** Consider adding events to the interface, for example:
```solidity
event TokenDecimalsInitialized(address indexed token, uint8 decimals);
event TokenDecimalsInconsistency(address indexed token, uint8 storedDecimals, uint8 readDecimals);
```

Note: Adding events would change the deployed bytecode, which would break the deterministic deployment address. This should only be considered for a future version.

---

### INFO-02: `TokenDecimalsReadFailure` error name is broader than its semantics

**Severity:** INFO

**Location:** Line 33

**Description:** The error `TokenDecimalsReadFailure` is used for both `ReadFailure` and `Inconsistent` outcomes (confirmed in `LibTOFUTokenDecimalsImplementation.sol` lines 146-147 and 170-171, where the safe functions revert when the outcome is neither `Consistent` nor `Initial`). The name `TokenDecimalsReadFailure` suggests only a failed read (e.g., the `staticcall` did not succeed), but it is also thrown when the read succeeds and the value is inconsistent with the stored decimals.

This is purely a naming concern and does not affect correctness. However, it could cause confusion for integrators catching this error by selector -- they may not realize that `tofuOutcome == Inconsistent` is a valid value for this error, not just `ReadFailure`.

**Recommendation:** Consider renaming to something more general like `TokenDecimalsTOFUFailure` or `TokenDecimalsUnsafe`, or document clearly in the error NatSpec that the error covers both inconsistency and read failure cases.

---

### INFO-03: Interface does not expose stored state for inspection

**Severity:** INFO

**Location:** Interface `ITOFUTokenDecimals`, lines 53-92

**Description:** The interface provides no way to query the raw stored `TOFUTokenDecimalsResult` for a given token without making an external `staticcall` to the token contract. Every call to `decimalsForTokenReadOnly` or `decimalsForToken` performs a live `staticcall` to the token. There is no function like `getStoredDecimals(address token) returns (bool initialized, uint8 tokenDecimals)` that returns only the stored state.

This means:
1. If a token contract self-destructs or becomes inaccessible, callers cannot retrieve the previously stored decimals without hitting a `ReadFailure` outcome. (The stored value is returned alongside `ReadFailure`, so it is accessible via the return tuple, but `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` will revert.)
2. Off-chain systems cannot cheaply check what value is stored without the overhead and potential failure of the external call to the token.

This is a design trade-off, not a bug. The `ReadFailure` return from the non-safe variants does return the stored value, providing a recovery path for callers who handle the outcome enum directly.

---

### INFO-04: `decimalsForTokenReadOnly` returns stored value (possibly zero) on `ReadFailure` without distinguishing initialized vs uninitialized

**Severity:** INFO

**Location:** Interface NatSpec, line 66; Implementation at `LibTOFUTokenDecimalsImplementation.sol` line 67

**Description:** Per the interface documentation (line 66): "On `ReadFailure`, the stored value (zero if uninitialized)." When a `ReadFailure` occurs, the returned `tokenDecimals` is the stored value. If the token was never initialized, this is `0`. If the token was previously initialized with `0` decimals (a legitimate value for some tokens), the returned tuple `(ReadFailure, 0)` is ambiguous -- the caller cannot distinguish between "never initialized, read failed" and "initialized with 0, read failed" purely from the return values.

The NatSpec documents this behavior parenthetically, but the ambiguity is inherent in the return type. A caller handling `ReadFailure` who wants to know whether to trust the `0` must make a separate check (which is not exposed by the interface, as noted in INFO-03).

In practice this is mitigated because callers using `safeDecimalsForToken` will revert on `ReadFailure`, and callers using the raw `decimalsForToken` are expected to handle the outcome enum carefully. Nevertheless, this is a potential source of subtle bugs in integrating code.

**Recommendation:** Document this ambiguity more prominently, or consider adding a `bool initialized` to the return tuple of the non-safe functions.

---

## Summary

No CRITICAL, HIGH, MEDIUM, or LOW findings were identified. The interface file is well-structured with appropriate type safety:

- The `TOFUTokenDecimalsResult` struct correctly uses `bool initialized` to disambiguate `0` decimals from uninitialized storage, and `uint8 tokenDecimals` matches the ERC20 `decimals()` return range.
- The `TOFUOutcome` enum covers all four logical outcomes exhaustively.
- The `TokenDecimalsReadFailure` error includes sufficient context (token address and outcome) for debugging.
- The interface function signatures correctly use `view` for read-only variants and non-`view` for state-mutating variants.
- The `^0.8.25` pragma is appropriate for an interface file (the concrete contract pins to `=0.8.25` for bytecode determinism, which is the correct layering).

Four informational findings were noted relating to observability (no events), error naming breadth, lack of raw state inspection, and a minor ambiguity in `ReadFailure` return values.
