# Audit Pass 1 (Security) -- LibTOFUTokenDecimals.sol

**Auditor:** A03
**File:** `src/lib/LibTOFUTokenDecimals.sol`
**Date:** 2026-02-21

## Evidence of Thorough Reading

**Library name:** `LibTOFUTokenDecimals` (line 21)

**Functions:**
| Function | Line | Visibility |
|---|---|---|
| `ensureDeployed()` | 51 | `internal view` |
| `decimalsForTokenReadOnly(address)` | 66 | `internal view` |
| `decimalsForToken(address)` | 79 | `internal` (state-changing) |
| `safeDecimalsForToken(address)` | 89 | `internal` (state-changing) |
| `safeDecimalsForTokenReadOnly(address)` | 97 | `internal view` |

**Types/Errors/Constants defined in this file:**
- **Error:** `TOFUTokenDecimalsNotDeployed(address expectedAddress)` (line 24)
- **Constant:** `TOFU_DECIMALS_DEPLOYMENT` -- `ITOFUTokenDecimals` at `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` (line 29-30)
- **Constant:** `TOFU_DECIMALS_EXPECTED_CODE_HASH` -- `bytes32` value `0x1de7d717...` (line 36-37)
- **Constant:** `TOFU_DECIMALS_EXPECTED_CREATION_CODE` -- `bytes` containing full init bytecode (line 44-45)

**Imports:**
- `TOFUOutcome` and `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

## Security Checklist Review

### 1. Hardcoded address and codehash verification in `ensureDeployed()` -- can this be bypassed?

The `ensureDeployed()` function (lines 51-58) checks two conditions:
1. `address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0` -- ensures code exists at the address.
2. `address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` -- ensures the deployed code matches the expected hash.

Both constants are `constant` (compile-time), so they cannot be modified at runtime. The codehash check prevents a different contract from being accepted at the same address. The test suite (`LibTOFUTokenDecimals.t.sol`) verifies that:
- `ensureDeployed()` reverts when no code is deployed (`testEnsureDeployedRevert`, line 71).
- `ensureDeployed()` reverts when wrong code is deployed (`testEnsureDeployedRevertWrongCodeHash`, line 81).
- The Zoltu-deployed address matches the constant (`testDeployAddress`, line 33).
- The codehash of a freshly deployed instance matches the constant (`testExpectedCodeHash`, line 61).
- The singleton is not metamorphic (`testNotMetamorphic`, line 47) -- no SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, or CREATE2 opcodes in reachable code.
- No CBOR metadata is present (`testNoCBORMetadata`, line 56).

**Conclusion:** The `ensureDeployed()` guard cannot be bypassed. The combination of deterministic deployment, codehash verification, and metamorphic/CBOR checks is thorough.

### 2. Access controls

This is a library with `internal` functions only. There are no external entry points and no privileged roles. Access control is inherited from whatever contract imports this library. No issues.

### 3. Error handling (what happens if the external call reverts?)

Each function calls `ensureDeployed()` first, which reverts with `TOFUTokenDecimalsNotDeployed` if the singleton is absent or has wrong code. If `ensureDeployed()` passes, the external call to the singleton is made via the Solidity interface (`TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)` etc.). If the singleton's internal `staticcall` to the token reverts, that is handled inside the implementation library -- it returns `TOFUOutcome.ReadFailure` rather than bubbling up the revert. The `safe*` variants then revert with the custom `TokenDecimalsReadFailure` error. No unhandled revert paths exist.

### 4. Reentrancy risk from delegating to an external contract

The library makes external calls to the singleton contract at `TOFU_DECIMALS_DEPLOYMENT`. There is a theoretical TOCTOU (time-of-check-time-of-use) concern: `ensureDeployed()` checks the codehash, then the subsequent call goes to that address. However, the test suite (`testNotMetamorphic`) confirms the singleton bytecode contains no SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, or CREATE2 opcodes in reachable code, so the code at that address cannot change between the check and the call.

Regarding reentrancy from the token contract: the singleton uses `staticcall` to read `decimals()` from the token (verified in `LibTOFUTokenDecimalsImplementation.sol` line 47), which prevents any state modifications during that call. The only state write is in `decimalsForToken` when `tofuOutcome == TOFUOutcome.Initial`, which occurs after the `staticcall` completes. There is no reentrancy vector.

### 5. Custom errors only (no `revert("...")`)

Confirmed. The only revert in this file uses the custom error `TOFUTokenDecimalsNotDeployed` (line 56). A grep across the entire `src/` directory confirmed zero instances of `revert("..."` or `require(`. All error paths use custom errors exclusively.

## Findings

No findings.
