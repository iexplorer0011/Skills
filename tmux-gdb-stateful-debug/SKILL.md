---
name: tmux-gdb-stateful-debug
description: Run and control persistent tmux-backed GDB sessions for pwnable and reversing workflows. Use when Codex must keep debugger state across multiple commands or turns, preserve breakpoints and inferior state, debug pause() in pwntools by PID attach, or prefer GDB/MI output for token-efficient parsing.
---

# Tmux Gdb Stateful Debugger

Use `scripts/tmux_gdb.sh` to keep one persistent debugger session per target.

## Workflow

1. Verify `tmux` and `gdb` availability.
2. Start or reuse one persistent debugger pane.
3. Prefer GDB/MI when parse efficiency matters.
4. Send one debugger command at a time.
5. Capture output after each step and iterate.
6. Stop the session only when reset is intentionally required.

## Quick Start (MI Mode)

```bash
# Start or reuse persistent GDB in MI mode
scripts/tmux_gdb.sh start \
  --session pwn-bof \
  --binary ./chall \
  --workdir /work/prob \
  --gdb-cmd 'gdb -q --interpreter=mi2'

# Drive debugger state with MI commands
scripts/tmux_gdb.sh send --session pwn-bof --command '-gdb-set pagination off'
scripts/tmux_gdb.sh send --session pwn-bof --command '-gdb-set disassembly-flavor intel'
scripts/tmux_gdb.sh send --session pwn-bof --command '-break-insert *main'
scripts/tmux_gdb.sh send --session pwn-bof --command '-exec-run'

# Capture recent output
scripts/tmux_gdb.sh capture --session pwn-bof --lines 180
```

## Pwntools `pause()` Attach Flow

1. Insert `pause()` in `solve.py` before the target trigger.
2. Run `solve.py` inside a tmux challenge pane and wait at pause.
3. Identify PID from pwntools output or process listing.
4. Start/reuse debugger session for the same binary.
5. Attach and prepare breakpoints:

```bash
scripts/tmux_gdb.sh send --session pwn-bof --command 'attach <PID>'
scripts/tmux_gdb.sh send --session pwn-bof --command 'break *0x401234'
scripts/tmux_gdb.sh send --session pwn-bof --command 'continue'
```

6. Return to exploit pane and press Enter (or any key expected by pause) to resume script execution.
7. Observe breakpoint hit in debugger pane and continue iterative debugging.

## Operational Rules

- Reuse one `--session` name per challenge.
- Keep default window name `gdb` unless multiple debugger windows are needed.
- Avoid `start --force` unless intentionally resetting debugger state.
- Prefer `send --command "run"` or `send --command "continue"` over relaunching GDB.
- Check health with `scripts/tmux_gdb.sh status --session <name>` before sending commands after long pauses.

## Resources

- Use `scripts/tmux_gdb.sh` for lifecycle and stateful command execution.
- Read `references/pwn-reversing-routine.md` for compact command loops.
- Read `references/pwntools-pause-attach.md` for attach-focused pwntools workflow.
