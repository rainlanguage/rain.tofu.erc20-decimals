# Audit: `src/lib/LibTOFUTokenDecimals.sol`

**Auditor:** A04
**Pass:** 3 (Documentation)
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

### Errors

| Name | Line | Parameters |
|---|---|---|
| `TOFUTokenDecimalsNotDeployed(address)` | 24 | `expectedAddress` |

### Constants

| Name | Type | Line |
|---|---|---|
| `TOFU_DECIMALS_DEPLOYMENT` | `ITOFUTokenDecimals constant` | 29-30 |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | `bytes32 constant` | 36-37 |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | `bytes constant` | 44-45 |

### Imports

- `TOFUOutcome` from `../interface/ITOFUTokenDecimals.sol` (line 5)
- `ITOFUTokenDecimals` from `../interface/ITOFUTokenDecimals.sol` (line 5)

---

## Documentation Findings

### A04-01: Library @title/@notice -- Well Documented

**Severity:** INFO

**Description:** The library has a `@title` tag on line 7 (`LibTOFUTokenDecimals`) and a comprehensive `@notice` spanning lines 8-20. The notice:

1. Describes the TOFU approach for reading and storing token decimals (lines 8-10).
2. Explains the read/write vs. read-only distinction and caller responsibility (lines 11-15).
3. Clarifies the library's role as a convenience wrapper around the deployed `TOFUTokenDecimals` singleton, abstracting away the Zoltu deployment details (lines 17-20).

**Conclusion:** The library-level documentation is thorough, accurate, and provides sufficient context for callers to understand the library's purpose and usage model. No issues.

---

### A04-02: `TOFUTokenDecimalsNotDeployed` Error -- NatSpec Complete

**Severity:** INFO

**Description:** The error on line 24 has:

- `@notice` (line 22): "Thrown when the singleton is not deployed or has an unexpected codehash."
- `@param expectedAddress` (line 23): "The address where the singleton was expected."

The `@notice` accurately describes both revert conditions in `ensureDeployed()` (line 52-57): (1) `code.length == 0` (not deployed) and (2) `codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` (unexpected codehash). The `@param` name matches the parameter name in the error declaration (`expectedAddress`). This was recently renamed from an earlier name and is now consistent.

**Conclusion:** Error NatSpec is complete and accurate. The parameter name `expectedAddress` matches the declaration.

---

### A04-03: `TOFU_DECIMALS_DEPLOYMENT` Constant -- NatSpec Accurate

**Severity:** INFO

**Description:** The constant on lines 29-30 has a `@notice` (lines 26-28) that:

1. Identifies it as "The deployed TOFUTokenDecimals contract address."
2. Explains the Zoltu deterministic deployment scheme that makes the address fixed across all supported networks.

The documentation is accurate. The constant is typed as `ITOFUTokenDecimals` (the interface type), and the address `0x200e12D10bb0c5E4a17e7018f0F1161919bb9389` is hardcoded.

**Conclusion:** No issues. The documentation correctly describes the constant and its derivation.

---

### A04-04: `TOFU_DECIMALS_EXPECTED_CODE_HASH` Constant -- NatSpec Accurate

**Severity:** INFO

**Description:** The constant on lines 36-37 has a `@notice` (lines 32-35) that:

1. Identifies it as "The expected code hash of the deployed TOFUTokenDecimals contract."
2. Explains its purpose: "Used to verify that the contract at the expected address is indeed the correct contract, providing an additional layer of safety against misconfiguration or malicious interference."

The documentation accurately describes how this constant is used in `ensureDeployed()` (line 54).

**Conclusion:** No issues.

---

### A04-05: `TOFU_DECIMALS_EXPECTED_CREATION_CODE` Constant -- NatSpec Accurate

**Severity:** INFO

**Description:** The constant on lines 44-45 has a `@notice` (lines 39-42) that:

1. Identifies it as "The expected creation code of the TOFUTokenDecimals contract."
2. Explains that "This is the init bytecode that, when deployed via the Zoltu factory, produces the contract at TOFU_DECIMALS_DEPLOYMENT with TOFU_DECIMALS_EXPECTED_CODE_HASH."

