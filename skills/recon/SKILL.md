---
name: recon
description: Analyze CTF pwn binaries to map attack surface and produce exploit-focused vulnerability hypotheses. Use when starting a new binary challenge, validating mitigations, triaging symbols or IO behavior, or preparing exploitation strategy with ida-pro-mcp first and local fallback tooling when MCP is unavailable.
---

# Recon

## Overview

Perform fast, repeatable binary reconnaissance before exploit development.
Prioritize `ida-pro-mcp` for structural analysis and decompilation-driven hypothesis building.
Fallback to local CLI tooling immediately when MCP is unavailable.

## Workflow

1. Run tool precheck.
Check availability of `checksec`, `readelf`, `objdump`, `strings`, and `ldd`.

2. Triage binary protections and metadata.
Collect file type, architecture, NX/PIE/RELRO/canary status, and linkage details.

3. Map attack surface.
Identify entrypoints, imported functions, suspicious strings, format strings, and writable/executable memory clues.

4. Build vulnerability hypotheses.
Connect concrete evidence to exploit classes: BOF, format string, UAF, OOB, integer issues, logic flaws.

5. Rate exploitability.
Estimate required primitives, likely leak/write targets, and expected exploit path complexity.

## IDA MCP First, Local Fallback Second

1. Attempt `ida-pro-mcp` workflow first.
Use MCP tools to inspect functions, call graphs, xrefs, and decompiled logic.

2. If MCP is unreachable or incomplete, continue without blocking.
Run local recon commands and clearly record fallback limitations in findings.

3. When both are available, correlate results.
Use CLI output for mitigation confirmation and IDA output for semantic understanding.

## Script Usage

Run the helper script from the challenge directory or with absolute paths:

```bash
scripts/recon_scan.sh <binary> [--out DIR] [--libc PATH]
```

Expected outputs include command artifacts and a `summary.txt` report.

## Resources

- Use `scripts/recon_scan.sh` for deterministic baseline triage.
- Read `references/recon-checklist.md` for analyst checklist and reporting shape.
- Read `references/ida-mcp-playbook.md` for MCP-first flow and fallback behavior.
