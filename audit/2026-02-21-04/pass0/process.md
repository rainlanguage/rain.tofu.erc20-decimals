# Pass 0: Process Review

## Documents Reviewed

- `CLAUDE.md` (72 lines)
- `foundry.toml` (45 lines)
- `REUSE.toml` (21 lines)
- `.github/workflows/rainix.yaml` (57 lines)
- `.github/workflows/manual-sol-artifacts.yaml` (46 lines)
- `.coderabbit.yaml` (6 lines)

## Findings

### P0-1: Testing Conventions incomplete on mock/etch patterns [INFO]
**File**: `CLAUDE.md`, line 61
**Description**: Testing Conventions mentions `vm.etch` with `hex"fd"` (revert opcode) and `vm.mockCall` but does not mention `vm.mockCallRevert` or `vm.etch` with `hex"00"` (STOP opcode), both of which are used in current tests. A future session following only the documented patterns might not use `vm.mockCallRevert` when it is the more appropriate tool (e.g., it correctly overrides a prior `vm.mockCall` whereas `vm.etch` does not).

### P0-2: CI rainix-sol-prelude step never runs [INFO]
**File**: `.github/workflows/rainix.yaml`, line 43-44
**Description**: The `rainix-sol-prelude` step is conditioned on `matrix.task == 'rainix-rs-test' || matrix.task == 'rainix-rs-static' || matrix.task == 'test-wasm-build'`, but the matrix only contains `rainix-sol-legal`, `rainix-sol-test`, `rainix-sol-static`. The condition never matches, making this a dead step. Likely a copy-paste artifact from a shared CI template. Not harmful but could confuse someone reading the workflow.
