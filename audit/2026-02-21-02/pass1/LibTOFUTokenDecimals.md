# Pass 1: Security Audit -- LibTOFUTokenDecimals.sol

**Auditor**: A04
**File**: `src/lib/LibTOFUTokenDecimals.sol` (99 lines)
**Date**: 2026-02-21

---

## 1. Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Imports

- `TOFUOutcome`, `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

### Errors

| Name | Line |
|------|------|
| `TOFUTokenDecimalsNotDeployed(address deployedAddress)` | 24 |

### Constants

| Name | Type | Line | Value |
|------|------|------|-------|
| `TOFU_DECIMALS_DEPLOYMENT` | `ITOFUTokenDecimals` | 29-30 | `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `bytes32` | 36-37 | `0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41` |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `bytes` | 43-44 | Large hex literal (init bytecode, 1099 bytes) |

### Functions

| Name | Visibility | Mutability | Line |
|------|-----------|------------|------|
| `ensureDeployed()` | `internal` | `view` | 49 |
| `decimalsForTokenReadOnly(address token)` | `internal` | `view` | 64 |
| `decimalsForToken(address token)` | `internal` | (state-changing) | 77 |
| `safeDecimalsForToken(address token)` | `internal` | (state-changing) | 87 |
| `safeDecimalsForTokenReadOnly(address token)` | `internal` | `view` | 95 |

### Events

None defined.

---

## 2. Security Findings

### A04-1 [LOW] Singleton has no access control -- any caller can front-run initialization for any token

**Location**: Lines 77-82 (via the external call to the singleton `TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)`)

**Description**: The `TOFUTokenDecimals` singleton contract (at `src/concrete/TOFUTokenDecimals.sol`) has no access control on any of its four external functions. The `decimalsForToken` function stores the token's decimals on first use and is callable by anyone.

This means the stored TOFU value for any token is set by whichever caller first invokes `decimalsForToken` on the singleton for that token. In the normal case, this is fine -- `decimals()` is read directly from the token contract via `staticcall`, so the stored value reflects the token's actual return value at that moment. However, this design means:

1. An attacker cannot directly inject a false value (since the singleton reads `decimals()` from the actual token contract).
2. But if a token's `decimals()` function is temporarily returning a wrong value (e.g., during a proxy upgrade, misconfigured initialization, or through a compromised proxy admin), an attacker could call `decimalsForToken` on the singleton during that window, permanently locking in the incorrect value for all future users of the singleton.

**Impact**: Low. This is inherent to the TOFU design and the singleton pattern. The token's `decimals()` must actually return the wrong value for this attack to work, and the singleton correctly reads from the token contract. The concern is the permanence of the stored value once set. Callers who use `safeDecimalsForToken` are protected against post-initialization changes (they get a revert on inconsistency), but the initially-stored value cannot be corrected.

**Mitigation**: This is a design-level property of the TOFU approach and is documented in the interface comments. Callers should be aware that the first `decimalsForToken` call for any token permanently sets the stored value in the shared singleton. No code change is recommended.

---

### A04-2 [INFO] TOCTOU gap between ensureDeployed() and external call is mitigated by metamorphic checks

**Location**: Lines 49-56 (`ensureDeployed`), then lines 68, 81, 89, 97 (external calls)

**Description**: Each function calls `ensureDeployed()` to verify the singleton exists with the expected codehash, then makes a separate external call to the singleton. In theory, the contract at the singleton address could change between these two operations.

However, this TOCTOU gap is comprehensively mitigated:

1. **Post-Dencun EVM (EIP-6780)**: `SELFDESTRUCT` only deletes a contract's code/storage when called in the same transaction that created the contract. The singleton is pre-deployed, so it cannot be destroyed mid-transaction.
2. **Metamorphic check**: The test `testNotMetamorphic()` in `LibTOFUTokenDecimals.t.sol` (line 47) uses `LibExtrospectMetamorphic.checkNotMetamorphic()` to scan the singleton's runtime bytecode for reachable `SELFDESTRUCT`, `DELEGATECALL`, `CALLCODE`, `CREATE`, and `CREATE2` opcodes. The absence of these opcodes means the singleton cannot self-destruct, delegate to arbitrary code, or deploy replacement contracts.
3. **No CBOR metadata**: The test `testNoCBORMetadata()` ensures no CBOR metadata is present, preventing metadata-based metamorphic address reuse attacks.
4. **Codehash pinning**: `ensureDeployed()` checks `codehash` (not just `code.length`), so even if a contract were somehow placed at the address through a non-Zoltu mechanism, it would be rejected unless its runtime bytecode hash matches exactly.

No exploitable TOCTOU gap exists. This is well-defended.

---

### A04-3 [INFO] External calls forward all available gas -- behavior is correct

**Location**: Lines 68, 81, 89, 97

