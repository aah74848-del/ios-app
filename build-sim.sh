#!/usr/bin/env bash
# Build a SIMULATOR bundle (KurdUnityLauncher-simulator.zip) for testing on
# appetize.io and local iOS Simulators. NOT for the iPhone — install the device
# KurdUnityLauncher.ipa with ESign instead.
set -euo pipefail

SCHEME="KurdUnityLauncher"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "==> Installing xcodegen"
  if command -v brew >/dev/null 2>&1; then
    brew install xcodegen
  else
    echo "xcodegen not found and Homebrew is unavailable." >&2
    exit 1
  fi
fi

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building for iOS Simulator (unsigned, Release)"
xcodebuild \
  -project "${SCHEME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -sdk iphonesimulator \
  -derivedDataPath build-sim \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="build-sim/Build/Products/Release-iphonesimulator/${SCHEME}.app"
if [ ! -d "$APP" ]; then
  echo "Simulator build output not found at $APP" >&2
  exit 1
fi

echo "==> Packaging simulator .app"
rm -f "${SCHEME}-simulator.zip"
ditto -c -k --keepParent "$APP" "${SCHEME}-simulator.zip"

echo "==> Done: ${ROOT}/${SCHEME}-simulator.zip"