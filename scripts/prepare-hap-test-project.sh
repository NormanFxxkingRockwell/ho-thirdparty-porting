#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/prepare-hap-test-project.sh --lib-name <name> [options]

Options:
  --template <zip>   Template zip. Defaults to templates/soTest-template.zip.
  --workdir <dir>    Work directory. Defaults to tmp/hap-test/<lib-name>.
  --so-path <path>   Specific .so file or lib directory to copy. Defaults to outputs/<lib-name>/lib/.
  --keep-existing    Do not remove an existing workdir before extraction.

Creates a fresh temporary HAP project and copies target shared libraries into:
  entry/libs/arm64-v8a/

Default copy behavior:
  - Copies outputs/<lib-name>/lib/*.so
  - Copies outputs/<lib-name>/lib/*.so.*
  - This is meant to keep versioned SONAME files available for HAP runtime loading.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LIB_NAME=""
TEMPLATE_ZIP="$PORTING_ROOT/templates/soTest-template.zip"
WORKDIR=""
SO_PATH=""
KEEP_EXISTING="false"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

safe_clean_workdir() {
  local target="$1"
  local base="$PORTING_ROOT/tmp/hap-test"
  local target_abs
  local base_abs

  target_abs="$(realpath -m "$target")"
  base_abs="$(realpath -m "$base")"

  case "$target_abs" in
    "$base_abs"/*) rm -rf -- "$target_abs" ;;
    *) fail "refuse to clean path outside tmp/hap-test: $target_abs" ;;
  esac
}

copy_shared_objects_from_dir() {
  local src_dir="$1"
  local matches=()

  shopt -s nullglob
  matches=("$src_dir"/*.so "$src_dir"/*.so.*)
  shopt -u nullglob

  [[ ${#matches[@]} -gt 0 ]] || return 1
  cp "${matches[@]}" "$TARGET_LIB_DIR/"
}

copy_shared_objects_from_path() {
  local src_path="$1"

  if [[ -d "$src_path" ]]; then
    copy_shared_objects_from_dir "$src_path" || fail "no shared libraries found under directory: $src_path"
    return 0
  fi

  [[ -f "$src_path" ]] || fail "specified .so path not found: $src_path"

  local src_dir
  local base
  local so_prefix
  src_dir="$(dirname "$src_path")"
  base="$(basename "$src_path")"

  if [[ "$base" == *.so || "$base" == *.so.* ]]; then
    so_prefix="${base%%.so*}.so"
    shopt -s nullglob
    local siblings=("$src_dir/$so_prefix" "$src_dir/$so_prefix".*)
    shopt -u nullglob

    if [[ ${#siblings[@]} -gt 0 ]]; then
      cp "${siblings[@]}" "$TARGET_LIB_DIR/"
      return 0
    fi
  fi

  cp "$src_path" "$TARGET_LIB_DIR/"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lib-name)
      LIB_NAME="$2"
      shift 2
      ;;
    --template)
      TEMPLATE_ZIP="$2"
      shift 2
      ;;
    --workdir)
      WORKDIR="$2"
      shift 2
      ;;
    --so-path)
      SO_PATH="$2"
      shift 2
      ;;
    --keep-existing)
      KEEP_EXISTING="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "$LIB_NAME" ]] || { usage; fail "--lib-name is required."; }
[[ -f "$TEMPLATE_ZIP" ]] || fail "template zip not found: $TEMPLATE_ZIP"
command -v unzip >/dev/null 2>&1 || fail "unzip is required."

if [[ -z "$WORKDIR" ]]; then
  WORKDIR="$PORTING_ROOT/tmp/hap-test/$LIB_NAME"
fi

if [[ "$KEEP_EXISTING" != "true" && -e "$WORKDIR" ]]; then
  safe_clean_workdir "$WORKDIR"
fi

mkdir -p "$WORKDIR"
unzip -q "$TEMPLATE_ZIP" -d "$WORKDIR"

PROJECT_DIR="$WORKDIR/soTest"
if [[ ! -d "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(find "$WORKDIR" -maxdepth 2 -type f -name 'oh-package.json5' -printf '%h\n' | head -n 1 || true)"
fi
[[ -n "$PROJECT_DIR" && -d "$PROJECT_DIR" ]] || fail "failed to locate extracted HAP project under: $WORKDIR"

TARGET_LIB_DIR="$PROJECT_DIR/entry/libs/arm64-v8a"
mkdir -p "$TARGET_LIB_DIR"

if [[ -n "$SO_PATH" ]]; then
  copy_shared_objects_from_path "$SO_PATH"
else
  copy_shared_objects_from_dir "$PORTING_ROOT/outputs/$LIB_NAME/lib" || \
    fail "no shared libraries found under outputs/$LIB_NAME/lib/"
fi

cat <<EOF
HAP test project prepared.
PROJECT_DIR=$PROJECT_DIR
TARGET_LIB_DIR=$TARGET_LIB_DIR

Next steps:
1. Review $TARGET_LIB_DIR and keep any required .so / .so.* runtime dependencies for this library.
2. Edit $PROJECT_DIR/entry/src/main/cpp/CMakeLists.txt to link the target .so.
3. Choose a library-specific HAP validation path: reuse upstream test logic when it can be wrapped into NAPI cleanly; otherwise build a minimal real API smoke path.
4. Edit $PROJECT_DIR/entry/src/main/cpp/napi_init.cpp to call a real API from $LIB_NAME.
5. Edit $PROJECT_DIR/entry/src/main/cpp/types/libentry/Index.d.ts for the ArkTS type declaration.
6. Edit $PROJECT_DIR/entry/src/main/ets/pages/Index.ets to display the native validation result.
7. Before install, verify runtime dependencies (for example via readelf/objdump) and make sure any non-system NEEDED libraries are packaged.
8. Build, install, launch, and record the result in reports/$LIB_NAME/hap-device-report.md.
EOF
