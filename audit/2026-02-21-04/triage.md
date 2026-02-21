# Triage — Audit 2026-02-21-04

## Summary

- **CRITICAL**: 0
- **HIGH**: 0
- **MEDIUM**: 5
- **LOW**: 27
- **INFO**: ~30 (not triaged — informational only)

Duplicate findings across agents are consolidated below. When multiple agents independently reported the same underlying issue, the primary finding is listed and duplicates are noted.

## MEDIUM Findings

### P2-A01-1: No test file for Deploy.run() [MEDIUM]
**Source**: pass2/Deploy.md
**Description**: `script/Deploy.sol` has no test file. `run()` has zero direct test coverage. Individual constants are verified indirectly by `LibTOFUTokenDecimals` tests.
**Status**: DISMISSED — Conventional for Foundry deploy scripts. All critical constants verified by existing tests.

### P3-A03-1: Inconsistent NatSpec tag usage — bare `///` vs `@notice` across codebase [MEDIUM]
**Source**: pass3/ITOFUTokenDecimals.md (A03-DOC-01, A03-DOC-02), pass3/LibTOFUTokenDecimals.md (A04-F02), pass3/LibTOFUTokenDecimalsImplementation.md (A05-1), pass4/CodeQuality.md (A06-04-2, A06-04-3, A06-04-4)
**Description**: Multiple files use bare `///` on some items and explicit `@notice` on others. In `ITOFUTokenDecimals.sol`, the enum and all four functions use bare `///` while the struct and error use `@notice`. In `LibTOFUTokenDecimalsImplementation.sol`, `decimalsForTokenReadOnly` uses `@notice` but the other three functions use bare `///`. In `LibTOFUTokenDecimals.sol`, `ensureDeployed` uses `@notice` but the four wrapper functions use bare `///`.
**Status**: FIXED — Added explicit `@notice` tags to all bare `///` NatSpec blocks across `ITOFUTokenDecimals.sol` (enum + 4 functions), `LibTOFUTokenDecimalsImplementation.sol` (3 functions), and `LibTOFUTokenDecimals.sol` (4 functions).

### P3-A02-5: safeDecimalsForTokenReadOnly pre-initialization warning absent from interface NatSpec [MEDIUM]
**Source**: pass3/TOFUTokenDecimals.md (A02-F05), pass3/ITOFUTokenDecimals.md (A03-DOC-06)
**Description**: The critical WARNING about pre-initialization behavior (each call is a fresh `Initial` read with no TOFU protection) exists only in `LibTOFUTokenDecimalsImplementation.sol`. It is absent from `ITOFUTokenDecimals.sol` and therefore not propagated via `@inheritdoc` to callers reading the public API.
**Status**: FIXED — Added WARNING about pre-initialization behavior to `safeDecimalsForTokenReadOnly` NatSpec in `ITOFUTokenDecimals.sol`.

