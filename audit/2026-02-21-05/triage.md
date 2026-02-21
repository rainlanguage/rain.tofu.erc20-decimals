# Triage — Audit 2026-02-21-05

## Summary

- **CRITICAL**: 0
- **HIGH**: 0
- **MEDIUM**: 0
- **LOW**: 18
- **INFO**: ~40 (not triaged — informational only)

Duplicate findings across agents are consolidated below. When multiple agents independently reported the same underlying issue, the primary finding is listed and duplicates are noted.

## LOW Findings

### P1-A02-03: Reentrancy surface via external staticcall to untrusted token [LOW]
**Source**: pass1/TOFUTokenDecimals.md (A02-03)
**Description**: The library performs a `staticcall` to the untrusted `token` address. A malicious token could attempt reentrant behavior. However, `staticcall` prevents state changes, and storage writes occur only after the call completes on the `Initial` path. Mitigated by `staticcall` and write-once pattern.
**Status**: DISMISSED — Fully mitigated by `staticcall` preventing state changes and the write-once pattern.

### P1-A02-06: Storage mapping visibility is internal — no direct external read [LOW]
**Source**: pass1/TOFUTokenDecimals.md (A02-06)
**Description**: The `sTOFUTokenDecimals` mapping is `internal`, meaning there is no getter to directly inspect stored values without triggering a `staticcall` to the token's `decimals()`. If the token becomes unreachable, stored values are still returned alongside `ReadFailure` for non-safe variants.
**Status**: DISMISSED — Inherent design trade-off. Non-safe variants still return stored values alongside ReadFailure.

### P1-A02-09: No events emitted on state changes [LOW]
**Source**: pass1/TOFUTokenDecimals.md (A02-09)
**Description**: When `decimalsForToken` initializes storage (the `Initial` outcome), no event is emitted. Off-chain monitoring cannot track initialization without tracing calls. Gas optimization trade-off.
**Status**: DISMISSED — Gas optimization trade-off. Callers can emit their own events. Adding events would change deployed bytecode.

### P1-A04-02: TOCTOU window between ensureDeployed() and external call [LOW]
**Source**: pass1/LibTOFUTokenDecimals.md (A04-02)
**Description**: Between `ensureDeployed()` check and the external call, code could theoretically change. Mitigated by `testNotMetamorphic()` which verifies no reachable SELFDESTRUCT/DELEGATECALL/CALLCODE opcodes.
**Status**: DISMISSED — Theoretical only; metamorphic test eliminates the concern.

### P1-A04-06: No input validation on token address parameter [LOW]
**Source**: pass1/LibTOFUTokenDecimals.md (A04-06)
**Description**: None of the four wrapper functions validate the `token` parameter. Passing `address(0)` or an EOA results in `ReadFailure`, which is correct behavior. By design.
**Status**: DISMISSED — By design. ReadFailure correctly covers invalid addresses.

### P1-A04-07: Hardcoded address and codehash must be maintained in sync [LOW]
**Source**: pass1/LibTOFUTokenDecimals.md (A04-07)
**Description**: Three constants (deployment address, code hash, creation code) must be consistent. Test suite includes `testDeployAddress()`, `testExpectedCodeHash()`, `testExpectedCreationCode()` to guard consistency. Operational risk only.
**Status**: DISMISSED — Test suite adequately guards consistency. Operational risk, not runtime.

### P1-A05-07: Stale memory read prevented by returndatasize guard (fragile ordering dependency) [LOW]
**Source**: pass1/LibTOFUTokenDecimalsImplementation.md (A05-07)
**Description**: If the `returndatasize() < 0x20` guard were removed or reordered, stale memory from the `mstore(0, selector)` could be interpreted as decimals. The guard is correct and the code is secure, but correctness depends on the guard ordering.
**Status**: DISMISSED — The guard is present, correct, and standard practice for assembly staticcall patterns. Changing bytecode is not an option.

### P2-A01-001: No test file for script/Deploy.sol [LOW]
**Source**: pass2/Deploy.md (A01-001)
**Description**: No test file exercises `Deploy.run()`. Underlying primitives (Zoltu deploy, creation code, expected address, code hash) are individually tested. Deploy scripts are inherently difficult to test in CI.
**Status**: DISMISSED — Conventional for Foundry deploy scripts. All critical constants verified by existing tests.

### P2-A02-1: No address(0) tests at concrete contract level [LOW]
**Source**: pass2/TOFUTokenDecimals.md (A02-1)
**Description**: None of the concrete contract test files exercise `address(0)` as the token parameter. Covered at implementation and lib layers.
**Status**: FIXED — Added `address(0)` tests to all four concrete test files.

