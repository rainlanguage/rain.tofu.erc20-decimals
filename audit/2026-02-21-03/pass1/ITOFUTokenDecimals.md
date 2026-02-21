# Pass 1: Security — ITOFUTokenDecimals.sol

Agent: A03

## Evidence of Thorough Reading

### src/interface/ITOFUTokenDecimals.sol

- **SPDX License**: `LicenseRef-DCL-1.0` (line 1)
- **Pragma**: `^0.8.25` (line 3)
- **Struct**: `TOFUTokenDecimalsResult` (line 13)
  - Field `initialized`: `bool` (line 14) -- distinguishes stored 0 decimals from uninitialized storage
  - Field `tokenDecimals`: `uint8` (line 15) -- stores the token's decimals value
- **Enum**: `TOFUOutcome` (line 19)
  - `Initial` = 0 (line 21) -- first read, no stored value
  - `Consistent` = 1 (line 23) -- stored value matches current read
  - `Inconsistent` = 2 (line 25) -- stored value differs from current read
  - `ReadFailure` = 3 (line 27) -- `decimals()` call failed or returned invalid data
- **Error**: `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` (line 33)
- **Interface**: `ITOFUTokenDecimals` (line 53)
- **Functions**:
  - `decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8)` (line 67) -- read-only TOFU check, no state modification
  - `decimalsForToken(address token) external returns (TOFUOutcome, uint8)` (line 77) -- reads and stores on first use
  - `safeDecimalsForToken(address token) external returns (uint8)` (line 83) -- reverts on inconsistency or read failure
  - `safeDecimalsForTokenReadOnly(address token) external view returns (uint8)` (line 91) -- read-only safe variant

## Findings

### A03-1: Enum zero-value `Initial` is a safe default [INFO]

The `TOFUOutcome` enum assigns `Initial` (meaning "not yet stored") to the zero value (index 0). In Solidity, uninitialized enum variables default to their zero value. If any code path inadvertently uses a default-initialized `TOFUOutcome`, it would be interpreted as `Initial` rather than a more alarming state like `ReadFailure`.

This is actually a **reasonable design choice** for this codebase. The `TOFUOutcome` is always returned from functions that explicitly set it, and `Initial` as the zero-value aligns semantically with "nothing has happened yet." A default of `ReadFailure` or `Inconsistent` at position 0 would be more dangerous, as it could cause false-positive reverts. The current ordering is sound.

No remediation needed.

### A03-2: NatSpec on `decimalsForTokenReadOnly` return for `Initial` case could be clearer about read-only semantics [INFO]

The NatSpec for `decimalsForTokenReadOnly` (lines 63-66) documents that on `Initial`, the return is "the freshly read value." This is correct but does not explicitly state that the value is **not persisted**. The function's own description (lines 54-61) does say "This does not store the decimals," but the `@return` doc for `tokenDecimals` does not repeat this caveat. A reader focusing only on the return value documentation could miss that the `Initial` outcome from this function leaves the token uninitialized.

The implementation in `LibTOFUTokenDecimalsImplementation` (lines 34-84) confirms the read-only function never writes to storage, so this is purely a documentation clarity concern.

No code change needed; this is a minor NatSpec completeness note.

### A03-3: Struct packing is optimal [INFO]

`TOFUTokenDecimalsResult` contains `bool initialized` (1 byte) and `uint8 tokenDecimals` (1 byte). These pack into a single 32-byte storage slot. The Solidity compiler will pack `bool` (1 byte) and `uint8` (1 byte) together in the same slot, using only 2 bytes of a 32-byte word. This is optimal for a mapping value type and keeps SSTORE/SLOAD costs minimal (single slot read/write). The assembly code in `LibTOFUTokenDecimalsImplementation` reads the struct into memory via the Solidity-generated memory layout, not raw slot manipulation, so struct field ordering does not introduce any assembly/layout mismatch risk.

No issue.

### A03-4: The `TokenDecimalsReadFailure` error could fire with `Initial` or `Consistent` outcome in theory [INFO]

The error `TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)` is defined to accept any `TOFUOutcome` value. Looking at the implementation in `LibTOFUTokenDecimalsImplementation`, the `safe*` functions (lines 140-174) only revert when the outcome is neither `Consistent` nor `Initial`, meaning the error is only ever emitted with `Inconsistent` or `ReadFailure`. The error type itself does not constrain this, which is fine -- the type system does not need to enforce this invariant, and having a general error type is standard practice. Including the `tofuOutcome` in the error data is valuable for debugging.

No issue.

### A03-5: Interface does not expose stored state or provide a query-only getter for the raw `TOFUTokenDecimalsResult` [LOW]

The interface does not include a function to query the raw stored `TOFUTokenDecimalsResult` for a given token address (i.e., to check whether a token is initialized and what its stored decimals are without triggering a new `decimals()` call to the token contract). Both `decimalsForTokenReadOnly` and `decimalsForToken` always perform an external `staticcall` to the token. There is no way for a caller to:

1. Check if a token has been initialized without making an external call to that token.
2. Retrieve the stored decimals without depending on the token contract being callable.

This means if a token contract self-destructs, becomes unreachable, or starts reverting, the only way to retrieve previously stored decimals is through `decimalsForTokenReadOnly`, which returns `ReadFailure` with the stored value. While this does return the stored value, the `safe*` variants would revert, making it impossible to safely retrieve known-good stored decimals when the token contract is broken.

However, the concrete contract `TOFUTokenDecimals` declares the mapping as `internal`, so it is not externally accessible. Adding a pure read of storage (without external call) could be useful for recovery scenarios, but this is a design trade-off rather than a vulnerability.

### A03-6: No event definitions in the interface [INFO]

The interface does not define any events. There are no events for token decimals initialization or inconsistency detection. While events are not strictly required for correctness, they are commonly expected for observability. Indexers or off-chain monitors would not be able to track which tokens have been initialized or when inconsistencies are detected without parsing transaction traces.

This is a design choice rather than a security issue. The contract is designed to be a lightweight singleton, and adding events would increase gas costs for every call.

No security finding.
