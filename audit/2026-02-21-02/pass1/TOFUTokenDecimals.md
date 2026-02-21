# Security Audit: `src/concrete/TOFUTokenDecimals.sol`

**Audit ID:** 2026-02-21-02, Pass 1 (Security)
**Agent:** A02
**File:** `src/concrete/TOFUTokenDecimals.sol`

## Evidence of Thorough Reading

### Contract
- **`TOFUTokenDecimals`** (line 13) -- inherits `ITOFUTokenDecimals`

### State Variables
- `sTOFUTokenDecimals` (line 16): `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)`, visibility `internal`

### Functions
| Function | Line | Mutability | Visibility |
|---|---|---|---|
| `decimalsForTokenReadOnly` | 19 | `view` | `external` |
| `decimalsForToken` | 25 | non-view (state-changing) | `external` |
| `safeDecimalsForToken` | 31 | non-view (state-changing) | `external` |
| `safeDecimalsForTokenReadOnly` | 36 | `view` | `external` |

### Imported Types/Errors/Constants (from `ITOFUTokenDecimals.sol`)
- `struct TOFUTokenDecimalsResult` (fields: `bool initialized`, `uint8 tokenDecimals`)
- `enum TOFUOutcome` (values: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`)
- `error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome)`
- `interface ITOFUTokenDecimals` (4 functions)

### Imported Library (from `LibTOFUTokenDecimalsImplementation.sol`)
- `library LibTOFUTokenDecimalsImplementation`
- `bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567`
- Functions: `decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`

### Compiler/Build Settings (from `foundry.toml`)
- `solc = "0.8.25"` (exact in concrete contract: `pragma solidity =0.8.25`)
- `evm_version = "cancun"`
- `optimizer = true`, `optimizer_runs = 1000000`
- `bytecode_hash = "none"`, `cbor_metadata = false`

---

## Findings

### LOW-1: No access control on `decimalsForToken` allows anyone to set the TOFU value for any token

**Severity:** LOW

**Description:** The `decimalsForToken` function (line 25) is `external` with no access restrictions. Any EOA or contract can call it to initialize the stored decimals for any token address. This means an attacker could front-run a protocol's first call to `decimalsForToken` for a given token. However, because the implementation reads the actual `decimals()` return value from the token contract via `staticcall`, the attacker's front-running call would store the same value that the legitimate caller would have stored. The only scenario where this matters is if the token's `decimals()` return value changes between the attacker's transaction and the legitimate caller's transaction (e.g., a proxy token whose implementation is upgraded between blocks). In that narrow window, the attacker could lock in a stale value.

**Impact:** Minimal in practice. The stored value is always whatever `decimals()` returns at call time. The TOFU design explicitly accepts the first-read value, so this is largely by design. The risk is limited to the scenario of a proxy token whose decimals change between blocks during the initialization window.

**Recommendation:** This is inherent to the TOFU design and the singleton pattern. Document that callers should initialize tokens they care about as early as possible, ideally in the same transaction as deployment or first use.

---

### LOW-2: Storage mapping visibility is `internal`, preventing external inspection of stored state

**Severity:** LOW

**Description:** The `sTOFUTokenDecimals` mapping (line 16) is `internal`. There is no public getter or function that exposes whether a token has been initialized or what its stored decimals value is, independent of a fresh `decimals()` call to the token. The only way to query is via `decimalsForTokenReadOnly`, which makes a fresh external call and returns the *outcome* but on `ReadFailure` returns the stored value (zero if uninitialized), making it impossible to distinguish "stored 0 decimals" from "uninitialized" purely from the return values when the external call fails.

Specifically: if `decimalsForTokenReadOnly` returns `(ReadFailure, 0)`, the caller cannot tell whether the token was previously initialized with `tokenDecimals = 0` or was never initialized at all.

**Impact:** A caller who needs to distinguish "initialized with 0 decimals but token is now unreachable" from "never initialized and token is unreachable" cannot do so through the contract interface.

**Recommendation:** Consider adding a view function that returns the raw `TOFUTokenDecimalsResult` struct (the `initialized` flag and `tokenDecimals`) for a given token, without making an external call. This would allow callers to inspect the stored state directly.

---

### INFO-1: Pragma version is pinned exactly as required for bytecode determinism

**Severity:** INFO (no action needed)

**Description:** The concrete contract uses `pragma solidity =0.8.25` (line 3), which pins the exact compiler version. This is consistent with `foundry.toml` setting `solc = "0.8.25"` and the project requirement that bytecode determinism is critical. The imported files use `^0.8.25` which is appropriate for library/interface code that may be consumed by other projects.

---

### INFO-2: Contract has no constructor, receive, or fallback function

**Severity:** INFO (no action needed)

**Description:** `TOFUTokenDecimals` has no constructor, `receive()`, or `fallback()` function. This means:
- It cannot accept ETH (calls with value will revert via the default behavior).
- There is no initialization logic that could be front-run or replayed.
- The default fallback behavior reverts on unknown selectors.

This is correct and desirable for a singleton pattern deployed via a deterministic factory.

---

### INFO-3: No reentrancy risk in the concrete contract

**Severity:** INFO (no action needed)

**Description:** `decimalsForToken` (the only state-changing path) delegates to `LibTOFUTokenDecimalsImplementation.decimalsForToken`, which internally calls `decimalsForTokenReadOnly`. That function uses `staticcall` to read `decimals()` from the token, which cannot modify state. The storage write (in `decimalsForToken`) happens after the `staticcall` completes, but since `staticcall` prevents the callee from making state changes or callbacks, reentrancy is not possible through the token call. The `external` entry points follow a read-then-write pattern, but the read uses `staticcall`, making reentrancy a non-issue.

---

### INFO-4: Assembly block in `LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly` is correctly annotated as memory-safe

**Severity:** INFO (no action needed)

**Description:** The assembly block at line 50 of `LibTOFUTokenDecimalsImplementation.sol` uses the `"memory-safe"` annotation. The block writes to memory offset 0 (the scratch space) for the selector and reads the return data from offset 0. Solidity's scratch space (offsets 0x00-0x3f) is explicitly designated for short-lived use by inline assembly. The `tofuTokenDecimals` memory struct was loaded before the assembly block (line 39) and is referenced after it (lines 67, 72, 80-81), but since it is a memory pointer (stored on the stack), the scratch space writes do not corrupt it. The `"memory-safe"` annotation is justified.

---

## Summary

The `TOFUTokenDecimals.sol` concrete contract is a thin delegation layer with minimal surface area. It contains no constructor, no admin functions, no ETH handling, and no complex logic of its own. The security-relevant logic resides in `LibTOFUTokenDecimalsImplementation`, which uses `staticcall` for external reads and properly validates return data. No critical or high severity issues were found. Two low-severity observations are noted regarding permissionless initialization and the inability to externally inspect raw stored state.

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 2 |
| INFO | 4 |
