# Pwn/Reversing Stateful GDB Routine

Use this checklist after starting a persistent session with `scripts/tmux_gdb.sh start`.

## Baseline setup

Run these first for readable output and repeatability:

```gdb
set pagination off
set disassembly-flavor intel
set print asm-demangle on
set follow-fork-mode parent
set detach-on-fork on
```

## Initial recon loop

```gdb
info files
info functions
info proc mappings
```

If symbols are stripped, use disassembly-driven breakpoints:

```gdb
disassemble /r main
break *0x401234
```

## Runtime loop

1. Send input path and run:
   - `run`
2. If crash/hang happens, capture evidence:
   - `info registers`
   - `x/16gx $rsp`
   - `bt`
3. Refine hypothesis:
   - Add/adjust breakpoint
   - Re-run with same session
4. Repeat `send` + `capture` until root cause or exploit primitive is clear.

## Memory watch loop

Use watchpoints when a value changes unexpectedly:

```gdb
watch *0x404080
continue
```

Use conditional breakpoints to reduce noise:

```gdb
break *0x40128a if $rax == 0xdeadbeef
```

## Session hygiene

- Keep one tmux session per binary/challenge.
- Avoid restarting GDB unless state is corrupt or binary changed.
- Use `scripts/tmux_gdb.sh status` before sending commands after long pauses.
- Use `scripts/tmux_gdb.sh stop --all` only when cleanup is intentional.
