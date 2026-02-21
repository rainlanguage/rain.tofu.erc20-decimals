# Pass 1: Security --- TOFUTokenDecimals.sol (Agent A04)

## Evidence of Reading

**Contract name**: `TOFUTokenDecimals` (line 13), inherits `ITOFUTokenDecimals`

**Pragma**: `pragma solidity =0.8.25;` (line 3) -- exact version pin for bytecode determinism

**Imports** (lines 5-6):
- `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult`, `TOFUOutcome` from `../interface/ITOFUTokenDecimals.sol`
- `LibTOFUTokenDecimalsImplementation` from `../lib/LibTOFUTokenDecimalsImplementation.sol`

**State variables**:
- `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals` -- line 16

**Functions** (all `external`, all in `TOFUTokenDecimals.sol`):
- `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` -- line 19
- `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` -- line 25
- `safeDecimalsForToken(address token) external returns (uint8)` -- line 31
- `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` -- line 36

**Types/errors/constants used** (defined in dependencies):
- `struct TOFUTokenDecimalsResult { bool initialized; uint8 tokenDecimals; }` -- ITOFUTokenDecimals.sol line 13
- `enum TOFUOutcome { Initial, Consistent, Inconsistent, ReadFailure }` -- ITOFUTokenDecimals.sol line 19
- `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` -- ITOFUTokenDecimals.sol line 55
- `bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567` -- LibTOFUTokenDecimalsImplementation.sol line 15

**No constructor** is defined; the contract uses the default no-argument constructor.

**No receive/fallback** functions are defined.

**No owner, admin, or privileged roles** are defined.

## Findings

No findings.

### Rationale

Each checklist item is addressed below:

**Access controls on state-modifying functions**: `decimalsForToken` and `safeDecimalsForToken` are the two state-modifying functions. Both are callable by anyone, which is by design. The TOFU model only writes storage on the `Initial` outcome (first read for a given token). Once initialized, the stored value is never overwritten. There is no benefit to restricting who can perform the first initialization -- any caller arriving first writes the same value that any other caller would have written, because the value comes from the token's own `decimals()` function via `staticcall`. An attacker cannot influence the stored value unless they control the token contract itself, in which case the token is already compromised regardless. Permissionless access is correct and intentional for a shared singleton.

**Reentrancy**: The external call to the token is performed via `staticcall` in the assembly block of `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` (line 47 of the implementation). `staticcall` prevents the called contract from modifying any state, which eliminates the classical reentrancy vector. The state-writing path in `decimalsForToken` writes storage only after the `staticcall` has completed and only on the `Initial` outcome. Even if reentrancy were somehow possible (it is not with `staticcall`), the write is idempotent for a given token -- it sets `initialized = true` and `tokenDecimals` to the value just read, and subsequent calls for the same token will never reach the `Initial` branch again. No reentrancy risk exists.

**Storage layout safety**: The contract declares a single state variable: `mapping(address => TOFUTokenDecimalsResult) internal sTOFUTokenDecimals` at slot 0. Each key maps to a `TOFUTokenDecimalsResult` struct containing `bool initialized` (1 byte) and `uint8 tokenDecimals` (1 byte), which pack into a single 32-byte storage slot. The `initialized` flag correctly distinguishes a stored `0` decimals from uninitialized storage (both fields default to `0`/`false`). There is no inheritance that introduces additional storage slots -- `ITOFUTokenDecimals` is an interface with no state. There is no proxy pattern or delegatecall, so storage collision is not a concern. The layout is safe and minimal.

**Missing access controls**: No access controls are missing. The contract is designed as a permissionless singleton. There is no administrative functionality, no upgradeability, no `selfdestruct`, no ETH handling, no token transfers, and no privileged operations. The only state mutation is the one-time-per-token write in `decimalsForToken`, which stores a value read directly from the token itself. Adding access controls would be counterproductive for a shared infrastructure contract deployed via deterministic factory.

**Custom errors only**: The contract itself contains no `revert` statements -- it is a pure delegation layer. The implementation library uses `revert ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome)` (a custom error) in both `safeDecimalsForToken` (line 143) and `safeDecimalsForTokenReadOnly` (line 167). No string reverts (`revert("...")` or `require(condition, "message")`) are used anywhere in the contract or its implementation library. This is correct.

**Additional observations**:
- The contract has no constructor, so no initialization logic can go wrong and there is no deployment front-running concern beyond what the Zoltu deterministic factory already handles.
- The `view` modifier on `decimalsForTokenReadOnly` and `safeDecimalsForTokenReadOnly` is correctly applied, and these functions correctly delegate to the `internal view` library functions. The compiler enforces that no state writes occur in these paths.
- The `// slither-disable-next-line unused-return` annotations on lines 20 and 26 are appropriate -- the return values are forwarded to the caller, and Slither's false positive is correctly suppressed.
