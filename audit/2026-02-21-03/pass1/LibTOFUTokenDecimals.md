# Pass 1: Security -- LibTOFUTokenDecimals.sol

Agent: A04

## Evidence of Thorough Reading

### src/lib/LibTOFUTokenDecimals.sol

- **Library**: `LibTOFUTokenDecimals` (line 21)
- **Functions**:
  - `ensureDeployed()` -- `internal view`, line 49. Checks `code.length == 0` and `codehash` mismatch; reverts with `TOFUTokenDecimalsNotDeployed`.
  - `decimalsForTokenReadOnly(address token)` -- `internal view`, line 64. Returns `(TOFUOutcome, uint8)`. Calls `ensureDeployed()` then delegates to singleton.
  - `decimalsForToken(address token)` -- `internal` (state-changing), line 77. Returns `(TOFUOutcome, uint8)`. Calls `ensureDeployed()` then delegates to singleton.
  - `safeDecimalsForToken(address token)` -- `internal` (state-changing), line 87. Returns `uint8`. Calls `ensureDeployed()` then delegates to singleton.
  - `safeDecimalsForTokenReadOnly(address token)` -- `internal view`, line 95. Returns `uint8`. Calls `ensureDeployed()` then delegates to singleton.
- **Error**: `TOFUTokenDecimalsNotDeployed(address deployedAddress)` -- line 24
- **Constants**:
  - `TOFU_DECIMALS_DEPLOYMENT` -- `ITOFUTokenDecimals` constant at `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` (lines 29-30)
  - `TOFU_DECIMALS_EXPECTED_CODE_HASH` -- `bytes32` constant `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41` (lines 36-37)
  - `TOFU_DECIMALS_EXPECTED_CREATION_CODE` -- `bytes` constant, full init bytecode hex literal (lines 43-44)
- **Imports**: `TOFUOutcome` and `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

### src/interface/ITOFUTokenDecimals.sol

- **Struct**: `TOFUTokenDecimalsResult` (line 13) -- fields: `bool initialized`, `uint8 tokenDecimals`
- **Enum**: `TOFUOutcome` (line 19) -- values: `Initial` (0), `Consistent` (1), `Inconsistent` (2), `ReadFailure` (3)
- **Error**: `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 33)
- **Interface**: `ITOFUTokenDecimals` (line 53) with four external functions:
  - `decimalsForTokenReadOnly(address) external view returns (TOFUOutcome, uint8)` (line 67)
  - `decimalsForToken(address) external returns (TOFUOutcome, uint8)` (line 77)
  - `safeDecimalsForToken(address) external returns (uint8)` (line 83)
  - `safeDecimalsForTokenReadOnly(address) external view returns (uint8)` (line 91)

## Findings

### A04-1: TOCTOU gap between ensureDeployed() and external call is mitigated by design [INFO]

**Location**: All four wrapper functions (lines 64-98)

**Description**: Each function calls `ensureDeployed()` to verify the singleton exists with the expected codehash, then makes a separate high-level external call to the singleton. In theory, the contract at the singleton address could change between these two operations within the same transaction (e.g., if `SELFDESTRUCT` were triggered in a preceding call within a multicall or batch).

**Mitigation**: The singleton contract (`TOFUTokenDecimals`) is tested for absence of metamorphic opcodes via `testNotMetamorphic()` in `LibTOFUTokenDecimalsTest.t.sol` (line 47), which uses `LibExtrospectMetamorphic.checkNotMetamorphic()` to confirm the runtime bytecode contains no reachable `SELFDESTRUCT`, `DELEGATECALL`, `CALLCODE`, `CREATE`, or `CREATE2` opcodes. Additionally, `testNoCBORMetadata()` (line 56) ensures no CBOR metadata is present, preventing metadata-based address reuse. Since the singleton cannot self-destruct or delegate to arbitrary code, the TOCTOU window cannot be exploited in practice. Furthermore, post-Cancun `SELFDESTRUCT` no longer removes code within the same transaction anyway (EIP-6780 limits destruction to the creating transaction only).

**Severity**: INFO -- no actionable risk, well-mitigated by design.

### A04-2: Hardcoded address and codehash correctness relies on test-time verification [INFO]

**Location**: Lines 29-30 (`TOFU_DECIMALS_DEPLOYMENT`), lines 36-37 (`TOFU_DECIMALS_EXPECTED_CODE_HASH`), lines 43-44 (`TOFU_DECIMALS_EXPECTED_CREATION_CODE`)

**Description**: The three hardcoded constants (address, codehash, creation code) form a chain of trust: creation code deployed via Zoltu factory produces the deterministic address, and the resulting runtime bytecode has the expected codehash. These values are compile-time constants with no on-chain derivation. If any of the three were incorrect, the library would either revert on `ensureDeployed()` (wrong codehash or no deployment) or point to the wrong contract (wrong address but matching codehash -- extremely unlikely given the Zoltu deterministic scheme).

