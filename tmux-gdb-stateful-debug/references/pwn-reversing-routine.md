# Pwn/Reversing Stateful GDB Routine

Use this checklist after starting a persistent session with `scripts/tmux_gdb.sh start`.

## Baseline Setup (CLI)

```gdb
set pagination off
set disassembly-flavor intel
set print asm-demangle on
set follow-fork-mode parent
set detach-on-fork on
```

## Baseline Setup (MI)

```text
-gdb-set pagination off
-gdb-set disassembly-flavor intel
-gdb-set print asm-demangle on
-gdb-set follow-fork-mode parent
-gdb-set detach-on-fork on
```

## Initial Recon Loop

1. Run binary and map runtime context:
   - CLI: `info files`, `info functions`, `info proc mappings`
   - MI: `-interpreter-exec console "info files"`, `-interpreter-exec console "info functions"`, `-interpreter-exec console "info proc mappings"`
2. If stripped, pivot to disassembly-driven breakpoints.

## Runtime Loop

1. Trigger execution (`run` / `continue`, or `-exec-run` / `-exec-continue`).
2. On crash/hang, capture evidence:
   - `info registers`
   - `x/16gx $rsp`
   - `bt`
3. Refine hypothesis and breakpoints.
4. Repeat send/capture until primitive or root cause is confirmed.

## Noise Control

- Use conditional breakpoints to reduce irrelevant stops.
- Use watchpoints when unexpected value mutations occur.
- Keep one persistent debugger session per target.
