#!/usr/bin/env bash
set -euo pipefail

script_name="$(basename "$0")"

usage() {
  cat <<USAGE
Usage:
  $script_name <binary> [--out DIR] [--libc PATH]
USAGE
}

die() {
  echo "[$script_name] $*" >&2
  exit 1
}

abspath() {
  local path="$1"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$PWD" "$path"
  fi
}

run_capture() {
  local outfile="$1"
  shift

  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'missing command: %s\n' "$cmd" >"$outfile"
    return 0
  fi

  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
  } >"$outfile" 2>&1 || true
}

binary=""
out_dir=""
libc=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      [[ $# -ge 2 ]] || die "Missing value for --out"
      out_dir="$2"
      shift 2
      ;;
    --libc)
      [[ $# -ge 2 ]] || die "Missing value for --libc"
      libc="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      if [[ -z "$binary" ]]; then
        binary="$1"
      else
        die "Unexpected positional argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "$binary" ]] || {
  usage
  die "Missing required <binary> argument"
}

binary="$(abspath "$binary")"
[[ -f "$binary" ]] || die "Binary not found: $binary"

if [[ -n "$libc" ]]; then
  libc="$(abspath "$libc")"
  [[ -f "$libc" ]] || die "libc not found: $libc"
fi

if [[ -z "$out_dir" ]]; then
  out_dir="$PWD/recon-$(basename "$binary")-$(date +%Y%m%d-%H%M%S)"
fi
out_dir="$(abspath "$out_dir")"
mkdir -p "$out_dir"

run_capture "$out_dir/01-file.txt" file "$binary"
run_capture "$out_dir/02-checksec.txt" checksec --file="$binary"
run_capture "$out_dir/03-readelf-header.txt" readelf -h "$binary"
run_capture "$out_dir/04-readelf-program-headers.txt" readelf -l "$binary"
run_capture "$out_dir/05-readelf-sections.txt" readelf -S "$binary"
run_capture "$out_dir/06-readelf-dynamic.txt" readelf -d "$binary"
run_capture "$out_dir/07-readelf-relocs.txt" readelf -r "$binary"
run_capture "$out_dir/08-readelf-symbols.txt" readelf -s "$binary"
run_capture "$out_dir/09-objdump-disasm.txt" objdump -d -M intel "$binary"
run_capture "$out_dir/10-strings.txt" strings -a -n 4 "$binary"
run_capture "$out_dir/11-ldd.txt" ldd "$binary"
run_capture "$out_dir/12-sha256.txt" sha256sum "$binary"

if [[ -n "$libc" ]]; then
  run_capture "$out_dir/13-libc-file.txt" file "$libc"
  run_capture "$out_dir/14-libc-checksec.txt" checksec --file="$libc"
  run_capture "$out_dir/15-libc-readelf-symbols.txt" readelf -s "$libc"
  run_capture "$out_dir/16-libc-sha256.txt" sha256sum "$libc"
fi

cat >"$out_dir/summary.txt" <<SUMMARY
Recon artifacts created.

Target binary: $binary
Output directory: $out_dir
Linked libc provided: ${libc:-no}

Baseline interpretation flow:
1. Read 02-checksec.txt for mitigations.
2. Use 06-readelf-dynamic.txt and 11-ldd.txt for linkage and loader behavior.
3. Use 08-readelf-symbols.txt and 10-strings.txt for attack-surface hints.
4. Use 09-objdump-disasm.txt for control-flow and primitive validation.

If ida-pro-mcp is unavailable, treat this output as fallback evidence and annotate limitations in final findings.
SUMMARY

echo "[recon_scan] Done. See: $out_dir"
