#!/bin/bash
set -e
binary="$1"
echo "[run-version-check] Running $binary --version"
"$binary" --version
