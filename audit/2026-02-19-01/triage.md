# Audit Triage — 2026-02-19-01

All LOW+ findings across all passes. Findings are keyed by `Pass.AgentID-FindingNumber`.

## MEDIUM Findings

| ID | Pass | File | Description | Status |
|----|------|------|-------------|--------|
| P3.A02-4 | 3 | LibTOFUTokenDecimalsImplementation | `decimalsForTokenReadOnly` `@return` tags don't document per-outcome return semantics | FIXED |
| P3.A02-5 | 3 | LibTOFUTokenDecimalsImplementation | `decimalsForToken` missing `@param` and `@return` NatSpec tags | FIXED |
| P3.A02-7 | 3 | LibTOFUTokenDecimalsImplementation | `safeDecimalsForToken` missing `@param` tags; docs omit `ReadFailure` revert | FIXED |
| P3.A02-9 | 3 | LibTOFUTokenDecimalsImplementation | `safeDecimalsForTokenReadOnly` missing `@param` tags; unclear revert semantics | FIXED |
| P3.A04-3 | 3 | LibTOFUTokenDecimals | `decimalsForTokenReadOnly` lacks `@param` and `@return` NatSpec tags | FIXED |
| P3.A04-4 | 3 | LibTOFUTokenDecimals | `decimalsForToken` lacks `@param` and `@return` NatSpec tags | FIXED |
| P3.A04-5 | 3 | LibTOFUTokenDecimals | `safeDecimalsForToken` lacks `@param` and `@return` NatSpec tags | FIXED |
| P3.A04-6 | 3 | LibTOFUTokenDecimals | `safeDecimalsForTokenReadOnly` lacks `@param` and `@return` NatSpec tags | FIXED |

## LOW Findings

| ID | Pass | File | Description | Status |
|----|------|------|-------------|--------|
| P0-2 | 0 | CLAUDE.md | Ambiguous singleton address — could be read as factory or singleton address | FIXED |
| P0-3 | 0 | CLAUDE.md | Test file naming convention doesn't mention base test files | FIXED |
| P1.A02-5 | 1 | LibTOFUTokenDecimalsImplementation | Forwarding all gas to external staticcall (theoretical gas griefing) | DISMISSED |
| P1.A04-3 | 1 | LibTOFUTokenDecimals | External calls propagate reverts without wrapping | DISMISSED |
| P1.A04-7 | 1 | LibTOFUTokenDecimals | TOCTOU gap between ensureDeployed() and external call (theoretical only) | FIXED |
| P2.A01-2 | 2 | ITOFUTokenDecimals | No test for TOFUTokenDecimals concrete contract in isolation | PENDING |
| P2.A02-3 | 2 | LibTOFUTokenDecimalsImplementation | No test that storage is NOT written on non-Initial outcomes | PENDING |
| P2.A02-4 | 2 | LibTOFUTokenDecimalsImplementation | `safeDecimalsForToken` Initial path not directly tested via safe wrapper | PENDING |
| P2.A02-12 | 2 | LibTOFUTokenDecimalsImplementation | No interleaved multi-call test (Initial -> ReadFailure -> Consistent) | PENDING |
| P2.A03-3 | 2 | TOFUTokenDecimals | No explicit cross-token storage isolation test | PENDING |
| P2.A04-8 | 2 | LibTOFUTokenDecimals | Read-only semantics not cross-verified with stateful function | PENDING |
| P2.A04-9 | 2 | LibTOFUTokenDecimals | `safe*` wrappers missing "initialized then ReadFailure" tests at singleton layer | PENDING |
| P3.A01-1 | 3 | ITOFUTokenDecimals | Interface doc block uses `@title` but has no explicit `@notice` | PENDING |
| P3.A01-2 | 3 | ITOFUTokenDecimals | Struct doc mixes untagged description with explicit `@param` tags | PENDING |
| P3.A01-3 | 3 | ITOFUTokenDecimals | Error doc mixes untagged description with explicit `@param` tags | PENDING |
| P3.A02-1 | 3 | LibTOFUTokenDecimalsImplementation | Library doc block has `@title` but no explicit `@notice` | PENDING |
| P3.A02-3 | 3 | LibTOFUTokenDecimalsImplementation | `decimalsForTokenReadOnly` description lacks explicit `@notice`/`@dev` tag | PENDING |
| P3.A03-1 | 3 | TOFUTokenDecimals | Contract doc block has `@title` but no explicit `@notice` | PENDING |
| P3.A03-2 | 3 | TOFUTokenDecimals | State variable `sTOFUTokenDecimals` has no NatSpec documentation | PENDING |
| P3.A04-1 | 3 | LibTOFUTokenDecimals | Library doc block has `@title` but no explicit `@notice` | PENDING |
| P3.A04-7 | 3 | LibTOFUTokenDecimals | Error `TOFUTokenDecimalsNotDeployed` lacks `@param` tag | PENDING |
| P4.A05-1 | 4 | TOFUTokenDecimals | Unused import of `LibTOFUTokenDecimals` in concrete contract | PENDING |
| P4.A05-2 | 4 | LibTOFUTokenDecimals | Unused import of `TokenDecimalsReadFailure` | PENDING |
| P4.A05-3 | 4 | script/Deploy.sol | Unused import of `console2` | PENDING |
