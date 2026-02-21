# Pass 2: Test Coverage -- ITOFUTokenDecimals.sol

Agent: A03

## Evidence of Thorough Reading

### src/interface/ITOFUTokenDecimals.sol
- **Struct**: `TOFUTokenDecimalsResult` (lines 13-16) -- contains `bool initialized` and `uint8 tokenDecimals`. The `initialized` flag guards against `0` being misinterpreted as a valid stored value when storage is actually uninitialized.
- **Enum**: `TOFUOutcome` (lines 19-28) -- four variants: `Initial` (0), `Consistent` (1), `Inconsistent` (2), `ReadFailure` (3). Represents the result of a TOFU read operation.
- **Error**: `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 33) -- thrown by the safe read functions when the outcome is neither `Initial` nor `Consistent`.
- **Interface**: `ITOFUTokenDecimals` (lines 53-92) -- four functions:
  - `decimalsForTokenReadOnly(address) external view returns (TOFUOutcome, uint8)` -- read-only check, does not persist state.
  - `decimalsForToken(address) external returns (TOFUOutcome, uint8)` -- reads and stores on first use.
  - `safeDecimalsForToken(address) external returns (uint8)` -- reverts on `Inconsistent` or `ReadFailure`.
  - `safeDecimalsForTokenReadOnly(address) external view returns (uint8)` -- read-only variant of safe read, reverts on `Inconsistent` or `ReadFailure`.
- **NatSpec return semantics**: On `Initial`, return the freshly read value. On `Consistent` or `Inconsistent`, return the previously stored value. On `ReadFailure`, return the stored value (zero if uninitialized). This is consistently documented across all four functions.

## Indirect Coverage Analysis

Since `ITOFUTokenDecimals.sol` is a pure interface file (no implementation logic), all testing is indirect through the three layers that use these types.

### TOFUTokenDecimalsResult struct

**Where tested:**
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForToken.t.sol` -- Directly constructs `TOFUTokenDecimalsResult{initialized: true, tokenDecimals: ...}` to pre-populate storage for testing initialized-state behavior (lines 22-23, 62, 85, 176).
- `test/src/lib/LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly.t.sol` -- Same pattern for read-only tests (lines 22-23, 39, 61, 87, 103).
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` -- Pre-populates storage to test initialized revert paths (lines 27, 74, 109, 124).
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` -- Same pattern (lines 27, 40, 67, 102, 117).

**Coverage assessment:**
- The struct is exercised with both `initialized: true` (explicit initialization) and the implicit `initialized: false` (default storage state).
- The `tokenDecimals` field is tested across the full `uint8` range via fuzz testing.
- The initialized/uninitialized distinction is thoroughly tested: uninitialized storage returns `Initial` on first read; initialized storage returns `Consistent`/`Inconsistent`.

### TOFUOutcome enum

**Where tested -- all four variants:**

1. **`Initial`**: Tested in `decimalsForToken` tests (first call to an uninitialized token), `decimalsForTokenReadOnly` tests (call with no stored value), and `safeDecimalsForToken` tests (first call succeeds without revert). Verified across all three layers: `LibTOFUTokenDecimalsImplementation`, `LibTOFUTokenDecimals`, and `TOFUTokenDecimals` concrete.

2. **`Consistent`**: Tested by first initializing with `decimalsA`, then reading again with the same `decimalsA`. Verified across all three layers with fuzz tests that check `decimalsA == decimalsB` branch.

3. **`Inconsistent`**: Tested by initializing with `decimalsA`, then reading with different `decimalsB` (`vm.assume(decimalsA != decimalsB)`). Verified that the returned decimals value is the **stored** value (not the new read), and that `safeDecimalsForToken` reverts with `TokenDecimalsReadFailure` containing `TOFUOutcome.Inconsistent`.

4. **`ReadFailure`**: Tested via multiple failure modes:
   - `address(0)` (no code to call)
   - `vm.etch(token, hex"fd")` (revert opcode)
   - Mock returning data too large for `uint8` (`> 0xff`)
   - Mock returning data shorter than 32 bytes (`< 0x20`)
   - All tested in both uninitialized and initialized states.

**Coverage assessment:** All four variants are exercised in every relevant test file, at all three architectural layers.

### TokenDecimalsReadFailure error

**Where tested:**
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForToken.t.sol` -- 8 `vm.expectRevert` calls with the error selector, testing both `TOFUOutcome.ReadFailure` and `TOFUOutcome.Inconsistent` payloads.
- `test/src/lib/LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly.t.sol` -- 9 `vm.expectRevert` calls with the error selector.
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForToken.t.sol` -- 8 `vm.expectRevert` calls.
- `test/src/lib/LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` -- 8 `vm.expectRevert` calls.
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol` -- 2 `vm.expectRevert` calls (Inconsistent + ReadFailure).
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` -- 2 `vm.expectRevert` calls (Inconsistent + ReadFailure).

