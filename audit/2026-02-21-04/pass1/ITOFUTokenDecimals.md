# Pass 1: Security — ITOFUTokenDecimals.sol

Agent: A03

## Evidence of Thorough Reading

**File**: `src/interface/ITOFUTokenDecimals.sol` (93 lines)

- **SPDX License**: `LicenseRef-DCL-1.0` (line 1)
- **Copyright**: Rain Open Source Software Ltd (line 2)
- **Pragma**: `^0.8.25` (line 3)

### Struct: `TOFUTokenDecimalsResult` (lines 13–16)

Defined at file scope (not inside the interface). Fields:
- `initialized`: `bool` (line 14) — guards against misinterpreting uninitialized storage `0` as a valid decimal value `0`
- `tokenDecimals`: `uint8` (line 15) — the stored decimal count

### Enum: `TOFUOutcome` (lines 19–28)

- `Initial` = 0 (line 21) — first read, no stored value yet
- `Consistent` = 1 (line 23) — current read matches stored value
- `Inconsistent` = 2 (line 25) — current read differs from stored value
- `ReadFailure` = 3 (line 27) — `decimals()` call failed or returned a value outside `uint8` range

### Error: `TokenDecimalsReadFailure` (line 33)

- `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`
- Thrown by `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` on `Inconsistent` or `ReadFailure` outcomes.

### Interface: `ITOFUTokenDecimals` (lines 53–92)

Functions:

| Function | Mutability | Line |
|---|---|---|
| `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` | `view` | 67 |
| `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` | non-payable | 77 |
| `safeDecimalsForToken(address token) external returns (uint8)` | non-payable | 83 |
| `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` | `view` | 91 |

### Cross-reference with implementation

The implementation in `src/lib/LibTOFUTokenDecimalsImplementation.sol` uses inline assembly to call `decimals()` (selector `0x313ce567`) via `staticcall`, validates that `returndatasize() >= 0x20` and that the returned value fits in `uint8`. On `Initial`, the value is stored in `src/concrete/TOFUTokenDecimals.sol`'s `sTOFUTokenDecimals` mapping. The concrete contract delegates all four interface functions directly to the library.

## Findings

### A03-1: `safeDecimalsForTokenReadOnly` provides no TOFU protection before initialization — naming creates a false sense of safety [INFO]

**Status of prior finding**: This finding was previously raised as P1-A05-8 in the 2026-02-21-03 audit and dismissed as "Already documented with explicit WARNING in NatSpec." The dismissal is appropriate given the NatSpec at `LibTOFUTokenDecimalsImplementation.sol:152-156`. This is recorded here for completeness, not as a new finding.

No new issue.

### A03-2: Interface pragma `^0.8.25` is range-allowing; concrete contract uses exact `=0.8.25` [INFO]

The interface declares `pragma solidity ^0.8.25` (line 3), which permits compilation with any `0.8.x` compiler where `x >= 25`. The concrete contract `TOFUTokenDecimals.sol` uses `pragma solidity =0.8.25` to lock bytecode determinism for the Zoltu singleton deployment. Any caller or downstream contract that imports this interface and compiles with a future `0.8.x` compiler version is permitted by the pragma. This is correct design: the interface's range pragma allows callers freedom, while the implementation locks its version for deployment reproducibility. There is no security issue here — the interface types and ABI are stable across `0.8.x`.

No issue.

### A03-3: No address-zero guard in the interface — callers may silently query the zero address [LOW]

**Affected functions**: All four interface functions accept `address token` with no documented or enforced restriction on the zero address (`address(0)`).

**Behaviour at `address(0)`**: A `staticcall` to `address(0)` is the precompile identity call in EVM. Because the `decimals()` selector (`0x313ce567`) does not map to any precompile, the call to `address(0)` will succeed with empty returndata. The assembly guard `if lt(returndatasize(), 0x20) { success := 0 }` will catch this — empty returndata has size 0, which is less than 0x20 — and the outcome will be `ReadFailure`. As a consequence:

- `decimalsForToken(address(0))` returns `(ReadFailure, 0)` and does not store anything (since `Initial` is the only outcome that triggers storage).
- `safeDecimalsForToken(address(0))` reverts with `TokenDecimalsReadFailure(address(0), ReadFailure)`.
- `decimalsForTokenReadOnly(address(0))` returns `(ReadFailure, 0)`.
- `safeDecimalsForTokenReadOnly(address(0))` reverts with `TokenDecimalsReadFailure(address(0), ReadFailure)`.

The zero address is thus handled safely by the existing `returndatasize` guard, not by explicit rejection. However, the interface NatSpec does not document this behaviour, which could lead a caller to misinterpret the `ReadFailure` outcome for `address(0)` as a transient network issue rather than a programming error. There is no storage corruption or fund loss risk because the result is never stored, but a caller that silently swallows `ReadFailure` (rather than reverting) could operate on a zero decimal value.

This is consistent across all prior audits: no prior audit raised or dismissed this specific concern.

**Recommendation**: Document in the `@param token` NatSpec on each function that `address(0)` will produce a `ReadFailure` outcome (or alternatively, add a note that callers are responsible for providing a valid ERC20 token address). A code-level `require(token != address(0))` in the concrete contract would give earlier and more descriptive failure, but would change deployed bytecode and is not feasible for the singleton. NatSpec clarification is feasible without bytecode impact.

### A03-4: Enum `TOFUOutcome` ordering means numeric default zero is `Initial`, not a failure state [INFO]

As noted in prior audits (A03-1 in the 2026-02-21-03 session), the zero-value of `TOFUOutcome` is `Initial`. This is intentional and correct: a default-zero enum would represent "not yet read" rather than a failure, which is the safest default. The prior finding confirmed no remediation is needed; this is re-confirmed here.

No issue.

### A03-5: No events defined — inconsistency detection is not observable on-chain without trace inspection [INFO]

The interface exposes no events. Callers detecting `Inconsistent` or `ReadFailure` outcomes have no standardized on-chain signal to emit. Off-chain monitoring for decimal drift attacks or token manipulation requires parsing call traces rather than event logs. This is a design choice (reducing gas cost for the singleton) and was noted as an informational finding in the 2026-02-21-03 audit (A03-6). The dismissal is appropriate.

No security issue; recorded for completeness.

### A03-6: `decimalsForToken` is callable by anyone — no access control [INFO]

The singleton is permissionless by design. Any caller can initialize the stored decimals for any token by calling `decimalsForToken`. This is the correct design for a trust-on-first-use scheme: the first caller wins and establishes the canonical decimals, and all subsequent callers benefit from consistency detection. There is no access control concern because the stored value is always validated against what the token contract itself reports — an adversary cannot set an arbitrary decimal value, only the one currently returned by the token.

No issue.

## Summary

No CRITICAL, HIGH, or MEDIUM findings.

One LOW finding (A03-3): the zero-address input case is handled safely by the assembly guard but is undocumented in the interface NatSpec, creating a risk that callers misinterpret `ReadFailure` for `address(0)` as a transient error. Recommended fix is NatSpec-only (no bytecode change required).

All other observations are informational and consistent with or re-confirming prior audit findings.
