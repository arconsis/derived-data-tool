#!/bin/bash
set -e
archive="$1"
outdir="$2"
echo "[extract-tar] Extracting $archive to $outdir"
mkdir -p "$outdir"
tar -xzf "$archive" -C "$outdir"
echo "[extract-tar] Extraction complete."