**Coverage assessment:**
- The error is verified to contain the correct `token` address and the correct `TOFUOutcome` value.
- Both `TOFUOutcome.Inconsistent` and `TOFUOutcome.ReadFailure` are tested as error payloads.
- The error is never emitted with `TOFUOutcome.Initial` or `TOFUOutcome.Consistent`, which is correct by design.

### ITOFUTokenDecimals interface

**Where tested:**
- `TOFUTokenDecimals` (in `src/concrete/TOFUTokenDecimals.sol`) declares `contract TOFUTokenDecimals is ITOFUTokenDecimals`, so the compiler enforces that all four interface functions are implemented.
- `test/src/concrete/TOFUTokenDecimals.decimalsForToken.t.sol` -- Tests all four outcomes through the concrete contract (Initial, Consistent, Inconsistent, ReadFailure), plus cross-token isolation and storage immutability on non-Initial outcomes.
- `test/src/concrete/TOFUTokenDecimals.decimalsForTokenReadOnly.t.sol` -- Tests all four outcomes, plus verifies read-only does not write storage.
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForToken.t.sol` -- Tests success paths (Initial, Consistent) and revert paths (Inconsistent, ReadFailure).
- `test/src/concrete/TOFUTokenDecimals.safeDecimalsForTokenReadOnly.t.sol` -- Tests success and revert paths, plus verifies read-only does not write storage.
- `test/src/concrete/TOFUTokenDecimals.immutability.t.sol` -- Verifies the deployed bytecode contains no SELFDESTRUCT, DELEGATECALL, or CALLCODE opcodes.
- `LibTOFUTokenDecimals` (convenience library) uses `ITOFUTokenDecimals` as the type for `TOFU_DECIMALS_DEPLOYMENT` and calls all four interface functions through it. All four are tested in dedicated test files.
- Real token integration tests in `test/src/lib/LibTOFUTokenDecimals.realTokens.t.sol` exercise the interface via the singleton on a mainnet fork against WETH, USDC, WBTC, and DAI.

**Coverage assessment:** The interface is thoroughly covered both directly (through the concrete contract) and indirectly (through the library wrappers).

## Findings

### A03-1: No direct interface conformance test via the ITOFUTokenDecimals type [INFO]

No test file casts or references `TOFUTokenDecimals` through an `ITOFUTokenDecimals`-typed variable. While the Solidity compiler enforces interface conformance through the `is ITOFUTokenDecimals` declaration, and `LibTOFUTokenDecimals` does call all four functions through an `ITOFUTokenDecimals`-typed constant, there is no test that explicitly verifies the contract can be called through the interface type (e.g., `ITOFUTokenDecimals(address(concrete)).decimalsForToken(token)`). This is purely informational because:
1. The compiler enforces the function signatures match at compile time.
2. `LibTOFUTokenDecimals` tests exercise all four functions through the interface type indirectly via `TOFU_DECIMALS_DEPLOYMENT` which is typed as `ITOFUTokenDecimals`.

### A03-2: TokenDecimalsReadFailure error is only tested with Inconsistent and ReadFailure outcomes [INFO]

The `TokenDecimalsReadFailure` error is defined with a generic `TOFUOutcome` parameter, meaning it could theoretically be emitted with any of the four enum values. Tests verify it is only emitted with `Inconsistent` and `ReadFailure`, which matches the implementation in `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` (which revert only when the outcome is neither `Initial` nor `Consistent`). This is correct behavior, not a gap.

### A03-3: All enum variants comprehensively tested across three architectural layers [INFO]

Each `TOFUOutcome` variant (`Initial`, `Consistent`, `Inconsistent`, `ReadFailure`) is tested at all three layers:
- **Layer 1** (`LibTOFUTokenDecimalsImplementation`): 5 test files (decimalsForToken, decimalsForTokenReadOnly, safeDecimalsForToken, safeDecimalsForTokenReadOnly, selector test).
- **Layer 2** (`TOFUTokenDecimals` concrete): 5 test files (decimalsForToken, decimalsForTokenReadOnly, safeDecimalsForToken, safeDecimalsForTokenReadOnly, immutability).
- **Layer 3** (`LibTOFUTokenDecimals` convenience library): 6 test files (decimalsForToken, decimalsForTokenReadOnly, safeDecimalsForToken, safeDecimalsForTokenReadOnly, general tests, real token integration).

Fuzz testing with `uint8` inputs ensures the full range of decimals values is exercised. Multiple failure modes (address zero, revert opcode, too-large return, truncated return) are tested in both initialized and uninitialized states.

No coverage gaps were identified for the types and error defined in this interface file.