This accurately describes the relationship between the three constants: creation code deployed via Zoltu yields the address with the expected codehash.

**Conclusion:** No issues. The cross-referencing between the three constants in the documentation is clear and correct.

---

### A04-06: `ensureDeployed()` Function -- NatSpec Accurate and Complete

**Severity:** INFO

**Description:** The function on lines 51-58 has a `@notice` (lines 47-50) that:

1. States: "Ensures that the TOFUTokenDecimals contract is deployed at the expected address with the expected codehash."
2. Documents the revert behavior: "Reverts with `TOFUTokenDecimalsNotDeployed` if the address has no code or the codehash does not match, preventing silent call failures."

Verification against implementation (lines 52-57):
- The check `address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0` matches "the address has no code".
- The check `address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH` matches "the codehash does not match".
- The revert `TOFUTokenDecimalsNotDeployed(address(TOFU_DECIMALS_DEPLOYMENT))` matches "Reverts with `TOFUTokenDecimalsNotDeployed`".
- The rationale "preventing silent call failures" is accurate -- without this guard, calling a non-existent contract would return empty data and the ABI decoder could produce unexpected results.

The function has no parameters and no return value, so no `@param`/`@return` tags are needed.

**Conclusion:** Documentation is accurate and complete. The recent update to mention "codehash" explicitly in the NatSpec is correct.

---

### A04-07: `decimalsForTokenReadOnly()` Wrapper -- NatSpec Complete

**Severity:** INFO

**Description:** The function on lines 66-71 has:

