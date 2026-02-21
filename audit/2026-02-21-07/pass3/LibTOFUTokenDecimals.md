# Audit Pass 3 (Documentation) -- `src/lib/LibTOFUTokenDecimals.sol`

**Agent:** A03
**Date:** 2026-02-21
**File:** `/Users/thedavidmeister/Code/rain.tofu.erc20-decimals/src/lib/LibTOFUTokenDecimals.sol`

## Evidence of Thorough Reading

- File is 101 lines, read in full.
- Cross-referenced all NatSpec against the interface (`ITOFUTokenDecimals.sol`, lines 1--100), the implementation library (`LibTOFUTokenDecimalsImplementation.sol`, lines 1--171), and the concrete contract (`TOFUTokenDecimals.sol`, lines 1--39).
- Verified every `@notice`, `@param`, and `@return` tag for all five functions, one error, and three constants.
- Confirmed the library-level `@title` and `@notice` tags (lines 7--20).
- Checked that documentation claims about behavior match the actual implementation code paths.

## Items Reviewed

| Item | Kind | Line | Has NatSpec | Params Documented | Returns Documented |
|---|---|---|---|---|---|
| `LibTOFUTokenDecimals` | library | 21 | Yes (@title, @notice) | N/A | N/A |
| `TOFUTokenDecimalsNotDeployed` | error | 24 | Yes (@notice, @param) | Yes (`expectedAddress`) | N/A |
| `TOFU_DECIMALS_DEPLOYMENT` | constant | 29 | Yes (@notice) | N/A | N/A |
| `TOFU_DECIMALS_EXPECTED_CODE_HASH` | constant | 36 | Yes (@notice) | N/A | N/A |
| `TOFU_DECIMALS_EXPECTED_CREATION_CODE` | constant | 44 | Yes (@notice) | N/A | N/A |
| `ensureDeployed` | function | 51 | Yes (@notice) | N/A (no params) | N/A (no returns) |
| `decimalsForTokenReadOnly` | function | 66 | Yes (@notice, @param, @return x2) | Yes (`token`) | Yes (`tofuOutcome`, `tokenDecimals`) |
| `decimalsForToken` | function | 79 | Yes (@notice, @param, @return x2) | Yes (`token`) | Yes (`tofuOutcome`, `tokenDecimals`) |
| `safeDecimalsForToken` | function | 89 | Yes (@notice, @param, @return) | Yes (`token`) | Yes (`tokenDecimals`) |
| `safeDecimalsForTokenReadOnly` | function | 97 | Yes (@notice, @param, @return) | Yes (`token`) | Yes (`tokenDecimals`) |

## Findings

### A03-1: `ensureDeployed` lacks `@return` and `@param` tags but correctly so -- however it has no revert condition documentation beyond prose [INFO]

The `ensureDeployed` function (line 51) documents its revert behavior in the `@notice` prose ("Reverts with `TOFUTokenDecimalsNotDeployed` if..."), which is adequate. It has no parameters and no return values, so the absence of `@param` and `@return` tags is correct. No issue here upon closer inspection.

**Disposition:** Not a finding. Withdrawn.

---

### A03-2: Library-level NatSpec references "read-only version" and "read/write" without naming the specific functions [INFO]

Lines 12--15 of the library-level `@notice` say "there is a read-only version of the logic" and "read/write and read-only versions are used appropriately" but do not name the specific functions (`decimalsForToken` vs `decimalsForTokenReadOnly`, `safeDecimalsForToken` vs `safeDecimalsForTokenReadOnly`). For a library that is the primary caller-facing entry point, naming the pairs would improve discoverability for integrators reading NatSpec.

**Severity:** INFO -- documentation could be slightly more specific, but the meaning is clear in context.

---

### A03-3: `decimalsForTokenReadOnly` and `decimalsForToken` share identical `@return` documentation, which is slightly inaccurate for `decimalsForTokenReadOnly` on `Initial` [INFO]

Lines 62--65 and 75--78 both state: "On `Initial`, the freshly read value." This is correct for both. However, the shared text "On `Consistent` or `Inconsistent`, the previously stored value" is technically misleading for `decimalsForTokenReadOnly` on `Inconsistent`, because in the read-only path the function returns the **stored** value (not the freshly read value), same as the write path. Checking the implementation at `LibTOFUTokenDecimalsImplementation.sol` lines 74--77, the read-only path does indeed return `tofuTokenDecimals.tokenDecimals` (the stored value) on both `Consistent` and `Inconsistent`. So the documentation is actually accurate. No issue.

**Disposition:** Not a finding. Withdrawn.

---

### A03-4: `safeDecimalsForToken` and `safeDecimalsForTokenReadOnly` NatSpec does not document the revert condition [INFO]

Lines 86--88 (`safeDecimalsForToken`) say "As per `ITOFUTokenDecimals.safeDecimalsForToken`" but do not mention the revert with `TokenDecimalsReadFailure` for `Inconsistent` or `ReadFailure` outcomes. The interface NatSpec at `ITOFUTokenDecimals.sol` lines 83--86 does document "reverting if the read fails or is inconsistent," and the "As per" cross-reference points there. Similarly for `safeDecimalsForTokenReadOnly` (lines 94--96), the "As per" reference covers the revert behavior.

This is a style choice -- the "As per" cross-reference delegates documentation to the interface. The interface documentation is thorough and accurate. However, a brief mention of the revert condition in the library NatSpec would help callers who read only the library without consulting the interface.

**Severity:** INFO -- the cross-reference is valid, but self-contained documentation would be marginally better for developer ergonomics.

---

### A03-5: `safeDecimalsForTokenReadOnly` lacks the WARNING about pre-initialization behavior that the interface and implementation include [LOW]

The interface at `ITOFUTokenDecimals.sol` lines 93--96 includes an explicit WARNING:

> WARNING: Before initialization, each call is a fresh `Initial` read with no stored value to check against, so inconsistency between calls cannot be detected.

The implementation library at `LibTOFUTokenDecimalsImplementation.sol` lines 149--153 also reproduces this WARNING.

However, `LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly` at line 94 says only "As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`" with no mention of the warning. Since `LibTOFUTokenDecimals` is the primary entry point for callers (as stated in its own library-level NatSpec, lines 17--18), and this warning describes a subtle security-relevant footgun, it should be surfaced directly rather than requiring the caller to follow the cross-reference to discover it.

By contrast, the implementation library **does** reproduce the warning. The caller-facing convenience library should do at least as much.

**Severity:** LOW -- the warning is security-relevant (callers may unknowingly bypass TOFU protection if they only use the read-only variant before initialization) and is missing from the most visible entry point.

---

### A03-6: `ensureDeployed` documents codehash mismatch check but not what it protects against [INFO]

Line 47--50 says "Reverts with `TOFUTokenDecimalsNotDeployed` if the address has no code or the codehash does not match, preventing silent call failures." This is accurate. It could additionally note that the codehash check guards against a different contract being deployed at the same address (e.g., on a chain where the Zoltu deployment has not yet occurred but another contract occupies the address), which is the "malicious interference" mentioned in the `TOFU_DECIMALS_EXPECTED_CODE_HASH` constant NatSpec (line 34). However, this is a minor completeness point.

**Severity:** INFO -- the existing documentation is correct; additional context would be a minor improvement.

---

No findings.

All documentation in `LibTOFUTokenDecimals.sol` is present and accurate. The only substantive observation is A03-5, where the security WARNING about `safeDecimalsForTokenReadOnly`'s pre-initialization behavior is present in the interface and implementation library but absent from the caller-facing convenience library. All other observations are informational style preferences.