### P2-A02-2: No EOA/codeless-address tests at concrete contract level [LOW]
**Source**: pass2/TOFUTokenDecimals.md (A02-2)
**Description**: No test with a bare EOA address at concrete layer. Both codeless and STOP-opcode addresses return 0 bytes of returndata, so the existing short-returndata tests effectively cover this path.
**Status**: DISMISSED — Identical EVM behavior to the existing STOP-opcode tests. Functionally covered.

### P2-A02-3: No explicit decimals=0 boundary test [LOW]
**Source**: pass2/TOFUTokenDecimals.md (A02-3), pass2/ITOFUTokenDecimals.md (A03-05)
**Description**: No dedicated named test at the concrete layer explicitly verifying the `decimals=0` round-trip (Initial then Consistent, proving the `initialized` flag works). Fuzz tests cover this probabilistically.
**Status**: FIXED — Added explicit `testDecimalsForTokenDecimalsZero` (and equivalents) to all four concrete test files, deterministically verifying the `initialized` flag with `decimals=0`.

### P2-A04-006: Real-token tests cover only one token per non-decimalsForToken function [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md (A04-006)
**Description**: `testRealTokenSafeDecimalsForTokenReadOnly` tests only WBTC, `testRealTokenDecimalsForTokenReadOnly` only WETH, `testRealTokenSafeDecimalsForToken` only USDC. Only `decimalsForToken` is tested against all 4 real tokens.
**Status**: FIXED — Expanded all three functions to test against all 4 real tokens (WETH/18, USDC/6, WBTC/8, DAI/18), one test per token per function.

### P2-A04-007: No real-token test for Inconsistent outcome [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md (A04-007)
**Description**: All real-token tests only exercise `Initial` and `Consistent` outcomes. `Inconsistent` is only validated via `vm.mockCall`. Testing with real tokens would require a malicious/upgradeable token.
**Status**: DISMISSED — Inconsistent requires a token that changes its decimals between calls, which cannot happen with standard real tokens. Thoroughly tested via `vm.mockCall` at all layers.

### P2-A05-1/2/3: No cross-token isolation tests for decimalsForTokenReadOnly, safeDecimalsForToken, safeDecimalsForTokenReadOnly at impl layer [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (A05-1, A05-2, A05-3)
**Description**: `decimalsForToken` has `testDecimalsForTokenCrossTokenIsolation` but the other three functions lack equivalent tests at the implementation layer. The underlying mapping lookup is shared, so cross-contamination is architecturally unlikely.
**Status**: DISMISSED — `decimalsForToken` is the only function that writes storage and already has the isolation test. `decimalsForTokenReadOnly` and `safeDecimalsForTokenReadOnly` are `view` (can't write storage). `safeDecimalsForToken` delegates to `decimalsForToken`.

### P2-A05-4: No storage write isolation test for safeDecimalsForToken at impl layer [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (A05-4)
**Description**: `decimalsForToken` has explicit tests for no-storage-write on non-Initial outcomes. `safeDecimalsForToken` inherits this behavior but has no direct test. Since safe functions revert on non-success outcomes, storage writes would be rolled back anyway.
**Status**: DISMISSED — `safeDecimalsForToken` reverts on Inconsistent/ReadFailure (rolling back any storage changes). On Consistent, it delegates to `decimalsForToken` which is already tested not to write on non-Initial outcomes.

### P3-A04-14: "As per" cross-reference pattern defers important pre-initialization warnings to interface [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md (A04-14)
**Description**: The library wrapper for `decimalsForTokenReadOnly` says only "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`" without repeating the interface's warning about the function being "relatively useless" before initialization. Callers reading only the library may miss important caveats.
**Status**: DISMISSED — Carried forward from audit-04 P3-A04-5. Cross-reference to the interface is the intended pattern for thin wrappers.

### P3-A05-3/4: safe function @return tags lack named return variable in implementation library [LOW]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (A05-3, A05-4)
**Description**: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` use `@return The token's decimals.` without naming the return variable `tokenDecimals`, unlike the interface and `LibTOFUTokenDecimals.sol` which use `@return tokenDecimals The token's decimals.`
**Status**: FIXED — Changed both `@return` tags to `@return tokenDecimals The token's decimals.` matching the interface and convenience library.

### P4-A06-10: NatSpec cross-reference pattern duplicates documentation with drift risk [LOW]
**Source**: pass4/CodeQuality.md (A06-10)
**Description**: Both library files use "As per `ITOFUTokenDecimals.xxx`" then duplicate `@param` and `@return` tags. The concrete contract uses `@inheritdoc` which avoids duplication. Library functions cannot use `@inheritdoc` due to different signatures. Duplication risks divergence over time.
**Status**: DISMISSED — Library functions cannot use `@inheritdoc` due to different signatures (they take a `mapping` storage parameter). The "As per" + duplicated tags pattern is the only viable approach.
