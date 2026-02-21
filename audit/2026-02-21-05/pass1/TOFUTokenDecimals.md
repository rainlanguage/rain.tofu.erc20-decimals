# Audit: `src/concrete/TOFUTokenDecimals.sol`

**Auditor:** A02
**Pass:** 1 (Security)
**Date:** 2026-02-21

---

## Evidence of Thorough Reading

### Contract Name
- `TOFUTokenDecimals` (line 13), inherits `ITOFUTokenDecimals`

### Functions (all four, complete list)

| # | Function | Line | Visibility | Mutability |
|---|----------|------|------------|------------|
| 1 | `decimalsForTokenReadOnly(address token)` | 19 | `external` | `view` |
| 2 | `decimalsForToken(address token)` | 25 | `external` | (state-changing) |
| 3 | `safeDecimalsForToken(address token)` | 31 | `external` | (state-changing) |
| 4 | `safeDecimalsForTokenReadOnly(address token)` | 36 | `external` | `view` |

### State Variables
- `sTOFUTokenDecimals` (line 16): `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)`, visibility `internal`

### Imported Types/Errors/Constants
- `ITOFUTokenDecimals` (interface, from `../interface/ITOFUTokenDecimals.sol`)
- `TOFUTokenDecimalsResult` (struct: `bool initialized`, `uint8 tokenDecimals`)
- `TOFUOutcome` (enum: `Initial=0`, `Consistent=1`, `Inconsistent=2`, `ReadFailure=3`)
- `TokenDecimalsReadFailure(address, TOFUOutcome)` (custom error, on `ITOFUTokenDecimals`)
- `LibTOFUTokenDecimalsImplementation` (library, from `../lib/LibTOFUTokenDecimalsImplementation.sol`)

### Pragma
- `pragma solidity =0.8.25;` (exact version pin, line 3)

### License
- `SPDX-License-Identifier: LicenseRef-DCL-1.0` (line 1)

---

## Security Review

### A02-01: No Access Control on `decimalsForToken` -- Permissionless Initialization [INFO]

**Location:** Line 25

**Description:** `decimalsForToken` is `external` with no access control. Any address can call it for any token, permanently locking in the decimals value on first use. Once initialized, the stored value is immutable (only `Initial` outcome triggers a write in the library, line 119 of `LibTOFUTokenDecimalsImplementation.sol`).

**Analysis:** This is by design for a shared singleton. The TOFU model inherently trusts the first reader. An attacker who front-runs the very first `decimalsForToken` call for a token cannot choose an arbitrary value since the library reads the actual on-chain `decimals()` return. The value stored is always what the token contract itself returns at call time. Therefore, front-running the initialization only matters if the token's `decimals()` can change between calls -- which is exactly the threat TOFU is designed to mitigate.

**Risk:** INFO -- Acknowledged design pattern. No action needed.

---

### A02-02: No Constructor or Initializer -- Zero Initialization State is Safe [INFO]

**Location:** Contract-wide

**Description:** `TOFUTokenDecimals` has no constructor, no initializer, and no owner. The storage mapping `sTOFUTokenDecimals` starts with all entries having `initialized = false` and `tokenDecimals = 0`, which is the correct uninitialized state.

**Analysis:** The `initialized` boolean in `TOFUTokenDecimalsResult` correctly distinguishes between "never read" and "read and got 0 decimals." This prevents the default zero-storage from being misinterpreted as a valid stored value. The library checks `!tofuTokenDecimals.initialized` (line 67 of implementation) before returning `Initial`, so the first call always reads fresh from the token.

**Risk:** INFO -- Design is correct. No action needed.

---

### A02-03: Reentrancy Surface via External `staticcall` to Untrusted Token [LOW]

**Location:** Line 25 (concrete), delegating to `LibTOFUTokenDecimalsImplementation.decimalsForToken` line 117, which calls `decimalsForTokenReadOnly` line 47 (assembly `staticcall`).

**Description:** The library performs a `staticcall` to the untrusted `token` address to read `decimals()`. A malicious token could attempt reentrant behavior. However, `staticcall` prevents the callee from modifying state, and the library's `decimalsForToken` writes storage only **after** the `staticcall` completes and only on the `Initial` path.

