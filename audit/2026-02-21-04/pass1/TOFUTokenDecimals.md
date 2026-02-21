<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 1 Security Audit: TOFUTokenDecimals.sol

**File:** `src/concrete/TOFUTokenDecimals.sol`
**Auditor:** A02
**Date:** 2026-02-21
**Pass:** 1 (Security)

---

## Evidence of Thorough Reading

### File Examined

`src/concrete/TOFUTokenDecimals.sol` (39 lines), plus supporting files read for full context:
- `src/interface/ITOFUTokenDecimals.sol`
- `src/lib/LibTOFUTokenDecimalsImplementation.sol`

### Contract / Library Name

- `TOFUTokenDecimals` (contract, line 13) — implements `ITOFUTokenDecimals`

### Every Function / Method Name and Line Number

| Line | Function | Visibility | Mutability |
|------|----------|------------|------------|
| 19 | `decimalsForTokenReadOnly(address token)` | `external` | `view` |
| 25 | `decimalsForToken(address token)` | `external` | (non-payable) |
| 31 | `safeDecimalsForToken(address token)` | `external` | (non-payable) |
| 36 | `safeDecimalsForTokenReadOnly(address token)` | `external` | `view` |

(No constructor is defined; Solidity generates a default one.)

### Every Type, Error, and Constant Defined

**Defined in `TOFUTokenDecimals.sol` itself:**

| Kind | Name | Location |
|------|------|----------|
| State variable (mapping) | `sTOFUTokenDecimals` | line 16 — `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal` |

**Imported and used (from `ITOFUTokenDecimals.sol`):**

