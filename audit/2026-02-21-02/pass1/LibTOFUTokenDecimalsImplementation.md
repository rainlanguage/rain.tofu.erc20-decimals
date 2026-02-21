# Security Audit: LibTOFUTokenDecimalsImplementation.sol

**Audit ID:** 2026-02-21-02
**Pass:** 1 (Security)
**Agent:** A05
**File:** `src/lib/LibTOFUTokenDecimalsImplementation.sol`
**Date:** 2026-02-21

---

## Evidence of Thorough Reading

### Library Name
- `LibTOFUTokenDecimalsImplementation` (line 18)

### Functions (with line numbers)
1. `decimalsForTokenReadOnly` (line 34) -- `internal view`, returns `(TOFUOutcome, uint8)`
2. `decimalsForToken` (line 113) -- `internal`, returns `(TOFUOutcome, uint8)`
3. `safeDecimalsForToken` (line 140) -- `internal`, returns `uint8`
4. `safeDecimalsForTokenReadOnly` (line 164) -- `internal view`, returns `uint8`

### Constants
- `TOFU_DECIMALS_SELECTOR` (line 20): `bytes4` constant = `0x313ce567`

### Imported Types/Errors
- `ITOFUTokenDecimals` (interface, imported but unused in this file)
- `TOFUTokenDecimalsResult` (struct: `{ bool initialized; uint8 tokenDecimals; }`)
- `TOFUOutcome` (enum: `Initial`, `Consistent`, `Inconsistent`, `ReadFailure`)
- `TokenDecimalsReadFailure` (error: `(address token, TOFUOutcome tofuOutcome)`)

### Assembly Block (lines 50-62)
- Uses `"memory-safe"` annotation
- Writes selector to scratch space at offset 0
- `staticcall(gas(), token, 0, 0x04, 0, 0x20)` -- forwards all gas, reads 4 bytes of calldata, writes 32 bytes of return data to offset 0
- Checks `returndatasize() < 0x20` as failure
- Checks `readDecimals > 0xff` as failure (uint8 bounds)

---

## Findings

### LOW-01: Scratch space write at offset 0 clobbers the `tofuTokenDecimals` memory struct pointer

**Severity:** LOW

**Location:** Lines 50-57

**Description:**

At line 39, `tofuTokenDecimals` is loaded from storage into memory. In Solidity, the local variable `tofuTokenDecimals` holds a memory pointer to where this struct resides. After the ABI encoding of the struct, the free memory pointer points past it. However, the struct pointer itself is stored on the stack, not at memory offset 0.

The assembly block writes the selector to `mstore(0, selector)` (line 51), which overwrites scratch space (bytes 0-31). Then the `staticcall` writes 32 bytes of return data to offset 0 (the output offset/size parameters are `0, 0x20`). This overwrites the same scratch space region.

Solidity's scratch space is bytes 0x00-0x3f, and the compiler is allowed to use it for temporary operations. The struct `tofuTokenDecimals` is allocated by the compiler at the free memory pointer (0x80+), so the struct data itself is not clobbered. The `"memory-safe"` annotation is correct in this context because the assembly block only writes to scratch space (0x00-0x3f), which is explicitly permitted by Solidity's memory-safe definition.

However, the `mload(0)` at line 57 reads the return data from scratch space, which is where the staticcall wrote its output. If the token contract returns more than 32 bytes, only the first 32 bytes are captured (due to the `0x20` output size limit), and any additional return data is silently ignored. This is safe because `returndatasize()` is checked to be at least `0x20`, and the value is bounds-checked to `<= 0xff`.

**Assessment:** After careful analysis, the scratch space usage is correct and the `"memory-safe"` annotation is valid. The struct is on the heap at 0x80+, not at offset 0. The pointer to it is on the stack. No memory corruption occurs. **This is correct behavior; however, the pattern is subtle and worth noting as it could become a bug if the assembly block were modified to write beyond 0x3f.**

**Recommendation:** Add a brief inline comment noting that offset 0 is Solidity scratch space and is deliberately used to avoid allocating new memory, and that `tofuTokenDecimals` is heap-allocated (0x80+) and unaffected.

---

### LOW-02: `staticcall` with `gas()` forwards all remaining gas to untrusted token contract

**Severity:** LOW

**Location:** Line 52

**Description:**

The `staticcall` forwards all available gas via `gas()` to the target `token` address. While `staticcall` prevents state modifications, a malicious or buggy token contract could consume nearly all remaining gas before returning, leaving very little gas for the caller to complete its transaction.

In a griefing scenario, a malicious token could implement `decimals()` with a gas-consuming loop that burns almost all forwarded gas. The caller would receive a successful return but might not have enough gas left to complete other operations in the same transaction. However, because this is a `staticcall`, the target cannot modify state, and the EVM's 63/64 rule guarantees that 1/64 of the gas is retained by the caller.

