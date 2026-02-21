# Pass 2: Test Coverage -- ITOFUTokenDecimals.sol (Agent A01)

## Evidence of Reading

### Types, Errors, Structs, and Enums Defined in Source

File: `src/interface/ITOFUTokenDecimals.sol`

| Item | Kind | Lines |
|------|------|-------|
| `TOFUTokenDecimalsResult` | struct | 13-16 |
| `TOFUTokenDecimalsResult.initialized` | field (bool) | 14 |
| `TOFUTokenDecimalsResult.tokenDecimals` | field (uint8) | 15 |
| `TOFUOutcome` | enum | 19-28 |
| `TOFUOutcome.Initial` | variant (0) | 21 |
| `TOFUOutcome.Consistent` | variant (1) | 23 |
| `TOFUOutcome.Inconsistent` | variant (2) | 25 |
| `TOFUOutcome.ReadFailure` | variant (3) | 27 |
| `ITOFUTokenDecimals` | interface | 48-97 |
| `ITOFUTokenDecimals.TokenDecimalsReadFailure` | error | 52 |
| `ITOFUTokenDecimals.decimalsForTokenReadOnly` | function | 67 |
| `ITOFUTokenDecimals.decimalsForToken` | function | 78 |
| `ITOFUTokenDecimals.safeDecimalsForToken` | function | 84 |
| `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly` | function | 96 |

### Test Files Referencing These Types

**`TOFUTokenDecimalsResult` struct** (used in 6 test files):
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- (also indirectly via concrete contract tests which go through the concrete wrapper)

**`TOFUOutcome` enum** (used in 16 test files -- all test files):
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.t.sol`
- `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/concrete/TOFUTokenDecimals.immutability.t.sol`

All four `TOFUOutcome` enum variants are asserted in tests:
- `TOFUOutcome.Initial`: asserted in 30+ assertions across multiple test files
- `TOFUOutcome.Consistent`: asserted in 26+ assertions across multiple test files
- `TOFUOutcome.Inconsistent`: asserted in 14+ assertions across multiple test files
- `TOFUOutcome.ReadFailure`: asserted in 75+ assertions across multiple test files

**`TokenDecimalsReadFailure` error** (used in 8 test files):
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
- `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol` (imports ITOFUTokenDecimals)
- `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` (imports ITOFUTokenDecimals)

The error is tested with both `TOFUOutcome.ReadFailure` and `TOFUOutcome.Inconsistent` payloads via `vm.expectRevert(abi.encodeWithSelector(...))`.

**`ITOFUTokenDecimals` interface functions** -- all four functions have dedicated test files at both the implementation layer (LibTOFUTokenDecimalsImplementation), the convenience library layer (LibTOFUTokenDecimals), and the concrete contract layer (TOFUTokenDecimals).

## Findings

No findings.

All types defined in `ITOFUTokenDecimals.sol` have thorough test coverage:

- The `TOFUTokenDecimalsResult` struct is constructed in test setup with both `initialized: true` and the implicit `initialized: false` (default/uninitialized storage) paths exercised.
- All four `TOFUOutcome` enum variants are explicitly asserted in tests.
- The `TokenDecimalsReadFailure` error is tested for both trigger conditions (`Inconsistent` outcome and `ReadFailure` outcome) across both `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` at all three architectural layers.
- All four interface functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) have dedicated test files with fuzz testing at each layer of the architecture.
