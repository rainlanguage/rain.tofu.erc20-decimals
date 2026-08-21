# CLAUDE.md

Solidity library implementing Trust On First Use (TOFU) for ERC20 token decimals: read `decimals()` once, store it, detect inconsistency on later reads. Deployed as a Zoltu singleton.

## The singleton is NOT built here

This is the library half. The concrete `TOFUTokenDecimals`, the deploy script and the deploy-pin record live in [rain.tofu.erc20-decimals.deploy](https://github.com/rainlanguage/rain.tofu.erc20-decimals.deploy). Nothing here compiles the singleton bytecode, so this repo's compiler settings no longer move the deployed address — the deploy repo's do.

`LibTOFUTokenDecimals` still carries `TOFU_DECIMALS_DEPLOYMENT`, `TOFU_DECIMALS_EXPECTED_CODE_HASH` and `TOFU_DECIMALS_EXPECTED_CREATION_CODE`, because a caller of the singleton needs them and must not need a deploy repo to get them. They are asserted against real compiler output over there, in `test/src/lib/LibTOFUTokenDecimals.t.sol`. Never edit them here to make something pass: a mismatch means the creation code moved, which breaks every already-deployed singleton and is not recoverable by redeploying.

## `LibTOFUTokenDecimals` is revert-path only here, deliberately

Its happy paths went to the deploy repo with the concrete. `ensureDeployed` pins the codehash, so the only thing that can sit at the pinned address and be accepted is the real singleton bytecode — no `vm.etch` scaffold satisfies it. Do not "restore coverage" with a mock. `LibTOFUTokenDecimalsImplementation` is the logic and is fully covered here.

## Other rulings

- `TOFUTokenDecimalsResult.initialized` is a bool specifically so a stored `0` decimals is distinguishable from uninitialized storage. Do not "optimize" it away.
- `safeDecimalsForTokenReadOnly` cannot detect inconsistency before initialization — there is no stored value to compare against. Callers needing TOFU protection must call `decimalsForToken` at least once first.
- All `.sol` files need the DCL-1.0 SPDX header (`reuse lint` enforces).
