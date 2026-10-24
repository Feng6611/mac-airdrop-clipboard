#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/ClipDrop.xcodeproj}"
SCHEME="${SCHEME:-ClipDrop}"
CONFIGURATION="${CONFIGURATION:-Debug}"
APP_NAME="${APP_NAME:-ClipDrop}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/clipdrop-dd-task-f}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  pkill -x "$APP_NAME" || true
  for _ in {1..20}; do
    if ! pgrep -x "$APP_NAME" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    pkill -9 -x "$APP_NAME" || true
  fi
fi

build_app() {
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    "$@" \
    build
}

build_app

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_PATH"
SIGNING_DETAILS="$(/usr/bin/codesign -dv --verbose=4 "$APP_PATH" 2>&1)"
if [[ "$CONFIGURATION" == "Debug" && ( "$SIGNING_DETAILS" != *"TeamIdentifier=Q3DZRXLGA3"* || "$SIGNING_DETAILS" == *"Signature=adhoc"* ) ]]; then
  echo "error: Debug must be Apple Development-signed before Apple Sandbox launch." >&2
  exit 1
fi

/usr/bin/open -n "$APP_PATH"

if [[ "${1:-}" == "--verify" ]]; then
  sleep 2
  pgrep -x "$APP_NAME" >/dev/null
fi
