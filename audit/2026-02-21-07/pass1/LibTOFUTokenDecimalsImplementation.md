# Audit Pass 1 (Security) - LibTOFUTokenDecimalsImplementation.sol

**Agent:** A02
**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Date:** 2026-02-21

## Evidence of Thorough Reading

**Library name:** `LibTOFUTokenDecimalsImplementation` (line 13)

**Functions:**

| Function | Line | Mutability |
|---|---|---|
| `decimalsForTokenReadOnly` | 29 | `view` |
| `decimalsForToken` | 109 | state-modifying |
| `safeDecimalsForToken` | 136 | state-modifying |
| `safeDecimalsForTokenReadOnly` | 160 | `view` |

**Constants:**

| Name | Line | Value |
|---|---|---|
| `TOFU_DECIMALS_SELECTOR` | 15 | `0x313ce567` (keccak256 of `decimals()`) |

**Types/errors referenced (defined in `ITOFUTokenDecimals.sol`):**

- `TOFUTokenDecimalsResult` struct: `{ bool initialized; uint8 tokenDecimals; }`
- `TOFUOutcome` enum: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`
- `ITOFUTokenDecimals.TokenDecimalsReadFailure` custom error

**Imports (line 5):**
- `TOFUTokenDecimalsResult`, `TOFUOutcome`, `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol`

## Security Analysis

### Assembly block (lines 45-57): Memory safety

The assembly block is annotated `"memory-safe"` and operates exclusively within the EVM scratch space (offsets 0x00-0x1f):

1. **`mstore(0, selector)`** (line 46): Writes the 4-byte function selector left-aligned into a 32-byte word at offset 0. The `bytes4` type in Solidity inline assembly is stored left-aligned (high-order bytes), so the selector occupies bytes 0x00-0x03. This correctly prepares the calldata for `staticcall`.

2. **`staticcall(gas(), token, 0, 0x04, 0, 0x20)`** (line 47): Input spans memory[0x00..0x04] (the selector). Output is written to memory[0x00..0x20]. Both regions are within scratch space (0x00-0x3f). The output overwrites the selector, which is no longer needed. The use of `staticcall` prevents any state modification by the callee, eliminating reentrancy risk.

3. **`returndatasize` check** (lines 48-50): If `returndatasize() < 0x20`, sets `success := 0`. This prevents reading stale memory when the callee returns fewer than 32 bytes. Correctly handles EOAs (returndatasize = 0), empty contracts, and tokens returning non-standard response sizes.

4. **`mload(0)` and `uint8` bounds check** (lines 52-55): Only executed when `success` is true (thus `returndatasize >= 0x20`). Reads the full 32-byte ABI-encoded return value. The `gt(readDecimals, 0xff)` check validates that the value fits in `uint8` before it is used, preventing truncation of malformed return data.

**Memory safety verdict:** The block stays entirely within scratch space (0x00-0x3f). The `tofuTokenDecimals` memory struct (line 34) is heap-allocated above the free memory pointer and is not affected by scratch space writes. The `"memory-safe"` annotation is correct.

### Input validation

- **Zero address / EOA / codeless address as `token`:** `staticcall` to a codeless address returns success=true with returndatasize=0. The `lt(returndatasize(), 0x20)` check catches this and sets `success := 0`, resulting in `ReadFailure`. Correct behavior.
- **Malicious token returning > 32 bytes:** The output buffer is capped at 0x20 bytes, so only the first word is written to memory. `returndatasize()` may exceed 0x20 but passes the `lt` check, and `mload(0)` reads exactly the first word. Correct.
- **Token returning a value > 255:** Caught by `gt(readDecimals, 0xff)` and treated as `ReadFailure`. Correct.

### Reentrancy and state consistency

- All external calls use `staticcall`, which prohibits state changes in the callee, eliminating reentrancy.
- In `decimalsForToken` (line 109), storage is written only on `Initial` outcome (line 119-121). Since `Initial` means `initialized == false`, this is a one-time write. The read (via `staticcall`) completes before the storage write, and no further external calls are made. No reentrancy window exists.

### Arithmetic safety

- No arithmetic operations are performed. The `uint8(readDecimals)` cast (line 71) is protected by the prior `gt(readDecimals, 0xff)` check. No overflow or underflow risk.

### Error handling

- All reverts use the custom error `ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome)` (lines 143, 167). No string-based `revert(...)` calls are present.
- The `safe*` functions (lines 136-146, 160-170) correctly revert on any outcome other than `Consistent` or `Initial`, covering both `Inconsistent` and `ReadFailure`.

### Gas forwarding

- `staticcall(gas(), ...)` forwards all remaining gas to the token contract. A malicious token could consume all forwarded gas, but since this is a `staticcall` (no state changes possible) and the caller controls transaction gas, this is by design and not a security concern.

## Findings

No findings.