**Verification**: The test suite establishes the full chain:
1. `testExpectedCreationCode()` (line 67 in test file) asserts `type(TOFUTokenDecimals).creationCode == TOFU_DECIMALS_EXPECTED_CREATION_CODE`, proving the creation code constant matches the compiler output.
2. `testDeployAddress()` (line 33 in test file) deploys that creation code via Zoltu on a fork and asserts the resulting address equals `TOFU_DECIMALS_DEPLOYMENT`. Then calls `ensureDeployed()`, which also validates the codehash.
3. `testExpectedCodeHash()` (line 61 in test file) deploys `TOFUTokenDecimals` via `new` and asserts its codehash matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.

Together these tests prove creation code -> deployed address -> codehash consistency. This is sound.

**Severity**: INFO -- no actionable risk, but the correctness of the hardcoded values is a critical invariant that depends entirely on these tests passing.

### A04-3: ensureDeployed() guard is called consistently across all functions [INFO]

**Location**: Lines 65, 78, 88, 96

**Description**: All four public-facing wrapper functions call `ensureDeployed()` as their first operation before making the external call. This is verified by review. There is no code path that bypasses `ensureDeployed()` to reach the external call. The guard prevents silent failures: if the singleton is not deployed on a given chain, or if a different contract occupies the address, the library will revert with a clear custom error (`TOFUTokenDecimalsNotDeployed`) rather than returning garbage data.

The `ensureDeployed()` check has two conditions joined by `||`:
1. `address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0` -- no code at the address.
2. `address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` -- wrong code at the address.

Both branches are tested (`testEnsureDeployedRevert` for condition 1, `testEnsureDeployedRevertWrongCodeHash` for condition 2).

Note: Condition 1 is technically redundant because an empty account has `codehash == keccak256("")` which would fail condition 2 anyway. However, the explicit `code.length == 0` check provides a clearer semantic signal and marginally different gas behavior. This is fine.

**Severity**: INFO -- no issues found.

### A04-4: External call error propagation is correct via high-level Solidity calls [INFO]

**Location**: Lines 68, 81, 89, 97

**Description**: All four external calls use Solidity's high-level call syntax (e.g., `TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)`), which automatically:
1. Checks that the target has code (redundant here due to `ensureDeployed()`, but provides defense-in-depth).
2. Reverts the entire transaction if the external call reverts, bubbling up the revert data (preserving the original custom error).
3. ABI-decodes the return value and reverts if decoding fails (e.g., if the return data is malformed).

This means errors from the singleton (such as `TokenDecimalsReadFailure`) are properly propagated to the caller. There are no silent failures possible: if the singleton reverts, the library function reverts with the same error. If the singleton returns unexpected data, the ABI decoder reverts.

**Severity**: INFO -- no issues found; error propagation is correct.

### A04-5: Codehash check cannot be spoofed via metamorphic contracts [INFO]

**Location**: Lines 50-55 (`ensureDeployed()`), test file lines 42-59

**Description**: The `codehash` check in `ensureDeployed()` verifies that the runtime bytecode at the singleton address matches the expected hash. For this to be spoofed, an attacker would need to deploy different code that produces the same `keccak256` hash as the legitimate singleton -- a keccak256 preimage attack, which is computationally infeasible.

The more realistic attack vector for codehash spoofing is metamorphic contracts: deploying code that later replaces itself (via `SELFDESTRUCT` + redeploy, `DELEGATECALL` to mutable logic, etc.). This is mitigated by:
1. `testNotMetamorphic()` verifying no metamorphic opcodes exist in the singleton's runtime bytecode.
2. `testNoCBORMetadata()` ensuring no CBOR metadata that could enable address-reuse tricks.
3. Zoltu deterministic factory using `CREATE2` with the creation code as part of the salt derivation, meaning different creation code produces a different address.
4. EIP-6780 (Cancun) limiting `SELFDESTRUCT` to the creating transaction, making post-deployment self-destruction impossible.

**Severity**: INFO -- no actionable risk.

### A04-6: No string reverts -- custom errors used correctly [INFO]

**Location**: Line 24 (error definition), line 54 (revert usage)

**Description**: The library defines one custom error (`TOFUTokenDecimalsNotDeployed`) and uses it for all revert conditions within `ensureDeployed()`. There are no `require()` statements with string messages or `revert("...")` string reverts anywhere in the library. The singleton's custom error (`TokenDecimalsReadFailure`) is also a custom error type. This is consistent with the project's convention and gas-efficient.

**Severity**: INFO -- compliant with the project's custom-error-only convention.
