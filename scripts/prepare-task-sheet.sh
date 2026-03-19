#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBS_DIR="$PORTING_ROOT/libs"
DATE_STAMP="${1:-$(date +%F)}"
TARGET_FILE="$LIBS_DIR/porting-tasks-$DATE_STAMP.xlsx"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

find_template_file() {
  local candidates=(
    "$LIBS_DIR/porting-tasks-模板.xlsx"
    "$LIBS_DIR/porting-tasks-template.xlsx"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

TEMPLATE_FILE="$(find_template_file)" || fail "Template file not found under $LIBS_DIR"

if [[ -e "$TARGET_FILE" ]]; then
  echo "Task sheet already exists: $TARGET_FILE"
else
  cp "$TEMPLATE_FILE" "$TARGET_FILE"
  echo "Created task sheet: $TARGET_FILE"
fi

bash "$SCRIPT_DIR/init-batch-report.sh" --date "$DATE_STAMP"
echo "Fill the task sheet and continue with Phase 2."
