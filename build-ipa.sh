#!/usr/bin/env bash
# Build an UNSIGNED KurdUnityLauncher.ipa. Run this on macOS (or in CI).
# The resulting .ipa is signed on-device with ESign.
set -euo pipefail

SCHEME="KurdUnityLauncher"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "==> Installing xcodegen"
  if command -v brew >/dev/null 2>&1; then
    brew install xcodegen
  else
    echo "xcodegen not found and Homebrew is unavailable. Install xcodegen first." >&2
    exit 1
  fi
fi

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building (unsigned, Release, iphoneos)"
xcodebuild \
  -project "${SCHEME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="build/Build/Products/Release-iphoneos/${SCHEME}.app"
if [ ! -d "$APP" ]; then
  echo "Build output not found at $APP" >&2
  exit 1
fi

echo "==> Packaging IPA"
rm -rf Payload "${SCHEME}.ipa"
mkdir -p Payload
cp -R "$APP" Payload/
zip -qr "${SCHEME}.ipa" Payload

echo "==> Done: ${ROOT}/${SCHEME}.ipa"
