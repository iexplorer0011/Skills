#!/usr/bin/env bash
set -euo pipefail

script_name="$(basename "$0")"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_path="$script_dir/../assets/WRITEUP.template.md"

usage() {
  cat <<USAGE
Usage:
  $script_name [--out PATH] [--force]
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

out_path="WRITEUP.md"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      [[ $# -ge 2 ]] || die "Missing value for --out"
      out_path="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      die "Unexpected positional argument: $1"
      ;;
  esac
done

[[ -f "$template_path" ]] || die "Template not found: $template_path"
out_path="$(abspath "$out_path")"

if [[ -e "$out_path" && "$force" -ne 1 ]]; then
  die "Output already exists: $out_path (use --force to overwrite)"
fi

mkdir -p "$(dirname "$out_path")"
cp "$template_path" "$out_path"

echo "[init_writeup] Created: $out_path"
