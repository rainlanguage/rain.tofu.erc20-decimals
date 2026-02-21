# Pass 1: Security Audit -- LibTOFUTokenDecimals.sol

**Auditor**: A04
**File**: `src/lib/LibTOFUTokenDecimals.sol` (84 lines)
**Date**: 2026-02-19

---

## 1. Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Constants

| Name | Type | Line | Value |
|------|------|------|-------|
| `TOFU_DECIMALS_DEPLOYMENT` | `ITOFUTokenDecimals` | 28-29 | `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `bytes32` | 35-36 | `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41` |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `bytes` | 42-43 | Large hex literal (init bytecode) |

### Errors

| Name | Line |
|------|------|
| `TOFUTokenDecimalsNotDeployed(address deployedAddress)` | 23 |

### Events

None defined.

### Functions

| Name | Visibility | Mutability | Line |
|------|-----------|------------|------|
| `ensureDeployed()` | `internal` | `view` | 48 |
| `decimalsForTokenReadOnly(address token)` | `internal` | `view` | 58 |
| `decimalsForToken(address token)` | `internal` | (state-changing) | 66 |
| `safeDecimalsForToken(address token)` | `internal` | (state-changing) | 74 |
| `safeDecimalsForTokenReadOnly(address token)` | `internal` | `view` | 80 |

### Imports

- `TOFUOutcome`, `ITOFUTokenDecimals`, `TokenDecimalsReadFailure` from `../interface/ITOFUTokenDecimals.sol` (line 5)

---

## 2. Security Findings

### A04-1 [INFO] Hardcoded address and codehash are validated by tests

**Location**: Lines 28-29 (address), lines 35-36 (codehash)

**Description**: The hardcoded singleton address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` and codehash `0x1de7d717...` are verified by three independent tests in `test/src/lib/LibTOFUTokenDecimals.t.sol`:

1. `testDeployAddress()` (line 31): Forks mainnet, deploys `TOFUTokenDecimals` via Zoltu, and asserts the resulting address matches `TOFU_DECIMALS_DEPLOYMENT`. Then calls `ensureDeployed()` which also validates the codehash.
2. `testExpectedCodeHash()` (line 40): Deploys a fresh `TOFUTokenDecimals` via `new` and asserts its codehash matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.
3. `testExpectedCreationCode()` (line 46): Asserts `type(TOFUTokenDecimals).creationCode` matches `TOFU_DECIMALS_EXPECTED_CREATION_CODE`.

These tests form a complete chain: creation code is correct, creation code deployed via Zoltu produces the expected address, and the deployed contract has the expected codehash. The constants are consistent with each other and with the compiled contract.

No issue found. The constants are adequately validated.

---

### A04-2 [INFO] ensureDeployed() provides adequate protection

**Location**: Lines 48-55

**Description**: `ensureDeployed()` checks two conditions:
1. `address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0` -- guards against the singleton not being deployed on the current chain.
2. `address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` -- guards against a different contract being present at that address.

Both conditions together ensure that code exists and it is the exact expected bytecode. The function uses a custom error (`TOFUTokenDecimalsNotDeployed`) rather than a string revert, which is correct.

`ensureDeployed()` is called at the start of every public-facing function in the library (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`), so no function can silently proceed with a missing or wrong singleton.

Test `testEnsureDeployedRevert()` confirms it reverts when nothing is deployed. Test `testEnsureDeployedRevertWrongCodeHash()` confirms it reverts when code exists but has the wrong codehash. Both negative paths are covered.

No issue found. The guard is comprehensive.

---

### A04-3 [LOW] No reentrancy risk but external calls propagate reverts without wrapping

**Location**: Lines 62, 70, 76, 82

**Description**: All four functions make external calls to the singleton contract via Solidity's high-level interface (`TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)`, etc.). These external calls:

- Are to a known, codehash-verified contract (not arbitrary).
- The singleton itself only performs `staticcall` to read `decimals()` from the token (see `LibTOFUTokenDecimalsImplementation.sol` line 50). For `decimalsForToken`, it additionally writes to its own storage mapping. There is no ETH transfer, no callback to the caller, and no delegatecall.
- The `decimalsForTokenReadOnly` and `safeDecimalsForTokenReadOnly` functions are `view`, so no state mutation can occur.
- The `decimalsForToken` function does mutate state (storing decimals in the singleton), but this only happens on the `Initial` outcome path, and the token's `decimals()` call uses `staticcall`, preventing the token from triggering reentrancy during the read.

If the singleton reverts (e.g., due to `TokenDecimalsReadFailure` in the `safe` variants), that revert will propagate directly to the caller. This is the intended behavior -- the caller sees the singleton's custom error, not a generic failure.

No reentrancy risk identified. The architecture cleanly separates read-only (`staticcall` to token) from storage writes (to singleton's own mapping), with no callbacks possible.

---

### A04-4 [INFO] Malicious contract deployment at expected address is infeasible

**Location**: Lines 28-29, 35-36

**Description**: The Zoltu deterministic factory (`0x7A0D94F55792C434d74a40883C6ed8545E406D12` per `LibRainDeploy`) derives the deployment address from the creation code itself (keccak256-based). The deployed address is a function of:
- The Zoltu factory address (fixed)
- The creation code (which would need to be identical to produce the same address)

For a malicious actor to place a contract at `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389`:
1. They would need to find creation code that, when deployed via Zoltu, produces this exact address. This requires a keccak256 preimage collision, which is computationally infeasible.
2. Even if they somehow deployed different creation code at the same address via another mechanism (e.g., CREATE2 from a different factory), the `ensureDeployed()` codehash check would reject it unless the runtime bytecode also matched exactly.

The combination of deterministic address derivation AND runtime codehash verification makes address spoofing infeasible. An attacker would need to produce different runtime bytecode with an identical keccak256 hash (a collision), which is not computationally feasible.

No issue found.

---

### A04-5 [INFO] Creation code constant is verified to produce the expected address

**Location**: Lines 42-43

**Description**: The `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant is a large hex literal containing the exact init bytecode. The test `testExpectedCreationCode()` in `LibTOFUTokenDecimals.t.sol` (line 46) asserts:

