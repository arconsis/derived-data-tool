#!/bin/bash
set -e
binary="$1"
ls -la ./extracted/
echo "[run-version-check] Running $binary --version"
"$binary" --version
