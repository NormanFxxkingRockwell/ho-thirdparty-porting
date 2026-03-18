#!/usr/bin/env bash

set -euo pipefail

# Template script.
# Copy this file to scripts/run-lycium-build-<lib>.sh and fill the variables below.
# This wrapper is recipe-first: pkgname + HPKBUILD are the primary inputs.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LYCIUM_ROOT="${LYCIUM_ROOT:-$PORTING_ROOT/tpc_c_cplusplus}"
COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-}"
OHOS_SDK="${OHOS_SDK:-}"

LIB_NAME=""
PKGNAME=""
ARCH="arm64-v8a"
HPK_DIR=""
RECIPE_SCOPE=""

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

prepare_lycium_toolchain_wrappers() {
  local buildtools_dir="$LYCIUM_ROOT/lycium/Buildtools"
  local archive="$buildtools_dir/toolchain.tar.gz"
  local llvm_bin="$OHOS_SDK/native/llvm/bin"

  [[ -d "$llvm_bin" ]] || fail "LLVM bin directory not found: $llvm_bin"

  if [[ -x "$llvm_bin/aarch64-linux-ohos-clang" && -x "$llvm_bin/arm-linux-ohos-clang" ]]; then
    return 0
  fi

  [[ -f "$archive" ]] || fail "lycium Buildtools archive not found: $archive"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  tar -xzf "$archive" -C "$tmp_dir"
  cp -f "$tmp_dir"/toolchain/* "$llvm_bin"/
  rm -rf "$tmp_dir"
}

main() {
  [[ -n "$LIB_NAME" ]] || fail "LIB_NAME is required."
  [[ -n "$PKGNAME" ]] || fail "PKGNAME is required."

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

  if [[ -z "$HPK_DIR" ]]; then
    if [[ -n "$RECIPE_SCOPE" ]]; then
      HPK_DIR="$LYCIUM_ROOT/$RECIPE_SCOPE/$PKGNAME"
    elif [[ -d "$LYCIUM_ROOT/thirdparty/$PKGNAME" ]]; then
      HPK_DIR="$LYCIUM_ROOT/thirdparty/$PKGNAME"
    elif [[ -d "$LYCIUM_ROOT/community/$PKGNAME" ]]; then
      HPK_DIR="$LYCIUM_ROOT/community/$PKGNAME"
    else
      fail "Unable to infer HPK_DIR. Set HPK_DIR or RECIPE_SCOPE."
    fi
  fi

  [[ -f "$LYCIUM_ROOT/lycium/build.sh" ]] || fail "lycium build.sh not found."
  [[ -f "$HPK_DIR/HPKBUILD" ]] || fail "HPKBUILD not found at $HPK_DIR."
  [[ -x "$OHOS_SDK/native/build-tools/cmake/bin/cmake" ]] || fail "SDK cmake not found under OHOS_SDK."

  export OHOS_SDK
  export ARCH
  export PATH="$OHOS_SDK/native/build-tools/cmake/bin:$PATH"

  prepare_lycium_toolchain_wrappers

  echo "Running lycium build"
  echo "  LIB_NAME=$LIB_NAME"
  echo "  PKGNAME=$PKGNAME"
  echo "  ARCH=$ARCH"
  echo "  HPK_DIR=$HPK_DIR"

  (
    cd "$LYCIUM_ROOT/lycium"
    ./build.sh "$PKGNAME"
  )
}

main "$@"
