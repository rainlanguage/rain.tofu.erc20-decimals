# Audit Pass 1 (Security) -- TOFUTokenDecimals.sol

**Agent ID:** A01
**Date:** 2026-02-21
**File under review:** `src/concrete/TOFUTokenDecimals.sol`
**Dependencies reviewed:** `src/interface/ITOFUTokenDecimals.sol`, `src/lib/LibTOFUTokenDecimalsImplementation.sol`

---

## Evidence of Thorough Reading

### Contract Name

`TOFUTokenDecimals` (line 13), inheriting from `ITOFUTokenDecimals`.

### Function Names and Line Numbers

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `decimalsForTokenReadOnly` | 19 | `external` | `view` |
| `decimalsForToken` | 25 | `external` | (state-changing) |
| `safeDecimalsForToken` | 31 | `external` | (state-changing) |
| `safeDecimalsForTokenReadOnly` | 36 | `external` | `view` |

### Types, Errors, and Constants Defined

**In `TOFUTokenDecimals.sol` itself:** None. The contract defines no types, errors, or constants directly. It defines one state variable:

- `sTOFUTokenDecimals` (line 16): `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)`, visibility `internal`.

**In `ITOFUTokenDecimals.sol` (imported):**

- **Struct:** `TOFUTokenDecimalsResult` (line 13) with fields `bool initialized` and `uint8 tokenDecimals`.
- **Enum:** `TOFUOutcome` (line 19) with values `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`.
- **Error:** `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 33).

**In `LibTOFUTokenDecimalsImplementation.sol` (imported):**

- **Constant:** `TOFU_DECIMALS_SELECTOR = 0x313ce567` (line 20) -- the `bytes4` selector for `decimals()`.

### Imports (in `TOFUTokenDecimals.sol`)

1. Line 5: `{ITOFUTokenDecimals, TOFUTokenDecimalsResult, TOFUOutcome}` from `"../interface/ITOFUTokenDecimals.sol"`
2. Line 6: `{LibTOFUTokenDecimalsImplementation}` from `"../lib/LibTOFUTokenDecimalsImplementation.sol"`

---

## Security Findings

### F-01 [INFO] -- Scratch space usage in assembly is safe but bears documenting

**Location:** `LibTOFUTokenDecimalsImplementation.sol`, lines 50-62

The assembly block in `decimalsForTokenReadOnly` uses memory offsets `0x00`-`0x1f` (scratch space) for both the `staticcall` input (writing the 4-byte selector at offset 0) and the output (reading 32 bytes at offset 0). Solidity reserves offsets `0x00`-`0x3f` as scratch space and `0x40`-`0x5f` as the free memory pointer. The block is annotated `"memory-safe"`, which is correct: it only uses scratch space and does not allocate or corrupt managed memory.

However, the `mstore(0, selector)` call writes the 4-byte selector right-padded into the full 32-byte word at offset 0. The `staticcall` sends only the first 4 bytes (`0, 0x04`), which correctly contains the selector in the high-order bytes. The return data then overwrites offset `0x00` with the response. This is functionally correct.

Note that `tofuTokenDecimals` is a `memory` struct loaded at line 39 and its pointer will be above the free-memory-pointer boundary, so the scratch space writes at offset 0 cannot corrupt it. **No issue.**

**Severity:** INFO

---

### F-02 [INFO] -- No reentrancy guard, but reentrancy risk is negligible

**Location:** `TOFUTokenDecimals.sol`, lines 25-28 and 31-33

The `decimalsForToken` and `safeDecimalsForToken` functions make an external `staticcall` to the `token` address (via the library's assembly) and then write to storage. There is no reentrancy guard (e.g., `nonReentrant` modifier).

However, the external call is a `staticcall`, which by the EVM specification cannot modify state. This means the called contract cannot re-enter `TOFUTokenDecimals` in a state-modifying way during the `staticcall`. By the time storage is written, the external call has already returned. Therefore, classical reentrancy is not possible here.

A `staticcall` callback could in theory call back into the `view` functions (`decimalsForTokenReadOnly`, `safeDecimalsForTokenReadOnly`), but those do not modify state, and the storage has not yet been updated at that point, so they would just see the pre-existing state -- which is consistent with expected behavior (they would return `Initial` again if uninitialized).

**Severity:** INFO

---

### F-03 [INFO] -- No access control by design

**Location:** `TOFUTokenDecimals.sol`, all four functions

All four external functions are callable by any address. There is no `onlyOwner`, role-based, or any other access restriction. This is intentional: the contract is a permissionless singleton that any caller can use to register token decimals. The first caller to invoke `decimalsForToken` for a given token address sets the stored value permanently.

This means an attacker could front-run the first legitimate `decimalsForToken` call. However, the value stored is read directly from the token contract itself via `staticcall`, so the attacker cannot choose an arbitrary value -- only the token's actual `decimals()` return value is stored. The only scenario where front-running matters is if the token's `decimals()` return value changes between the attacker's call and the legitimate caller's call, which is an inherently adversarial token situation that the TOFU design already handles via the `Inconsistent` outcome.

**Severity:** INFO

---

### F-04 [INFO] -- Unchecked arithmetic is not present; overflow/underflow is not a risk

**Location:** `TOFUTokenDecimals.sol` and `LibTOFUTokenDecimalsImplementation.sol`

Solidity 0.8.25 has built-in overflow/underflow checks. The assembly block manually checks `gt(readDecimals, 0xff)` to ensure the value fits in `uint8` before the Solidity-level cast `uint8(readDecimals)` at line 76. There is no `unchecked` block anywhere in the codebase. No arithmetic overflow/underflow risk.

**Severity:** INFO

---

### F-05 [INFO] -- Storage layout is simple and correct

**Location:** `TOFUTokenDecimals.sol`, line 16

The contract has exactly one state variable: `sTOFUTokenDecimals`, a `mapping(address => TOFUTokenDecimalsResult)`. Mappings in Solidity do not occupy sequential storage slots; each key-value pair is stored at `keccak256(key . slot)`. The struct `TOFUTokenDecimalsResult` has two fields (`bool initialized` at 1 byte, `uint8 tokenDecimals` at 1 byte), which pack into a single 32-byte storage slot. There are no storage layout concerns, no gaps, and no risk of slot collision.

The contract does not use `delegatecall` and is not intended to be used behind a proxy, so storage layout compatibility is not a concern.

**Severity:** INFO

---

### F-06 [LOW] -- Return data size exactly 0x20 is required; some non-standard tokens return different sizes

**Location:** `LibTOFUTokenDecimalsImplementation.sol`, lines 53-54

The assembly checks `lt(returndatasize(), 0x20)` and treats any return data shorter than 32 bytes as a failure. This correctly handles tokens that return no data or short data. However, some non-standard token implementations might return more than 32 bytes (e.g., if they return a dynamically-encoded value or extra padding). The code reads exactly the first 32 bytes via `mload(0)` after writing the output to offset 0, so extra return data beyond 32 bytes is simply ignored. This is correct behavior.

Some extremely non-standard tokens might return the decimals value as a smaller type (e.g., `bytes1`) without ABI padding, which would result in `returndatasize() < 0x20` and a `ReadFailure` outcome. This is by design -- the contract only trusts standard ABI-compliant responses. The `ReadFailure` outcome is surfaced to callers, who can decide how to handle it.

**Severity:** LOW -- Minor edge case with non-ABI-compliant tokens; handled by design through the `ReadFailure` outcome.

---

### F-07 [LOW] -- Token with self-destructed or non-existent code returns success on staticcall

**Location:** `LibTOFUTokenDecimalsImplementation.sol`, lines 50-62

When `staticcall` is made to an address with no code (EOA or self-destructed contract), the EVM returns `success = true` with `returndatasize() = 0`. The check `lt(returndatasize(), 0x20)` correctly catches this and sets `success := 0`, leading to a `ReadFailure` outcome. This is correct behavior.

**Severity:** LOW -- Correctly handled, but worth noting that calling `decimalsForToken` with a non-contract address does not revert; it returns `ReadFailure`. Callers using `safeDecimalsForToken` will get a revert, which is the expected safe path.

---

### F-08 [INFO] -- The `"memory-safe"` annotation is correctly applied

**Location:** `LibTOFUTokenDecimalsImplementation.sol`, line 50

The `assembly ("memory-safe")` annotation tells the Solidity compiler that the assembly block respects Solidity's memory model. This block:

1. Writes only to scratch space (offset 0x00).
2. Does not modify the free memory pointer (offset 0x40).
3. Does not allocate memory.
4. Returns data via stack variables (`success`, `readDecimals`).

All four conditions for memory safety are met. The annotation is correct and allows the optimizer to make assumptions about memory around this block.

**Severity:** INFO

---

### F-09 [INFO] -- Deterministic deployment constraints are maintained

**Location:** `TOFUTokenDecimals.sol`, line 3

The contract uses `pragma solidity =0.8.25` (exact version pin), which is critical for bytecode determinism. The `foundry.toml` configuration (per CLAUDE.md) specifies `bytecode_hash = "none"` and `cbor_metadata = false`. These constraints ensure the deployed bytecode is identical across compilations, which is required for the Zoltu deterministic factory deployment. No issue, but any change to this pragma or the compiler settings would break the deployed address.

**Severity:** INFO

---

## Summary Table

| ID | Severity | Title | Location |
|---|---|---|---|
| F-01 | INFO | Scratch space usage in assembly is safe | `LibTOFUTokenDecimalsImplementation.sol:50-62` |
| F-02 | INFO | No reentrancy guard; not needed due to `staticcall` | `TOFUTokenDecimals.sol:25-33` |
| F-03 | INFO | No access control by design (permissionless singleton) | `TOFUTokenDecimals.sol` (all functions) |
| F-04 | INFO | No unchecked arithmetic; overflow not possible | `TOFUTokenDecimals.sol`, `LibTOFUTokenDecimalsImplementation.sol` |
| F-05 | INFO | Storage layout is simple and correct | `TOFUTokenDecimals.sol:16` |
| F-06 | LOW | Non-standard tokens with non-ABI return data get `ReadFailure` | `LibTOFUTokenDecimalsImplementation.sol:53-54` |
| F-07 | LOW | Non-contract addresses return `ReadFailure` (correctly handled) | `LibTOFUTokenDecimalsImplementation.sol:50-62` |
| F-08 | INFO | `"memory-safe"` annotation is correctly applied | `LibTOFUTokenDecimalsImplementation.sol:50` |
| F-09 | INFO | Deterministic deployment constraints are maintained | `TOFUTokenDecimals.sol:3` |

---

## Overall Assessment

The `TOFUTokenDecimals.sol` contract is a minimal, well-structured thin wrapper that delegates all logic to `LibTOFUTokenDecimalsImplementation`. The contract itself contains no logic beyond storage ownership and delegation, which minimizes its attack surface.

**No CRITICAL, HIGH, or MEDIUM severity issues were found.**

The two LOW findings are edge cases involving non-standard tokens and non-contract addresses, both of which are handled correctly by the `ReadFailure` outcome path. The remaining findings are informational, confirming that the assembly is memory-safe, reentrancy is not a risk due to `staticcall`, access control is intentionally absent, and the storage layout is sound.

The code demonstrates careful defensive programming: the assembly block validates return data size and value range, the `staticcall` prevents reentrancy, and the `initialized` flag in the struct prevents confusion between stored-zero and uninitialized states.
