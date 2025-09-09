#!/bin/bash
set -e
url="$1"
output="$2"
echo "[download-release] Downloading $url to $output"
curl -L "$url" -o "$output"
echo "[download-release] Download complete."
