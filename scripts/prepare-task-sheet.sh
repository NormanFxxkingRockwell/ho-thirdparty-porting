#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBS_DIR="$PORTING_ROOT/libs"
TEMPLATE_FILE="$LIBS_DIR/porting-tasks-模板.xlsx"
DATE_STAMP="${1:-$(date +%F)}"
TARGET_FILE="$LIBS_DIR/porting-tasks-$DATE_STAMP.xlsx"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$TEMPLATE_FILE" ]] || fail "Template file not found: $TEMPLATE_FILE"

if [[ -e "$TARGET_FILE" ]]; then
  echo "Task sheet already exists: $TARGET_FILE"
else
  cp "$TEMPLATE_FILE" "$TARGET_FILE"
  echo "Created task sheet: $TARGET_FILE"
fi

bash "$SCRIPT_DIR/init-batch-report.sh" --date "$DATE_STAMP"
echo "Fill the task sheet and continue with Phase 2."
