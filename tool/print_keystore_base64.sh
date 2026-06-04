#!/usr/bin/env bash
# Print a single-line base64 keystore for GitHub secret ANDROID_KEYSTORE_BASE64.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT/android/app/upload-keystore.jks"
if [ ! -f "$KEYSTORE" ]; then
  echo "Missing $KEYSTORE — generate the release keystore first." >&2
  exit 1
fi
base64 -w 0 "$KEYSTORE"
echo
