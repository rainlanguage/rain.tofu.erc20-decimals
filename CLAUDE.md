# CLAUDE.md

Solidity library implementing Trust On First Use (TOFU) for ERC20 token decimals: read `decimals()` once, store it, detect inconsistency on later reads. Deployed as a Zoltu singleton.

## Fork tests use `SEPOLIA_RPC_URL`

The forking `LibTOFUTokenDecimals` suites need `SEPOLIA_RPC_URL`. (`prod.t.sol` and `realTokens.t.sol` instead use the `[rpc_endpoints]` aliases in `foundry.toml`.)

Sepolia is a deliberate ruling, not a default. Those suites assert only that `deployZoltu` lands the singleton on the pinned `TOFU_DECIMALS_DEPLOYMENT` and that `ensureDeployed` finds it; every token in their bodies is a synthetic `makeAddr` with `vm.mockCall`/`vm.etch`. Nothing reads chain-specific state, and the pin is `CREATE2`-with-zero-salt from a factory whose bytecode is identical on every chain — so it is chain-independent and cannot select a network. They pass identically on Sepolia and mainnet.

What the assertions *do* require is that the singleton address be **vacant** on the forked chain, or `CREATE2` returns zero and `deployZoltu` reverts `DeployFailed`. That makes this a durability call: mainnet is a plausible future deploy target, and the day the singleton ships there these suites break permanently. Sepolia never will be. Do not "fix" this by pointing them at `ETHEREUM_RPC_URL`.

This was previously `ETH_RPC_URL`, which rainix bound to the Sepolia-era `CI_DEPLOY_SEPOLIA_RPC_URL` — a name that read as mainnet, resolved to a testnet, then to an empty string, silently. Name the network explicitly (rainlanguage/rainix#340, #34).

## Bytecode determinism is load-bearing

`bytecode_hash = "none"`, `cbor_metadata = false`, solc `=0.8.25`, `evm_version = "cancun"`, optimizer at 1M runs. Changing **any** of these changes the creation code, which changes the Zoltu address, which breaks every already-deployed singleton and the pinned constants in `LibTOFUTokenDecimals`. This is not recoverable by redeploying.

## Other rulings

- `TOFUTokenDecimalsResult.initialized` is a bool specifically so a stored `0` decimals is distinguishable from uninitialized storage. Do not "optimize" it away.
- `safeDecimalsForTokenReadOnly` cannot detect inconsistency before initialization — there is no stored value to compare against. Callers needing TOFU protection must call `decimalsForToken` at least once first.
- All `.sol` files need the DCL-1.0 SPDX header (`reuse lint` enforces).
