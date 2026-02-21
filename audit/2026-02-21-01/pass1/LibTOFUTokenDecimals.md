# Audit Pass 1 (Security) -- LibTOFUTokenDecimals.sol

**Agent ID:** A03
**Date:** 2026-02-21
**File:** `/src/lib/LibTOFUTokenDecimals.sol`

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Functions (with line numbers)

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `ensureDeployed` | 49 | `internal` | `view` |
| `decimalsForTokenReadOnly` | 64 | `internal` | `view` |
| `decimalsForToken` | 77 | `internal` | (non-view, state-changing via external call) |
| `safeDecimalsForToken` | 87 | `internal` | (non-view, state-changing via external call) |
| `safeDecimalsForTokenReadOnly` | 95 | `internal` | `view` |

### Types, Errors, and Constants

**Error:**
- `TOFUTokenDecimalsNotDeployed(address deployedAddress)` (line 24)

**Constants:**
- `TOFU_DECIMALS_DEPLOYMENT` -- `ITOFUTokenDecimals` constant at address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` (line 29-30)
- `TOFU_DECIMALS_EXPECTED_CODE_HASH` -- `bytes32` constant `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41` (line 36-37)
- `TOFU_DECIMALS_EXPECTED_CREATION_CODE` -- `bytes` constant containing the full init bytecode (line 43-44)

### Imports

- `TOFUOutcome` from `"../interface/ITOFUTokenDecimals.sol"` (line 5)
- `ITOFUTokenDecimals` from `"../interface/ITOFUTokenDecimals.sol"` (line 5)

---

## Security Findings

### Finding 1: TOCTOU Gap Between `ensureDeployed()` and External Call

**Severity: LOW**

**Location:** Lines 49-56, and every function that calls `ensureDeployed()` followed by an external call (lines 64-68, 77-81, 87-89, 95-97).

**Description:** Each public-facing function follows the pattern of calling `ensureDeployed()` (which checks `code.length > 0` and `codehash` match) and then making a separate external call to `TOFU_DECIMALS_DEPLOYMENT`. In theory, the state could change between the `ensureDeployed()` check and the subsequent external call. For example, if the singleton were self-destructable, the code could be removed between the two operations within the same transaction.

**Mitigating factors:** The test suite (`testNotMetamorphic` in `LibTOFUTokenDecimalsTest`) explicitly verifies that the singleton bytecode does not contain any metamorphic opcodes (SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2). This eliminates the practical attack vector. Also, `SELFDESTRUCT` no longer destroys code post-Cancun (EIP-6780), and the bytecode is verified via the codehash constant. The Zoltu factory deployment model with deterministic bytecode further constrains this.

**Recommendation:** No action needed. The existing metamorphic check test is the correct mitigation. The risk is theoretical only given the design constraints.

---

### Finding 2: Hard-coded Address and Code Hash -- Correctness Dependency

**Severity: INFO**

**Location:** Lines 29-30 (`TOFU_DECIMALS_DEPLOYMENT`), lines 36-37 (`TOFU_DECIMALS_EXPECTED_CODE_HASH`), lines 43-44 (`TOFU_DECIMALS_EXPECTED_CREATION_CODE`).

**Description:** The library hard-codes a singleton address, its expected runtime code hash, and its expected creation code. The correctness of the entire system depends on these three constants being mutually consistent and matching the actual deployed contract produced by the Zoltu factory. If any compiler setting changes (solc version, optimizer runs, evm_version, bytecode_hash, cbor_metadata), the constants would need to be regenerated.

**Mitigating factors:** The test suite comprehensively validates all three constants:
- `testDeployAddress` deploys via Zoltu on a fork and asserts the resulting address matches `TOFU_DECIMALS_DEPLOYMENT`.
- `testExpectedCodeHash` deploys locally and asserts the codehash matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.
- `testExpectedCreationCode` asserts `type(TOFUTokenDecimals).creationCode` matches `TOFU_DECIMALS_EXPECTED_CREATION_CODE`.
- `testNoCBORMetadata` verifies no CBOR metadata is present in the runtime bytecode.

These tests would fail if any compiler setting drifted, providing a CI safety net.

**Recommendation:** No action needed. The existing test coverage is thorough and sufficient.

---

### Finding 3: Code Hash Verification Is Sound

**Severity: INFO**

**Location:** Lines 50-55 (`ensureDeployed` function).

**Description:** The `ensureDeployed()` function performs a two-part check: (1) `code.length > 0` ensures code exists, and (2) `codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` ensures the code is the expected contract. This correctly prevents both the case of no deployment and the case of a different contract at the same address. Since the code hash covers the entire runtime bytecode, it cannot be bypassed by deploying different code.

The `code.length == 0` check is technically redundant because an address with no code has a codehash of `keccak256("")` (`0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470`) or `bytes32(0)` (for non-existent accounts per EIP-1052), neither of which would match the expected code hash. However, the redundant check provides a clearer error path and is harmless.

**Recommendation:** The redundancy is acceptable as a defense-in-depth measure. No action needed.

---

### Finding 4: External Call Safety -- Return Data Handling

**Severity: INFO**

**Location:** Lines 68, 81, 89, 97.

**Description:** All four wrapper functions make high-level Solidity calls to the `TOFU_DECIMALS_DEPLOYMENT` contract through the `ITOFUTokenDecimals` interface. High-level calls automatically:
- Revert if the call fails (no silent failure risk).
- ABI-decode the return data according to the interface signature.
- Propagate reverts from the callee (including `TokenDecimalsReadFailure` from the safe variants).

There is no risk of return data being silently ignored or misinterpreted because the Solidity compiler generates the appropriate `returndatacopy` and `returndatasize` checks.

**Recommendation:** No action needed. The high-level call pattern is correct.

---

### Finding 5: No Access Control on Singleton -- By Design

**Severity: INFO**

**Location:** The `TOFUTokenDecimals` concrete contract and how `LibTOFUTokenDecimals` interacts with it.

**Description:** The singleton `TOFUTokenDecimals` contract has no access control. Any address can call `decimalsForToken` to initialize storage for any token. This means an attacker could front-run the first `decimalsForToken` call with a malicious token that returns a crafted decimals value, then change its `decimals()` return value. The TOFU model would then permanently lock in the attacker's initial value.

**Mitigating factors:** This is inherent to the TOFU design. The model explicitly trusts the first read and detects inconsistency on subsequent reads. The `safeDecimalsForToken` variant reverts on inconsistency or read failure, providing callers a safe path. Callers using the raw `decimalsForToken` variant are expected to handle `Inconsistent` and `ReadFailure` outcomes themselves. Additionally, legitimate ERC20 tokens have immutable `decimals()` values, so front-running initialization for a legitimate token would produce the correct value.

**Recommendation:** No action needed. The documentation correctly communicates this design assumption.

---

### Finding 6: Pragma Version Range

**Severity: INFO**

**Location:** Line 3 (`pragma solidity ^0.8.25`).

**Description:** The library uses `^0.8.25`, allowing compilation with any 0.8.x compiler >= 0.8.25. This is appropriate for a library that callers import, as it gives callers flexibility. The concrete contract (`TOFUTokenDecimals.sol`) correctly uses `=0.8.25` to ensure bytecode determinism. There is no security issue here; the distinction is correct and intentional.

**Recommendation:** No action needed.

---

### Finding 7: Gas Forwarding in External Calls

**Severity: INFO**

**Location:** Lines 68, 81, 89, 97.

**Description:** The high-level Solidity calls forward all available gas (minus the 1/64th EIP-150 retention) to the singleton. Inside the singleton, `LibTOFUTokenDecimalsImplementation` uses `gas()` in its assembly `staticcall` to the token contract, forwarding gas again. This is standard and correct behavior. There is no risk of gas griefing because:
- The singleton is a known, trusted contract (verified by codehash).
- The token's `decimals()` call uses `staticcall`, preventing state changes.
- Return data size is bounded (read exactly 0x20 bytes).

**Recommendation:** No action needed.

---

### Finding 8: Creation Code Constant Validation

**Severity: INFO**

**Location:** Lines 43-44 (`TOFU_DECIMALS_EXPECTED_CREATION_CODE`).

**Description:** The library includes the full expected creation code as a constant. This serves as a reference for deployers and is validated by `testExpectedCreationCode`. Notably, this constant is not used at runtime by any function in the library -- it exists purely for documentation and test verification purposes. It cannot be exploited.

**Recommendation:** No action needed.

---

## Summary Table

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | TOCTOU gap between `ensureDeployed()` and external call | LOW | Mitigated by metamorphic check test and EIP-6780 (Cancun) |
| 2 | Hard-coded address/codehash correctness dependency | INFO | Validated by comprehensive test suite |
| 3 | Code hash verification is sound (redundant `code.length` check) | INFO | Defense-in-depth, no issue |
| 4 | External call return data handling via high-level calls | INFO | Correct by construction |
| 5 | No access control on singleton (TOFU design) | INFO | By design, documented |
| 6 | Pragma version range `^0.8.25` vs `=0.8.25` | INFO | Correct distinction between library and concrete contract |
| 7 | Gas forwarding in external calls | INFO | Standard, no risk with verified singleton |
| 8 | Creation code constant is not used at runtime | INFO | Test-only reference, no risk |

**Overall Assessment:** The `LibTOFUTokenDecimals` library is well-designed and does not contain any CRITICAL, HIGH, or MEDIUM severity issues. The single LOW finding (TOCTOU gap) is already mitigated by the metamorphic opcode check in the test suite and by EVM-level guarantees post-Cancun. The code hash verification in `ensureDeployed()` is correctly implemented and provides strong protection against deployment misconfiguration or address collision. All external calls use high-level Solidity patterns with proper ABI decoding. The hard-coded constants are validated by a comprehensive test suite that would catch any drift from compiler settings.
