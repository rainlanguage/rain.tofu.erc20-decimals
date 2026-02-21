# Pass 3: Documentation — TOFUTokenDecimals.sol

Agent: A02

## Evidence of Thorough Reading

**File:** `src/concrete/TOFUTokenDecimals.sol` (39 lines)

**Contract:** `TOFUTokenDecimals` (line 13), inherits `ITOFUTokenDecimals`.

**Imports (lines 5-6):**
- `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome` from `../interface/ITOFUTokenDecimals.sol`
- `LibTOFUTokenDecimalsImplementation` from `../lib/LibTOFUTokenDecimalsImplementation.sol`

**Contract-level NatSpec (lines 8-12):**
- `@title TOFUTokenDecimals`
- `@notice` describing the contract as a minimal implementation that stores the mapping and delegates to the library.

**State variables:**
- `sTOFUTokenDecimals` — `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal` (line 16). Has `@notice` on line 14.

**Functions (all external, all using `@inheritdoc ITOFUTokenDecimals`):**

| # | Function | Line | Mutability | @inheritdoc |
|---|----------|------|------------|-------------|
| 1 | `decimalsForTokenReadOnly(address)` | 19 | `view` | line 18 |
| 2 | `decimalsForToken(address)` | 25 | (non-view) | line 24 |
| 3 | `safeDecimalsForToken(address)` | 31 | (non-view) | line 30 |
| 4 | `safeDecimalsForTokenReadOnly(address)` | 36 | `view` | line 35 |

**Types/errors/constants referenced (from interface file `src/interface/ITOFUTokenDecimals.sol`):**
- `TOFUTokenDecimalsResult` struct (interface line 13): fields `initialized` (bool), `tokenDecimals` (uint8). Has `@notice` and `@param` tags.
- `TOFUOutcome` enum (interface line 19): variants `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`. Each variant has a `///` comment.
- `TokenDecimalsReadFailure` error (interface line 33): params `token`, `tofuOutcome`. Has `@notice` and `@param` tags.

## Findings

### @inheritdoc Verification

All four `@inheritdoc ITOFUTokenDecimals` references resolve correctly to the interface declarations:

1. `decimalsForTokenReadOnly` -> interface line 67, NatSpec lines 54-66. Covers purpose, `@param token`, `@return tofuOutcome`, `@return tokenDecimals` with per-outcome semantics.
2. `decimalsForToken` -> interface line 77, NatSpec lines 69-76. Covers purpose, `@param token`, `@return tofuOutcome`, `@return tokenDecimals` with per-outcome semantics.
3. `safeDecimalsForToken` -> interface line 83, NatSpec lines 79-82. Covers purpose, `@param token`, `@return tokenDecimals`.
4. `safeDecimalsForTokenReadOnly` -> interface line 91, NatSpec lines 85-90. Covers purpose including the uninitialized caveat, `@param token`, `@return tokenDecimals`.

### Documentation Accuracy Checks

- Contract `@notice` says it "stores the mapping ... and delegates all logic to the library" -- **accurate**: all four functions delegate directly to `LibTOFUTokenDecimalsImplementation` passing the storage mapping.
- Interface NatSpec for `decimalsForTokenReadOnly` states it "does not store the decimals" -- **accurate**: the concrete delegates to the library's `view` function.
- Interface NatSpec for `decimalsForToken` states it stores on first read -- **accurate**: the library stores on `TOFUOutcome.Initial` (library line 123-124).
- Interface NatSpec for both `safe*` functions states they revert on failure/inconsistency -- **accurate**: library reverts with `TokenDecimalsReadFailure` when outcome is neither `Consistent` nor `Initial`.
- Interface return value semantics ("On `ReadFailure`, the stored value (zero if uninitialized)") -- **accurate**: library returns `tofuTokenDecimals.tokenDecimals` which defaults to 0 for uninitialized storage.
- Interface NatSpec for `safeDecimalsForTokenReadOnly` warns that before initialization each call is a fresh `Initial` read -- **accurate**: the library's read-only path does not persist, confirmed by `view` mutability.

No documentation findings.
