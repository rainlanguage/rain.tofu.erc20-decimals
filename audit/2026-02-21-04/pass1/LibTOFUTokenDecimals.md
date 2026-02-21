<!-- SPDX-License-Identifier: LicenseRef-DCL-1.0 -->
<!-- SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd -->

# Pass 1 (Security) — `src/lib/LibTOFUTokenDecimals.sol`

Auditor: A04
Date: 2026-02-21

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Every Function/Method and Its Line Number

| Function | Visibility | Mutability | Line |
|---|---|---|---|
| `ensureDeployed()` | `internal` | `view` | 50 |
| `decimalsForTokenReadOnly(address token)` | `internal` | `view` | 65 |
| `decimalsForToken(address token)` | `internal` | (non-view) | 78 |
| `safeDecimalsForToken(address token)` | `internal` | (non-view) | 88 |
| `safeDecimalsForTokenReadOnly(address token)` | `internal` | `view` | 96 |

### Every Type, Error, and Constant Defined

**Errors:**

| Name | Line | Description |
|---|---|---|
| `TOFUTokenDecimalsNotDeployed(address deployedAddress)` | 24 | Thrown when the singleton is absent or has unexpected codehash |

**Constants:**

| Name | Type | Line | Value |
|---|---|---|---|
| `TOFU_DECIMALS_DEPLOYMENT` | `ITOFUTokenDecimals` | 29–30 | `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `bytes32` | 36–37 | `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41` |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `bytes` | 44–45 | Long hex blob (init bytecode) |

**Imported Types (from `ITOFUTokenDecimals.sol`):**

- `TOFUOutcome` — enum with values `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`
- `ITOFUTokenDecimals` — interface (used as the type for `TOFU_DECIMALS_DEPLOYMENT`)
- (indirectly in scope) `TOFUTokenDecimalsResult` struct, `TokenDecimalsReadFailure` error

---

## Security Review

### Finding 1 — `ensureDeployed` codehash check uses `!=` which passes for zero codehash on self-destructed or pre-deployment address

**Classification: INFO**

The `ensureDeployed` function at line 51–56 guards with two conditions joined by `||`:

```solidity
if (
    address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0
        || address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH
) {
    revert TOFUTokenDecimalsNotDeployed(address(TOFU_DECIMALS_DEPLOYMENT));
}
```

This is correct and thorough. The `code.length == 0` check catches the EOA/not-deployed case (where `codehash` would be `bytes32(0)` or the empty-hash `0xc5d2...`). The `codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` check then validates exact bytecode identity. Even if `code.length == 0` evaluates to false (meaning code exists), the codehash must still match. There is no bypass: both conditions must be false simultaneously for execution to continue. This is the correct defense-in-depth pattern.

No vulnerability; recorded as INFO for completeness.

---

### Finding 2 — `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant is never verified on-chain

**Classification: INFO**

