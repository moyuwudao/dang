#!/usr/bin/env bash
# Dart wrapper for WSL - converts WSL paths to Windows paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Convert arguments: WSL paths (/mnt/c/...) to Windows paths (C:/...)
convert_arg() {
  local arg="$1"
  if [[ "$arg" =~ ^/mnt/([a-zA-Z])/(.*)$ ]]; then
    echo "${BASH_REMATCH[1]^^}:/${BASH_REMATCH[2]}"
  else
    echo "$arg"
  fi
}

# Convert all arguments
converted_args=()
for arg in "$@"; do
  converted_args+=("$(convert_arg "$arg")")
done

"$SCRIPT_DIR/dart.exe" "${converted_args[@]}"
