#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/collect-hap-test-artifacts.sh --lib-name <name> [options]

Options:
  --template <zip>    Template zip. Defaults to templates/soTest-template.zip.
  --workdir <dir>     Work directory. Defaults to tmp/hap-test/<lib-name>.
  --log-file <path>   Optional device or build log to copy into artifacts.
  --extra-artifact <path>
                      Optional signed HAP, p7b, sign-run directory, or other artifact to copy.
                      Repeatable.
  --keep-workdir      Keep the temporary project after collection.

Collects patch, HAP artifacts, and optional logs under:
  reports/<lib-name>/hap-device/
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LIB_NAME=""
TEMPLATE_ZIP="$PORTING_ROOT/templates/soTest-template.zip"
WORKDIR=""
LOG_FILE=""
EXTRA_ARTIFACTS=()
KEEP_WORKDIR="false"

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

copy_extra_artifact() {
  local path="$1"
  local copied="false"

  if [[ -f "$path" ]]; then
    cp "$path" "$ARTIFACT_DIR/"
    return 0
  fi

  if [[ -d "$path" ]]; then
    while IFS= read -r -d '' file; do
      cp "$file" "$ARTIFACT_DIR/"
      copied="true"
    done < <(find "$path" -maxdepth 2 -type f \( -name '*.hap' -o -name '*.p7b' -o -name '*.log' -o -name '*.txt' -o -name '*.json' \) -print0)
    [[ "$copied" == "true" ]] || fail "no collectable artifacts found under directory: $path"
    return 0
  fi

  fail "artifact path not found: $path"
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
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --extra-artifact)
      EXTRA_ARTIFACTS+=("$2")
      shift 2
      ;;
    --keep-workdir)
      KEEP_WORKDIR="true"
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
command -v diff >/dev/null 2>&1 || fail "diff is required."

if [[ -z "$WORKDIR" ]]; then
  WORKDIR="$PORTING_ROOT/tmp/hap-test/$LIB_NAME"
fi

PROJECT_DIR="$WORKDIR/soTest"
[[ -d "$PROJECT_DIR" ]] || fail "HAP project not found: $PROJECT_DIR"

REPORT_DIR="$PORTING_ROOT/reports/$LIB_NAME/hap-device"
ARTIFACT_DIR="$REPORT_DIR/artifacts"
mkdir -p "$ARTIFACT_DIR"

BASELINE_DIR="$(mktemp -d "$PORTING_ROOT/tmp/hap-test/${LIB_NAME}.baseline.XXXXXX")"
trap 'rm -rf "$BASELINE_DIR"' EXIT
unzip -q "$TEMPLATE_ZIP" -d "$BASELINE_DIR"
BASELINE_PROJECT="$BASELINE_DIR/soTest"
[[ -d "$BASELINE_PROJECT" ]] || BASELINE_PROJECT="$(find "$BASELINE_DIR" -maxdepth 2 -type f -name 'oh-package.json5' -printf '%h\n' | head -n 1 || true)"
[[ -n "$BASELINE_PROJECT" && -d "$BASELINE_PROJECT" ]] || fail "failed to locate baseline project from template."

PATCH_FILE="$REPORT_DIR/hap-test.patch"
set +e
diff -ruN \
  --exclude='.hvigor' \
  --exclude='.idea' \
  --exclude='oh_modules' \
  --exclude='.cxx' \
  --exclude='build' \
  "$BASELINE_PROJECT" "$PROJECT_DIR" > "$PATCH_FILE"
diff_status=$?
set -e
if [[ "$diff_status" -gt 1 ]]; then
  fail "diff failed while creating patch."
fi

find "$PROJECT_DIR" -type f -name '*.hap' -print0 | while IFS= read -r -d '' hap; do
  cp "$hap" "$ARTIFACT_DIR/"
done

if [[ -n "$LOG_FILE" ]]; then
  [[ -f "$LOG_FILE" ]] || fail "log file not found: $LOG_FILE"
  cp "$LOG_FILE" "$ARTIFACT_DIR/"
fi

if [[ ${#EXTRA_ARTIFACTS[@]} -gt 0 ]]; then
  for artifact in "${EXTRA_ARTIFACTS[@]}"; do
    copy_extra_artifact "$artifact"
  done
fi

find "$PROJECT_DIR" -maxdepth 4 -type f | sed "s#^$PROJECT_DIR/##" | sort > "$REPORT_DIR/project-files.txt"

if [[ "$KEEP_WORKDIR" != "true" ]]; then
  safe_clean_workdir "$WORKDIR"
fi

cat <<EOF
HAP test artifacts collected.
REPORT_DIR=$REPORT_DIR
PATCH_FILE=$PATCH_FILE
ARTIFACT_DIR=$ARTIFACT_DIR
WORKDIR_CLEANED=$([[ "$KEEP_WORKDIR" == "true" ]] && echo false || echo true)
EOF
