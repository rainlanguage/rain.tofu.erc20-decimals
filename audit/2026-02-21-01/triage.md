# Audit Triage -- 2026-02-21-01

All LOW+ findings from all passes. Status: FIXED, DOCUMENTED, DISMISSED, UPSTREAM, or PENDING.

---

## Pass 0 (Process)

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| P0-1 | LOW | CLAUDE.md says "Ethereum mainnet RPC" but CI uses Sepolia | FIXED |
| P0-2 | LOW | `evm_version` not listed in bytecode determinism constraints in CLAUDE.md | FIXED |

## Pass 1 (Security)

| ID | Severity | Finding | File | Status |
|----|----------|---------|------|--------|
| P1/A01-F06 | LOW | Non-standard tokens with non-ABI return data get `ReadFailure` | `pass1/TOFUTokenDecimals.md` | DOCUMENTED |
| P1/A01-F07 | LOW | Non-contract addresses return `ReadFailure` (correctly handled) | `pass1/TOFUTokenDecimals.md` | DISMISSED |
| P1/A03-1 | LOW | TOCTOU gap between `ensureDeployed()` and external call | `pass1/LibTOFUTokenDecimals.md` | DISMISSED |
| P1/A04-F02 | LOW | `staticcall` forwards all remaining gas | `pass1/LibTOFUTokenDecimalsImplementation.md` | DISMISSED |
| P1/A04-F10 | LOW | Non-deterministic token `decimals()` handling | `pass1/LibTOFUTokenDecimalsImplementation.md` | DISMISSED |

## Pass 2 (Test Coverage)

| ID | Severity | Finding | File | Status |
|----|----------|---------|------|--------|
| P2/A01-1 | LOW | Concrete-level tests only cover Initial/happy path | `pass2/TOFUTokenDecimals.md` | FIXED |
| P2/A01-2 | LOW | No concrete-level test for `ReadFailure` wiring | `pass2/TOFUTokenDecimals.md` | FIXED |
| P2/A01-3 | LOW | No concrete-level test for `Inconsistent` outcome wiring | `pass2/TOFUTokenDecimals.md` | FIXED |
| P2/A01-4 | LOW | No concrete-level test for `TokenDecimalsReadFailure` error propagation | `pass2/TOFUTokenDecimals.md` | FIXED |
| P2/A01-5 | LOW | No concrete-level test for cross-token storage isolation | `pass2/TOFUTokenDecimals.md` | FIXED |
| P2/A01-6 | LOW | No concrete-level test for storage immutability after non-Initial | `pass2/TOFUTokenDecimals.md` | FIXED |
| P2/A02-1 | LOW | Concrete contract tests only cover Initial/happy-path outcome | `pass2/ITOFUTokenDecimals.md` | DISMISSED |
| P2/A03-1 | LOW | No test that `safeDecimalsForTokenReadOnly` does not write storage | `pass2/LibTOFUTokenDecimals.md` | FIXED |
| P2/A03-5 | LOW | No integration test against real mainnet tokens via library | `pass2/LibTOFUTokenDecimals.md` | FIXED |
| P2/A04-3 | LOW | No explicit assertion that `decimalsForTokenReadOnly` does not write storage | `pass2/LibTOFUTokenDecimalsImplementation.md` | FIXED |

## Pass 3 (Documentation)

| ID | Severity | Finding | File | Status |
|----|----------|---------|------|--------|
| P3/A02-1 | LOW | Enum `TOFUOutcome` lacks `@notice` NatSpec tag | `pass3/ITOFUTokenDecimals.md` | DISMISSED |
| P3/A02-2 | LOW | Enum variants lack `@notice` NatSpec tags | `pass3/ITOFUTokenDecimals.md` | DISMISSED |
| P3/A02-3 | LOW | `decimalsForTokenReadOnly` lacks `@notice` NatSpec tag | `pass3/ITOFUTokenDecimals.md` | DISMISSED |
| P3/A02-4 | LOW | `decimalsForToken` lacks `@notice` NatSpec tag | `pass3/ITOFUTokenDecimals.md` | DISMISSED |
| P3/A02-5 | LOW | `safeDecimalsForToken` lacks `@notice` NatSpec tag | `pass3/ITOFUTokenDecimals.md` | DISMISSED |
| P3/A02-6 | LOW | `safeDecimalsForTokenReadOnly` lacks `@notice` NatSpec tag | `pass3/ITOFUTokenDecimals.md` | DISMISSED |
| P3/A03-1 | LOW | Constants use plain `///` comments rather than NatSpec tags | `pass3/LibTOFUTokenDecimals.md` | DISMISSED |
| P3/A03-2 | LOW | `ensureDeployed` uses plain `///` comment rather than `@notice` | `pass3/LibTOFUTokenDecimals.md` | DISMISSED |
| P3/A03-3 | LOW | Error `@notice` does not fully describe the revert condition (codehash mismatch) | `pass3/LibTOFUTokenDecimals.md` | FIXED |
| P3/A04-6 | MEDIUM | `safeDecimalsForTokenReadOnly` doc omits warning about lack of TOFU protection before initialization | `pass3/LibTOFUTokenDecimalsImplementation.md` | FIXED |
