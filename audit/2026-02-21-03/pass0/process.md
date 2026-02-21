# Pass 0: Process Review

Audit namespace: `2026-02-21-03`

## Documents Reviewed

- `CLAUDE.md` (project instructions)
- `foundry.toml` (build configuration)
- `.coderabbit.yaml` (code review configuration)
- `REUSE.toml` (license compliance metadata)
- `.github/workflows/rainix.yaml` (CI workflow)

## Findings

### P0-1: CI workflow contains dead conditional [INFO]

`.github/workflows/rainix.yaml:44` has a conditional for `rainix-sol-prelude`:
```yaml
if: matrix.task == 'rainix-rs-test' || matrix.task == 'rainix-rs-static' || matrix.task == 'test-wasm-build'
```
But the matrix only includes `[rainix-sol-legal, rainix-sol-test, rainix-sol-static]`. The condition can never be true, making this step dead code. Harmless but could confuse future maintainers wondering if Rust tasks are supposed to be present.

### P0-2: CLAUDE.md does not document the deploy script [LOW]

`script/Deploy.sol` exists and is part of the project but is not mentioned in the Architecture or Build & Test Commands sections of CLAUDE.md. A future session tasked with deployment or architecture questions might not discover it. The Architecture section describes three layers but omits the deployment script that ties the Zoltu factory to the concrete contract.

### P0-3: CLAUDE.md does not mention REUSE.toml or legal compliance tooling [INFO]

CLAUDE.md documents `nix develop -c rainix-sol-legal` but doesn't explain what it checks or that `REUSE.toml` configures license annotations for non-`.sol` files. A future session adding non-Solidity files might not know to update `REUSE.toml`.

### P0-4: Test file naming pattern has undocumented base test files [INFO]

CLAUDE.md states test files follow `ContractName.functionName.t.sol` naming, but there are also base/helper test files (`LibTOFUTokenDecimalsImplementation.t.sol`, `LibTOFUTokenDecimals.t.sol`) that don't include a function name. These appear to be shared test infrastructure. The convention documentation doesn't account for these.