```solidity
assertEq(type(TOFUTokenDecimals).creationCode, LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CREATION_CODE);
```

This confirms the constant matches the compiler output. The test `testDeployAddress()` then deploys this creation code via `LibRainDeploy.deployZoltu()` and confirms the address matches `TOFU_DECIMALS_DEPLOYMENT`. Together, these tests prove the full chain from creation code to deployed address.

The `foundry.toml` uses deterministic compilation settings (`bytecode_hash = "none"`, `cbor_metadata = false`, `solc = "0.8.25"`, `optimizer_runs = 1000000`), ensuring the creation code is reproducible across builds.

No issue found. The creation code constant is properly validated.

---

### A04-6 [INFO] No string reverts found

**Location**: Entire file

**Description**: The file contains exactly one revert statement (line 53), which uses the custom error `TOFUTokenDecimalsNotDeployed(address)`. No `revert("...")` string-based reverts are present anywhere in the file or in any of the other `src/` files (confirmed via grep). This is consistent with the project's design constraint.

No issue found.

---

### A04-7 [LOW] TOCTOU gap between ensureDeployed() and the subsequent external call

**Location**: Lines 48-55, then 62/70/76/82

**Description**: Each function calls `ensureDeployed()` to verify the singleton, then makes an external call to it. In theory, between these two operations (within the same transaction), the code at the singleton address could change if `SELFDESTRUCT` were involved. However:

1. Since the Dencun upgrade (EIP-6780), `SELFDESTRUCT` only deletes contract storage/code within the same transaction that created the contract. An already-deployed singleton cannot be destroyed mid-transaction by an external call.
2. Even pre-Dencun, the singleton contract `TOFUTokenDecimals` contains no `SELFDESTRUCT` opcode (it delegates only to library functions with no self-destruct path), so this is a non-issue regardless.
3. Both the `ensureDeployed()` check and the external call happen within a single transaction, so cross-block TOCTOU does not apply -- the code is guaranteed stable within a single EVM execution context.

This is a theoretical concern that does not apply in practice. No action needed.

---

### A04-8 [INFO] Gas forwarding on external calls is safe

**Location**: Lines 62, 70, 76, 82

**Description**: The high-level Solidity calls (`TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)`, etc.) forward all available gas minus the EIP-150 1/64th reservation. Since the singleton performs a `staticcall(gas(), token, ...)` internally, an extremely gas-limited context could theoretically cause the inner `staticcall` to fail. However, this would simply result in a `ReadFailure` outcome (or revert in the `safe` variants), which is the correct and safe behavior. There is no risk of partial execution or inconsistent state from gas exhaustion.

No issue found.

---

### A04-9 [INFO] Return value handling is correct

**Location**: Lines 62, 70, 76, 82

**Description**: All four functions correctly propagate the return values from the singleton. The `slither-disable-next-line unused-return` comments on `decimalsForTokenReadOnly` (line 61) and `decimalsForToken` (line 69) are accurate -- these are false positives because the returns are used (they are the function's own return values).

The `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` functions return a single `uint8`, which is the pattern from the interface. If the singleton reverts (due to `Inconsistent` or `ReadFailure`), the revert propagates to the caller.

No issue found.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A04-1 | INFO | Hardcoded address and codehash are validated by tests |
| A04-2 | INFO | ensureDeployed() provides adequate protection |
| A04-3 | LOW | No reentrancy risk; external calls propagate reverts correctly |
| A04-4 | INFO | Malicious contract deployment at expected address is infeasible |
| A04-5 | INFO | Creation code constant is verified to produce the expected address |
| A04-6 | INFO | No string reverts found |
| A04-7 | LOW | TOCTOU gap between ensureDeployed() and external call is theoretical only |
| A04-8 | INFO | Gas forwarding on external calls is safe |
| A04-9 | INFO | Return value handling is correct |

**Overall Assessment**: The `LibTOFUTokenDecimals` library is well-designed from a security perspective. No CRITICAL, HIGH, or MEDIUM findings were identified. The two LOW findings are both theoretical concerns that do not apply in practice given the contract architecture and post-Dencun EVM semantics. The `ensureDeployed()` guard is comprehensive (checking both code existence and codehash), all error handling uses custom errors, and the test suite provides strong coverage of the hardcoded constants and negative paths.
