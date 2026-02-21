# Triage — Audit 2026-02-21-07

## Summary

- **CRITICAL**: 0
- **HIGH**: 0
- **MEDIUM**: 0
- **LOW**: 1
- **INFO**: ~8 (not triaged — informational only)

## LOW Findings

### P3-A03-5: `safeDecimalsForTokenReadOnly` in LibTOFUTokenDecimals missing pre-initialization WARNING [LOW]
**Source**: pass3/LibTOFUTokenDecimals.md (Finding A03-5)
**Description**: The interface (`ITOFUTokenDecimals.sol` lines 93-96) and implementation library (`LibTOFUTokenDecimalsImplementation.sol` lines 149-153) both include an explicit WARNING that before initialization, each `safeDecimalsForTokenReadOnly` call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected. However, `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly` (line 94) only says "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`" without reproducing this security-relevant warning. Since `LibTOFUTokenDecimals` is the primary caller-facing entry point, this warning should be surfaced directly.
**Status**: FIXED — Added the WARNING about pre-initialization behavior directly to `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly` NatSpec, matching the interface and implementation library.