**Analysis:**
- The `staticcall` prevents the token from writing state during the call.
- State is written only once per token (guarded by `tofuOutcome == TOFUOutcome.Initial`).
- Even if the token were called via `CALL` instead of `STATICCALL`, the write-once pattern means reentering `decimalsForToken` for the same token mid-execution would still read the same un-initialized storage and attempt the same write -- no double-write or corruption is possible since struct fields are set atomically in a single SSTORE.
- The use of `staticcall` in the `view` functions (`decimalsForTokenReadOnly`, `safeDecimalsForTokenReadOnly`) is correct and prevents any state modification.

**Risk:** LOW -- Mitigated by `staticcall` and write-once pattern. No action needed.

---

### A02-04: Assembly Memory Safety -- Scratch Space Usage [INFO]

**Location:** `LibTOFUTokenDecimalsImplementation.sol` lines 45-57 (called by the concrete contract)

**Description:** The assembly block writes the 4-byte selector to memory offset 0 (`mstore(0, selector)`) and reads the return data from offset 0 (`mload(0)`). Memory offsets 0x00-0x3F are Solidity's scratch space. The block is annotated `"memory-safe"`.

**Analysis:**
- Writing to scratch space (0x00-0x3F) is explicitly permitted by Solidity's memory-safety definition for inline assembly.
- The return data overwrites offset 0x00-0x1F which is also scratch space.
- The `tofuTokenDecimals` memory struct was loaded before the assembly block (line 34), so it resides at the free memory pointer location (0x80+) and is not affected by scratch space writes.
- The `"memory-safe"` annotation is correct.

**Risk:** INFO -- Assembly is correctly using scratch space. No action needed.

---

### A02-05: `returndatasize` Check Guards Against Short Returns [INFO]

**Location:** `LibTOFUTokenDecimalsImplementation.sol` line 48 (called by the concrete contract)

**Description:** The assembly checks `lt(returndatasize(), 0x20)` after the `staticcall`. If the token returns less than 32 bytes, success is set to 0, resulting in `ReadFailure`.

**Analysis:** This correctly handles:
- EOAs (no code, returndatasize = 0)
- Contracts that revert (staticcall returns 0)
- Contracts with a fallback that returns insufficient data
- Non-standard tokens returning less than 32 bytes

The `gt(readDecimals, 0xff)` check (line 53) then catches tokens that return a valid 32-byte value but with a number exceeding uint8 range, treating them as `ReadFailure`.

**Risk:** INFO -- Well-defended. No action needed.

---

### A02-06: Storage Mapping Visibility is `internal` -- No Direct External Read [LOW]

**Location:** Line 16

**Description:** The `sTOFUTokenDecimals` mapping is `internal`, meaning there is no getter to directly inspect stored values without going through the four external functions. All four functions perform a fresh `staticcall` to the token and compare against stored state.

**Analysis:** This means there is no way to read the stored decimals value for a token without also triggering a `staticcall` to that token's `decimals()` function. If the token contract is subsequently destroyed (via `SELFDESTRUCT` in pre-Cancun chains, or becomes unreachable), the only outcome would be `ReadFailure` -- the stored value is still returned alongside that outcome for the non-safe variants, and the safe variants revert. This is correct behavior, but callers should be aware that reading stored state always requires the token to be callable.

**Risk:** LOW -- This is an inherent design trade-off. Callers relying on the non-safe `decimalsForToken` / `decimalsForTokenReadOnly` can still extract the stored value from the returned tuple even on `ReadFailure`. No action needed.

---

### A02-07: Bytecode Determinism Configuration [INFO]

**Location:** `foundry.toml` and `pragma solidity =0.8.25` (line 3 of concrete contract)

**Description:** The concrete contract uses exact pragma `=0.8.25`. The `foundry.toml` sets `solc = "0.8.25"`, `bytecode_hash = "none"`, `cbor_metadata = false`, `evm_version = "cancun"`, `optimizer = true`, `optimizer_runs = 1000000`. The `LibTOFUTokenDecimals.sol` hard-codes the expected creation code, deployed address (`0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`), and code hash (`0x1de7d717...`).

