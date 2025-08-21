#!/usr/bin/env bash
set -e

# Usage: get-latest-tag-and-next-version.sh <base-version>
# Example: get-latest-tag-and-next-version.sh 1.2.3

BASE_VERSION="$1"
if [[ -z "$BASE_VERSION" ]]; then
  echo "Usage: $0 <base-version>"
  exit 1
fi

# Find all tags matching semantic versioning with optional build number
TAGS=$(git tag --sort=-creatordate | grep -E "^${BASE_VERSION}(\\.[0-9]+)?$")

LATEST_BUILD=0
LATEST_TAG=""
for TAG in $TAGS; do
  # Extract build number if present
  if [[ "$TAG" =~ ^${BASE_VERSION}\.([0-9]+)$ ]]; then
    BUILD_NUM=${BASH_REMATCH[1]}
    if (( BUILD_NUM > LATEST_BUILD )); then
      LATEST_BUILD=$BUILD_NUM
      LATEST_TAG=$TAG
    fi
  elif [[ "$TAG" == "$BASE_VERSION" ]]; then
    if (( LATEST_BUILD == 0 )); then
      LATEST_TAG=$TAG
    fi
  fi

done

NEXT_BUILD=$((LATEST_BUILD + 1))
NEXT_VERSION="${BASE_VERSION}.${NEXT_BUILD}"

# Output results
if [[ -n "$LATEST_TAG" ]]; then
  echo "Latest tag: $LATEST_TAG"
else
  echo "No tag found for base version $BASE_VERSION"
fi

echo "Next version: $NEXT_VERSION"
