# Triage — Audit 2026-02-21-06

## Summary

- **CRITICAL**: 0
- **HIGH**: 0
- **MEDIUM**: 0
- **LOW**: 7
- **INFO**: ~2 (not triaged — informational only)

## LOW Findings

### P2-A02-2: No cross-function interaction tests at concrete level [LOW]
**Source**: pass2/TOFUTokenDecimals.md (Finding 2)
**Description**: No dedicated test exercises all four concrete contract functions in sequence on the same token to verify shared-state wiring through the `sTOFUTokenDecimals` mapping. The read-only test files already use `decimalsForToken` to initialize state before testing read-only paths, which is a form of cross-function interaction.
**Status**: FIXED — Added `testDecimalsForTokenCrossFunctionInteraction` exercising all four functions in sequence: `decimalsForToken` (Initial) → `decimalsForTokenReadOnly` (Consistent) → `safeDecimalsForToken` → `safeDecimalsForTokenReadOnly`.

### P2-A02-3: safeDecimalsForToken lacks cross-token isolation and storage immutability tests at concrete level [LOW]
**Source**: pass2/TOFUTokenDecimals.md (Finding 3)
**Description**: `decimalsForToken` test file has cross-token isolation and storage immutability tests. `safeDecimalsForToken` test file does not mirror these, even though the underlying behavior is identical (delegates to `decimalsForToken`).
**Status**: DISMISSED — `safeDecimalsForToken` is a one-liner delegating to `decimalsForToken` (already tested). Immutability tests are moot since `safeDecimalsForToken` reverts on Inconsistent/ReadFailure, rolling back any state. Cross-token isolation is a mapping property proven by `decimalsForToken`.

### P2-A04-1: No does-not-write-storage test for decimalsForTokenReadOnly at impl level [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (Finding 1)
**Description**: `decimalsForTokenReadOnly` is `view` (compiler-enforced), but no explicit test verifies calling it on an uninitialized token leaves storage unchanged. Defense-in-depth concern only.
**Status**: DISMISSED — The `view` modifier is compiler-enforced; no storage writes are possible. The agent acknowledges this is informational.

### P2-A04-2: No cross-token isolation test for decimalsForTokenReadOnly at impl level [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (Finding 2)
**Description**: `decimalsForToken` has `testDecimalsForTokenCrossTokenIsolation` but no equivalent for `decimalsForTokenReadOnly`. Storage isolation is a mapping property, not function-specific.
**Prior triage**: Duplicate of audit-05 P2-A05-1/2/3.
**Status**: DISMISSED — Carried forward from audit-05. `decimalsForToken` is the only function that writes storage and already has the isolation test. `decimalsForTokenReadOnly` is `view` and cannot write storage.

### P2-A04-4: safeDecimalsForToken lacks cross-token isolation and storage-write-on-Initial tests at impl level [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (Finding 4)
**Description**: No direct test verifying cross-token isolation or Initial-writes-storage for `safeDecimalsForToken`. Delegates to `decimalsForToken` which is well-tested.
**Prior triage**: Duplicate of audit-05 P2-A05-4.
**Status**: DISMISSED — Carried forward from audit-05. `safeDecimalsForToken` reverts on Inconsistent/ReadFailure (rolling back any storage). On Consistent, delegates to `decimalsForToken` which is tested.

### P2-A04-5: No test for decimalsForToken ReadFailure on first call confirming no storage write [LOW]
**Source**: pass2/LibTOFUTokenDecimalsImplementation.md (Finding 5)
**Description**: When `decimalsForToken` encounters a `ReadFailure` on the very first call (uninitialized storage), no test verifies storage remains uninitialized afterward (i.e., a subsequent valid call should return `Initial`). Existing `testDecimalsForTokenNoStorageWriteOnNonInitial` covers ReadFailure *after* initialization, not before.
**Status**: FIXED — Added `testDecimalsForTokenNoStorageWriteOnUninitializedReadFailure` at both impl and concrete levels. Sequence: ReadFailure on uninitialized → fix mock → second call returns Initial.

### P3-A04-1: TokenDecimalsReadFailure error name used for both Inconsistent and ReadFailure outcomes [LOW]
**Source**: pass3/LibTOFUTokenDecimalsImplementation.md (Finding 1)
**Description**: The error `TokenDecimalsReadFailure` is raised for both `Inconsistent` and `ReadFailure` outcomes. The name suggests only read failures, but it also covers inconsistency. The `tofuOutcome` parameter distinguishes the two cases, so callers have full information.
**Status**: DOCUMENTED — Updated NatSpec on `TokenDecimalsReadFailure` in ITOFUTokenDecimals.sol to explicitly state it covers both `Inconsistent` and `ReadFailure` outcomes. Error cannot be renamed without changing deployed bytecode.
