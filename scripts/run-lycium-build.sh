#!/usr/bin/env bash

set -euo pipefail

# Template script.
# Copy this file to scripts/run-lycium-build-<lib>.sh and fill the variables below.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LYCIUM_ROOT="${LYCIUM_ROOT:-$PORTING_ROOT/tpc_c_cplusplus}"
COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-}"
OHOS_SDK="${OHOS_SDK:-}"

LIB_NAME=""
ARCH="arm64-v8a"
HPK_DIR=""
SOURCE_DIR=""

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

main() {
  [[ -n "$LIB_NAME" ]] || fail "LIB_NAME is required."
  [[ -n "$HPK_DIR" ]] || fail "HPK_DIR is required."
  [[ -n "$SOURCE_DIR" ]] || fail "SOURCE_DIR is required."

  if [[ -z "$COMMAND_LINE_TOOLS_ROOT" ]]; then
    if [[ -d "$PORTING_ROOT/../command-line-tools" ]]; then
      COMMAND_LINE_TOOLS_ROOT="$PORTING_ROOT/../command-line-tools"
    else
      fail "COMMAND_LINE_TOOLS_ROOT is not set."
    fi
  fi

  if [[ -z "$OHOS_SDK" ]]; then
    OHOS_SDK="$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony"
  fi

  [[ -f "$LYCIUM_ROOT/lycium/build.sh" ]] || fail "lycium build.sh not found."
  [[ -f "$HPK_DIR/HPKBUILD" ]] || fail "HPKBUILD not found at $HPK_DIR."
  [[ -d "$SOURCE_DIR" ]] || fail "SOURCE_DIR not found: $SOURCE_DIR."

  export OHOS_SDK
  export ARCH

  local pkgname
  pkgname="$(basename "$HPK_DIR")"

  echo "Running lycium build"
  echo "  LIB_NAME=$LIB_NAME"
  echo "  ARCH=$ARCH"
  echo "  HPK_DIR=$HPK_DIR"
  echo "  SOURCE_DIR=$SOURCE_DIR"
  echo "  PKGNAME=$pkgname"

  (
    cd "$LYCIUM_ROOT/lycium"
    ./build.sh "$pkgname"
  )
}

main "$@"

