---
name: tmux-gdb-stateful-debug
description: Run and control persistent tmux-backed GDB sessions for pwnable and reversing workflows. Use when Codex must keep debugger state across multiple commands or turns, preserve breakpoints and inferior state, or iterate with send/capture loops instead of launching fresh GDB processes.
---

# Tmux Gdb Stateful Debug

Use `scripts/tmux_gdb.sh` to keep one persistent debugger session per target.

## Workflow

1. Verify `tmux` and `gdb` availability.
2. Start or reuse the persistent debugger pane.
3. Send one GDB command at a time.
4. Capture pane output after each command.
5. Iterate until enough evidence is collected.
6. Stop the window/session only when reset is required.

## Quick Start

```bash
# Start or reuse a persistent session
scripts/tmux_gdb.sh start \
  --session pwn-bof \
  --binary ./chall \
  --workdir /work/prob

# Drive debugger state
scripts/tmux_gdb.sh send --session pwn-bof --command "set pagination off"
scripts/tmux_gdb.sh send --session pwn-bof --command "set disassembly-flavor intel"
scripts/tmux_gdb.sh send --session pwn-bof --command "break *main"
scripts/tmux_gdb.sh send --session pwn-bof --command "run"

# Read latest output
scripts/tmux_gdb.sh capture --session pwn-bof --lines 180
```

## Operational Rules

- Reuse the same `--session` name for the same challenge.
- Keep default window name `gdb` unless multiple debugger windows are required.
- Avoid `start --force` unless intentionally resetting state.
- Prefer `send --command "run"` or `send --command "continue"` over relaunching GDB.
- Check health with `scripts/tmux_gdb.sh status --session <name>` before sending commands.

## Resources

- Use `scripts/tmux_gdb.sh` for lifecycle and stateful command execution.
- Load `references/pwn-reversing-routine.md` when a concise command checklist is needed.
