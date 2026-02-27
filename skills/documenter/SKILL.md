---
name: documenter
description: Create CTF pwn writeups after exploitation is complete. Use when shell or flag acquisition is achieved and Codex must produce a structured WRITEUP.md with Summary, Vulnerability Analysis, Exploit Script, and Flag or proof evidence.
---

# Documenter

## Overview

Produce a clean, reproducible `WRITEUP.md` after successful exploitation.
Keep explanations evidence-based and aligned with the final exploit behavior.

## Required Structure

- Summary
- Vulnerability Analysis
- Exploit Script
- Flag/Proof

## Workflow

1. Initialize writeup file from template.

```bash
scripts/init_writeup.sh [--out PATH] [--force]
```

2. Fill each section using verified exploit evidence.

3. Ensure exploit steps are reproducible from a clean environment.

4. Include final shell/flag proof output with minimal noise.

## Resources

- Use `assets/WRITEUP.template.md` as the baseline structure.
- Use `references/writeup-checklist.md` for quality gates before finalization.
