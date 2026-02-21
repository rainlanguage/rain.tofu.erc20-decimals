# Pass 1: Security — LibTOFUTokenDecimalsImplementation.sol (Agent A04)

## Evidence of Reading

**Library name**: `LibTOFUTokenDecimalsImplementation` (line 13)

**Functions (with line numbers)**:
1. `decimalsForTokenReadOnly` — line 29 (`internal view`, returns `(TOFUOutcome, uint8)`)
2. `decimalsForToken` — line 109 (`internal`, returns `(TOFUOutcome, uint8)`)
3. `safeDecimalsForToken` — line 136 (`internal`, returns `uint8`)
4. `safeDecimalsForTokenReadOnly` — line 160 (`internal view`, returns `uint8`)

**Constants**:
- `TOFU_DECIMALS_SELECTOR` — line 15 (`bytes4`, value `0x313ce567`, the selector for `decimals()`)

**Types referenced (defined in ITOFUTokenDecimals.sol)**:
- `TOFUTokenDecimalsResult` struct — fields: `bool initialized`, `uint8 tokenDecimals`
- `TOFUOutcome` enum — values: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`

**Errors referenced (defined in ITOFUTokenDecimals.sol)**:
- `ITOFUTokenDecimals.TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` — used in `safeDecimalsForToken` (line 143) and `safeDecimalsForTokenReadOnly` (line 167)

## Findings

No findings.

### Detailed Analysis

The following areas were reviewed and found to be correct:

**Assembly memory safety (lines 45-57)**: The assembly block is annotated `"memory-safe"` and correctly confines all memory operations to the Solidity scratch space (offsets 0x00-0x3f). The `tofuTokenDecimals` memory struct loaded on line 34 is allocated via the free memory pointer (at 0x80 or higher) and is not corrupted by the scratch space writes. `mstore(0, selector)` writes the left-aligned 4-byte selector to offset 0, and the `staticcall` reads exactly 4 bytes of calldata from this location. The output buffer `(0, 0x20)` overwrites the same scratch space with return data, which is then correctly read by `mload(0)`.

**returndatasize check (line 48-50)**: The `lt(returndatasize(), 0x20)` check correctly prevents reading stale or partial data when the callee returns fewer than 32 bytes. This handles EOAs (returndatasize = 0), contracts that revert, and non-standard implementations that return short data.

**uint8 bounds check (lines 53-55)**: The `gt(readDecimals, 0xff)` check ensures the returned uint256 fits in a uint8 before the cast on line 71. Values above 255 are treated as read failures, which is the correct conservative behavior.

**Reentrancy**: The external call is a `staticcall`, which cannot modify state. The only state write occurs in `decimalsForToken` (line 120) after the call completes, and it only writes on the `Initial` outcome (first use). There is no reentrancy risk.

**Input validation**: No explicit validation of the `token` address is needed. Calls to `address(0)` or EOAs return no data, which is caught by the `returndatasize` check and returned as `ReadFailure`. Precompile addresses (1-9) similarly produce either failures or unexpected return data that is caught by the same checks.

**State consistency**: The `initialized` flag correctly distinguishes stored `decimals = 0` from uninitialized storage. Storage is only written on `Initial` outcome (line 119-121), ensuring the TOFU value is immutable once set. The `decimalsForToken` function correctly delegates to `decimalsForTokenReadOnly` for the read logic before conditionally writing.

**Custom errors**: The library uses the custom error `TokenDecimalsReadFailure` (no string reverts). The non-safe variants (`decimalsForTokenReadOnly`, `decimalsForToken`) never revert and instead return outcome enums, which is the intended design.

**Gas forwarding**: The `staticcall(gas(), ...)` forwards all available gas, which is appropriate for a read-only call to an unknown token contract. There is no risk of the callee consuming all gas maliciously because `staticcall` cannot modify state, and if it runs out of gas, `success` will be false and the `ReadFailure` path is taken.
