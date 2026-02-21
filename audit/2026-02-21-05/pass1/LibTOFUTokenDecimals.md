# Audit: `src/lib/LibTOFUTokenDecimals.sol`

**Auditor:** A04
**Pass:** 1 (Security)
**Audit ID:** 2026-02-21-05
**Date:** 2026-02-21

---

## Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Functions (with line numbers)

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `ensureDeployed()` | 51 | `internal` | `view` |
| `decimalsForTokenReadOnly(address)` | 66 | `internal` | `view` |
| `decimalsForToken(address)` | 79 | `internal` | (state-changing) |
| `safeDecimalsForToken(address)` | 89 | `internal` | (state-changing) |
| `safeDecimalsForTokenReadOnly(address)` | 97 | `internal` | `view` |

### Types, Errors, and Constants

| Name | Kind | Line |
|---|---|---|
| `TOFUTokenDecimalsNotDeployed(address)` | `error` | 24 |
| `TOFU_DECIMALS_DEPLOYMENT` | `constant ITOFUTokenDecimals` | 29-30 |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `constant bytes32` | 36-37 |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `constant bytes` | 44-45 |

### Imports

- `TOFUOutcome` from `../interface/ITOFUTokenDecimals.sol` (line 5)
- `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

---

## Security Findings

### A04-01: `ensureDeployed()` Guard Is Robust -- No Issues Found

**Severity:** INFO

**Description:** The `ensureDeployed()` function (lines 51-58) performs two checks:

1. `address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0` -- confirms code exists at the address.
2. `address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` -- confirms the runtime bytecode hash matches.

Both checks are combined with OR, so either failure causes a revert. This guards against both undeployed states and wrong-code-at-address scenarios. The check uses `codehash` (the keccak256 of the runtime bytecode), which is the correct Solidity built-in for this purpose and returns `bytes32(0)` for EOAs/empty accounts (handled by the first check).

**Conclusion:** No issues. The guard is correctly implemented.

---

### A04-02: TOCTOU Window Between `ensureDeployed()` and External Call

**Severity:** LOW

**Description:** Each of the four wrapper functions calls `ensureDeployed()` and then immediately makes an external call to the singleton contract at the hardcoded address. In theory, between the `ensureDeployed()` check and the external call, the code at the singleton address could change. However, this would require:

1. The singleton to `SELFDESTRUCT` itself within the same transaction (and even post-EIP-6780/Cancun, `SELFDESTRUCT` only destroys within the creating transaction).
2. Or some other mechanism to mutate the code at that address mid-transaction.

The test file `LibTOFUTokenDecimals.t.sol` includes `testNotMetamorphic()` (line 47) which verifies the singleton bytecode contains no reachable metamorphic opcodes (`SELFDESTRUCT`, `DELEGATECALL`, `CALLCODE`, `CREATE`, `CREATE2`). This eliminates the TOCTOU concern because the singleton cannot self-destruct or delegate to code that changes behavior.

**Conclusion:** The TOCTOU gap is theoretical only, and the `testNotMetamorphic()` test provides a concrete compile-time guarantee that the singleton is immutable. No action needed.

---

### A04-03: Codehash Collision Feasibility

**Severity:** INFO

**Description:** The `ensureDeployed()` guard checks `codehash` against a hardcoded keccak256 value (`0x1de7d717...`). For an attacker to bypass this guard, they would need to deploy different runtime bytecode at the singleton address that produces the same keccak256 hash. This requires a keccak256 second-preimage attack, which has a security level of 256 bits -- computationally infeasible with current and foreseeable technology.

Additionally, the address itself is deterministic (derived from the Zoltu factory address and the creation code). To deploy to the same address, the attacker would need the same creation code, which would produce the same runtime bytecode and thus the same codehash anyway. An attacker would need to find different creation code that both:
- Produces the same CREATE2 address (keccak256 collision on the creation code)
- Results in runtime bytecode with the same codehash (keccak256 collision on runtime bytecode)

This is a double collision requirement, making it doubly infeasible.

**Conclusion:** No risk. The codehash verification is cryptographically sound.

---

### A04-04: Singleton Address Front-Running / Manipulation

**Severity:** INFO

**Description:** The singleton is deployed via the Zoltu deterministic factory at address `0x7A0D94F55792C434d74a40883C6ed8545E406D12`. The Zoltu factory uses a `CREATE` opcode internally (not CREATE2 with a user-supplied salt), where the deployed address depends on the factory's address and its internal nonce. Once deployed, the address is fixed. Key observations:

1. **Pre-deployment front-running:** Before the singleton is deployed, an attacker could potentially front-run the deployment transaction. However, the Zoltu factory uses a nonce-based scheme, and the resulting address depends on the factory nonce at deployment time. If an attacker front-runs, they would consume the nonce and deploy their own code at the target address -- but the `codehash` check in `ensureDeployed()` would reject it unless it matches. The legitimate deployment would then land at a different address. This would require the hardcoded address in the library to be updated.

2. **Post-deployment:** Once deployed, the address is occupied and cannot be redeployed to. Combined with the metamorphic check (A04-02), the code is immutable.

3. **Practical consideration:** The library embeds both the address AND the codehash. Even if an attacker managed to deploy to the address first, the codehash would not match (unless they deployed the exact same code, which is not an attack).

**Conclusion:** The deployment address is hardcoded and verified by codehash. Front-running the deployment transaction could cause deployment to fail, but cannot result in a malicious singleton being accepted by the library. At worst, it would be a denial-of-service requiring redeployment with an updated address.

---

### A04-05: Reentrancy Concerns with External Calls to the Singleton

**Severity:** INFO

**Description:** The four wrapper functions make external calls to the singleton:

- `decimalsForTokenReadOnly` (line 70): calls `TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token)` -- `view` function, no state changes.
- `decimalsForToken` (line 83): calls `TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)` -- state-changing (writes storage on `Initial` outcome).
- `safeDecimalsForToken` (line 91): calls `TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForToken(token)` -- state-changing.
- `safeDecimalsForTokenReadOnly` (line 99): calls `TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForTokenReadOnly(token)` -- `view` function.

The singleton contract (`TOFUTokenDecimals.sol`) delegates to `LibTOFUTokenDecimalsImplementation`, which internally makes a `staticcall` to the target token's `decimals()` function. Since `staticcall` prevents state changes, a malicious token cannot use the `decimals()` callback to reenter the singleton in a way that modifies the singleton's storage during the `staticcall` itself.

However, for the state-changing paths (`decimalsForToken` and `safeDecimalsForToken`), the singleton reads decimals via `staticcall`, then writes to storage if `Initial`. The `staticcall` to the token completes before the storage write, so there is no reentrancy window where a malicious token could manipulate the singleton's state. The flow is: read token (staticcall) -> check stored value -> write if needed -> return. There is no external call after the storage write.

From the caller's perspective, the caller makes an external call to the singleton, and the singleton calls back to a token. If the caller has state that depends on the singleton's return value, the caller should follow checks-effects-interactions. But this is the caller's responsibility, not the library's.

**Conclusion:** No reentrancy risk in the library or singleton. The `staticcall` to the token prevents state-changing callbacks, and the storage write occurs after the external call completes.

---

### A04-06: No Input Validation on `token` Address Parameter

**Severity:** LOW

**Description:** None of the four wrapper functions validate the `token` parameter. Passing `address(0)` or an EOA (externally owned account with no code) will result in the `staticcall` to `decimals()` failing (returning 0 bytes), which the implementation correctly handles as a `ReadFailure` outcome. The `safe` variants would revert with `TokenDecimalsReadFailure`.

This is acceptable behavior -- the library correctly propagates the failure rather than silently accepting bad input. Callers using the non-safe variants must handle the `ReadFailure` outcome appropriately.

**Conclusion:** The lack of explicit address validation is by design. The `ReadFailure` outcome correctly covers these edge cases.

---

### A04-07: Hardcoded Address and Codehash Must Be Maintained in Sync

**Severity:** LOW

**Description:** The library hardcodes three related constants:

- `TOFU_DECIMALS_DEPLOYMENT` (line 29): the singleton address
- `TOFU_DECIMALS_EXPECTED_CODE_HASH` (line 36): the expected runtime codehash
- `TOFU_DECIMALS_EXPECTED_CREATION_CODE` (line 44): the expected creation code

These three values must be consistent: the creation code, when deployed via Zoltu, must produce a contract at the specified address with the specified codehash. The test suite (`LibTOFUTokenDecimals.t.sol`) includes:

- `testDeployAddress()` (line 33): verifies the Zoltu deployment produces the hardcoded address.
- `testExpectedCodeHash()` (line 61): verifies the deployed code has the expected codehash.
- `testExpectedCreationCode()` (line 67): verifies the creation code constant matches the compiler output.

These tests ensure consistency. However, if any build parameter changes (solc version, optimizer settings, EVM version, etc.), all three constants would need to be updated simultaneously.

**Conclusion:** The test suite adequately guards consistency. The risk is operational (developer error during updates), not a runtime security issue.

---

### A04-08: `ensureDeployed()` Uses Solidity High-Level Code Access -- No Memory Safety Concerns

**Severity:** INFO

**Description:** The `ensureDeployed()` function uses `address(...).code.length` and `address(...).codehash`, which are high-level Solidity expressions that do not involve inline assembly or manual memory management. There are no memory safety concerns.

The four wrapper functions use standard Solidity ABI-encoded external calls (`TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token)`, etc.), which are handled by the Solidity compiler's call encoding/decoding. Return values are properly typed and no manual ABI decoding is performed.

**Conclusion:** No memory safety issues in this file. All operations use safe, high-level Solidity constructs.

---

### A04-09: View Functions Correctly Marked

**Severity:** INFO

**Description:** The function mutability modifiers are correctly applied:

- `ensureDeployed()` is `view` -- correct, only reads `code.length` and `codehash`.
- `decimalsForTokenReadOnly()` is `view` -- correct, delegates to the singleton's `view` function.
- `decimalsForToken()` has no `view`/`pure` -- correct, the singleton writes storage on `Initial`.
- `safeDecimalsForToken()` has no `view`/`pure` -- correct, delegates to state-changing singleton function.
- `safeDecimalsForTokenReadOnly()` is `view` -- correct, delegates to the singleton's `view` function.

**Conclusion:** All mutability modifiers are correct.

---

### A04-10: External Call Failure Handling

**Severity:** INFO

**Description:** The external calls to the singleton (lines 70, 83, 91, 99) use standard Solidity high-level calls. If the singleton reverts (e.g., `TokenDecimalsReadFailure` from `safeDecimalsForToken`), the revert will bubble up to the caller. If the singleton returns unexpected data, Solidity's ABI decoder will revert.

The `ensureDeployed()` guard runs before every call, ensuring the singleton exists and has the correct code. This prevents the scenario where a call to an empty address would succeed with empty return data (which Solidity would misinterpret as default zero values).

**Conclusion:** Error handling is correct. The `ensureDeployed()` pre-check and Solidity's built-in ABI decoding provide adequate protection.

---

## Summary

| ID | Severity | Title |
|---|---|---|
| A04-01 | INFO | `ensureDeployed()` guard is robust |
| A04-02 | LOW | TOCTOU window between `ensureDeployed()` and external call (mitigated by metamorphic check) |
| A04-03 | INFO | Codehash collision is computationally infeasible |
| A04-04 | INFO | Singleton address front-running is impractical and codehash-verified |
| A04-05 | INFO | No reentrancy risk due to `staticcall` in implementation |
| A04-06 | LOW | No explicit `token` address validation (by design, `ReadFailure` covers it) |
| A04-07 | LOW | Hardcoded constants must be maintained in sync (guarded by tests) |
| A04-08 | INFO | No memory safety concerns -- all high-level Solidity |
| A04-09 | INFO | View function modifiers are correctly applied |
| A04-10 | INFO | External call failure handling is correct |

**Overall Assessment:** The library is well-designed with defense-in-depth. The `ensureDeployed()` guard provides strong protection against misconfiguration and malicious interference. The combination of deterministic deployment, codehash verification, and metamorphic-free bytecode verification in the test suite makes the hardcoded singleton address trustworthy. No CRITICAL or HIGH severity findings were identified. The three LOW findings are all mitigated by design or by the test suite and do not require code changes.
