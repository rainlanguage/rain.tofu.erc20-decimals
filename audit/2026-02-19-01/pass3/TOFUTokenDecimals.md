# Pass 3 - Documentation Audit: `TOFUTokenDecimals.sol`

**Auditor:** A03
**Date:** 2026-02-19
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/concrete/TOFUTokenDecimals.sol`

---

## 1. Evidence of Thorough Reading

### Contract Name
- `TOFUTokenDecimals` (line 14)

### Imports (lines 5-7)
| Import | Source |
|--------|--------|
| `ITOFUTokenDecimals`, `TOFUTokenDecimalsResult` | `../interface/ITOFUTokenDecimals.sol` |
| `TOFUOutcome`, `LibTOFUTokenDecimals` | `../lib/LibTOFUTokenDecimals.sol` |
| `LibTOFUTokenDecimalsImplementation` | `../lib/LibTOFUTokenDecimalsImplementation.sol` |

### State Variables
| Name | Type | Visibility | Line |
|------|------|-----------|------|
| `sTOFUTokenDecimals` | `mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals)` | `internal` | 16 |

### Functions
| Name | Visibility | Mutability | Line |
|------|-----------|-----------|------|
| `decimalsForTokenReadOnly` | `external` | `view` | 19 |
| `decimalsForToken` | `external` | (non-view) | 25 |
| `safeDecimalsForToken` | `external` | (non-view) | 31 |
| `safeDecimalsForTokenReadOnly` | `external` | `view` | 36 |

### Inheritance
- Implements `ITOFUTokenDecimals` (line 14)

---

## 2. Documentation Findings

### A03-1: Contract doc block uses `@title` but lacks explicit `@notice` tag [LOW]

**Location:** Lines 9-13

**Description:** The contract-level NatSpec block begins with `@title TOFUTokenDecimals` on line 9, but the descriptive paragraph on lines 10-13 is not preceded by an explicit `@notice` tag. Per Solidity NatSpec conventions, when a doc block contains any explicit tag (such as `@title`), all entries should be explicitly tagged. Without `@notice`, the descriptive text is implicitly treated as `@notice` by the compiler, but this is inconsistent with explicit-tag style and may confuse documentation generators or downstream tooling.

**Current:**
```solidity
/// @title TOFUTokenDecimals
/// Minimal implementation of the ITOFUTokenDecimals interface using
/// LibTOFUTokenDecimalsImplementation for the logic. The concrete contract
/// simply stores the mapping of token addresses to TOFUTokenDecimalsResult
/// structs and delegates all logic to the library.
```

**Recommended:**
```solidity
/// @title TOFUTokenDecimals
/// @notice Minimal implementation of the ITOFUTokenDecimals interface using
/// LibTOFUTokenDecimalsImplementation for the logic. The concrete contract
/// simply stores the mapping of token addresses to TOFUTokenDecimalsResult
/// structs and delegates all logic to the library.
```

---

### A03-2: State variable `sTOFUTokenDecimals` has no NatSpec documentation [LOW]

**Location:** Line 16

**Description:** The internal state variable `sTOFUTokenDecimals` is the sole piece of contract-owned storage and is central to the contract's purpose. It has a `forge-lint` suppression comment but no NatSpec documentation explaining its role. While the mapping's named parameters (`token`, `tofuTokenDecimals`) and the contract-level doc block provide some implicit context, an explicit `@dev` comment would improve clarity for auditors and maintainers, particularly regarding the fact that this is the storage backing for the TOFU singleton.

**Current:**
```solidity
// forge-lint: disable-next-line(mixed-case-variable)
mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;
```

**Recommended:**
```solidity
/// @dev Storage mapping from token address to its TOFU decimals result.
/// This is the backing store for the deployed singleton; all reads and
/// writes are delegated to LibTOFUTokenDecimalsImplementation.
// forge-lint: disable-next-line(mixed-case-variable)
mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;
```

---

### A03-3: Unused import of `LibTOFUTokenDecimals` [INFO]

**Location:** Line 6

**Description:** The import on line 6 brings in both `TOFUOutcome` and `LibTOFUTokenDecimals` from `../lib/LibTOFUTokenDecimals.sol`. While `TOFUOutcome` is used in the function return types (lines 19, 25), `LibTOFUTokenDecimals` itself is never referenced in the contract body. All delegation goes through `LibTOFUTokenDecimalsImplementation`, not `LibTOFUTokenDecimals`. This is a documentation/clarity concern: the unused import may mislead readers into thinking the convenience library is used within the concrete contract.

Note: `TOFUOutcome` is originally defined in `ITOFUTokenDecimals.sol` and re-exported through `LibTOFUTokenDecimals.sol`. It could alternatively be imported directly from the interface file alongside the other interface imports on line 5, which would eliminate the need to import from `LibTOFUTokenDecimals.sol` entirely.

---

### A03-4: All four functions correctly use `@inheritdoc` [INFO]

**Location:** Lines 18, 24, 30, 35

**Description:** All four external functions (`decimalsForTokenReadOnly`, `decimalsForToken`, `safeDecimalsForToken`, `safeDecimalsForTokenReadOnly`) use `/// @inheritdoc ITOFUTokenDecimals`, which correctly inherits the full NatSpec documentation from the interface. The interface (`ITOFUTokenDecimals.sol`) provides complete documentation for each function including `@param` and `@return` tags. This is correct and follows best practices for interface implementations.

---

### A03-5: Accuracy of contract-level documentation [INFO]

**Location:** Lines 9-13

**Description:** The contract-level doc block states:
1. "Minimal implementation of the ITOFUTokenDecimals interface" -- Accurate. The contract implements `ITOFUTokenDecimals` and contains no logic beyond delegation.
2. "using LibTOFUTokenDecimalsImplementation for the logic" -- Accurate. All four functions delegate to `LibTOFUTokenDecimalsImplementation`.
3. "stores the mapping of token addresses to TOFUTokenDecimalsResult structs" -- Accurate. The `sTOFUTokenDecimals` mapping on line 16 matches this description.
4. "delegates all logic to the library" -- Accurate. Every function body is a single delegation call.

No accuracy issues found.

---

### A03-6: Interface NatSpec completeness verification [INFO]

**Location:** `src/interface/ITOFUTokenDecimals.sol`, lines 54-85

**Description:** Since the concrete contract relies entirely on `@inheritdoc`, the quality of inherited documentation depends on the interface. Verified that all four interface functions have:
- Descriptive `@notice`-equivalent text (implicit, as the interface doc blocks do not use explicit `@notice` tags either)
- `@param token` documented for all four functions
- `@return tofuOutcome` and `@return tokenDecimals` documented for `decimalsForToken` and `decimalsForTokenReadOnly`
- `@return tokenDecimals` documented for `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly`

The inherited documentation is complete and accurate for all delegated functions.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A03-1 | LOW | Contract doc block uses `@title` but lacks explicit `@notice` tag |
| A03-2 | LOW | State variable `sTOFUTokenDecimals` has no NatSpec documentation |
| A03-3 | INFO | Unused import of `LibTOFUTokenDecimals` |
| A03-4 | INFO | All four functions correctly use `@inheritdoc` |
| A03-5 | INFO | Accuracy of contract-level documentation verified |
| A03-6 | INFO | Interface NatSpec completeness verified |

**Total findings:** 6 (0 CRITICAL, 0 HIGH, 0 MEDIUM, 2 LOW, 4 INFO)
