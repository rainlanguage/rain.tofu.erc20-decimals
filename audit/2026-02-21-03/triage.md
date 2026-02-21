# Triage — Audit 2026-02-21-03

## Summary

- **CRITICAL**: 0
- **HIGH**: 0
- **MEDIUM**: 0
- **LOW**: 14
- **INFO**: ~50 (not triaged — informational only)

## LOW+ Findings

Finding IDs are prefixed with pass number for disambiguation (e.g., P2-A01-1 = Pass 2, Agent A01, Finding 1).

### P0-2: CLAUDE.md does not document the deploy script [LOW]
**Source**: pass0/process.md
**Description**: `script/Deploy.sol` exists but is not mentioned in CLAUDE.md's Architecture or Build & Test sections.
**Status**: FIXED — Added deploy script paragraph to Architecture section of CLAUDE.md.

### P1-A03-5: No raw state query in interface [LOW]
**Source**: pass1/ITOFUTokenDecimals.md
**Description**: No way to query the raw stored `TOFUTokenDecimalsResult` without triggering a `decimals()` call. If a token becomes unreachable, `safe*` variants revert even though stored decimals exist.
**Status**: DISMISSED — By design. Adding a raw getter would change deployed bytecode and break the deterministic address. Non-safe `decimalsForTokenReadOnly` returns stored value on `ReadFailure` as the recovery path.

### P1-A05-8: safeDecimalsForTokenReadOnly provides no TOFU protection before initialization [LOW]
**Source**: pass1/LibTOFUTokenDecimalsImplementation.md
**Description**: Before `decimalsForToken` has been called, every `safeDecimalsForTokenReadOnly` call returns `Initial` with whatever the token currently reports. No inconsistency detection possible. Documented in NatSpec but callers could misuse.
**Status**: DISMISSED — Already documented with explicit WARNING in NatSpec at LibTOFUTokenDecimalsImplementation.sol:152-156.

### P2-A01-1: No direct test for Deploy.run() [LOW]
**Source**: pass2/Deploy.md
**Description**: Deploy script has no test file. Individual constants are verified indirectly. Multi-network deployment flow is untested.
**Status**: DISMISSED — Conventional for Foundry deploy scripts. All critical constants verified by existing tests.

### P2-A02-1: Missing ReadFailure test for decimalsForTokenReadOnly when initialized [LOW]
**Source**: pass2/TOFUTokenDecimals.md
**Description**: Concrete contract test covers ReadFailure only for uninitialized case. No test verifies stored value is returned on ReadFailure after initialization.
**Status**: FIXED — Added `testDecimalsForTokenReadOnlyReadFailureInitialized` fuzz test to `TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`.

### P2-A02-2: Missing test for safeDecimalsForTokenReadOnly on uninitialized Initial path [LOW]
**Source**: pass2/TOFUTokenDecimals.md
**Description**: All tests pre-initialize via `decimalsForToken`. No test confirms `safeDecimalsForTokenReadOnly` returns correct value on first use without prior initialization.
**Status**: FIXED — Added `testSafeDecimalsForTokenReadOnlyInitial` fuzz test to `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`.

### P2-A02-3: No test for safeDecimalsForToken ReadFailure after initialization [LOW]
**Source**: pass2/TOFUTokenDecimals.md
**Description**: Tests ReadFailure only for uninitialized case. No test verifies revert error contains stored decimals after initialization.
**Status**: FIXED — Added `testSafeDecimalsForTokenReadFailureInitializedReverts` fuzz test to `TOFUTokenDecimals.safeDecimalsForToken.t.sol`.

### P2-A04-1: No test for safeDecimalsForTokenReadOnly proving it does not write storage [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md
**Description**: `decimalsForTokenReadOnly` has an explicit storage-non-modification test but `safeDecimalsForTokenReadOnly` does not. Mitigated by `view` modifier.
**Status**: DISMISSED — Test already exists: `testSafeDecimalsForTokenReadOnlyDoesNotWriteStorage` at `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol:70`.

### P2-A04-6: safeDecimalsForTokenReadOnly not tested for multi-call on uninitialized token [LOW]
**Source**: pass2/LibTOFUTokenDecimals.md
**Description**: No test confirms successive `safeDecimalsForTokenReadOnly` calls on uninitialized tokens all succeed (each returning `Initial`).
**Status**: FIXED — Added `testSafeDecimalsForTokenReadOnlyMultiCallUninitialized` fuzz test to `TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`.

### P2-A05-5: No test for token with code but no decimals function [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md
**Description**: Tests cover EOAs and contracts that revert, but not a contract with actual bytecode that lacks a `decimals()` function (e.g., fallback/receive only).
**Status**: FIXED — Added `testDecimalsForTokenNoDecimalsFunction` to `TOFUTokenDecimals.decimalsForToken.t.sol`. Uses `vm.etch` with STOP opcode to exercise the `returndatasize < 0x20` guard.

### P3-A01-1: No NatSpec on Deploy contract or run() function [LOW]
**Source**: pass3/Deploy.md
**Description**: Deploy script has no `@title`, `@notice`, or documentation of the `DEPLOYMENT_KEY` environment variable requirement.
**Status**: FIXED — Added `@title`, `@notice` on contract and `run()` function, documenting `DEPLOYMENT_KEY` requirement.

### P3-A04-3: Constants in LibTOFUTokenDecimals lack NatSpec tags [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md
**Description**: Three constants use plain `///` instead of `@notice`/`@dev` tags. Won't appear in NatSpec JSON output.
**Status**: FIXED — Added `@notice` tags to all three constants in `LibTOFUTokenDecimals.sol`.

### P3-A04-4: ensureDeployed() lacks NatSpec tag [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md
**Description**: Uses plain `///` instead of `@notice`/`@dev`. Won't appear in NatSpec JSON output.
**Status**: FIXED — Added `@notice` tag to `ensureDeployed()` in `LibTOFUTokenDecimals.sol`.

### P4-A06-1: Unused import of ITOFUTokenDecimals in LibTOFUTokenDecimalsImplementation [LOW]
**Source**: pass4/CodeQuality.md
**Description**: `ITOFUTokenDecimals` is imported but only referenced in NatSpec comments, not in executable code.
**Status**: FIXED — Removed `ITOFUTokenDecimals` from the import in `LibTOFUTokenDecimalsImplementation.sol`.
