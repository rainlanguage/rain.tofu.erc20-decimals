# Pass 1: Security — LibTOFUTokenDecimalsImplementation.sol

Agent: A05

## Evidence of Thorough Reading

### src/lib/LibTOFUTokenDecimalsImplementation.sol
- Library: `LibTOFUTokenDecimalsImplementation` (line 18)
- Functions:
  - `decimalsForTokenReadOnly` (line 34) — `internal view`, takes storage mapping + token address, returns `(TOFUOutcome, uint8)`. Core read logic with assembly block. Does not write storage.
  - `decimalsForToken` (line 113) — `internal`, calls `decimalsForTokenReadOnly`, writes storage on `Initial` outcome only, returns `(TOFUOutcome, uint8)`.
  - `safeDecimalsForToken` (line 140) — `internal`, calls `decimalsForToken`, reverts on `Inconsistent` or `ReadFailure`, returns `uint8`.
  - `safeDecimalsForTokenReadOnly` (line 164) — `internal view`, calls `decimalsForTokenReadOnly`, reverts on `Inconsistent` or `ReadFailure`, returns `uint8`.
- Constants:
  - `TOFU_DECIMALS_SELECTOR` (line 20) — `bytes4 constant = 0x313ce567` (ERC20 `decimals()` selector)
- Types/Errors imported from `ITOFUTokenDecimals.sol`:
  - `TOFUTokenDecimalsResult` struct — `{ bool initialized; uint8 tokenDecimals; }`
  - `TOFUOutcome` enum — `Initial (0)`, `Consistent (1)`, `Inconsistent (2)`, `ReadFailure (3)`
  - `TokenDecimalsReadFailure` error — `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`
  - `ITOFUTokenDecimals` interface (imported but not directly used in the library)

### src/interface/ITOFUTokenDecimals.sol
- Struct: `TOFUTokenDecimalsResult` (line 13) — `bool initialized`, `uint8 tokenDecimals`
- Enum: `TOFUOutcome` (line 19) — `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`
- Error: `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 33)
- Interface: `ITOFUTokenDecimals` (line 53) with four external functions: `decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

## Findings

### A05-1: Assembly scratch space usage is safe but worth documenting [INFO]

The assembly block (lines 50-62) uses memory addresses 0x00-0x1f (scratch space) for both the `mstore(0, selector)` write and the `staticcall` output buffer (`0, 0x20`). This is safe under the Solidity memory model:

- Bytes 0x00-0x3f are designated as "scratch space" by the Solidity compiler. The compiler does not guarantee their contents across operations and they are explicitly available for short-term use in assembly.
- `mstore(0, selector)` writes 32 bytes starting at 0x00. Since `selector` is a `bytes4`, the upper 28 bytes are zero-padded. This writes into scratch space (0x00-0x1f) and the free memory pointer slot (0x20-0x3f). However, the `selector` value `0x313ce567` stored as a `bytes4` in a `uint256` word places the 4 selector bytes in the most-significant position (bytes 0x00-0x03) with zeros in bytes 0x04-0x1f, leaving 0x20-0x3f as zeros. After the `staticcall`, the return data overwrites 0x00-0x1f. The free memory pointer at 0x40 is never touched.

**Wait** — let me re-examine this more carefully. `mstore(0, selector)` writes 32 bytes at offset 0. A `bytes4` value loaded into a stack word is left-padded (high-order bytes). So the 32 bytes written at address 0 are: `[0x313ce567][28 bytes of zeros]`. This occupies memory addresses 0x00 through 0x1f. The free memory pointer lives at 0x40, not 0x20. The `staticcall` output buffer is `(0, 0x20)`, meaning it writes returndata to addresses 0x00-0x1f. This does NOT touch the free memory pointer at 0x40. The `mstore(0, selector)` also does not touch 0x40 since it writes 32 bytes starting at 0, which is 0x00-0x1f.

Corrected analysis: Both the `mstore` and the `staticcall` output only touch 0x00-0x1f (scratch space). The free memory pointer at 0x40 is untouched. This is fully safe.

The `staticcall` input calldata range is `(0, 0x04)`, meaning only the first 4 bytes (the selector) are sent. This is correct for a no-argument function call.

The block is annotated `"memory-safe"`, which is valid because it only uses the scratch space region (0x00-0x3f).

No action needed. The usage is correct.

### A05-2: `staticcall` prevents reentrancy — no state modification possible [INFO]

The external call to `token` at line 52 uses `staticcall`, which by EVM specification prevents the callee from modifying state (no `SSTORE`, `LOG`, `CREATE`, `SELFDESTRUCT`, or further non-static calls that modify state). This eliminates reentrancy as a concern for this call. A malicious token contract could consume gas (griefing via gas exhaustion) but cannot alter contract storage or emit events. Since `gas()` is forwarded, a token designed to consume all gas would cause the outer transaction to fail, but this is no worse than a reverting token (treated as `ReadFailure`).

No action needed.

### A05-3: `returndatasize()` check correctly guards against short return data [INFO]