**Analysis:** The bytecode determinism chain is intact:
1. Exact solc version pinned in both `foundry.toml` and the pragma.
2. Metadata stripping (`bytecode_hash = "none"`, `cbor_metadata = false`) eliminates non-deterministic metadata.
3. Fixed optimizer settings ensure reproducible compilation.
4. The library verifies the deployed code hash before every interaction (`ensureDeployed()`).

Any modification to the contract, compiler version, or build settings would change the bytecode and break the deployment address, which would be caught by the code hash check.

**Risk:** INFO -- Configuration is correct and well-defended. No action needed.

---

### A02-08: No `receive()` or `fallback()` -- ETH Cannot Be Trapped [INFO]

**Location:** Contract-wide

**Description:** The contract defines no `receive()` or `fallback()` function. Any ETH sent to the contract address via a plain transfer or send will revert. The four defined functions are all non-payable (no `payable` modifier).

**Analysis:** This is correct. The contract has no reason to hold ETH, and the absence of these functions prevents accidental ETH lockup.

**Risk:** INFO -- Correct behavior. No action needed.

---

### A02-09: No Events Emitted on State Changes [LOW]

**Location:** Lines 25-28 (concrete), `LibTOFUTokenDecimalsImplementation.decimalsForToken` lines 119-121

**Description:** When `decimalsForToken` initializes storage for a token (the `Initial` outcome), no event is emitted. Off-chain monitoring systems cannot easily track which tokens have been initialized or detect inconsistency outcomes without tracing calls.

**Analysis:** This is a gas optimization trade-off. For a singleton that may be called in hot paths (e.g., during token swaps), omitting events saves gas. However, it reduces observability. Callers that need auditing can emit their own events after calling the singleton.

**Risk:** LOW -- Minor observability gap; acceptable for a gas-sensitive singleton. No action needed unless the project desires off-chain monitoring.

---

### A02-10: Thin Wrapper Correctness -- All Functions Properly Delegate [INFO]

**Location:** Lines 19-38

**Description:** Each of the four external functions in `TOFUTokenDecimals` is a direct pass-through to the corresponding function in `LibTOFUTokenDecimalsImplementation`, passing the same `sTOFUTokenDecimals` storage reference and `token` parameter. Return types match exactly. View functions correctly call view library functions; state-changing functions correctly call non-view library functions.

**Analysis:** The wiring is correct:
- `decimalsForTokenReadOnly` -> `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` (both `view`)
- `decimalsForToken` -> `LibTOFUTokenDecimalsImplementation.decimalsForToken` (both non-view)
- `safeDecimalsForToken` -> `LibTOFUTokenDecimalsImplementation.safeDecimalsForToken` (both non-view)
- `safeDecimalsForTokenReadOnly` -> `LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly` (both `view`)

No additional logic, no missed parameters, no return value manipulation.

**Risk:** INFO -- Correct. No action needed.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A02-01 | INFO | No Access Control on `decimalsForToken` -- Permissionless Initialization |
| A02-02 | INFO | No Constructor or Initializer -- Zero Initialization State is Safe |
| A02-03 | LOW | Reentrancy Surface via External `staticcall` to Untrusted Token |
| A02-04 | INFO | Assembly Memory Safety -- Scratch Space Usage |
| A02-05 | INFO | `returndatasize` Check Guards Against Short Returns |
| A02-06 | LOW | Storage Mapping Visibility is `internal` -- No Direct External Read |
| A02-07 | INFO | Bytecode Determinism Configuration |
| A02-08 | INFO | No `receive()` or `fallback()` -- ETH Cannot Be Trapped |
| A02-09 | LOW | No Events Emitted on State Changes |
| A02-10 | INFO | Thin Wrapper Correctness -- All Functions Properly Delegate |

**Overall Assessment:** The `TOFUTokenDecimals` concrete contract is a minimal, well-structured thin wrapper. No CRITICAL or HIGH severity issues were found. The three LOW findings are design trade-offs rather than vulnerabilities. The contract correctly delegates all logic to `LibTOFUTokenDecimalsImplementation`, maintains proper view/mutability annotations, and its bytecode determinism configuration is intact. Test coverage across five dedicated test files exercises all four functions, including edge cases (overwide decimals, no-function contracts, cross-token isolation, storage immutability after read failures and inconsistencies).
