# Pass 1: Security -- LibTOFUTokenDecimals.sol (Agent A03)

## Evidence of Reading

**Library name**: `LibTOFUTokenDecimals` (line 21)

**Functions (with line numbers)**:
- `ensureDeployed()` -- line 51 (internal view)
- `decimalsForTokenReadOnly(address token)` -- line 66 (internal view, returns `(TOFUOutcome, uint8)`)
- `decimalsForToken(address token)` -- line 79 (internal, returns `(TOFUOutcome, uint8)`)
- `safeDecimalsForToken(address token)` -- line 89 (internal, returns `uint8`)
- `safeDecimalsForTokenReadOnly(address token)` -- line 97 (internal view, returns `uint8`)

**Types, errors, and constants**:
- **Error**: `TOFUTokenDecimalsNotDeployed(address expectedAddress)` -- line 24
- **Constant**: `TOFU_DECIMALS_DEPLOYMENT` (type `ITOFUTokenDecimals`) -- line 29, value `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`
- **Constant**: `TOFU_DECIMALS_EXPECTED_CODE_HASH` (type `bytes32`) -- line 36, value `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41`
- **Constant**: `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (type `bytes`) -- line 44, hex literal (1099 bytes of init bytecode)

**Imports**:
- `TOFUOutcome` and `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

## Findings

### Analysis Summary

I performed a thorough security review of `LibTOFUTokenDecimals.sol`, covering the following areas:

**1. Input validation**: All four public-facing functions accept an `address token` parameter and forward it to the external singleton. The `ensureDeployed()` guard runs before every external call. No additional input validation is needed; the singleton contract handles token address validation via its own logic (staticcall that naturally handles zero/EOA addresses as read failures).

**2. Reentrancy risks**: The library makes external calls to the singleton (`TOFU_DECIMALS_DEPLOYMENT`), but the singleton address is hardcoded and its codehash is verified before every call via `ensureDeployed()`. The singleton itself is verified to be non-metamorphic (tested via `testNotMetamorphic`). The `decimalsForTokenReadOnly` and `safeDecimalsForTokenReadOnly` functions are `view`, and the state-modifying functions (`decimalsForToken`, `safeDecimalsForToken`) delegate to the singleton which only writes on `Initial` outcome. The singleton's `decimalsForToken` uses `staticcall` to read the token's `decimals()`, which cannot modify state. No reentrancy vector exists.

**3. Arithmetic safety**: No arithmetic operations are performed in this library. All arithmetic/casting occurs in `LibTOFUTokenDecimalsImplementation`.

**4. Access control**: The library functions are `internal`, meaning they can only be called by contracts that import and use the library. The singleton contract itself has no access control (intentionally permissionless). This is appropriate for the design.

**5. Hardcoded address and codehash consistency**: The hardcoded constants (`TOFU_DECIMALS_DEPLOYMENT`, `TOFU_DECIMALS_EXPECTED_CODE_HASH`, `TOFU_DECIMALS_EXPECTED_CREATION_CODE`) are verified in tests:
   - `testDeployAddress()` deploys via Zoltu and checks the resulting address matches `TOFU_DECIMALS_DEPLOYMENT`.
   - `testExpectedCodeHash()` deploys `TOFUTokenDecimals` and asserts `codehash == TOFU_DECIMALS_EXPECTED_CODE_HASH`.
   - `testExpectedCreationCode()` asserts `type(TOFUTokenDecimals).creationCode == TOFU_DECIMALS_EXPECTED_CREATION_CODE`.
   - The foundry.toml configuration (`bytecode_hash = "none"`, `cbor_metadata = false`, `solc = "0.8.25"`, `evm_version = "cancun"`, optimizer at 1M runs) ensures deterministic bytecode.
   All three constants are mutually consistent and verified at test time.

**6. TOCTOU vulnerabilities**: There is a theoretical TOCTOU gap between `ensureDeployed()` (which checks the codehash) and the subsequent external call to the singleton. However, this is mitigated by:
   - The singleton is deployed via the Zoltu deterministic factory (no `SELFDESTRUCT` in the factory).
   - The singleton bytecode is verified to contain no metamorphic opcodes (`testNotMetamorphic`).
   - The singleton has no CBOR metadata that could be exploited (`testNoCBORMetadata`).
   - After Ethereum's Dencun upgrade (EIP-6780), `SELFDESTRUCT` only sends ETH and no longer removes code (except in the same transaction as creation), making this gap entirely eliminated on Cancun+ chains.
   No practical TOCTOU vulnerability exists.

**7. Custom errors**: The library uses only the custom error `TOFUTokenDecimalsNotDeployed(address)` (line 24). No string reverts are used. The singleton's errors (`TokenDecimalsReadFailure`) are also custom errors defined in the interface. Compliant.

**8. Return value handling**: All external calls to the singleton use explicit return value capture. The `slither-disable-next-line unused-return` annotations are correctly placed -- the return values are in fact used (they are returned to the caller). These are false positive suppression comments.

**9. Pragma version**: The library uses `^0.8.25` (line 3), which is appropriate for a library that will be compiled alongside consumer contracts. The concrete contract uses `=0.8.25` for bytecode determinism. This is consistent and correct.

No findings.
