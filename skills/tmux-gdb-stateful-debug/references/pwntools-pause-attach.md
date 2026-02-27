# Pwntools Pause-Attach Routine

## Goal

Debug a running pwntools exploit without losing process or debugger state between commands.

## Step-by-Step

1. Place `pause()` right before the code section that should be observed in GDB.
2. Run exploit script in a tmux pane and wait at pause.
3. Obtain target PID:
   - Prefer pwntools printed PID if available.
   - Fallback: `ps -ef | grep <binary_name>`.
4. Start/reuse stateful debugger session for same binary.
5. Attach and set breakpoints.
6. Continue in GDB, then resume exploit pane input to release pause.
7. Confirm breakpoint hit and inspect state.

## Command Skeleton

```bash
# In debugger pane
scripts/tmux_gdb.sh send --session pwn-bof --command 'attach <PID>'
scripts/tmux_gdb.sh send --session pwn-bof --command 'break *<ADDR>'
scripts/tmux_gdb.sh send --session pwn-bof --command 'continue'

# In exploit pane
# press Enter to release pause()
```

## Validation Checklist

- PID matches exploit process, not helper process.
- Breakpoint address matches current binary base/PIE context.
- Pause release timing is controlled to avoid racing past target point.
