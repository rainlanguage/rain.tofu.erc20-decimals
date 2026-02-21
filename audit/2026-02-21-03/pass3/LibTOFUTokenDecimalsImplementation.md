# Pass 3: Documentation -- LibTOFUTokenDecimalsImplementation.sol

Agent: A05

## Evidence of Thorough Reading

**Library**: `LibTOFUTokenDecimalsImplementation` (line 18)

**Constants**:
- `TOFU_DECIMALS_SELECTOR` = `0x313ce567` (line 20) -- verified correct keccak256 selector for `decimals()`

**Functions** (4 total):
1. `decimalsForTokenReadOnly` (line 34) -- `internal view`, returns `(TOFUOutcome, uint8)`. Core read logic with assembly `staticcall` to `decimals()`. Does not write to storage.
2. `decimalsForToken` (line 113) -- `internal`, returns `(TOFUOutcome, uint8)`. Delegates to `decimalsForTokenReadOnly` then persists the result to storage on `Initial` outcome.
3. `safeDecimalsForToken` (line 140) -- `internal`, returns `uint8`. Wraps `decimalsForToken`, reverting on `Inconsistent` or `ReadFailure`.
4. `safeDecimalsForTokenReadOnly` (line 164) -- `internal view`, returns `uint8`. Wraps `decimalsForTokenReadOnly`, reverting on `Inconsistent` or `ReadFailure`.

**Imports**: `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome`, `TokenDecimalsReadFailure` from `../interface/ITOFUTokenDecimals.sol`

## Findings

### A05-1: Missing @notice tag on decimalsForToken NatSpec [INFO]

The NatSpec comment for `decimalsForToken` (line 86) begins with `/// Trust on first use (TOFU) token decimals.` without an explicit `@notice` tag. While Solidity defaults untagged `///` comments to `@notice`, the sibling function `decimalsForTokenReadOnly` (line 22) explicitly uses `@notice`. The same applies to `safeDecimalsForToken` (line 129) and `safeDecimalsForTokenReadOnly` (line 152). For consistency, all four functions should either all use explicit `@notice` tags or all rely on the implicit default.

### A05-2: Constant TOFU_DECIMALS_SELECTOR lacks @notice tag [INFO]

The constant `TOFU_DECIMALS_SELECTOR` (line 20) has a `@dev` comment but no `@notice` tag. This is consistent with internal-use constants where `@dev` is appropriate. No functional issue, but noted for completeness. The `@dev` description ("The selector for the `decimals()` function in the ERC20 standard") is accurate.

### A05-3: Assembly block inline comments are accurate [INFO]

The assembly block (lines 50-62) in `decimalsForTokenReadOnly` was verified step by step:

1. **Line 51** `mstore(0, selector)`: Stores the 4-byte `decimals()` selector left-aligned at memory position 0 (scratch space). Correct -- `bytes4` values are left-aligned in a 32-byte word by Solidity ABI conventions.

2. **Line 52** `staticcall(gas(), token, 0, 0x04, 0, 0x20)`: Calls `token` with 4 bytes of calldata (the selector) from memory 0, writing up to 32 bytes of return data to memory 0. Correct -- this overwrites the selector with the return data, which is acceptable since the selector is no longer needed.

3. **Lines 53-55** `if lt(returndatasize(), 0x20) { success := 0 }`: Treats return data smaller than 32 bytes as failure. This correctly handles non-compliant tokens that return fewer bytes or no data.

4. **Lines 56-61** `if success { readDecimals := mload(0); if gt(readDecimals, 0xff) { success := 0 } }`: Loads the full 32-byte return value, then validates it fits in a `uint8`. This correctly handles tokens that return values greater than 255, treating them as failures.

5. **"memory-safe" annotation**: The block only uses memory positions 0x00-0x1F (Solidity scratch space) and does not allocate or depend on managed memory. This annotation is correct.

There are no inline comments within the assembly block itself. The comments are placed before the assembly block (lines 41-46) and accurately describe the rationale: errors and unexpected return values are treated as read failures so the calling context can decide how to proceed.

### A05-4: @param and @return tags present and accurate on all functions [INFO]

Verification of all four functions:

- **`decimalsForTokenReadOnly`** (lines 25-33): `@param sTOFUTokenDecimals`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals` -- all present, descriptions match the implementation. The return behavior for each `TOFUOutcome` variant is documented and verified correct against the code.

- **`decimalsForToken`** (lines 104-112): `@param sTOFUTokenDecimals`, `@param token`, `@return tofuOutcome`, `@return tokenDecimals` -- all present, descriptions identical to `decimalsForTokenReadOnly`. This is accurate because `decimalsForToken` returns the same values as `decimalsForTokenReadOnly` (it only adds the storage side effect on `Initial`).

- **`safeDecimalsForToken`** (lines 133-138): `@param sTOFUTokenDecimals`, `@param token`, `@return The token's decimals.` -- all present and accurate.

- **`safeDecimalsForTokenReadOnly`** (lines 157-162): `@param sTOFUTokenDecimals`, `@param token`, `@return The token's decimals.` -- all present and accurate.

### A05-5: decimalsForTokenReadOnly NatSpec cross-reference is slightly confusing [INFO]

Line 22 says: "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`. Works as `decimalsForToken` but does not store any state, simply checking for consistency if we have a stored value."

This could be read as implying `decimalsForToken` is the primary function and `decimalsForTokenReadOnly` is derived from it, when in fact the implementation relationship is the opposite: `decimalsForToken` (line 121) calls `decimalsForTokenReadOnly` internally and adds a storage write. The documentation is not technically inaccurate -- the external behavior is indeed "like `decimalsForToken` minus state storage" -- but the description could be clearer about the implementation direction. A more precise phrasing might be: "Core read logic that `decimalsForToken` builds upon. Does not store any state."

### A05-6: safeDecimalsForToken revert condition documentation matches implementation [INFO]

Line 130-131 states it "reverts with `TokenDecimalsReadFailure` if the token's decimals are inconsistent or the read fails." The implementation (line 146) reverts when `tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial`, which is equivalent to reverting on `Inconsistent` or `ReadFailure` (the only other two `TOFUOutcome` variants). Documentation is accurate.

### A05-7: safeDecimalsForTokenReadOnly WARNING comment is valuable and accurate [INFO]

Lines 153-156 contain a `WARNING` about pre-initialization behavior: "Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected." This is verified correct: `decimalsForTokenReadOnly` returns `Initial` when `!tofuTokenDecimals.initialized` (line 72), and since the read-only variant never stores, subsequent calls will keep returning `Initial` without any consistency check. The warning appropriately advises callers to ensure `decimalsForToken` has been called at least once.

### A05-8: Library-level NatSpec is accurate [INFO]

The library `@title` (line 12) and `@notice` (lines 13-17) accurately describe the purpose: implementation logic for TOFU token decimals, designed to be used in `TOFUTokenDecimals`. This matches the actual architecture where `TOFUTokenDecimals.sol` (the concrete contract) delegates all logic to this library.