**Description**: The four external calls use Solidity's high-level call syntax (e.g., `TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token)`), which forwards all available gas minus the EIP-150 1/64th reservation. The singleton internally performs a `staticcall(gas(), token, ...)` to the token contract.

In an extremely gas-constrained context, the inner `staticcall` to the token could fail due to insufficient gas. This would result in:
- For `decimalsForTokenReadOnly` / `decimalsForToken`: A `ReadFailure` outcome returned to the caller.
- For `safeDecimalsForToken` / `safeDecimalsForTokenReadOnly`: A `TokenDecimalsReadFailure` revert.

Both behaviors are safe and correct. There is no risk of partial state mutation from gas exhaustion because the singleton only writes storage on `Initial` outcome (which requires a successful read), and gas exhaustion would prevent the read from succeeding.

No issue found.

---

### A04-4 [INFO] Return data handling is correct; slither suppressions are accurate

**Location**: Lines 67-68, 79-81

**Description**: The `decimalsForTokenReadOnly` and `decimalsForToken` functions each have a `slither-disable-next-line unused-return` comment. These are accurate false-positive suppressions: the return values from the singleton calls are directly returned by the library functions. Slither flags them because the return statement uses `return externalCall()` syntax, but the values are indeed used as the function's own return values.

The `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` functions return a single `uint8` from the singleton. If the singleton reverts (on `Inconsistent` or `ReadFailure` outcomes), the revert propagates directly to the caller with the singleton's custom error (`TokenDecimalsReadFailure`).

No issue found.

---

### A04-5 [INFO] Hardcoded constants are mutually consistent and validated by a complete test chain

**Location**: Lines 29-30 (address), 36-37 (codehash), 43-44 (creation code)

**Description**: The three constants form a provable chain validated by tests in `test/src/lib/LibTOFUTokenDecimals.t.sol`:

1. `testExpectedCreationCode()` (line 67): Asserts `type(TOFUTokenDecimals).creationCode == TOFU_DECIMALS_EXPECTED_CREATION_CODE`. This proves the creation code constant matches the compiler output.
2. `testDeployAddress()` (line 33): Forks mainnet, deploys the creation code via Zoltu, and asserts the resulting address equals `TOFU_DECIMALS_DEPLOYMENT`. Then calls `ensureDeployed()`, which also validates the codehash. This proves creation code -> address -> codehash consistency.
3. `testExpectedCodeHash()` (line 61): Deploys `TOFUTokenDecimals` via `new` and asserts its codehash matches `TOFU_DECIMALS_EXPECTED_CODE_HASH`.

The compilation settings in `foundry.toml` (`bytecode_hash = "none"`, `cbor_metadata = false`, `solc = "0.8.25"`, `optimizer_runs = 1000000`, `evm_version = "cancun"`) ensure deterministic bytecode across builds.

No issue found. Constants are fully validated.

---

### A04-6 [INFO] ensureDeployed() cannot be bypassed

**Location**: Lines 49-56, called at lines 65, 78, 88, 96

**Description**: `ensureDeployed()` is called at the beginning of every function in the library that makes an external call (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`). It checks two conditions with an OR:

1. `address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0` -- no code at the address.
2. `address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` -- wrong code at the address.

If either condition is true, it reverts with `TOFUTokenDecimalsNotDeployed`. There is no way to bypass this check when calling through the library, because:
- All functions are `internal`, so they execute in the caller's context.
- The check is the first statement in each function.
- The constant address and codehash are compile-time constants that cannot be modified.

Tests `testEnsureDeployedRevert()` and `testEnsureDeployedRevertWrongCodeHash()` cover both negative paths.

No bypass possible.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A04-1 | LOW | Singleton has no access control -- any caller can front-run initialization for any token |
| A04-2 | INFO | TOCTOU gap between ensureDeployed() and external call is mitigated by metamorphic checks |
| A04-3 | INFO | External calls forward all available gas -- behavior is correct |
| A04-4 | INFO | Return data handling is correct; slither suppressions are accurate |
| A04-5 | INFO | Hardcoded constants are mutually consistent and validated by a complete test chain |
| A04-6 | INFO | ensureDeployed() cannot be bypassed |

**Overall Assessment**: The `LibTOFUTokenDecimals` library is well-constructed from a security perspective. No CRITICAL, HIGH, or MEDIUM findings were identified. The single LOW finding (A04-1) describes an inherent property of the TOFU singleton design -- that anyone can trigger the first-use initialization for any token -- which is a design-level tradeoff rather than a bug. The `ensureDeployed()` guard is robust, checking both code existence and codehash. The TOCTOU gap is thoroughly mitigated by metamorphic runtime bytecode scanning, CBOR metadata absence, and post-Dencun SELFDESTRUCT semantics. External calls, gas forwarding, and return value handling are all correct.