Line 53: `if lt(returndatasize(), 0x20) { success := 0 }` — This correctly handles:
- EOAs or contracts without code (returndatasize = 0)
- Contracts that return fewer than 32 bytes
- Contracts that revert (success is already 0 from staticcall)

The check is performed after the `staticcall`, so `returndatasize()` correctly reflects the return data from that specific call. This is safe.

### A05-4: `gt(readDecimals, 0xff)` correctly validates uint8 range [INFO]

Line 58: After loading the 32-byte return value via `mload(0)`, the code checks if `readDecimals > 0xff`. Since `mload(0)` loads a full 256-bit word, a compliant `decimals()` returning a `uint8` will have the value right-padded in a 256-bit ABI-encoded word (value in low-order bytes, high bytes zero). If a non-compliant contract returns a value larger than 255 in any of the upper bytes, this check catches it and treats it as a `ReadFailure`. This is the correct approach to sanitize ABI-decoded uint8 values from untrusted external calls.

### A05-5: `tofuTokenDecimals` loaded into memory before external call [INFO]

Line 39: `TOFUTokenDecimalsResult memory tofuTokenDecimals = sTOFUTokenDecimals[token]` loads the stored struct into memory BEFORE the assembly block performs the external `staticcall`. This means the struct data in memory is a snapshot from before the call. Since `staticcall` cannot modify state, the storage cannot change during the call anyway. But even if this were a regular `call`, the memory copy would be safe to use post-call. This is a sound pattern.

However, there is a subtle point: the `mstore(0, selector)` at line 51 writes to scratch space (0x00-0x1f). The `tofuTokenDecimals` memory struct is allocated by Solidity at the free memory pointer (>= 0x80), so it is NOT overwritten by the assembly block. Confirmed safe.

### A05-6: Storage write in `decimalsForToken` is correctly guarded [INFO]

Line 123-125 in `decimalsForToken`: Storage is only written when `tofuOutcome == TOFUOutcome.Initial`. This means:
- On `Consistent`: no write (correct, value already stored)
- On `Inconsistent`: no write (correct, preserves original TOFU value)
- On `ReadFailure`: no write (correct, does not corrupt stored state)
- On `Initial`: writes the new value (correct, first use)

The guard is correct. Once initialized, the stored value is immutable through this function.

### A05-7: Safe variants correctly reject non-success outcomes [INFO]

Lines 146 and 170: Both `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` check `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial` before reverting. This means they only allow `Consistent` and `Initial` outcomes through, and revert on `Inconsistent` and `ReadFailure`. This is correct and covers all four enum values exhaustively.

### A05-8: `safeDecimalsForTokenReadOnly` cannot provide TOFU protection before initialization [LOW]

As documented in the NatSpec (lines 152-156), `safeDecimalsForTokenReadOnly` does not store state, so before `decimalsForToken` has been called for a given token, every call returns `TOFUOutcome.Initial` with whatever the token currently reports. This means a malicious or mutable token could return different values on consecutive read-only calls without triggering `Inconsistent`. The documentation clearly warns about this. However, callers who use `safeDecimalsForTokenReadOnly` without first calling `decimalsForToken` will have no TOFU protection at all.

This is a design limitation that is explicitly documented, not a bug. Callers must ensure `decimalsForToken` has been called at least once before relying on `safeDecimalsForTokenReadOnly` for consistency guarantees.

### A05-9: Calling `decimalsForToken` on an EOA or contract without `decimals()` permanently locks the token to `ReadFailure` [INFO]

If `decimalsForToken` is called with a token address that is an EOA (no code) or a contract that does not implement `decimals()`, the `staticcall` will fail, and `ReadFailure` is returned. Since no storage is written on `ReadFailure`, the mapping entry remains uninitialized. If the address later has code deployed to it (e.g., via CREATE2) that implements `decimals()`, a subsequent call to `decimalsForToken` would succeed with `Initial` and store the value. So there is no permanent lock-out issue. This is correct behavior.

### A05-10: No risk from `mload(0)` reading stale data on success=false path [INFO]

When the `staticcall` fails (success=0) or `returndatasize() < 0x20`, the `if success` block (lines 56-61) is skipped, so `readDecimals` remains at its initialized value of 0. The `mload(0)` at line 57 is never executed on the failure path. This is correct.

Even if a malicious contract somehow returned exactly 31 bytes of data, the `returndatasize()` check would catch it and `readDecimals` would remain 0. The `staticcall` with output buffer `(0, 0x20)` would write however many bytes were returned (up to 0x20) to scratch space, but since `success` is set to 0, the value is never read. Safe.

## Summary

No security vulnerabilities were found. The assembly block correctly uses EVM scratch space (0x00-0x3f) without touching the free memory pointer (0x40). The `staticcall` prevents reentrancy. Input validation (`returndatasize` check, `uint8` range check) is thorough. The TOFU state machine (Initial -> Consistent/Inconsistent/ReadFailure) is correctly implemented with storage writes guarded to only occur on the Initial path. The safe variants correctly revert on all non-success outcomes. The only design-level consideration (A05-8) is explicitly documented in the source code.
