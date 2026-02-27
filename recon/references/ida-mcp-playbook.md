# IDA MCP Playbook

## Goal

Use `ida-pro-mcp` as primary analysis path for semantic understanding, then confirm environment/protection details with local tooling.

## MCP-First Routine

1. Open target in IDA and ensure RPC endpoint is reachable.
2. Enumerate core functions and xrefs around user-controlled input.
3. Follow data flow into copy/format/heap operations.
4. Note exact basic blocks and conditions that gate dangerous behavior.

## Fallback Routine (No MCP)

1. Run `scripts/recon_scan.sh <binary>`.
2. Build a first-pass model from symbols, disassembly, and strings.
3. Record explicit limitation: "IDA semantic context unavailable; hypothesis confidence reduced."

## Correlation Routine

1. Use MCP findings to prioritize candidate bug paths.
2. Use CLI outputs to validate mitigations and runtime dependencies.
3. Keep one evidence table with function/address/observation/actionable exploit implication.
