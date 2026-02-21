# Audit: Test Coverage for `script/Deploy.sol`

**Auditor:** A05
**Pass:** 2 (Test Coverage)
**Date:** 2026-02-21

## Source File

`/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/script/Deploy.sol`

### Contract and Functions

| Line | Item |
|------|------|
| 15 | `contract Deploy is Script` |
| 19 | `function run() external` |

The `run()` function (lines 19-32) is the sole function. It reads `DEPLOYMENT_KEY` from the environment, then calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with the following arguments:
- `type(TOFUTokenDecimals).creationCode`
- The Zoltu-deterministic source path string
- `address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)`
- `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH`
- An empty address array

### Test Files Found

No dedicated test files exist for `Deploy.sol`. There are no files matching `test/**/Deploy*` or `test/script/**`.

Seven test files reference "deploy" but none import or test the `Deploy` script itself. They test the underlying deployment constants and mechanisms:

- `test/src/lib/LibTOFUTokenDecimals.t.sol` -- tests `TOFU_DECIMALS_DEPLOYMENT` address, `TOFU_DECIMALS_EXPECTED_CODE_HASH`, `TOFU_DECIMALS_EXPECTED_CREATION_CODE`, `ensureDeployed()` success and revert paths
- `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol` -- deploys via `LibRainDeploy.deployZoltu` in constructor, asserts address matches `TOFU_DECIMALS_DEPLOYMENT`
- `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` -- same pattern
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` -- same pattern
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` -- same pattern
- `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol` -- deploys via Zoltu and asserts address
- `test/src/concrete/TOFUTokenDecimals.immutability.t.sol` -- tests immutability of deployed bytecode

## Coverage Analysis

The `Deploy.run()` script itself has zero direct test coverage. However, every constant and value it passes to `LibRainDeploy.deployAndBroadcastToSupportedNetworks` is independently verified:

1. **`type(TOFUTokenDecimals).creationCode`** -- tested in `testExpectedCreationCode()` (LibTOFUTokenDecimals.t.sol, line 67) which asserts it equals `TOFU_DECIMALS_EXPECTED_CREATION_CODE`.
2. **`TOFU_DECIMALS_DEPLOYMENT` address** -- tested in `testDeployAddress()` (LibTOFUTokenDecimals.t.sol, line 33) and in every other test file constructor that deploys via Zoltu and asserts the resulting address matches the constant.
3. **`TOFU_DECIMALS_EXPECTED_CODE_HASH`** -- tested in `testExpectedCodeHash()` (LibTOFUTokenDecimals.t.sol, line 61) and indirectly via `ensureDeployed()` which checks the codehash.
4. **`deployAndBroadcastToSupportedNetworks`** -- this is third-party library code from `rain.deploy`; testing it is that library's responsibility.

## Findings

No findings. The deploy script is conventionally untested in Foundry projects -- it is a thin orchestration wrapper around `LibRainDeploy` that passes hardcoded constants, and every one of those constants has thorough independent test coverage. The `run()` function contains no branching logic, no computation, and no values that are not already validated by the existing test suite. Adding a direct test for `Deploy.run()` would require mocking the `DEPLOYMENT_KEY` environment variable and the multi-network broadcast infrastructure, providing minimal additional assurance beyond what already exists.
