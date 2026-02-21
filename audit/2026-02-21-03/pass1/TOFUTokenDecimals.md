# Pass 1: Security -- TOFUTokenDecimals.sol

Agent: A02

## Evidence of Thorough Reading

### src/concrete/TOFUTokenDecimals.sol
- Contract: `TOFUTokenDecimals` (line 13), inherits `ITOFUTokenDecimals`
- Functions:
  - `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 19)
  - `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 25)
  - `safeDecimalsForToken(address token) external returns (uint8)` (line 31)
  - `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 36)
- Types/Errors/Constants: None defined locally
- State variables:
  - `sTOFUTokenDecimals` (line 16): `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal`
- Pragma: `=0.8.25` (exact version, critical for deterministic bytecode)

### src/interface/ITOFUTokenDecimals.sol
- Interface: `ITOFUTokenDecimals` (line 53)
- Functions:
  - `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 67)
  - `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 77)
  - `safeDecimalsForToken(address token) external returns (uint8)` (line 83)
  - `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 91)
- Types/Errors/Constants:
  - `struct TOFUTokenDecimalsResult { bool initialized; uint8 tokenDecimals; }` (lines 13-16)
  - `enum TOFUOutcome { Initial, Consistent, Inconsistent, ReadFailure }` (lines 19-28)
  - `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 33)
- Pragma: `^0.8.25`

### src/lib/LibTOFUTokenDecimalsImplementation.sol
- Library: `LibTOFUTokenDecimalsImplementation` (line 18)
- Functions:
  - `decimalsForTokenReadOnly(mapping(...) storage, address token) internal view returns (TOFUOutcome, uint8)` (line 34)
  - `decimalsForToken(mapping(...) storage, address token) internal returns (TOFUOutcome, uint8)` (line 113)
  - `safeDecimalsForToken(mapping(...) storage, address token) internal returns (uint8)` (line 140)
  - `safeDecimalsForTokenReadOnly(mapping(...) storage, address token) internal view returns (uint8)` (line 164)
- Types/Errors/Constants:
  - `bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567` (line 20) -- ERC20 `decimals()` selector
- Imports: `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome`, `TokenDecimalsReadFailure`

## Findings

### A02-1: Assembly scratch space usage overlaps with Solidity memory conventions [INFO]

In `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` (lines 50-62), the assembly block uses memory offset `0` for both the calldata argument (`mstore(0, selector)`) and the return data buffer (`staticcall(..., 0, 0x04, 0, 0x20)`). The return data is written to `[0, 0x20)` and then read via `mload(0)`.

Memory addresses `0x00`-`0x3f` are Solidity's "scratch space," which is explicitly allowed for short-term use. However, the `tofuTokenDecimals` memory struct was loaded from storage on line 39 *before* the assembly block. If the compiler allocates this struct at the free memory pointer (which for a simple struct it will, at `0x80` or higher), the scratch space writes will not corrupt it.

Verified: The struct is loaded into memory before the assembly block. Solidity allocates structs at the free memory pointer (`>= 0x80`), so writing to `[0, 0x20)` does not corrupt the struct. The block is correctly annotated `"memory-safe"`. The free memory pointer at `0x40` is also not touched. This is safe but worth documenting for future maintainers.

**No action required.**

### A02-2: No access control on decimalsForToken (storage write path) [INFO]

The `decimalsForToken` function in `TOFUTokenDecimals.sol` (line 25) is `external` with no access restriction. Any caller can invoke it and trigger the first-use storage write for any token address. This is by design for a singleton: the TOFU model inherently trusts the first caller to trigger the initial read. However, this means an attacker could front-run a legitimate first use by:

1. Deploying a malicious contract at a token address that returns a chosen `decimals()` value.
2. Calling `decimalsForToken` on the singleton to lock in that value.
3. The real token later deploying to the same address (via CREATE2 metamorphic patterns) with different decimals.

This is mitigated because:
- The scenario requires metamorphic deployment of the token itself, which is extremely unusual for legitimate tokens.
- The `Inconsistent` outcome allows callers to detect and respond to changes.
- The singleton is explicitly designed to be permissionless.

**No action required, but callers should be aware that the first reader of any token address establishes the trusted value.**

### A02-3: staticcall to arbitrary address without existence check [INFO]

In `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` (line 52), a `staticcall` is made to the `token` address. If `token` is an EOA or has no code, `staticcall` succeeds with `returndatasize()` of 0, which is correctly caught by the `lt(returndatasize(), 0x20)` check on line 53 that sets `success` to 0. This correctly results in a `ReadFailure` outcome.

Verified: The code handles all edge cases for the staticcall:
- EOA / no code: `returndatasize() < 0x20` -> `ReadFailure`
- Contract that reverts: `success = 0` -> `ReadFailure`
- Contract returning value > `0xff`: `gt(readDecimals, 0xff)` check sets `success = 0` -> `ReadFailure`
- Contract returning valid uint8: correctly processed

**No action required.**

### A02-4: initialized flag correctly distinguishes stored 0 from uninitialized [INFO]

The `TOFUTokenDecimalsResult` struct (interface file, line 13) uses `bool initialized` alongside `uint8 tokenDecimals`. In `decimalsForTokenReadOnly` (implementation, line 72), the `!tofuTokenDecimals.initialized` check correctly distinguishes:
- Uninitialized storage (both `initialized = false` and `tokenDecimals = 0`) -> `TOFUOutcome.Initial`
- Stored value of 0 decimals (where `initialized = true` and `tokenDecimals = 0`) -> proceeds to consistency check

The storage write in `decimalsForToken` (implementation, line 124) correctly sets `initialized: true` alongside the decimal value.

Verified: The struct packing in a single storage slot (bool = 1 byte at offset 0, uint8 = 1 byte at offset 1) is efficient and correct. The initialized flag design properly handles the zero-decimals case.

**No action required.**

### A02-5: Reentrancy via external staticcall is mitigated by design [INFO]

The `staticcall` to the token contract (implementation, line 52) prevents state modification during the call, so the token cannot re-enter and modify the TOFU mapping during the read. For the state-modifying `decimalsForToken`, the call sequence is: (1) read token decimals via `staticcall` (no reentrancy possible), (2) write to storage only on `Initial` outcome. Since `staticcall` is used rather than `call`, there is no reentrancy vector.

**No action required.**

### A02-6: TOFUTokenDecimals concrete contract has no constructor or initializer [INFO]

The contract has no constructor, which means the storage mapping starts empty (all values zero / uninitialized). This is correct behavior: the singleton is deployed with no pre-populated state, and all token decimals are populated on first use via `decimalsForToken`. The absence of a constructor also contributes to bytecode determinism for the Zoltu deployment.

**No action required.**

### A02-7: No string reverts -- custom errors used throughout [INFO]

All revert paths use the custom error `TokenDecimalsReadFailure(address, TOFUOutcome)` defined in the interface (line 33). No string-based `require` or `revert` statements are present in any of the three files. This is consistent with the project's design constraints.

**No action required.**

## Summary

No security findings of CRITICAL, HIGH, MEDIUM, or LOW severity were identified. The `TOFUTokenDecimals.sol` concrete contract is a thin delegation layer that correctly passes its storage mapping to `LibTOFUTokenDecimalsImplementation`. The implementation library's assembly is memory-safe, handles all `staticcall` edge cases, correctly uses the `initialized` flag to distinguish stored-zero from uninitialized, and is not susceptible to reentrancy. The permissionless nature of the singleton is by design and well-documented.
