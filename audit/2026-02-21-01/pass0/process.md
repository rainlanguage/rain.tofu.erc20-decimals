# Audit Pass 0 (Process Review) — 2026-02-21-01

**Date:** 2026-02-21
**Scope:** CLAUDE.md, foundry.toml, REUSE.toml, .coderabbit.yaml, .github/workflows/rainix.yaml, slither.config.json

---

## 1. Evidence of Thorough Reading

### CLAUDE.md (69 lines)
- Sections: Project Overview, Build & Test Commands, Architecture, Key Design Constraints, Testing Conventions, Dependencies
- Architecture: 3-layer description (LibTOFUTokenDecimalsImplementation, TOFUTokenDecimals, LibTOFUTokenDecimals)
- Build commands: forge build, forge test, nix develop -c rainix-sol-test, rainix-sol-static, rainix-sol-legal
- Dependencies listed: forge-std, rain.deploy, rain.extrospection

### foundry.toml (45 lines)
- Profile: default
- Compiler: solc 0.8.25, evm_version cancun, optimizer 1M runs, bytecode_hash "none", cbor_metadata false
- Remappings: rain.deploy, rain.extrospection, rain.solmem
- RPC endpoints: arbitrum, base, flare, polygon
- Etherscan keys: arbitrum, base, flare, polygon
- Commented-out debug optimizer settings (lines 11-15)

### .github/workflows/rainix.yaml (57 lines)
- Triggers: push to main, pull requests
- Matrix: ubuntu-latest × [rainix-sol-legal, rainix-sol-test, rainix-sol-static]
- ETH_RPC_URL set from CI_DEPLOY_SEPOLIA_RPC_URL

### REUSE.toml (21 lines)
- Version 1, single annotation block covering config files, audit, docs

### .coderabbit.yaml (5 lines)
- Excludes audit/**, CLAUDE.md, .claude/**

### slither.config.json (4 lines)
- Excludes: assembly-usage, solc-version, unused-imports, different-pragma-directives-are-used
- Filter paths: forge-std

---

## 2. Process Findings

### P0-1: CLAUDE.md says "Ethereum mainnet RPC" but CI uses Sepolia [LOW]

CLAUDE.md line 34 states: "Tests require `ETH_RPC_URL` set to an Ethereum mainnet RPC endpoint."

However, `.github/workflows/rainix.yaml` line 48 sets `ETH_RPC_URL` from `CI_DEPLOY_SEPOLIA_RPC_URL`. The fork tests actually run against Sepolia in CI, not mainnet. A future session following CLAUDE.md literally would use mainnet, which works but is inconsistent with CI behavior.

### P0-2: `evm_version` not listed in bytecode determinism constraints [LOW]

CLAUDE.md Key Design Constraints (line 50) lists `bytecode_hash`, `cbor_metadata`, solc version, and optimizer runs as determinism-critical settings. However, `foundry.toml` line 9 also sets `evm_version = "cancun"`, which affects code generation and thus the deployed address. A future session might not realize changing `evm_version` breaks determinism.

### P0-3: Combined test files not reflected in testing conventions [INFO]

CLAUDE.md line 56 states test files follow `ContractName.functionName.t.sol` naming. However, `LibTOFUTokenDecimalsImplementation.t.sol` and `LibTOFUTokenDecimals.t.sol` are combined files containing tests for multiple functions (helpers, deployment checks, ensureDeployed). The convention documentation doesn't mention when combined files are appropriate.

---

## Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| CRITICAL | 0 | -- |
| HIGH | 0 | -- |
| MEDIUM | 0 | -- |
| LOW | 2 | P0-1, P0-2 |
| INFO | 1 | P0-3 |
