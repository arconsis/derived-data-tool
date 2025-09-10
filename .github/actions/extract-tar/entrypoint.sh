#!/bin/bash
set -e
archive="$1"
outdir="$2"
echo "[extract-tar] Extracting $archive to $outdir"
mkdir -p "$outdir"
tar -xzf "$archive" -C "$outdir"
shopt -s nullglob
files=("$outdir"/*)
if [ ${#files[@]} -eq 1 ] && [ -d "${files[0]}" ]; then
	folder="${files[0]}"
	echo "[extract-tar] Moving files from $folder to $outdir"
	mv "$folder"/* "$outdir/"
	rmdir "$folder"
fi
shopt -u nullglob
echo "[extract-tar] Extraction complete."
