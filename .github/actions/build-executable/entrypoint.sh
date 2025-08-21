#!/bin/bash
set -e

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$ARCH" || -z "$OUTPUT" ]]; then
  echo "Missing required arguments."
  exit 1
fi

if [[ "$ARCH" == "universal" ]]; then
  echo "Building universal binary (arm64 & x86_64)..."
  swift build -c release --arch arm64 --arch x86_64
  BIN_PATH=$(swift build -c release --show-bin-path)
  cp "$BIN_PATH/App" "$OUTPUT"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "x86_64" ]]; then
  echo "Building for $ARCH..."
  swift build -c release --arch "$ARCH"
  BIN_PATH=$(swift build -c release --show-bin-path)
  cp "$BIN_PATH/App" "$OUTPUT"
else
  echo "Unknown architecture: $ARCH"
  exit 1
fi

echo "Build completed: $OUTPUT"
