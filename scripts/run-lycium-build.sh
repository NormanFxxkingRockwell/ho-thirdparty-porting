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

LIB_NAME="${LIB_NAME:-}"
PKGNAME="${PKGNAME:-}"
ARCH="${ARCH:-arm64-v8a}"
HPK_DIR="${HPK_DIR:-}"
RECIPE_SCOPE="${RECIPE_SCOPE:-}"
TEMP_LINK=""
RECIPE_BUILDDIR=""
RECIPE_PACKAGENAME=""

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

ensure_recipe_visible_to_lycium() {
  local thirdparty_dir="$LYCIUM_ROOT/thirdparty"
  local expected_dir="$thirdparty_dir/$PKGNAME"

  if [[ "$HPK_DIR" == "$expected_dir" ]]; then
    return 0
  fi

  mkdir -p "$thirdparty_dir"

  if [[ -e "$expected_dir" ]]; then
    fail "lycium expects recipe at $expected_dir, but a different path already exists."
  fi

  ln -s "$HPK_DIR" "$expected_dir"
  TEMP_LINK="$expected_dir"
}

cleanup() {
  if [[ -n "$TEMP_LINK" && -L "$TEMP_LINK" ]]; then
    rm -f "$TEMP_LINK"
  fi
}

load_recipe_metadata() {
  local metadata
  metadata="$(bash -lc "set -euo pipefail; source '$HPK_DIR/HPKBUILD'; printf '%s\n' \"\${builddir:-}\" \"\${packagename:-}\" \"\${source:-}\"")"
  RECIPE_BUILDDIR="$(printf '%s' "$metadata" | sed -n '1p')"
  RECIPE_PACKAGENAME="$(printf '%s' "$metadata" | sed -n '2p')"
  local recipe_source
  recipe_source="$(printf '%s' "$metadata" | sed -n '3p')"

  [[ -n "$RECIPE_BUILDDIR" ]] || fail "builddir is empty in $HPK_DIR/HPKBUILD"
  [[ -n "$RECIPE_PACKAGENAME" ]] || fail "packagename is empty in $HPK_DIR/HPKBUILD"
  [[ -n "$recipe_source" ]] || fail "source is empty in $HPK_DIR/HPKBUILD"

  local download_name
  download_name="$(basename "${recipe_source%%\?*}")"

  [[ -f "$HPK_DIR/SHA512SUM" ]] || fail "SHA512SUM not found at $HPK_DIR"
  local checksum_name
  checksum_name="$(awk 'NF {print $NF}' "$HPK_DIR/SHA512SUM" | tail -n 1)"
  [[ -n "$checksum_name" ]] || fail "SHA512SUM does not contain a package filename: $HPK_DIR/SHA512SUM"

  if [[ "$checksum_name" != "$RECIPE_PACKAGENAME" ]]; then
    fail "SHA512SUM filename ($checksum_name) does not match packagename ($RECIPE_PACKAGENAME)"
  fi

  if [[ "$download_name" != "$RECIPE_PACKAGENAME" ]]; then
    fail "download package name ($download_name) does not match packagename ($RECIPE_PACKAGENAME)"
  fi
}

preclean_previous_state() {
  local hpk_csv="$LYCIUM_ROOT/lycium/usr/hpk_build.csv"
  local usr_pkg_dir="$LYCIUM_ROOT/lycium/usr/$PKGNAME"

  if [[ -f "$hpk_csv" ]]; then
    python3 - "$hpk_csv" "$PKGNAME" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
pkg = sys.argv[2]
lines = path.read_text().splitlines()
filtered = [line for line in lines if not line.startswith(f"{pkg},")]
path.write_text(("\n".join(filtered) + "\n") if filtered else "")
PY
  fi

  rm -rf "$usr_pkg_dir"

  if [[ -n "$RECIPE_BUILDDIR" ]]; then
    rm -rf "$HPK_DIR/$RECIPE_BUILDDIR"
  fi

  find "$HPK_DIR" -maxdepth 1 -type f -name '*lycium_build.log' -delete || true
}

check_build_failures() {
  local reject_count
  reject_count="$(find "$HPK_DIR" -name '*.rej' | wc -l | tr -d ' ')"
  if [[ "$reject_count" != "0" ]]; then
    fail "Detected .rej files under recipe directory: $HPK_DIR"
  fi

  local latest_log=""
  latest_log="$(find "$HPK_DIR" -maxdepth 1 -type f -name '*lycium_build.log' | sort | tail -n 1)"
  if [[ -n "$latest_log" ]]; then
    if grep -Eq '(^|[^A-Za-z])(FAILED|error:|CMake Error|configure: error|ld: error)' "$latest_log"; then
      fail "Detected failure markers in lycium build log: $latest_log"
    fi
  fi
}

check_expected_outputs() {
  local arch_dir="$LYCIUM_ROOT/lycium/usr/$PKGNAME/$ARCH"
  [[ -d "$arch_dir" ]] || fail "lycium reported success, but output directory is missing: $arch_dir"

  local file_count
  file_count="$(find "$arch_dir" -mindepth 1 | wc -l | tr -d ' ')"
  [[ "$file_count" != "0" ]] || fail "lycium reported success, but output directory is empty: $arch_dir"

  if ! find "$arch_dir" -type f \( -name '*.so' -o -name '*.so.*' -o -perm -111 \) | grep -q .; then
    fail "lycium reported success, but no shared library or executable was found under $arch_dir"
  fi
}

main() {
  trap cleanup EXIT

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

  load_recipe_metadata
  preclean_previous_state
  prepare_lycium_toolchain_wrappers
  ensure_recipe_visible_to_lycium

  echo "Running lycium build"
  echo "  LIB_NAME=$LIB_NAME"
  echo "  PKGNAME=$PKGNAME"
  echo "  ARCH=$ARCH"
  echo "  HPK_DIR=$HPK_DIR"
  echo "  builddir=$RECIPE_BUILDDIR"
  echo "  packagename=$RECIPE_PACKAGENAME"

  (
    cd "$LYCIUM_ROOT/lycium"
    ./build.sh "$PKGNAME"
  )

  check_build_failures
  check_expected_outputs
}

main "$@"
