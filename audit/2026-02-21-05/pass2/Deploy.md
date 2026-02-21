# Pass 2 -- Test Coverage: `script/Deploy.sol`

**Auditor:** A01
**Date:** 2026-02-21
**Source file:** `script/Deploy.sol` (33 lines)

## Source File Summary

`Deploy` is a Forge `Script` contract with a single external function `run()`. It:

1. Reads `DEPLOYMENT_KEY` from the environment via `vm.envUint`.
2. Calls `LibRainDeploy.deployAndBroadcastToSupportedNetworks` with:
   - The list of supported networks from `LibRainDeploy.supportedNetworks()`
   - The deployer private key
   - `TOFUTokenDecimals` creation code
   - The contract path string literal
   - The expected singleton address from `LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT`
   - The expected code hash from `LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH`
   - An empty `address[]` for dependencies

## Evidence of Reading

### Source file (`script/Deploy.sol`)

- 33 lines total, single contract `Deploy is Script`, single function `run()`.
- Imports: `Script` (forge-std), `LibRainDeploy` (rain.deploy), `TOFUTokenDecimals` (concrete), `LibTOFUTokenDecimals` (lib).
- `run()` reads `DEPLOYMENT_KEY` env var, then delegates to `LibRainDeploy.deployAndBroadcastToSupportedNetworks` passing hardcoded constants from the library.

### Test search

- **No test file exists for `Deploy.sol`.** No file matching `Deploy*.t.sol` or `*Deploy*.t.sol` was found under `test/`.
- No `test/script/` directory exists.
- Grep for `Deploy.run`, `Deploy.sol`, `script/Deploy`, `new Deploy`, `DEPLOYMENT_KEY`, `deployAndBroadcast`, or `supportedNetworks` in the `test/` directory returned zero matches for the Deploy script itself.

### Related indirect coverage

Several test files in `test/src/lib/` exercise deployment-adjacent logic, but none test the `Deploy` script:

- `LibTOFUTokenDecimals.t.sol` -- tests `deployZoltu` (not `deployAndBroadcastToSupportedNetworks`), validates the deployed address matches `TOFU_DECIMALS_DEPLOYMENT`, checks creation code and code hash constants, and tests `ensureDeployed` revert paths.
- Multiple test files use `LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode)` in their constructors to set up a forked singleton, which exercises the underlying Zoltu mechanism but not the multi-network broadcast script.

## Findings

### A01-001 -- No test file for `script/Deploy.sol` [LOW]

**Description:** There is no test file exercising the `Deploy` contract or its `run()` function. The expected naming convention would be `test/script/Deploy.run.t.sol` or similar. No directory `test/script/` exists at all.

**Impact:** The deploy script itself is never validated in CI. While the underlying primitives (Zoltu deploy, creation code, expected address, expected code hash) are well-tested individually in `LibTOFUTokenDecimals.t.sol`, the composition of these primitives in `Deploy.run()` is not tested. Specifically:

1. **The `DEPLOYMENT_KEY` env-var read** -- untested. A typo in the env var name would only be caught at deploy time.
2. **The `contractPath` string literal** (`"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"`) -- untested. This is passed to Etherscan verification. An incorrect value would cause verification to fail silently on all networks.
3. **The empty dependencies array** (`new address[](0)`) -- untested. If dependencies were added later but not reflected in the script, there would be no test to catch the omission.
4. **The wiring of constants** (e.g., passing `TOFU_DECIMALS_DEPLOYMENT` as `expectedAddress` and `TOFU_DECIMALS_EXPECTED_CODE_HASH` as `expectedCodeHash`) is not tested end-to-end through the script entry point.

**Mitigation:** This is classified as LOW because:
- Deploy scripts are inherently difficult to test in CI (they require private keys and multi-network RPC access).
- The constituent parts (creation code, address, code hash) are individually tested with strong assertions in `LibTOFUTokenDecimals.t.sol`.
- The script delegates all non-trivial logic to `LibRainDeploy`, which is an external dependency and presumably tested in its own repository.
- The script is run infrequently and manually with human oversight.

A dry-run test using `vm.envUint` mocking or a fork-based simulation could add confidence, but the risk of the untested composition layer is low given the existing indirect coverage.

### A01-002 -- No test for `contractPath` string correctness [INFO]

**Description:** The string `"src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals"` is hardcoded in `Deploy.sol` and used for Etherscan source verification. There is no automated check that this path accurately corresponds to the compiled contract. If the source file were renamed or the contract name changed, this string would silently become stale, causing verification failures on all four networks.

**Impact:** Verification-only issue; no on-chain impact. Would only manifest as failed Etherscan verification after deployment.

**Mitigation:** A static assertion or compile-time test could validate that this path resolves correctly.

## Coverage Summary

| Item | Covered | Notes |
|------|---------|-------|
| `Deploy.run()` function | No | No test file exists |
| `DEPLOYMENT_KEY` env read | No | Not exercised in tests |
| `contractPath` string literal | No | No validation of string correctness |
| Empty dependencies array | No | Not verified in tests |
| Constant wiring (address, code hash) | Indirect | Tested individually in `LibTOFUTokenDecimals.t.sol` but not through `Deploy.run()` |
| Underlying `deployZoltu` | Yes | Tested in `LibTOFUTokenDecimals.t.sol:testDeployAddress()` |
| Creation code correctness | Yes | Tested in `LibTOFUTokenDecimals.t.sol:testExpectedCreationCode()` |
| Code hash correctness | Yes | Tested in `LibTOFUTokenDecimals.t.sol:testExpectedCodeHash()` |
| Deploy address correctness | Yes | Tested in `LibTOFUTokenDecimals.t.sol:testDeployAddress()` |