**Assessment:** The 63/64 gas retention rule mitigates the worst case, and `staticcall` prevents reentrancy with state changes. In practice, `decimals()` is a view function on well-known ERC20 tokens and should consume minimal gas. Capping gas (e.g., to 30,000) would be more defensive but could break compatibility with tokens that have unusually expensive `decimals()` implementations (e.g., proxy tokens with multiple delegate calls).

**Recommendation:** This is an acceptable design trade-off. Document that `gas()` is intentional to maximize compatibility with proxy-based tokens. If gas griefing becomes a practical concern, consider adding a configurable gas cap.

---

### INFO-01: `decimalsForTokenReadOnly` returns `Initial` on every call before storage initialization, preventing inconsistency detection

**Severity:** INFO

**Location:** Lines 70-76

**Description:**

When `decimalsForTokenReadOnly` is called for a token that has never been initialized via `decimalsForToken`, the `initialized` flag is `false`, and the function always returns `TOFUOutcome.Initial` with whatever the token currently reports. Since the read-only variant never writes to storage, repeated calls will always return `Initial` even if the token changes its decimals between calls. This means the TOFU inconsistency detection is completely bypassed for tokens that have never been initialized.

This is documented in the NatDoc for `safeDecimalsForTokenReadOnly` (lines 152-156) which warns: "Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected."

**Assessment:** This is by design and well-documented. The caller is expected to call `decimalsForToken` at least once to initialize the stored value before relying on the read-only variant. However, callers who only use the read-only variant may get a false sense of security, believing they have TOFU protection when they do not.

**Recommendation:** Already documented. No change needed.

---

### INFO-02: EOA and empty-code addresses silently return `ReadFailure` rather than a distinct error

**Severity:** INFO

**Location:** Lines 50-62

**Description:**

When `token` is an externally owned account (EOA), a precompile, or an address with no deployed code, the `staticcall` will succeed (returning `true`) with `returndatasize() == 0`. The `lt(returndatasize(), 0x20)` check on line 53 catches this and sets `success := 0`, producing a `ReadFailure` outcome.

This is correct defensive behavior. However, the `ReadFailure` outcome conflates several distinct failure modes:
- Token contract reverts
- Token contract returns less than 32 bytes
- Token contract returns a value > 255 (not a valid uint8)
- Target address has no code (EOA)

Callers cannot distinguish between "token has no code deployed" vs "token's decimals() reverted" vs "token returned garbage."

**Assessment:** This is an intentional design simplification. The `TOFUOutcome` enum is kept minimal. All non-success cases are equally "untrustworthy" from the TOFU perspective, so a single `ReadFailure` bucket is appropriate. Callers who need finer-grained diagnostics can check `extcodesize` before calling.

**Recommendation:** No change needed. This is a reasonable design choice for the scope of this library.

---

### INFO-03: Comparison uses `readDecimals` (the live value) against `tofuTokenDecimals.tokenDecimals` (stored), but returns the stored value on both Consistent and Inconsistent

**Severity:** INFO

**Location:** Lines 78-83

**Description:**

On the `Consistent` and `Inconsistent` branches, the function returns `tofuTokenDecimals.tokenDecimals` (the stored value), not `readDecimals` (the freshly read value). This means:
- On `Inconsistent`, the caller receives the originally stored (trusted) value, not the new (untrusted) value.
- On `Consistent`, returning either would produce the same result since they are equal.

This is the correct TOFU behavior: once a value is trusted, always return the trusted value. The caller is informed via the outcome enum that something changed, but never receives the untrusted new value through this API.

**Assessment:** Correct by design. The "trust on first use" semantics are properly implemented.

**Recommendation:** No change needed.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| LOW-01 | LOW | Scratch space usage is correct but subtle; could break under modification |
| LOW-02 | LOW | `staticcall` forwards all gas to untrusted token |
| INFO-01 | INFO | Read-only variant bypasses TOFU protection before initialization (documented) |
| INFO-02 | INFO | `ReadFailure` conflates multiple distinct failure modes |
| INFO-03 | INFO | Returns stored value on Inconsistent (correct TOFU semantics, noting for completeness) |

**Overall Assessment:** The `LibTOFUTokenDecimalsImplementation` library is well-written with careful attention to security. The inline assembly is correct: the `"memory-safe"` annotation is valid (only scratch space is used), the `returndatasize` check prevents underread, the `> 0xff` check ensures uint8 bounds, and `staticcall` prevents reentrancy with state changes. Storage writes are correctly gated to only occur on the `Initial` outcome. The safe variants properly revert on `ReadFailure` and `Inconsistent`. No CRITICAL or HIGH severity issues were identified.
