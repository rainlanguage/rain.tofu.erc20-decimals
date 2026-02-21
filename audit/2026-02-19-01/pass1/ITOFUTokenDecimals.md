# Audit Pass 1 (Security) -- ITOFUTokenDecimals.sol

**Auditor:** A01
**Date:** 2026-02-19
**File:** `src/interface/ITOFUTokenDecimals.sol`
**Lines:** 87

---

## 1. Evidence of Thorough Reading

### Pragma

- Line 3: `pragma solidity ^0.8.25;`

### Structs

| Name | Line | Fields |
|------|------|--------|
| `TOFUTokenDecimalsResult` | 13 | `bool initialized` (line 14), `uint8 tokenDecimals` (line 15) |

### Enums

| Name | Line | Members |
|------|------|---------|
| `TOFUOutcome` | 19 | `Initial` (line 21), `Consistent` (line 23), `Inconsistent` (line 25), `ReadFailure` (line 27) |

### Custom Errors

| Name | Line | Parameters |
|------|------|------------|
| `TokenDecimalsReadFailure` | 33 | `address token`, `TOFUOutcome tofuOutcome` |

### Interfaces

| Name | Line |
|------|------|
| `ITOFUTokenDecimals` | 53 |

### Functions (all within `ITOFUTokenDecimals`)

| Function Name | Line | Mutability | Returns |
|---------------|------|------------|---------|
| `decimalsForTokenReadOnly` | 65 | `external view` | `(TOFUOutcome, uint8)` |
| `decimalsForToken` | 73 | `external` | `(TOFUOutcome, uint8)` |
| `safeDecimalsForToken` | 79 | `external` | `uint8` |
| `safeDecimalsForTokenReadOnly` | 85 | `external view` | `uint8` |

### License

<!-- REUSE-IgnoreStart -->
- Line 1: `SPDX-License-Identifier: LicenseRef-DCL-1.0`
- Line 2: `SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd`
<!-- REUSE-IgnoreEnd -->

---

## 2. Security Findings

### Checklist Results

| Check | Result |
|-------|--------|
| Assembly blocks for memory safety | None present. File contains no assembly. |
| Stack protection | N/A -- interface only, no implementation. |
| Reentrancy risks | N/A -- interface only, no implementation. |
| Unchecked arithmetic | None present. No arithmetic in this file. |
| Custom errors using string messages (`revert("...")`) | None. The single custom error `TokenDecimalsReadFailure` uses typed parameters, not string messages. Compliant. |
| Other security issues | See below. |

### Findings

No security findings.

This file is a pure interface definition containing one struct, one enum, one custom error, and one interface with four function signatures. There is no implementation logic, no assembly, no arithmetic, and no state. The custom error correctly uses typed parameters rather than string messages. The `view` annotations on `decimalsForTokenReadOnly` and `safeDecimalsForTokenReadOnly` are appropriate. The pragma `^0.8.25` is acceptable for an interface file (the concrete contract pins the exact version for bytecode determinism; the interface does not need to).