### P3-A05-2: Missing interface cross-references on implementation functions [MEDIUM]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (A05-2)
**Description**: `decimalsForTokenReadOnly` says "As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`" but the other three implementation functions (`decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) lack equivalent cross-references.
**Status**: FIXED — Added `As per ITOFUTokenDecimals.<function>` cross-references to all three functions in `LibTOFUTokenDecimalsImplementation.sol`.

### P3-A05-3: Duplicate forge-lint suppression annotations on safe functions [MEDIUM]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (A05-3), pass4/CodeQuality.md (A06-04-1)
**Description**: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` each have two `forge-lint: disable-next-line(mixed-case-variable)` annotations — one before `function`, one before the parameter. The non-safe functions have only one (before the parameter). Either the extra annotation is redundant or the non-safe functions are missing one.
**Status**: FIXED — Removed the redundant annotation before `function` on both safe functions, matching the non-safe functions' pattern.

## LOW Findings

### P1-A02-2: No zero-address guard on token parameter [LOW]
**Source**: pass1/TOFUTokenDecimals.md (A02-2), pass1/ITOFUTokenDecimals.md (A03-3), pass1/LibTOFUTokenDecimals.md (A04-5)
**Description**: Passing `address(0)` produces `ReadFailure` via the assembly `returndatasize` guard. Behavior is safe but undocumented. Adding a guard would change deployed bytecode.
**Status**: DISMISSED — Behavior verified by extensive `address(0)` tests at implementation and lib layers (all four functions, both uninitialized and initialized). Adding a guard would break deployed bytecode.

### P1-A02-7: No gas cap on staticcall to token [LOW]
**Source**: pass1/TOFUTokenDecimals.md (A02-7)
**Description**: The assembly `staticcall` forwards all remaining gas. A malicious token could consume gas via an expensive fallback. Mitigated by `staticcall` preventing state changes.
**Status**: DISMISSED — Standard practice for view calls. High-level Solidity would also forward all gas. staticcall prevents state changes; gas consumption is the caller's responsibility.

### P1-A02-10: ReadFailure returns 0 decimals for uninitialized tokens [LOW]
**Source**: pass1/TOFUTokenDecimals.md (A02-10)
**Description**: Non-safe variants return `(ReadFailure, 0)` for uninitialized tokens when the read fails. Callers not checking the outcome enum may silently use 0 decimals.
**Status**: DISMISSED — By design. Non-safe variants return the outcome enum for callers to handle. Safe variants exist for automatic revert. The 0 is correct uninitialized storage default.

### P2-A01-2: Deploy.run() arguments not directly asserted in tests [LOW]
**Source**: pass2/Deploy.md (A01-2)
**Description**: The creation code, expected address, code hash, and empty dependencies array passed to `deployAndBroadcastToSupportedNetworks` are not directly tested through `run()`. Indirectly verified by `LibTOFUTokenDecimals` constant tests.
**Status**: DISMISSED — All critical constants verified by existing tests. Conventional for Foundry deploy scripts.

### P2-A01-3: Missing DEPLOYMENT_KEY env var failure path not tested [LOW]
**Source**: pass2/Deploy.md (A01-3)
**Description**: The `vm.envUint("DEPLOYMENT_KEY")` revert when the env var is missing is not tested.
**Status**: DISMISSED — Foundry cheatcode behavior, not project logic. Standard for deploy scripts.

### P2-A02-1: address(0) not tested at concrete layer [LOW]
**Source**: pass2/TOFUTokenDecimals.md (A02-F01, A02-F02)
**Description**: No concrete contract test passes `address(0)` as the token to any entry-point. Covered at the implementation layer but not at the concrete smoke-test layer.
**Status**: DISMISSED — Covered at implementation and lib layers. Concrete tests are smoke tests for pass-through wiring.

### P2-A02-3: Short-returndata path not tested via vm.etch at concrete layer [LOW]
**Source**: pass2/TOFUTokenDecimals.md (A02-F03, A02-F04)
**Description**: `decimalsForToken` has a `vm.etch(hex"00")` test but the read-only and safe variants do not exercise the short-returndata assembly guard via `vm.etch` at the concrete layer.
**Status**: FIXED — Added `vm.etch(hex"00")` tests to `decimalsForTokenReadOnly`, `safeDecimalsForToken`, and `safeDecimalsForTokenReadOnly` concrete test files.

### P2-A02-5: Over-wide decimals return (>0xff) not tested at concrete layer [LOW]
**Source**: pass2/TOFUTokenDecimals.md (A02-F05)
**Description**: The assembly guard `gt(readDecimals, 0xff)` is not tested at the concrete layer for any entry-point.
**Status**: FIXED — Added overwide-decimals fuzz tests to all four concrete test files.

### P2-A03-4: safeDecimalsForTokenReadOnly missing initialized+ReadFailure test at concrete layer [LOW]
**Source**: pass2/ITOFUTokenDecimals.md (A03-F04)
**Description**: The concrete test file has no test that initializes a token then triggers ReadFailure for `safeDecimalsForTokenReadOnly`. Covered at the implementation layer.
**Status**: FIXED — Added `testSafeDecimalsForTokenReadOnlyReadFailureInitializedReverts` fuzz test to concrete test file.

### P2-A04-1: TOFUTokenDecimalsNotDeployed error conflates two sub-conditions [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md (A04-LIB-01)
**Description**: The error does not distinguish zero-code-length from wrong-codehash. Tests cover both paths but comments don't clarify which sub-condition each test triggers.
**Status**: DISMISSED — Both conditions mean the singleton is unavailable. Distinguishing would change bytecode. Tests cover both branches.

### P2-A04-2: ensureDeployed happy path not tested via external wrapper [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md (A04-LIB-02)
**Description**: The happy path is exercised via a bare internal call in the test wrapper, not through the external-facing function.
**Status**: DISMISSED — Happy path exercised every time any of the four wrapper functions succeeds in tests. Called directly in 8+ test files.

### P2-A04-3: No "does not write storage" test for safeDecimalsForTokenReadOnly at lib layer [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md (A04-LIB-03)
**Description**: `decimalsForTokenReadOnly` has this test but `safeDecimalsForTokenReadOnly` does not at the `LibTOFUTokenDecimals` layer. Exists at the concrete layer.
**Status**: FIXED — Added `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` fuzz test to `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`.

### P2-A04-5: Real-token integration tests only cover decimalsForToken [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md (A04-LIB-05)
**Description**: `realTokens.t.sol` exercises only `decimalsForToken`. The other three functions have no real-token fork test.
**Status**: FIXED — Added real-token tests for `decimalsForTokenReadOnly`, `safeDecimalsForToken`, and `safeDecimalsForTokenReadOnly` to `realTokens.t.sol`.

### P2-A05-1: EOA/zero-returndata path not deterministically isolated at impl layer [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (A05-P2-01, A05-P2-02)
**Description**: No named test uses a plain EOA address (non-contract, non-zero) to deterministically exercise the `returndatasize == 0` sub-case.
**Status**: PENDING

### P2-A05-4: safeDecimalsForTokenReadOnly not integration-tested at impl layer [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (A05-P2-04)
**Description**: No test initializes via `decimalsForToken` then reads back through `safeDecimalsForTokenReadOnly` at the implementation layer.
**Status**: PENDING

### P3-A01-1: Deploy.run() doesn't document empty dependencies argument [LOW]
**Source**: pass3/Deploy.md (A01-D-DOC-01)
**Description**: `new address[](0)` is passed as dependencies but the NatSpec doesn't explain this means no on-chain prerequisites.
**Status**: PENDING

### P3-A02-3: forge-lint suppression between NatSpec and storage variable [LOW]
**Source**: pass3/TOFUTokenDecimals.md (A02-F03)
**Description**: The `forge-lint: disable-next-line(mixed-case-variable)` comment sits between the `@inheritdoc` NatSpec block and the `sTOFUTokenDecimals` storage variable, which may confuse doc tooling.
**Status**: PENDING

### P3-A02-4: No @dev for singleton/deterministic-bytecode constraint on TOFUTokenDecimals [LOW]
**Source**: pass3/TOFUTokenDecimals.md (A02-F04)
**Description**: The concrete contract has no documentation explaining why it uses exact pragma `=0.8.25` or the bytecode determinism constraints.
**Status**: PENDING

### P3-A03-4: decimalsForToken interface description omits state-mutation detail [LOW]
**Source**: pass3/ITOFUTokenDecimals.md (A03-DOC-04)
**Description**: The NatSpec doesn't explicitly state that storage is written only on the `Initial` outcome.
**Status**: PENDING

### P3-A03-5: safe* functions don't name TokenDecimalsReadFailure in interface NatSpec [LOW]
**Source**: pass3/ITOFUTokenDecimals.md (A03-DOC-05)
**Description**: Integrators reading only the interface cannot discover which error type the safe variants revert with.
**Status**: PENDING

### P3-A04-4: ensureDeployed @notice omits codehash-mismatch sub-condition [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md (A04-F04)
**Description**: Documentation only mentions "deployed" check but not the codehash verification.
**Status**: PENDING

### P3-A04-5: Delegating functions are cross-references only [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md (A04-F05)
**Description**: The four wrapper functions say "As per `ITOFUTokenDecimals.X`" but provide no standalone description.
**Status**: PENDING

### P3-A04-7: TOFUTokenDecimalsNotDeployed parameter name misleading [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md (A04-F07)
**Description**: Parameter is named `deployedAddress` which implies deployment succeeded, but it's the address where deployment was expected.
**Status**: PENDING

### P3-A05-4: TOFU_DECIMALS_SELECTOR uses @dev while other items use @notice [LOW]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (A05-4)
**Description**: Style inconsistency — the constant uses `@dev` while other documented items use `@notice`.
**Status**: PENDING

### P3-A05-5: Pre-initialization WARNING embedded in prose, not a distinct @dev tag [LOW]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (A05-5)
**Description**: The critical warning about TOFU bypass before initialization is part of the general `///` description rather than a separate `@dev` block.
**Status**: PENDING

### P3-A05-6: @return label mismatch with local variable [LOW]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (A05-6)
**Description**: `@return tokenDecimals` doesn't match the local variable name `readDecimals` used in `decimalsForToken`.
**Status**: PENDING