| Kind | Name |
|------|------|
| Struct | `TOFUTokenDecimalsResult` (`bool initialized`, `uint8 tokenDecimals`) |
| Enum | `TOFUOutcome` (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`) |
| Error | `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` |

**Imported and used (from `LibTOFUTokenDecimalsImplementation.sol`):**

| Kind | Name |
|------|------|
| Library | `LibTOFUTokenDecimalsImplementation` |
| Constant | `TOFU_DECIMALS_SELECTOR` (`bytes4 0x313ce567`) |

---

## Security Analysis

### 1. Access Control

The contract exposes four `external` functions with no access restrictions. This is intentional: the contract is a public singleton registry. Any caller can query or initialize the TOFU entry for any token address. There is no admin, owner, or privileged role. This design is correct for the stated use case (public good singleton).

**Finding:** INFO — No access control. Intentional by design; no privileged operations exist that would require it.

---

### 2. Input Validation — Zero Address (`address(0)`)

Neither `TOFUTokenDecimals.sol` nor `LibTOFUTokenDecimalsImplementation` validates that `token != address(0)`. A caller can pass `address(0)`.

The assembly block in `decimalsForTokenReadOnly` performs:

```solidity
success := staticcall(gas(), token, 0, 0x04, 0, 0x20)
```

A `staticcall` to `address(0)` is a call to the EVM identity precompile. The identity precompile does not implement `decimals()` and will return the calldata (4 bytes) as its output. The output length will be 4 bytes, which is less than `0x20` (32 bytes), so the `lt(returndatasize(), 0x20)` guard will trigger and set `success := 0`. This results in `TOFUOutcome.ReadFailure` being returned.

Separately, mapping key `address(0)` can be written to `sTOFUTokenDecimals` just like any other address, allowing a TOFU entry to be set for the zero address. Because the read from `address(0)` always results in `ReadFailure` (the precompile returns only 4 bytes), the mapping slot for `address(0)` can never be initialized via `decimalsForToken`. Callers querying `address(0)` will always receive `ReadFailure`.

**Finding:** LOW — No zero-address guard. Practically harmless (zero-address calls reliably produce `ReadFailure`), but callers could be confused by the behavior. A revert on `token == address(0)` would make the API cleaner. Because this is a public utility singleton, the absence of a guard causes no loss of funds or state corruption.

---

### 3. Reentrancy

`decimalsForToken` and `safeDecimalsForToken` write to storage (`sTOFUTokenDecimals[token]`). The call sequence in `decimalsForToken` (via `decimalsForTokenReadOnly`) is:

1. Read storage (`sTOFUTokenDecimals[token]`).
2. `staticcall` to `token.decimals()`.
3. Write storage (`sTOFUTokenDecimals[token] = ...`) only if `Initial`.

`staticcall` cannot modify state, so the external call cannot re-enter with a state-changing call to `TOFUTokenDecimals`. An attacker-controlled token implementing `decimals()` cannot call back into `decimalsForToken` or `safeDecimalsForToken` during the `staticcall` because `staticcall` forbids state-changing operations in the called context.

There is no `call` or `delegatecall` to external contracts; only `staticcall` is used for the external interaction. Storage is written only after the `staticcall` returns.

**Finding:** INFO — No reentrancy risk. `staticcall` prevents re-entry with state modification.

---

### 4. Memory Safety in Assembly

The assembly block in `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` (the only assembly in the call chain) is annotated `("memory-safe")`. It operates exclusively in the Solidity scratch space (`0x00`–`0x3f`):

- `mstore(0, selector)` — writes 4 bytes of selector into slot 0 (scratch space).
- `staticcall(gas(), token, 0, 0x04, 0, 0x20)` — reads 4 bytes from 0 as calldata; writes return data (up to 32 bytes) starting at 0.
- `mload(0)` — reads 32 bytes from slot 0.

Solidity's scratch space (`0x00`–`0x3f`, i.e., two 32-byte words) is documented as safe for transient use in assembly. The free memory pointer at `0x40` is not touched. The `memory-safe` annotation is accurate.

The `lt(returndatasize(), 0x20)` check ensures that a token returning fewer than 32 bytes is treated as a failure, preventing incomplete data from being read from memory that may contain stale content from the `mstore(0, selector)` call.

The `gt(readDecimals, 0xff)` check ensures the returned value fits in `uint8`, preventing silent truncation when storing into `tokenDecimals`.

**Finding:** INFO — Memory usage is correct and safe within scratch space. Guards against short return data and out-of-range values are present.

---

### 5. Arithmetic Safety

No arithmetic operations are performed anywhere in `TOFUTokenDecimals.sol`. The library uses only comparisons (`lt`, `gt`, `==`) and an explicit range check (`gt(readDecimals, 0xff)`). The cast `uint8(readDecimals)` is guarded by the prior `gt(readDecimals, 0xff)` check.

**Finding:** INFO — No arithmetic; no overflow/underflow risk.

---

### 6. Delegatecall / Upgrade Patterns

The contract is not upgradeable. It has no `delegatecall`, no proxy pattern, and no `selfdestruct`. The storage mapping is `internal`. The CLAUDE.md confirms deterministic bytecode requirements; changing any compiler setting breaks the deployed address. This means the contract is immutable after deployment.

**Finding:** INFO — Non-upgradeable singleton. Immutability is intentional and consistent with design.

---

### 7. Denial of Service via Gas

The `staticcall` passes `gas()` (all remaining gas) to the token's `decimals()`. A maliciously crafted token could consume all gas in its `decimals()` implementation. However:

- This is a public utility contract and callers set their own gas limits.
- The call pattern (passing all gas) is standard for ERC20 `decimals()` queries.
- A gas-exhausting token would simply cause the outer transaction to run out of gas, which is a property of the caller's transaction, not a state-corrupting attack on the singleton.

**Finding:** LOW — No gas limit on `staticcall`. A malicious token can cause the calling transaction to run out of gas. This is an inherent property of the design (reading arbitrary ERC20 tokens) and cannot be mitigated without capping gas, which risks false `ReadFailure` for expensive tokens. Documented behavior; acceptable risk.

---

### 8. TOFU Initialization Race Condition

If two transactions simultaneously call `decimalsForToken` for the same token for the first time (both seeing `!initialized`), both will perform the `staticcall` and both will attempt to write the same value. Because the storage write is idempotent (both write the same `uint8` from the same token's `decimals()` return), the race is benign provided the token's `decimals()` returns a stable value.

If the token's `decimals()` value changes between the two concurrent calls (extremely unlikely in practice, as decimals are typically immutable), both writes would store different values, with the later transaction's value winning. The first writer's stored value would be silently overwritten. The losing writer's stored value would be discarded, with no indication. However:

- For this to cause divergence, `decimals()` must return different values in the same block, which would require an extraordinarily adversarial token.
- The TOFU model is explicitly designed around the assumption that decimals are stable after first read, so this scenario is outside the threat model.

**Finding:** INFO — Initialization race is benign under the stated threat model (stable `decimals()` return).

---

### 9. `safeDecimalsForTokenReadOnly` — TOFU Guarantee Absence Before Initialization

The `safeDecimalsForTokenReadOnly` function and its underlying `decimalsForTokenReadOnly` do not persist state. Before any call to `decimalsForToken`, every call to `safeDecimalsForTokenReadOnly` is effectively a fresh read with no stored value to check against. Two successive calls to `safeDecimalsForTokenReadOnly` for an uninitialized token, where the token changes its `decimals()` between calls, will return different values with no detection of inconsistency.

This behavior is explicitly documented in the NatDoc of `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly`:

> "WARNING: Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected."

**Finding:** INFO — Documented limitation; no security defect. Callers relying on TOFU guarantees must use `decimalsForToken` at least once before relying on `safeDecimalsForTokenReadOnly`.

---

### 10. `ReadFailure` Outcome in `decimalsForTokenReadOnly` Returns Stored (Possibly Uninitialized) Value

On `ReadFailure`, `decimalsForTokenReadOnly` returns `tofuTokenDecimals.tokenDecimals`, which is the stored value or `0` if uninitialized. The interface NatDoc documents this:

> "On `ReadFailure`, the stored value (zero if uninitialized)."

If a caller fails to check the returned `TOFUOutcome` and blindly uses the returned `uint8` decimals on `ReadFailure`, it may silently use `0` as the decimals value for an uninitialized token. The `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` wrappers do revert on `ReadFailure`, providing safe alternatives.

**Finding:** LOW — `ReadFailure` returns zero for uninitialized tokens. Callers using the raw `decimalsForToken` / `decimalsForTokenReadOnly` functions without checking the outcome enum may silently treat uninitialized tokens as having 0 decimals. The safe wrappers mitigate this; the issue is a caller-responsibility concern documented in the interface, not a defect in `TOFUTokenDecimals.sol` itself.

---

## Summary Table

| # | Title | Classification |
|---|-------|---------------|
| 1 | No access control (intentional) | INFO |
| 2 | No zero-address guard on `token` | LOW |
| 3 | No reentrancy risk (`staticcall` only) | INFO |
| 4 | Memory usage correct in assembly scratch space | INFO |
| 5 | No arithmetic; no overflow risk | INFO |
| 6 | Non-upgradeable singleton (intentional) | INFO |
| 7 | No gas cap on `staticcall` to token | LOW |
| 8 | TOFU initialization race is benign | INFO |
| 9 | `safeDecimalsForTokenReadOnly` provides no TOFU before initialization (documented) | INFO |
| 10 | `ReadFailure` returns zero for uninitialized token; caller must check outcome | LOW |

**No CRITICAL or HIGH findings.**
