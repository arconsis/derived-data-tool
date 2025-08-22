#!/bin/bash
set -e

# Entrypoint for GitHub Action: Generate or Retrieve Cached Dependencies
# This script calculates the SHA-1 hash of Package.resolved and outputs it for caching purposes.

# Print a message for clarity
log() {
  echo "[create-swift-dependency-cache] $1"
}

# Calculate SHA-1 hash of Package.resolved
log "Calculating SHA-1 hash for Package.resolved"
CACHE_SHA1=$(shasum -a 1 Package.resolved | awk '{print $1}')
log "SHA-1 hash: $CACHE_SHA1"

# Output the hash for use in GitHub Actions
log "Writing cache_sha1 to $GITHUB_OUTPUT"
echo "cache_sha1=$CACHE_SHA1" >> \"$GITHUB_OUTPUT\"