The constant `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (line 44–45) stores the expected init bytecode but `ensureDeployed` does not compare it against anything at runtime. The on-chain guard uses only the deployed code hash (`TOFU_DECIMALS_EXPECTED_CODE_HASH`). The creation code constant exists solely for off-chain tooling and test-time verification (e.g., the `testExpectedCreationCode` test noted in `CLAUDE.md`), which is the appropriate place for it.

This is an intentional design choice: verifying creation code on-chain would be impossible after deployment (it is not stored). The runtime guard is the codehash of the deployed runtime bytecode, which is correct.

No vulnerability; recorded as INFO.

---

### Finding 3 — No access control on state-mutating delegation (`decimalsForToken`, `safeDecimalsForToken`)

**Classification: INFO**

`LibTOFUTokenDecimals.decimalsForToken` (line 78) and `safeDecimalsForToken` (line 88) are `internal` functions that forward to the singleton `TOFUTokenDecimals` contract, which is a publicly callable shared singleton. There is no access control restricting who can call `decimalsForToken` to initialize or write a token's stored decimals.

This is intentional by design: the singleton is a global shared service. Any caller can initialize the stored decimals for any token address. The TOFU guarantee is that the *first* write wins, and subsequent callers can only get consistent/inconsistent signals — they cannot overwrite a stored value. The concrete contract (`TOFUTokenDecimals`) does not expose a setter beyond the TOFU logic, which is write-once-per-token. The design accepts the risk that any party can "claim" the first read for any token, but this maps to the real-world semantics of TOFU: whoever calls first establishes the baseline.

No vulnerability; recorded as INFO.

---

### Finding 4 — Reentrancy: external call to singleton before any state mutation in the library

**Classification: INFO**

The library delegates to `TOFU_DECIMALS_DEPLOYMENT` (an external contract) via high-level interface calls. The singleton itself internally performs a `staticcall` to the token's `decimals()` selector and, for the write path, stores the result. The `staticcall` prevents reentrancy into the singleton's own storage during the read. After the `staticcall` completes, storage is written once and control is returned.

From the caller's perspective, the library functions are `internal` and thus execute within the caller's own call frame. The external call is to the singleton (a known, immutable, codehash-verified contract), not to an arbitrary user-supplied address. No reentrancy risk exists within the library itself.

No vulnerability; recorded as INFO.

---

### Finding 5 — Lack of zero-address validation for `token` parameter

**Classification: LOW**

None of the four public-facing library functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) validate that `token != address(0)`. Passing `address(0)` results in a `staticcall` to the zero address, which has no code. The `staticcall` will "succeed" (EVM returns success for calls to addresses with no code) but return zero bytes, causing `returndatasize() < 0x20` to be true. This causes the assembly block to set `success = 0`, returning `TOFUOutcome.ReadFailure`.

For the `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` paths, `ReadFailure` is not in the allowed set, so these will revert with `TokenDecimalsReadFailure(address(0), ReadFailure)`. The error message is informative enough that a developer can diagnose the issue.

For `decimalsForToken` and `decimalsForTokenReadOnly`, a `ReadFailure` outcome for `address(0)` is returned to the caller, which must handle it. Since `address(0)` is not a real token, the caller should never pass it; however, defensive validation at the library boundary would surface the issue earlier and more clearly. The impact is limited to wasted gas and confusing error signals rather than loss of funds or state corruption, since no storage is written for a `ReadFailure` outcome.

**Recommendation:** Add `require(token != address(0))` or an equivalent explicit revert at the entry point of each function in `LibTOFUTokenDecimals`, or document that callers are responsible for ensuring a non-zero address.

---

### Finding 6 — Silent forwarding of all return values from external singleton calls

**Classification: INFO**

The `// slither-disable-next-line unused-return` comments at lines 68 and 81 suppress Slither warnings about the return values of the external calls. However, the functions do explicitly `return` the result of the external calls (e.g., `return TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token)`), so the Slither annotation is a false-positive suppression — the return value is not actually discarded. The actual return is propagated correctly. No issue here; the annotations are a documentation artifact of Slither's heuristic.

No vulnerability; recorded as INFO.

---

### Finding 7 — Pragma range `^0.8.25` vs. singleton deployed with exact `=0.8.25`

**Classification: INFO**

`LibTOFUTokenDecimals.sol` uses the floating pragma `^0.8.25` (line 3). The concrete singleton `TOFUTokenDecimals.sol` uses `=0.8.25` for bytecode determinism. The library is never deployed independently (it is inlined by the compiler into whichever caller imports it), so its pragma range does not affect the singleton's deterministic bytecode. Callers compiling with `^0.8.25` may use any `0.8.x >= 0.8.25` compiler for their own contracts, which is standard practice for library files. This is not a security issue.

No vulnerability; recorded as INFO.

---

## Summary

| ID | Title | Classification |
|---|---|---|
| F1 | `ensureDeployed` dual-condition check is correct | INFO |
| F2 | `TOFU_DECIMALS_EXPECTED_CREATION_CODE` not verified on-chain (intentional) | INFO |
| F3 | No access control on state-mutating calls (intentional by design) | INFO |
| F4 | No reentrancy risk via external singleton delegation | INFO |
| F5 | No zero-address validation for `token` parameter | LOW |
| F6 | Slither unused-return suppression is a false-positive annotation | INFO |
| F7 | Floating pragma vs. fixed-pragma singleton (no impact) | INFO |

Only one finding above INFO level: **F5 (LOW)** — missing zero-address guard on the `token` parameter. All other observations are informational confirmations of correct design.
