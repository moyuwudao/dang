#!/usr/bin/env bash
# Dart wrapper for WSL
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/dart.exe" "$@"
