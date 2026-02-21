# Pass 2: Test Coverage — `script/Deploy.sol`

**Date:** 2026-02-21
**Auditor:** A01 (automated agent)
**Target:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/script/Deploy.sol`

---

## 1. Evidence of Thorough Reading

### 1.1 `script/Deploy.sol`

**Contract:** `Deploy` (inherits `forge-std/Script.sol`)

| Function | Line | Description |
|----------|------|-------------|
| `run()` | 19 | Entry point. Reads `DEPLOYMENT_KEY` env var via `vm.envUint`, then calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with the `TOFUTokenDecimals` creation code, the hard-coded expected deployment address (`LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT`), the expected code hash (`LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH`), and an empty dependencies array. |

The contract has exactly one externally callable entry point: `run()`. It is 34 lines total, with the meaningful logic spanning lines 19–32.

### 1.2 `lib/rain.deploy/src/lib/LibRainDeploy.sol` (called by Deploy.sol)

Reviewed to understand the full call graph of `run()`.

| Function | Line | Description |
|----------|------|-------------|
| `deployZoltu(bytes)` | 48 | Low-level `call` to the Zoltu factory. Reverts with `DeployFailed` on failure or empty code. |
| `supportedNetworks()` | 67 | Returns `["arbitrum", "base", "flare", "polygon"]`. |
| `deployAndBroadcastToSupportedNetworks(...)` | 83 | Iterates networks: checks Zoltu factory exists (`MissingDependency`), checks extra dependencies, then deploys or skips if already deployed, validates address (`UnexpectedDeployedAddress`) and code hash (`UnexpectedDeployedCodeHash`). |

---

## 2. Test File Search Results

### 2.1 Glob searches

- `test/**/Deploy*` — **0 results**
- `test/**/*deploy*` — **0 results**

### 2.2 Grep for "Deploy" across `test/`

No test file imports or references `script/Deploy.sol` or the `Deploy` contract. The grep hits that appeared all relate to `LibRainDeploy.deployZoltu` (the low-level Zoltu helper) used in test setup, not to the `Deploy` script itself.

### 2.3 Complete test file inventory

```
test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol
test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol
test/src/concrete/TOFUTokenDecimals.immutability.t.sol
test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol
test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol
test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol
test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol
test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol
test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol
test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol
test/src/lib/LibTOFUTokenDecimals.t.sol
test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol
test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol
test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol
test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol
test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol
```

None of these files exercise `script/Deploy.sol`.

---

## 3. Coverage Gaps and Findings

### Finding 1 — MEDIUM: No test file exists for `script/Deploy.sol`

**Classification:** MEDIUM

**Detail:** There is no test file (`test/**/Deploy*` or `test/**/*Deploy*`) that imports, instantiates, or calls the `Deploy` contract. The `run()` function has zero test coverage.

**Impact:** Regressions in the deploy script — including wrong arguments passed to `LibRainDeploy.deployAndBroadcastToSupportedNetworks`, a stale hardcoded expected address, or a stale code hash — would not be caught by the test suite. The deploy script is the canonical artifact used to publish the singleton on every supported chain.

**Mitigating factors:** The deploy script is intentionally thin: it delegates entirely to `LibRainDeploy` (an upstream library) and the arguments it passes are the same constants (`TOFU_DECIMALS_DEPLOYMENT`, `TOFU_DECIMALS_EXPECTED_CODE_HASH`) already validated by `LibTOFUTokenDecimals.t.sol` tests (`testExpectedCodeHash`, `testDeployAddress`). A full integration test of `run()` itself would require network RPC access and a `DEPLOYMENT_KEY`, which is operationally sensitive. The severity is therefore MEDIUM rather than HIGH.

**Recommendation:** Add a `test/script/Deploy.t.sol` that:
1. Forks a supported test network (e.g. Sepolia, or any network where the Zoltu factory exists).
2. Calls `new Deploy().run()` (with a prank/broadcast wrapper and a deterministic test private key).
3. Asserts the singleton is deployed at the expected address with the correct code hash.

Alternatively, add a `forge script --dry-run` invocation to CI that validates argument construction at least at the compilation level.

---

### Finding 2 — LOW: `run()` function is entirely untested at the unit level

**Classification:** LOW

**Detail:** `Deploy.run()` (line 19) performs two observable operations:
1. `vm.envUint("DEPLOYMENT_KEY")` — reads an environment variable.
2. `LibRainDeploy.deployAndBroadcastToSupportedNetworks(...)` — broadcasts to multiple networks.

Neither operation is tested. Specifically, there is no test that verifies:
- The correct creation code (`type(TOFUTokenDecimals).creationCode`) is passed.
- The correct expected address (`LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT`) is passed.
- The correct expected code hash (`LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH`) is passed.
- The dependencies array is passed as empty (correct, since `TOFUTokenDecimals` has no on-chain dependencies).
- The `contractPath` string literal `"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"` is correct (used only for `forge verify-contract` console output, so wrong value is non-critical but untested).

**Mitigating factors:** The constants being passed are exercised elsewhere in the test suite; the script itself is a thin wrapper. This finding is subordinate to Finding 1.

---

### Finding 3 — LOW: Missing `DEPLOYMENT_KEY` error path not tested

**Classification:** LOW

**Detail:** If `DEPLOYMENT_KEY` is not set in the environment, `vm.envUint("DEPLOYMENT_KEY")` will revert with a Forge VM error. There is no test verifying that this expected failure mode surfaces a clear error message. While this is an operational/usability concern rather than a security one, a smoke test would increase confidence in operator experience.

**Mitigating factors:** This is standard Forge `Script` behavior; the error message from `vm.envUint` is Foundry-native and well-understood. Impact is limited to deploy-time confusion, not production contract behavior.

---

### Finding 4 — INFO: `script/Deploy.sol` is not on the `test/` directory mirror path

**Classification:** INFO

**Detail:** The project follows the convention `test/src/<path>.t.sol` mirroring `src/<path>.sol`. The `script/` directory has no corresponding `test/script/` mirror. This is a structural observation: the absence of `test/script/` means the pattern is incomplete. This is common in Solidity projects where deploy scripts are considered operational artifacts rather than library code, but it is worth documenting.

---

## 4. Summary Table

| # | Severity | Title |
|---|----------|-------|
| 1 | MEDIUM   | No test file exists for `script/Deploy.sol` — `run()` has zero test coverage |
| 2 | LOW      | Individual argument correctness in `run()` is not directly asserted |
| 3 | LOW      | Missing `DEPLOYMENT_KEY` env-var failure path is not tested |
| 4 | INFO     | No `test/script/` mirror directory exists for the `script/` directory |

---

## 5. Positive Observations

- The deploy script is intentionally thin; all logic is delegated to `LibRainDeploy` and the well-tested `LibTOFUTokenDecimals` constants.
- `testExpectedCreationCode` (line 67, `LibTOFUTokenDecimals.t.sol`) verifies the creation code constant is correct.
- `testExpectedCodeHash` (line 61, `LibTOFUTokenDecimals.t.sol`) verifies the code hash constant used in the deploy script is correct.
- `testDeployAddress` (line 33, `LibTOFUTokenDecimals.t.sol`) verifies the deployment address constant matches what Zoltu would actually produce.
- These tests collectively provide indirect assurance that the constants passed in `Deploy.run()` are correct, even though `run()` itself is never invoked in a test.
