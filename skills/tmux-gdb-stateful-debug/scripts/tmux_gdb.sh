#!/usr/bin/env bash
set -euo pipefail

script_name="$(basename "$0")"

die() {
  echo "[$script_name] $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

pane_target() {
  local session="$1"
  local window="$2"
  local pane="$3"
  printf "%s:%s.%s" "$session" "$window" "$pane"
}

session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

window_exists() {
  local session="$1"
  local window="$2"
  tmux list-windows -t "$session" -F '#W' | grep -Fxq "$window"
}

pane_exists() {
  local session="$1"
  local window="$2"
  local pane="$3"
  tmux list-panes -t "${session}:${window}" -F '#P' | grep -Fxq "$pane"
}

first_pane() {
  local session="$1"
  local window="$2"
  tmux list-panes -t "${session}:${window}" -F '#P' | head -n 1
}

resolve_pane() {
  local session="$1"
  local window="$2"
  local pane="$3"

  if [[ "$pane" == "auto" ]]; then
    pane="$(first_pane "$session" "$window")"
  fi

  [[ -n "$pane" ]] || die "No panes found in ${session}:${window}"
  echo "$pane"
}

ensure_session_window() {
  local session="$1"
  local window="$2"

  if ! session_exists "$session"; then
    tmux new-session -d -s "$session" -n "$window"
  fi

  if ! window_exists "$session" "$window"; then
    tmux new-window -d -t "$session" -n "$window"
  fi
}

usage() {
  cat <<EOF
Usage:
  $script_name start   --session NAME [--binary PATH] [--args 'ARG STRING'] [--workdir DIR] [--window NAME] [--pane N] [--gdb-cmd 'gdb -q'] [--force]
  $script_name send    --session NAME --command 'GDB COMMAND' [--window NAME] [--pane N]
  $script_name capture --session NAME [--lines N] [--window NAME] [--pane N]
  $script_name status  --session NAME [--window NAME] [--pane N]
  $script_name stop    --session NAME [--window NAME] [--all]

Examples:
  $script_name start --session pwn-bof --binary ./chall --workdir /work/prob
  $script_name send --session pwn-bof --command 'break *main'
  $script_name capture --session pwn-bof --lines 160
EOF
}

usage_start() {
  cat <<EOF
Usage:
  $script_name start --session NAME [--binary PATH] [--args 'ARG STRING'] [--workdir DIR] [--window NAME] [--pane N] [--gdb-cmd 'gdb -q'] [--force]
EOF
}

usage_send() {
  cat <<EOF
Usage:
  $script_name send --session NAME --command 'GDB COMMAND' [--window NAME] [--pane N]
EOF
}

usage_capture() {
  cat <<EOF
Usage:
  $script_name capture --session NAME [--lines N] [--window NAME] [--pane N]
EOF
}

usage_status() {
  cat <<EOF
Usage:
  $script_name status --session NAME [--window NAME] [--pane N]
EOF
}

usage_stop() {
  cat <<EOF
Usage:
  $script_name stop --session NAME [--window NAME] [--all]
EOF
}

cmd_start() {
  local session=""
  local window="gdb"
  local pane="auto"
  local workdir=""
  local binary=""
  local program_args=""
  local gdb_cmd="gdb -q"
  local force=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session)
        [[ $# -ge 2 ]] || die "Missing value for --session"
        session="$2"
        shift 2
        ;;
      --window)
        [[ $# -ge 2 ]] || die "Missing value for --window"
        window="$2"
        shift 2
        ;;
      --pane)
        [[ $# -ge 2 ]] || die "Missing value for --pane"
        pane="$2"
        shift 2
        ;;
      --workdir)
        [[ $# -ge 2 ]] || die "Missing value for --workdir"
        workdir="$2"
        shift 2
        ;;
      --binary)
        [[ $# -ge 2 ]] || die "Missing value for --binary"
        binary="$2"
        shift 2
        ;;
      --args)
        [[ $# -ge 2 ]] || die "Missing value for --args"
        program_args="$2"
        shift 2
        ;;
      --gdb-cmd)
        [[ $# -ge 2 ]] || die "Missing value for --gdb-cmd"
        gdb_cmd="$2"
        shift 2
        ;;
      --force)
        force=1
        shift
        ;;
      -h|--help)
        usage_start
        return 0
        ;;
      *)
        die "Unknown option for start: $1"
        ;;
    esac
  done

  [[ -n "$session" ]] || die "Missing required option: --session"

  require_cmd tmux
  local gdb_bin
  gdb_bin="${gdb_cmd%% *}"
  require_cmd "$gdb_bin"

  if [[ -n "$workdir" ]]; then
    [[ -d "$workdir" ]] || die "workdir does not exist: $workdir"
  fi

  if [[ -n "$binary" ]]; then
    local resolved_binary="$binary"
    if [[ "$binary" != /* ]]; then
      local base_dir="${workdir:-$PWD}"
      resolved_binary="${base_dir}/${binary}"
    fi
    [[ -e "$resolved_binary" ]] || die "binary does not exist: $resolved_binary"
  fi

  ensure_session_window "$session" "$window"

  if [[ "$force" -eq 1 ]]; then
    tmux kill-window -t "${session}:${window}" 2>/dev/null || true
    tmux new-window -d -t "$session" -n "$window"
  fi

  pane="$(resolve_pane "$session" "$window" "$pane")"

  if ! pane_exists "$session" "$window" "$pane"; then
    die "Pane does not exist: $(pane_target "$session" "$window" "$pane")"
  fi

  local target
  target="$(pane_target "$session" "$window" "$pane")"

  local pane_cmd
  pane_cmd="$(tmux display-message -p -t "$target" '#{pane_current_command}')"
  if [[ "$pane_cmd" == "gdb" ]] && [[ "$force" -eq 0 ]]; then
    echo "Reusing existing gdb pane: $target"
    return 0
  fi

  local launch_cmd="$gdb_cmd"
  if [[ -n "$binary" ]]; then
    launch_cmd+=" --args $(printf '%q' "$binary")"
    if [[ -n "$program_args" ]]; then
      launch_cmd+=" $program_args"
    fi
  fi
  if [[ -n "$workdir" ]]; then
    launch_cmd="cd $(printf '%q' "$workdir") && $launch_cmd"
  fi

  tmux send-keys -t "$target" C-c
  tmux send-keys -t "$target" "$launch_cmd" C-m

  local detected_cmd=""
  local i
  for i in {1..20}; do
    detected_cmd="$(tmux display-message -p -t "$target" '#{pane_current_command}')"
    if [[ "$detected_cmd" == "gdb" ]]; then
      break
    fi
    sleep 0.1
  done

  echo "Started gdb in $(pane_target "$session" "$window" "$pane")"
  if [[ "$detected_cmd" != "gdb" ]]; then
    echo "Warning: pane command is '$detected_cmd'. gdb may still be initializing." >&2
  fi
  echo "Attach with: tmux attach -t $session"
}

cmd_send() {
  local session=""
  local window="gdb"
  local pane="auto"
  local gdb_command=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session)
        [[ $# -ge 2 ]] || die "Missing value for --session"
        session="$2"
        shift 2
        ;;
      --window)
        [[ $# -ge 2 ]] || die "Missing value for --window"
        window="$2"
        shift 2
        ;;
      --pane)
        [[ $# -ge 2 ]] || die "Missing value for --pane"
        pane="$2"
        shift 2
        ;;
      --command)
        [[ $# -ge 2 ]] || die "Missing value for --command"
        gdb_command="$2"
        shift 2
        ;;
      --)
        shift
        gdb_command="$*"
        break
        ;;
      -h|--help)
        usage_send
        return 0
        ;;
      *)
        die "Unknown option for send: $1"
        ;;
    esac
  done

  [[ -n "$session" ]] || die "Missing required option: --session"
  [[ -n "$gdb_command" ]] || die "Missing required option: --command"

  require_cmd tmux
  session_exists "$session" || die "Session not found: $session"
  window_exists "$session" "$window" || die "Window not found: ${session}:${window}"
  pane="$(resolve_pane "$session" "$window" "$pane")"
  pane_exists "$session" "$window" "$pane" || die "Pane not found: $(pane_target "$session" "$window" "$pane")"

  local target
  target="$(pane_target "$session" "$window" "$pane")"
  local pane_cmd
  pane_cmd="$(tmux display-message -p -t "$target" '#{pane_current_command}')"
  if [[ "$pane_cmd" != "gdb" ]]; then
    echo "Warning: pane command is '$pane_cmd' (expected 'gdb'). Sending command anyway." >&2
  fi

  tmux send-keys -t "$target" "$gdb_command" C-m
  echo "Sent to $target: $gdb_command"
}

cmd_capture() {
  local session=""
  local window="gdb"
  local pane="auto"
  local lines="120"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session)
        [[ $# -ge 2 ]] || die "Missing value for --session"
        session="$2"
        shift 2
        ;;
      --window)
        [[ $# -ge 2 ]] || die "Missing value for --window"
        window="$2"
        shift 2
        ;;
      --pane)
        [[ $# -ge 2 ]] || die "Missing value for --pane"
        pane="$2"
        shift 2
        ;;
      --lines)
        [[ $# -ge 2 ]] || die "Missing value for --lines"
        lines="$2"
        shift 2
        ;;
      -h|--help)
        usage_capture
        return 0
        ;;
      *)
        die "Unknown option for capture: $1"
        ;;
    esac
  done

  [[ -n "$session" ]] || die "Missing required option: --session"
  [[ "$lines" =~ ^[0-9]+$ ]] || die "--lines must be a positive integer"
  [[ "$lines" -gt 0 ]] || die "--lines must be greater than zero"

  require_cmd tmux
  session_exists "$session" || die "Session not found: $session"
  window_exists "$session" "$window" || die "Window not found: ${session}:${window}"
  pane="$(resolve_pane "$session" "$window" "$pane")"
  pane_exists "$session" "$window" "$pane" || die "Pane not found: $(pane_target "$session" "$window" "$pane")"

  local target
  target="$(pane_target "$session" "$window" "$pane")"
  tmux capture-pane -p -t "$target" -S "-$lines"
}

cmd_status() {
  local session=""
  local window="gdb"
  local pane="auto"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session)
        [[ $# -ge 2 ]] || die "Missing value for --session"
        session="$2"
        shift 2
        ;;
      --window)
        [[ $# -ge 2 ]] || die "Missing value for --window"
        window="$2"
        shift 2
        ;;
      --pane)
        [[ $# -ge 2 ]] || die "Missing value for --pane"
        pane="$2"
        shift 2
        ;;
      -h|--help)
        usage_status
        return 0
        ;;
      *)
        die "Unknown option for status: $1"
        ;;
    esac
  done

  [[ -n "$session" ]] || die "Missing required option: --session"

  require_cmd tmux
  if ! session_exists "$session"; then
    echo "session=$session exists=no"
    return 1
  fi

  echo "session=$session exists=yes"

  if ! window_exists "$session" "$window"; then
    echo "window=${session}:${window} exists=no"
    return 2
  fi

  echo "window=${session}:${window} exists=yes"

  pane="$(resolve_pane "$session" "$window" "$pane")"

  if ! pane_exists "$session" "$window" "$pane"; then
    echo "pane=$(pane_target "$session" "$window" "$pane") exists=no"
    return 3
  fi

  local target
  target="$(pane_target "$session" "$window" "$pane")"
  local pane_cmd
  pane_cmd="$(tmux display-message -p -t "$target" '#{pane_current_command}')"

  echo "pane=$target exists=yes"
  echo "pane_current_command=$pane_cmd"
  if [[ "$pane_cmd" == "gdb" ]]; then
    echo "gdb_running=yes"
  else
    echo "gdb_running=no"
  fi
}

cmd_stop() {
  local session=""
  local window="gdb"
  local stop_all=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session)
        [[ $# -ge 2 ]] || die "Missing value for --session"
        session="$2"
        shift 2
        ;;
      --window)
        [[ $# -ge 2 ]] || die "Missing value for --window"
        window="$2"
        shift 2
        ;;
      --all)
        stop_all=1
        shift
        ;;
      -h|--help)
        usage_stop
        return 0
        ;;
      *)
        die "Unknown option for stop: $1"
        ;;
    esac
  done

  [[ -n "$session" ]] || die "Missing required option: --session"

  require_cmd tmux
  if ! session_exists "$session"; then
    echo "Session not found, nothing to stop: $session"
    return 0
  fi

  if [[ "$stop_all" -eq 1 ]]; then
    tmux kill-session -t "$session"
    echo "Stopped session: $session"
    return 0
  fi

  if ! window_exists "$session" "$window"; then
    echo "Window not found, nothing to stop: ${session}:${window}"
    return 0
  fi

  tmux kill-window -t "${session}:${window}"
  echo "Stopped window: ${session}:${window}"
}

main() {
  [[ $# -gt 0 ]] || {
    usage
    exit 1
  }

  local subcommand="$1"
  shift

  case "$subcommand" in
    start)
      cmd_start "$@"
      ;;
    send)
      cmd_send "$@"
      ;;
    capture)
      cmd_capture "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    stop)
      cmd_stop "$@"
      ;;
    -h|--help)
      usage
      ;;
    *)
      die "Unknown subcommand: $subcommand"
      ;;
  esac
}

main "$@"
