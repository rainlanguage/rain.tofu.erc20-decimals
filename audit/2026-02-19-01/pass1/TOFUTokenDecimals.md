# Audit Pass 1 (Security) -- TOFUTokenDecimals.sol

**Auditor:** A03
**Date:** 2026-02-19
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/concrete/TOFUTokenDecimals.sol`
**Commit:** `dd9cd1f` (branch `2026-02-19-safe-read`)

---

## 1. Evidence of Thorough Reading

### Contract

- **Contract name:** `TOFUTokenDecimals` (line 14)
- **Inherits:** `ITOFUTokenDecimals` (line 14)
- **Pragma:** `=0.8.25` (exact, line 3)
- **SPDX License:** `LicenseRef-DCL-1.0` (line 1)

### State Variables

| Name | Type | Visibility | Line |
|------|------|------------|------|
| `sTOFUTokenDecimals` | `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)` | `internal` | 16 |

### Functions

| Function | Visibility | Mutability | Line |
|----------|-----------|------------|------|
| `decimalsForTokenReadOnly(address)` | `external` | `view` | 19 |
| `decimalsForToken(address)` | `external` | (state-changing) | 25 |
| `safeDecimalsForToken(address)` | `external` | (state-changing) | 31 |
| `safeDecimalsForTokenReadOnly(address)` | `external` | `view` | 36 |

### Errors / Events / Structs Defined in This File

None defined directly in this file. All types are imported:
- `ITOFUTokenDecimals` and `TOFUTokenDecimalsResult` from `../interface/ITOFUTokenDecimals.sol`
- `TOFUOutcome` and `LibTOFUTokenDecimals` from `../lib/LibTOFUTokenDecimals.sol` (note: `LibTOFUTokenDecimals` is imported but not used in this file)
- `LibTOFUTokenDecimalsImplementation` from `../lib/LibTOFUTokenDecimalsImplementation.sol`

### Imports

| Import | Source | Line |
|--------|--------|------|
| `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult` | `../interface/ITOFUTokenDecimals.sol` | 5 |
| `TOFUOutcome`, `LibTOFUTokenDecimals` | `../lib/LibTOFUTokenDecimals.sol` | 6 |
| `LibTOFUTokenDecimalsImplementation` | `../lib/LibTOFUTokenDecimalsImplementation.sol` | 7 |

---

## 2. Security Findings

### A03-1: Unused Import of `LibTOFUTokenDecimals` [INFO]

**Location:** Line 6

**Description:** The contract imports `LibTOFUTokenDecimals` from `../lib/LibTOFUTokenDecimals.sol` but never uses it. Only `TOFUOutcome` from that import path is used. `TOFUOutcome` is actually defined in `ITOFUTokenDecimals.sol` and re-exported through `LibTOFUTokenDecimals.sol`, so it could alternatively be imported directly from the interface.

**Impact:** No security impact. Minor code hygiene issue. The unused import does not affect bytecode because the library is never linked or called. However, since bytecode determinism is critical for this contract, any future change that accidentally uses this library could alter the deployed bytecode.

**Recommendation:** Consider importing `TOFUOutcome` directly from `../interface/ITOFUTokenDecimals.sol` instead and removing the `LibTOFUTokenDecimals` import. Verify this does not change the compiled bytecode before applying.

---

### A03-2: No Reentrancy Risk Identified [INFO]

**Location:** Entire contract

**Description:** The contract makes external `staticcall`s to token contracts to read `decimals()` (via the library). The `staticcall` opcode prevents state modifications in the callee, eliminating reentrancy through the `decimals()` call path. The state-mutating functions (`decimalsForToken`, `safeDecimalsForToken`) only write to storage *after* the external read completes, and the write is a simple struct assignment to the mapping. There is no reentrancy vector because:
1. `staticcall` is used for the external call.
2. Storage writes occur after the external call returns, and the only write is setting `initialized = true` with the read value. Even if reentrancy were possible, a second entry would see `initialized = true` and follow the `Consistent`/`Inconsistent` path, not the `Initial` path, so no double-init or state corruption would occur.

**Impact:** None.

---

### A03-3: No Access Control -- By Design [INFO]

**Location:** Lines 19, 25, 31, 36

**Description:** All four functions are `external` with no access control modifiers (no `onlyOwner`, no role checks). Any address can call `decimalsForToken` to initialize the stored decimals for any token. This is intentional: the contract is a public singleton and the TOFU model means the first caller to read a token's decimals sets the stored value for all subsequent callers. The trust assumption is that the token contract returns a correct `decimals()` value at the time of first read.

**Impact:** None, given the design. A malicious actor cannot influence the stored value because it is read directly from the token contract via `staticcall`. The only scenario where a "wrong" value is stored is if the token contract itself returns an incorrect `decimals()` at the time of first use, which is outside the scope of this contract's threat model.

---

### A03-4: Storage Layout is Simple and Safe [INFO]

**Location:** Line 16

**Description:** The contract has exactly one state variable: a `mapping(address => TOFUTokenDecimalsResult)`. `TOFUTokenDecimalsResult` is a struct with `bool initialized` and `uint8 tokenDecimals`, which pack into a single storage slot. The mapping is `internal` and not exposed directly. There are no other state variables, no inheritance chain with state (the interface `ITOFUTokenDecimals` has no state), and no gaps or complex layout.

**Impact:** No storage collision or layout concerns.

---

### A03-5: No Proxy/Upgrade Pattern -- Immutable Contract [INFO]

**Location:** Entire contract

**Description:** The contract has no proxy pattern, no `delegatecall`, no upgrade mechanism, no `selfdestruct`, no `receive`/`fallback` function, and is not `payable`. It is deployed via the Zoltu deterministic factory and intended to be immutable. This is a strength: the code at the deterministic address cannot be changed.

**Impact:** None. This is a positive security property.

---

### A03-6: No String Reverts Found [INFO]

**Location:** Entire contract and its library dependency

**Description:** Searched all source files under `src/` for `revert("...")` and `require(...)` patterns. None found. All reverts use custom errors (`TokenDecimalsReadFailure`, `TOFUTokenDecimalsNotDeployed`), which is consistent with the project's coding standards and produces more gas-efficient revert data.

**Impact:** None. Compliant with project rules.

---

### A03-7: Bytecode Determinism Constraints Are Correctly Maintained [INFO]

**Location:** Line 3 (`pragma solidity =0.8.25;`), `foundry.toml`

**Description:** The concrete contract uses `pragma solidity =0.8.25;` (exact version, not a range), which is correct. The `foundry.toml` confirms:
- `solc = "0.8.25"` (line 8)
- `optimizer = true` with `optimizer_runs = 1000000` (lines 18-19)
- `bytecode_hash = "none"` (line 21)
- `cbor_metadata = false` (line 22)

These settings match the bytecode determinism requirements documented in `CLAUDE.md`. The library and interface files use `^0.8.25` (range), which is acceptable since they are not the deployed artifact -- only the concrete contract needs the exact pragma.

The expected creation code is hardcoded in `LibTOFUTokenDecimals.sol` (line 42-43) and the expected runtime codehash is at line 35-36, providing a compile-time verification mechanism.

**Impact:** None. Constraints are correctly enforced.

---

### A03-8: Library Delegation is Correct [INFO]

**Location:** Lines 19-38

**Description:** All four functions correctly delegate to `LibTOFUTokenDecimalsImplementation` by passing the storage mapping `sTOFUTokenDecimals` as the first argument and `token` as the second. The return types match the interface definitions. The `view` modifier is correctly applied to the read-only variants. The non-view variants correctly omit `view` to allow storage writes within the library.

Verified delegation chain:
- `decimalsForTokenReadOnly` -> `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` (view, returns `(TOFUOutcome, uint8)`)
- `decimalsForToken` -> `LibTOFUTokenDecimalsImplementation.decimalsForToken` (mutating, returns `(TOFUOutcome, uint8)`)
- `safeDecimalsForToken` -> `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken` (mutating, returns `uint8`)
- `safeDecimalsForTokenReadOnly` -> `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly` (view, returns `uint8`)

**Impact:** None. Delegation is correct and complete.

---

### A03-9: No Constructor -- Default Behavior is Safe [INFO]

**Location:** Entire contract

**Description:** The contract has no constructor. The default constructor does nothing. Since the only state is a mapping (which defaults to zero-initialized entries), there is no initialization step required. The `initialized` boolean in `TOFUTokenDecimalsResult` correctly distinguishes between "never read" (`initialized = false, tokenDecimals = 0`) and "read and stored as 0 decimals" (`initialized = true, tokenDecimals = 0`).

**Impact:** None. The lack of a constructor is intentional and safe.

---

### A03-10: ETH Sent to Contract is Rejected [INFO]

**Location:** Entire contract

**Description:** The contract has no `receive()` function, no `fallback()` function, and no `payable` functions. Any ETH sent to the contract (via direct transfer or as `msg.value` in a call) will be rejected by the EVM, which is the correct behavior for a singleton utility contract.

**Impact:** None. Positive security property preventing accidental ETH lock-up.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A03-1 | INFO | Unused import of `LibTOFUTokenDecimals` |
| A03-2 | INFO | No reentrancy risk identified |
| A03-3 | INFO | No access control -- by design |
| A03-4 | INFO | Storage layout is simple and safe |
| A03-5 | INFO | No proxy/upgrade pattern -- immutable contract |
| A03-6 | INFO | No string reverts found |
| A03-7 | INFO | Bytecode determinism constraints correctly maintained |
| A03-8 | INFO | Library delegation is correct |
| A03-9 | INFO | No constructor -- default behavior is safe |
| A03-10 | INFO | ETH sent to contract is rejected |

**No CRITICAL, HIGH, MEDIUM, or LOW findings identified.**

The `TOFUTokenDecimals.sol` concrete contract is a minimal, well-structured wrapper that correctly delegates all logic to `LibTOFUTokenDecimalsImplementation`. The contract's attack surface is very small: it has no access control (by design, as a public singleton), no ETH handling, no proxy/upgrade mechanism, no complex inheritance, and a single storage mapping. The bytecode determinism constraints required for Zoltu deployment are correctly enforced.
