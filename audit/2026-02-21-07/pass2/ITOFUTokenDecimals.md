# Audit Pass 2 (Test Coverage) -- ITOFUTokenDecimals.sol

**Agent:** A01
**Date:** 2026-02-21
**File:** `src/interface/ITOFUTokenDecimals.sol`

## Evidence of Thorough Reading

**Interface name:** `ITOFUTokenDecimals`

**Struct:** `TOFUTokenDecimalsResult`
- Fields: `bool initialized`, `uint8 tokenDecimals`

**Enum:** `TOFUOutcome`
- Values: `Initial` (0), `Consistent` (1), `Inconsistent` (2), `ReadFailure` (3)

**Error:** `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`

**Functions (4):**
1. `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` -- read-only TOFU check
2. `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` -- stateful TOFU read (writes on Initial)
3. `safeDecimalsForToken(address token) external returns (uint8)` -- reverts on non-success outcomes
4. `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` -- read-only, reverts on non-success

## Test Coverage Analysis

### TOFUOutcome enum -- all 4 values exercised

| Outcome | decimalsForToken | decimalsForTokenReadOnly | safeDecimalsForToken | safeDecimalsForTokenReadOnly |
|---|---|---|---|---|
| `Initial` | Tested at impl, lib, and concrete layers | Tested at impl, lib, and concrete layers | Tested (success path) at impl, lib, and concrete layers | Tested (success path) at impl, lib, and concrete layers |
| `Consistent` | Tested at impl, lib, and concrete layers | Tested at impl, lib, and concrete layers | Tested (success path) at impl, lib, and concrete layers | Tested (success path) at impl, lib, and concrete layers |
| `Inconsistent` | Tested at impl, lib, and concrete layers | Tested at impl, lib, and concrete layers | Tested (revert path) at impl, lib, and concrete layers | Tested (revert path) at impl, lib, and concrete layers |
| `ReadFailure` | Tested at impl, lib, and concrete layers | Tested at impl, lib, and concrete layers | Tested (revert path) at impl, lib, and concrete layers | Tested (revert path) at impl, lib, and concrete layers |

### TokenDecimalsReadFailure error -- tested with both relevant outcomes

- **With `TOFUOutcome.ReadFailure`:** Tested across all safe-variant test files for address(0), reverting tokens (`vm.etch` with `hex"fd"`), too-large return values (`> 0xff`), insufficient return data (`< 0x20 bytes`), and STOP-opcode contracts (`hex"00"`). Both uninitialized and initialized storage states are covered.
- **With `TOFUOutcome.Inconsistent`:** Tested in all safe-variant test files via fuzz tests that initialize with `decimalsA` then mock `decimalsB != decimalsA`.

### TOFUTokenDecimalsResult struct -- exercised

- The `initialized` flag is explicitly tested by the `decimals=0` boundary tests at the concrete layer (`testDecimalsForTokenDecimalsZero`, `testSafeDecimalsForTokenDecimalsZero`, `testSafeDecimalsForTokenReadOnlyDecimalsZero`, `testDecimalsForTokenReadOnlyDecimalsZero`) which prove that stored `0` is distinguished from uninitialized storage.
- The struct is directly constructed in `LibTOFUTokenDecimalsImplementation` tests via `sTokenTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: ...})` to set up initialized-storage preconditions.

### Test layers covering the interface types

1. **`LibTOFUTokenDecimalsImplementation` (impl layer, no fork):**
   - `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol`
   - `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol`
   - `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol`
   - `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol`

2. **`LibTOFUTokenDecimals` (lib layer, fork-based):**
   - `test/src/lib/LibTOFUTokenDecimals.decimalsForToken.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`
   - `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol`

3. **`TOFUTokenDecimals` (concrete layer, no fork):**
   - `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol`
   - `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol`
   - `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol`
   - `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol`

## Findings

No findings.

All four `TOFUOutcome` enum values are exercised across all four interface functions, at all three implementation layers (impl, lib, concrete). The `TokenDecimalsReadFailure` error is tested with both `ReadFailure` and `Inconsistent` outcomes (the only two that trigger it), under both uninitialized and initialized storage states. The `TOFUTokenDecimalsResult` struct's `initialized` flag is explicitly boundary-tested with `decimals=0` to confirm it distinguishes stored zero from uninitialized storage. Coverage is thorough and no untested types or error conditions were identified.
