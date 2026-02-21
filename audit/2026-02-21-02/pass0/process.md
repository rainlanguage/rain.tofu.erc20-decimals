# Pass 0: Process Review

**Date:** 2026-02-21
**Audit:** 2026-02-21-02

---

## Documents Reviewed

- `CLAUDE.md`
- `foundry.toml`
- `.gitmodules`

---

## Findings

### P0-1: Example test function in CLAUDE.md does not exist [LOW]

**Location:** `CLAUDE.md` line 22

**Description:** The example `forge test --match-test testDecimalsForTokenInitial` references a test function that does not exist in the codebase. The closest match is `testSafeDecimalsForTokenInitial`. A future session copying this example would get zero test matches with no error, silently running nothing.

### P0-2: Testing conventions mention `vm.etch` but concrete tests now use `vm.mockCallRevert` [LOW]

**Location:** `CLAUDE.md` line 59

**Description:** The testing conventions state: "`vm.etch` with `hex"fd"` (revert opcode) to test failure paths". The concrete test files (`test/src/concrete/TOFUTokenDecimals.*.t.sol`) now use `vm.mockCallRevert` instead of `vm.etch` for failure paths. The convention should mention both approaches, or be updated to reflect the preferred approach. A future session following the convention literally would use `vm.etch` for new concrete tests, creating inconsistency with the existing concrete tests.

---

## Summary

| ID | Severity | Finding |
|----|----------|---------|
| P0-1 | LOW | Example test function `testDecimalsForTokenInitial` does not exist |
| P0-2 | LOW | Testing conventions mention `vm.etch` but concrete tests now use `vm.mockCallRevert` |
