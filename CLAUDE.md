# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Solidity library implementing Trust On First Use (TOFU) for ERC20 token decimals. Reads `decimals()` once, stores the result, and detects inconsistency on subsequent reads. Deployed as a singleton via the Zoltu deterministic factory at `0x8b40CC241745D8eAB9396EDC12401Cfa1D5940c9` across all supported chains (Arbitrum, Base, Flare, Polygon).

## Build & Test Commands

```bash
# Build
forge build

# Run all tests (requires ETH_RPC_URL env var for fork tests)
forge test

# Run a single test file
forge test --match-path test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol

# Run a single test function
forge test --match-test testDecimalsForTokenInitial

# Run via Nix (matches CI exactly)
nix develop -c rainix-sol-test

# Static analysis
nix develop -c rainix-sol-static

# License/legal compliance
nix develop -c rainix-sol-legal
```

Tests require `ETH_RPC_URL` set to an Ethereum mainnet RPC endpoint. Many tests fork mainnet in their constructor via `vm.createSelectFork`.

## Architecture

Three layers, from lowest to highest:

1. **`LibTOFUTokenDecimalsImplementation`** (`src/lib/`) — Core logic. Takes a `mapping(address => TOFUTokenDecimalsResult)` storage ref as parameter. Uses inline assembly with `staticcall` to read `decimals()`. Returns a `TOFUOutcome` enum (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`). Does not own storage.

2. **`TOFUTokenDecimals`** (`src/concrete/`) — Minimal deployable contract. Owns the storage mapping. Delegates all logic to `LibTOFUTokenDecimalsImplementation`. Uses exact solc version (`=0.8.25`) and deterministic bytecode settings for reproducible Zoltu deployment.

3. **`LibTOFUTokenDecimals`** (`src/lib/`) — Caller convenience library. Hard-codes the deployed singleton address and expected codehash. Callers import this to interact with the singleton as if it were an internal library.

The interface and shared types (`TOFUTokenDecimalsResult`, `TOFUOutcome`, `TokenDecimalsReadFailure`) live in `src/interface/ITOFUTokenDecimals.sol`.

## Key Design Constraints

- **Bytecode determinism is critical**: `bytecode_hash = "none"`, `cbor_metadata = false`, exact solc `=0.8.25`, optimizer at 1M runs. Changing any of these breaks the deployed address.
- **`initialized` flag**: The `TOFUTokenDecimalsResult` struct uses a boolean to distinguish stored `0` decimals from uninitialized storage.
- All `.sol` files must have the DCL-1.0 SPDX license identifier header.

## Testing Conventions

- One test file per function: `ContractName.functionName.t.sol`
- Fuzz tests use `uint8` inputs for decimals values
- `vm.mockCall` to mock `decimals()` return values
- `vm.etch` with `hex"fd"` (revert opcode) to test failure paths
- `LibTOFUTokenDecimalsImplementation` tests use local state (no fork); most `LibTOFUTokenDecimals` tests fork mainnet and deploy via Zoltu (pure compile-time checks like `testExpectedCreationCode` do not)

## Dependencies

Managed as git submodules:
- `forge-std` — Foundry test framework
- `rain.deploy` — Rain deterministic deployment utilities (Zoltu factory)

Nix flake provides the development environment; CI runs all tasks as `nix develop -c <task>`.
