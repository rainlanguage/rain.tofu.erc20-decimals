# Audit Pass 3 (Documentation) -- LibTOFUTokenDecimals.sol

**Agent ID:** A03
**Date:** 2026-02-21
**File:** `src/lib/LibTOFUTokenDecimals.sol`

---

## 1. Evidence of Thorough Reading

### Library Name

`LibTOFUTokenDecimals` (line 21)

### Functions

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `ensureDeployed` | 49 | `internal` | `view` |
| `decimalsForTokenReadOnly` | 64 | `internal` | `view` |
| `decimalsForToken` | 77 | `internal` | (state-changing) |
| `safeDecimalsForToken` | 87 | `internal` | (state-changing) |
| `safeDecimalsForTokenReadOnly` | 95 | `internal` | `view` |

### Types, Errors, and Constants

#### Error

| Error | Line | Parameters |
|---|---|---|
| `TOFUTokenDecimalsNotDeployed` | 24 | `address deployedAddress` |

#### Constants

| Constant | Line | Type |
|---|---|---|
| `TOFU_DECIMALS_DEPLOYMENT` | 29-30 | `ITOFUTokenDecimals` |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | 36-37 | `bytes32` |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | 43-44 | `bytes` |

---

## 2. Documentation Findings

### A03-1: Constants use plain `///` comments rather than NatSpec tags [LOW]

**Location:** Lines 26-28, 32-35, 39-41

All three constants have documentation via `///` comments, but none use explicit NatSpec tags. The content is accurate.

### A03-2: `ensureDeployed` function uses plain `///` comment rather than `@notice` [LOW]

**Location:** Lines 46-48

The function's doc comment is accurate and descriptive but does not use an explicit `@notice` tag.

### A03-3: Error `@notice` does not fully describe the revert condition [LOW]

**Location:** Line 22

The `@notice` reads: "Thrown when attempting to use an address that is not deployed." However, `ensureDeployed()` also reverts when the address IS deployed but has a codehash mismatch. The error fires in two scenarios:
1. The contract is not deployed (`code.length == 0`).
2. The contract is deployed but its runtime bytecode does not match the expected hash.

The current description only covers scenario 1.

### A03-4: Library doc block has `@title` and `@notice` -- well documented [INFO]

The library has both `@title` and `@notice` with thorough description covering the TOFU approach and the purpose of wrapping the Zoltu singleton.

### A03-5: All four delegating functions are fully documented with NatSpec tags [INFO]

All four functions have cross-references to the interface, plus `@param` and `@return` tags. Documentation was verified accurate against the interface.

### A03-6: Cross-reference style ("As per") is informal but functional [INFO]

All four delegating functions use `/// As per ITOFUTokenDecimals.functionName.` to cross-reference the interface. This is supplemented by full `@param` and `@return` tags.

### A03-7: All cross-references verified accurate against interface [INFO]

All four "As per" references were verified against `ITOFUTokenDecimals.sol` -- signature and semantics match in all cases.

---

## Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| CRITICAL | 0 | -- |
| HIGH | 0 | -- |
| MEDIUM | 0 | -- |
| LOW | 3 | A03-1, A03-2, A03-3 |
| INFO | 4 | A03-4 through A03-7 |
