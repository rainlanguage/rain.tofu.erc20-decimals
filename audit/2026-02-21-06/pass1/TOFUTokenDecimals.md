# Pass 1: Security --- TOFUTokenDecimals.sol (Agent A02)

## Evidence of Reading

**Contract name**: `TOFUTokenDecimals` (concrete contract, inherits `ITOFUTokenDecimals`)

**Functions** (all in `TOFUTokenDecimals.sol`):
- `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` -- line 19
- `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` -- line 25
- `safeDecimalsForToken(address token) external returns (uint8)` -- line 31
- `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` -- line 36

**Types, errors, and constants** (defined in the interface and implementation, used by this contract):
- `struct TOFUTokenDecimalsResult { bool initialized; uint8 tokenDecimals; }` -- ITOFUTokenDecimals.sol line 13
- `enum TOFUOutcome { Initial, Consistent, Inconsistent, ReadFailure }` -- ITOFUTokenDecimals.sol line 19
- `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` -- ITOFUTokenDecimals.sol line 52
- `bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567` -- LibTOFUTokenDecimalsImplementation.sol line 15

**State variables** (in `TOFUTokenDecimals.sol`):
- `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals` -- line 16

## Findings

No findings.

### Rationale

The `TOFUTokenDecimals.sol` concrete contract is a thin delegation layer. Each of the four external functions simply passes the storage mapping and the `token` argument through to the corresponding function in `LibTOFUTokenDecimalsImplementation`. The analysis below covers each area of concern:

**Input validation**: The only input is `address token`, which is passed directly to `staticcall` in the implementation library. There is no need for zero-address validation here because calling `decimals()` on `address(0)` will simply produce a `ReadFailure` outcome (the staticcall will fail), which is correctly handled by the caller. No truncation or ABI-decoding issues exist since the address type is inherently 20 bytes.

**Reentrancy**: The `decimalsForToken` function writes storage only on `TOFUOutcome.Initial`, and it writes after reading the external call result. This is technically a read-then-write pattern, but the external call uses `staticcall` (not `call`), meaning the target token contract cannot modify state. The `staticcall` eliminates reentrancy risk from the token call. The contract has no payable functions and no ETH handling. All four external functions either delegate to `view` (read-only) variants using `staticcall` or to `decimalsForToken` which itself uses `staticcall` internally. No reentrancy concern exists.

**Arithmetic safety**: The only arithmetic is the `gt(readDecimals, 0xff)` check in the assembly block of the implementation library, which correctly bounds the value before casting to `uint8`. No overflow or underflow is possible.

**Access control**: The contract is intentionally permissionless -- any address can call any function. This is by design: it is a singleton that stores token decimals on first use. There is no privileged role, no owner, no upgradeability. The TOFU model means only the first write for each token matters, and subsequent calls never overwrite the stored value. This is correct.

**Assembly memory safety**: The assembly block in `decimalsForTokenReadOnly` (in the implementation library) uses the scratch space at memory offset 0 for both the outgoing calldata (4 bytes for the selector) and incoming returndata (32 bytes). This is safe because Solidity's scratch space (0x00-0x3f) is explicitly designated for short-lived use, and the `"memory-safe"` annotation is appropriate here. The `returndatasize()` check ensures at least 32 bytes were returned before reading `mload(0)`.

**Custom errors**: The contract uses `error TokenDecimalsReadFailure(address, TOFUOutcome)` which is a proper custom error. No string reverts are used anywhere in the contract or its implementation library.

**Bytecode determinism**: The concrete contract uses `pragma solidity =0.8.25` (exact version pin) at line 3, while the interface and implementation library use `^0.8.25`. This is correct -- the concrete contract that gets deployed via Zoltu must have deterministic bytecode, which requires an exact pragma. The `foundry.toml` confirms `bytecode_hash = "none"`, `cbor_metadata = false`, `evm_version = "cancun"`, and `optimizer_runs = 1000000`. All determinism constraints are satisfied.

**Storage layout**: The single mapping `sTOFUTokenDecimals` occupies slot 0. The `TOFUTokenDecimalsResult` struct packs `bool initialized` (1 byte) and `uint8 tokenDecimals` (1 byte) into a single 32-byte storage slot per token address. The `initialized` flag correctly distinguishes a stored value of 0 decimals from uninitialized storage.
