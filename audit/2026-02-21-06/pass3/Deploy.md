# Audit Pass 3 (Documentation) - Deploy.sol

**Auditor**: A05
**Date**: 2026-02-21
**File**: `script/Deploy.sol`

## Evidence of Reading

**Contract name**: `Deploy` (line 15), inherits `Script`.

**Functions**:
| Function | Line |
|----------|------|
| `run()` | 19 |

## Documentation Assessment

The contract has a `@title` tag (line 10) and a `@notice` tag (lines 11-14) that accurately describes its purpose: deploying the `TOFUTokenDecimals` singleton via the Zoltu deterministic factory, and that it requires `DEPLOYMENT_KEY`.

The `run()` function has a `@notice` tag (lines 16-18) that accurately describes what it does: reading `DEPLOYMENT_KEY` from the environment and broadcasting the creation code to all supported networks via `LibRainDeploy`.

The documentation matches the implementation. The function takes no parameters and has no return value, so `@param` and `@return` tags are not applicable.

## Findings

No findings. The NatSpec documentation on the contract and the single function is adequate and accurately reflects the implementation.
