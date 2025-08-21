#!/bin/bash
set -e

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --executable)
      EXECUTABLE="$2"
      shift 2
      ;;
    --identity)
      IDENTITY="$2"
      shift 2
      ;;
    --apple_id)
      APPLE_ID="$2"
      shift 2
      ;;
    --team_id)
      TEAM_ID="$2"
      shift 2
      ;;
    --password)
      APP_SPECIFIC_PASSWORD="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$EXECUTABLE" || -z "$IDENTITY" || -z "$APPLE_ID" || -z "$TEAM_ID" || -z "$APP_SPECIFIC_PASSWORD" ]]; then
  echo "Missing required arguments."
  exit 1
fi

echo "Signing $EXECUTABLE with identity $IDENTITY..."
codesign --timestamp --options runtime --sign "$IDENTITY" "$EXECUTABLE"

echo "Submitting $EXECUTABLE for notarization..."
xcrun notarytool submit "$EXECUTABLE" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_SPECIFIC_PASSWORD" --wait

echo "Stapling notarization ticket to $EXECUTABLE..."
xcrun stapler staple "$EXECUTABLE"

echo "Sign and notarize process completed."
