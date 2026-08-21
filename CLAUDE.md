# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Solidity library implementing Trust On First Use (TOFU) for ERC20 token decimals. Reads `decimals()` once, stores the result, and detects inconsistency on subsequent reads. Deployed as a singleton via the Zoltu deterministic factory across all supported chains (Arbitrum, Base, Flare, Polygon).

## Build & Test Commands

```bash
# Build
forge build

# Run all tests (requires SEPOLIA_RPC_URL env var for fork tests)
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

Fork tests require `SEPOLIA_RPC_URL` set to a Sepolia endpoint. Many tests fork in their constructor via `vm.createSelectFork`. `LibTOFUTokenDecimals.prod.t.sol` and `LibTOFUTokenDecimals.realTokens.t.sol` instead use the named `[rpc_endpoints]` aliases in `foundry.toml`, which read `<NETWORK>_RPC_URL`.

### Why Sepolia and not mainnet

The forking `LibTOFUTokenDecimals` suites assert only that `deployZoltu` places the singleton at the pinned `TOFU_DECIMALS_DEPLOYMENT` and that `ensureDeployed` then finds it; every token in their bodies is a synthetic `makeAddr` driven by `vm.mockCall`/`vm.etch`. None of them reads chain-specific state, so nothing in what they assert selects a network. Zoltu deploys via `CREATE2` with a zero salt from a factory whose bytecode is identical on every chain, so the pinned address is chain-independent by construction and cannot discriminate either.

What the assertions do impose is a precondition: the singleton address must be **vacant** on the forked chain, or `CREATE2` returns zero and `deployZoltu` reverts `DeployFailed`. That makes the choice a durability question rather than a correctness one. Ethereum mainnet is a plausible future deploy target for the singleton — Rain adds supported chains periodically — and the day it ships there these suites would break permanently. Sepolia is not and will not be a production deploy target, so the precondition holds indefinitely.

Historically this was `ETH_RPC_URL`, which rainix bound to the Sepolia-era `CI_DEPLOY_SEPOLIA_RPC_URL` secret: a name that read as mainnet but resolved to a testnet, and eventually to an empty string. Naming the network explicitly is what stops that drift recurring (rainlanguage/rainix#340, this repo's #34).

## Architecture

Three layers, from lowest to highest:

1. **`LibTOFUTokenDecimalsImplementation`** (`src/lib/`) — Core logic. Takes a `mapping(address => TOFUTokenDecimalsResult)` storage ref as parameter. Uses inline assembly with `staticcall` to read `decimals()`. Returns a `TOFUOutcome` enum (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`). Does not own storage.

2. **`TOFUTokenDecimals`** (`src/concrete/`) — Minimal deployable contract. Owns the storage mapping. Delegates all logic to `LibTOFUTokenDecimalsImplementation`. Uses exact solc version (`=0.8.25`) and deterministic bytecode settings for reproducible Zoltu deployment.

3. **`LibTOFUTokenDecimals`** (`src/lib/`) — Caller convenience library. Hard-codes the deployed singleton address and expected codehash. Callers import this to interact with the singleton as if it were an internal library.

The interface and shared types (`TOFUTokenDecimalsResult`, `TOFUOutcome`, `TokenDecimalsReadFailure`) live in `src/interface/ITOFUTokenDecimals.sol`.

The deploy script (`script/Deploy.sol`) uses `LibRainDeploy.deployAndBroadcastToSupportedNetworks` to deploy the `TOFUTokenDecimals` singleton via the Zoltu factory across all supported chains. It requires the `DEPLOYMENT_KEY` environment variable. CI runs it via manual `workflow_dispatch` only.

## Key Design Constraints

- **Bytecode determinism is critical**: `bytecode_hash = "none"`, `cbor_metadata = false`, exact solc `=0.8.25`, `evm_version = "cancun"`, optimizer at 1M runs. Changing any of these breaks the deployed address.
- **`initialized` flag**: The `TOFUTokenDecimalsResult` struct uses a boolean to distinguish stored `0` decimals from uninitialized storage.
- All `.sol` files must have the DCL-1.0 SPDX license identifier header.

## Testing Conventions

- Test files follow `ContractName.functionName.t.sol` naming
- Fuzz tests use `uint8` inputs for decimals values
- `vm.mockCall` to mock `decimals()` return values
- `vm.etch` with `hex"fd"` (revert opcode) to test failure paths
- `LibTOFUTokenDecimalsImplementation` tests use local state (no fork); most `LibTOFUTokenDecimals` tests fork via `SEPOLIA_RPC_URL` and deploy via Zoltu (pure compile-time checks like `testExpectedCreationCode` do not)

## Dependencies

Managed as git submodules:
- `forge-std` — Foundry test framework
- `rain.deploy` — Rain deterministic deployment utilities (Zoltu factory)
- `rain.extrospection` — Bytecode introspection (metamorphic detection, CBOR metadata, opcode scanning)

Nix flake provides the development environment; CI runs all tasks as `nix develop -c <task>`.