- `@notice` (line 60): "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`." -- Correct cross-reference to the interface function.
- `@param token` (line 61): "The token to read the decimals for." -- Present and accurate.
- `@return tofuOutcome` (line 62): "The outcome of the TOFU read." -- Present.
- `@return tokenDecimals` (lines 63-65): Multi-line description detailing behavior for each `TOFUOutcome` variant (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`).

Cross-checking the `@return tokenDecimals` documentation against the interface (`ITOFUTokenDecimals.sol` lines 64-66) and the implementation (`LibTOFUTokenDecimalsImplementation.sol` lines 29-79):

- "On `Initial`, the freshly read value." -- Correct. Implementation line 71 returns `uint8(readDecimals)`.
- "On `Consistent` or `Inconsistent`, the previously stored value." -- Correct. Implementation lines 74-77 return `tofuTokenDecimals.tokenDecimals` for both.
- "On `ReadFailure`, the stored value (zero if uninitialized)." -- Correct. Implementation line 62 returns `tofuTokenDecimals.tokenDecimals`, which is zero when uninitialized (default Solidity storage).

The `@return` documentation exactly mirrors the interface's documentation for the same function, which is appropriate since this is a wrapper.

**Conclusion:** NatSpec is complete, with all `@param` and `@return` tags present and accurate.

---

### A04-08: `decimalsForToken()` Wrapper -- NatSpec Complete

**Severity:** INFO

**Description:** The function on lines 79-84 has:

- `@notice` (line 73): "As per `ITOFUTokenDecimals.decimalsForToken`." -- Correct cross-reference.
- `@param token` (line 74): "The token to read the decimals for." -- Present and accurate.
- `@return tofuOutcome` (line 75): "The outcome of the TOFU read." -- Present.
- `@return tokenDecimals` (lines 76-78): Same multi-line description as `decimalsForTokenReadOnly`, detailing each `TOFUOutcome` variant.

Cross-checking against the implementation (`LibTOFUTokenDecimalsImplementation.decimalsForToken`, lines 109-123): The function calls `decimalsForTokenReadOnly` internally and then writes storage only on `Initial`. The return semantics are identical to the read-only variant, making the shared `@return` documentation correct.

**Conclusion:** NatSpec is complete, with all `@param` and `@return` tags present and accurate.

---

### A04-09: `safeDecimalsForToken()` Wrapper -- NatSpec Complete

**Severity:** INFO

**Description:** The function on lines 89-92 has:

- `@notice` (line 86): "As per `ITOFUTokenDecimals.safeDecimalsForToken`." -- Correct cross-reference.
- `@param token` (line 87): "The token to read the decimals for." -- Present and accurate.
- `@return tokenDecimals` (line 88): "The token's decimals." -- Present.

The function returns only `uint8` (no `TOFUOutcome`), so a single `@return` tag is appropriate. The `@return` name `tokenDecimals` matches the return type's semantic meaning. The interface (`ITOFUTokenDecimals.sol` line 83) also uses the same documentation pattern.

**Conclusion:** NatSpec is complete and accurate. The simpler `@return` documentation is appropriate for the safe variant, which reverts on failure rather than returning an outcome enum.

---

### A04-10: `safeDecimalsForTokenReadOnly()` Wrapper -- NatSpec Complete

**Severity:** INFO

**Description:** The function on lines 97-100 has:

- `@notice` (line 94): "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`." -- Correct cross-reference.
- `@param token` (line 95): "The token to read the decimals for." -- Present and accurate.
- `@return tokenDecimals` (line 96): "The token's decimals." -- Present.

Same pattern as `safeDecimalsForToken`, which is appropriate given the parallel design. The interface (`ITOFUTokenDecimals.sol` line 95) uses the same documentation.

**Conclusion:** NatSpec is complete and accurate.

---

### A04-11: Cross-Reference Consistency Between Library and Interface

**Severity:** INFO

**Description:** All four wrapper functions use the pattern "As per `ITOFUTokenDecimals.X`" in their `@notice` tags, where `X` is the corresponding interface function name. Verifying each cross-reference:

| Library Function | Cross-Reference | Interface Function (line) | Match? |
|---|---|---|---|
| `decimalsForTokenReadOnly` (line 60) | `ITOFUTokenDecimals.decimalsForTokenReadOnly` | line 67 | Yes |
| `decimalsForToken` (line 73) | `ITOFUTokenDecimals.decimalsForToken` | line 78 | Yes |
| `safeDecimalsForToken` (line 86) | `ITOFUTokenDecimals.safeDecimalsForToken` | line 84 | Yes |
| `safeDecimalsForTokenReadOnly` (line 94) | `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly` | line 96 | Yes |

All cross-references are valid and point to existing interface functions. The function signatures in the library exactly match the interface signatures (with `internal` instead of `external` visibility, which is correct for a library wrapper).

**Conclusion:** Cross-references are consistent and accurate.

---

### A04-12: `@return` Tags Use Named Returns Matching Interface Convention

**Severity:** INFO

**Description:** The `@return` tags in the library use named return parameters (`tofuOutcome`, `tokenDecimals`) that match the interface's `@return` tag names exactly. This is consistent throughout:

- `decimalsForTokenReadOnly` and `decimalsForToken` both use `@return tofuOutcome` and `@return tokenDecimals`, mirroring the interface (ITOFUTokenDecimals.sol lines 63-66, 74-77).
- `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` both use `@return tokenDecimals`, mirroring the interface (lines 83, 95).

Note: The Solidity function signatures themselves do not use named return variables (they return unnamed types), but the `@return` tag names serve as documentation identifiers. This is standard NatSpec practice and not an issue.

**Conclusion:** Return tag naming is consistent with the interface documentation.

---

### A04-13: Library @notice Mentions Read-Only vs. Read-Write Distinction Accurately

**Severity:** INFO

**Description:** The library-level `@notice` (lines 8-15) states: "As this involves storing the decimals, which is a state change, there is a read-only version of the logic to simply check that decimals are either uninitialized or consistent, without storing anything. The caller is responsible for ensuring that read/write and read-only versions are used appropriately for their use case without introducing inconsistency."

This is accurate:
- The read-write functions (`decimalsForToken`, `safeDecimalsForToken`) call the singleton's state-changing functions, which store decimals on first read.
- The read-only functions (`decimalsForTokenReadOnly`, `safeDecimalsForTokenReadOnly`) call the singleton's `view` functions, which do not write storage.
- The caller responsibility note is important and accurate -- using only read-only functions would never initialize storage, so every call would return `Initial` and inconsistency would never be detected.

**Conclusion:** The distinction and the caller responsibility warning are documented correctly.

---

### A04-14: Missing NatSpec Warning on `decimalsForTokenReadOnly` About Pre-Initialization Behavior

**Severity:** LOW

**Description:** The interface NatSpec for `decimalsForTokenReadOnly` (ITOFUTokenDecimals.sol lines 54-61) includes important context: "This is relatively useless until after `decimalsForToken` has been called at least once for the token to initialize the stored decimals. The caller is advised to handle the uninitialized case appropriately when using read-only decimals."

The library wrapper's `@notice` (line 60) says only "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`." This cross-reference pattern is intentional and consistent, delegating full documentation to the interface. However, the interface's warning about the function being "relatively useless" before initialization is subtle and important -- a developer reading only the library (which is the intended entry point for callers) might miss it.

In contrast, `safeDecimalsForTokenReadOnly` in the interface (lines 86-96) has an explicit `WARNING:` block about pre-initialization behavior, but the library wrapper for this function (line 94) similarly defers to the cross-reference.

This is a documentation style choice. The "As per" pattern keeps the library lean and avoids duplicating documentation that could drift out of sync. However, it requires callers to follow the cross-reference to understand important caveats.

**Conclusion:** The cross-reference pattern is consistent and acceptable. Callers should consult the interface documentation for full behavioral details. This is a minor usability concern, not a correctness issue.

---

### A04-15: `ensureDeployed()` Has No `@param`/`@return` Tags -- Correct

**Severity:** INFO

**Description:** `ensureDeployed()` (line 51) takes no parameters and returns nothing (it reverts on failure). The absence of `@param` and `@return` tags is correct. The `@notice` tag adequately describes the function's behavior and revert conditions.

**Conclusion:** No missing tags.

---

## Summary

| ID | Severity | Title |
|---|---|---|
| A04-01 | INFO | Library @title/@notice is thorough and accurate |
| A04-02 | INFO | `TOFUTokenDecimalsNotDeployed` error NatSpec is complete with correct `expectedAddress` param |
| A04-03 | INFO | `TOFU_DECIMALS_DEPLOYMENT` constant NatSpec is accurate |
| A04-04 | INFO | `TOFU_DECIMALS_EXPECTED_CODE_HASH` constant NatSpec is accurate |
| A04-05 | INFO | `TOFU_DECIMALS_EXPECTED_CREATION_CODE` constant NatSpec is accurate |
| A04-06 | INFO | `ensureDeployed()` NatSpec is accurate and reflects codehash check |
| A04-07 | INFO | `decimalsForTokenReadOnly()` wrapper NatSpec is complete with @param/@return |
| A04-08 | INFO | `decimalsForToken()` wrapper NatSpec is complete with @param/@return |
| A04-09 | INFO | `safeDecimalsForToken()` wrapper NatSpec is complete with @param/@return |
| A04-10 | INFO | `safeDecimalsForTokenReadOnly()` wrapper NatSpec is complete with @param/@return |
| A04-11 | INFO | All four "As per" cross-references resolve to valid interface functions |
| A04-12 | INFO | @return tag naming is consistent with interface convention |
| A04-13 | INFO | Library-level read-only vs. read-write documentation is accurate |
| A04-14 | LOW | "As per" cross-reference pattern defers important pre-initialization warnings to interface |
| A04-15 | INFO | `ensureDeployed()` correctly omits @param/@return tags |

**Overall Assessment:** The documentation in `LibTOFUTokenDecimals.sol` is thorough and accurate. Every public item (library, error, constants, functions) has NatSpec. All `@param` and `@return` tags are present and correctly named. The error parameter `expectedAddress` matches the declaration. The `ensureDeployed()` NatSpec accurately describes both the code-existence and codehash-mismatch checks. The four wrapper functions use a consistent "As per `ITOFUTokenDecimals.X`" cross-reference pattern with locally duplicated `@param`/`@return` documentation that matches the interface. The only LOW finding (A04-14) notes that callers reading only the library may miss behavioral caveats documented in the interface, but this is an inherent trade-off of the cross-reference pattern and not a correctness issue. No CRITICAL, HIGH, or MEDIUM findings were identified.
