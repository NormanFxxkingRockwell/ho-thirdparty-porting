#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBS_DIR="$PORTING_ROOT/libs"
TASK_FILE=""
OUTPUT_FORMAT="tsv"
AUTO_INSTALL="true"

usage() {
  cat <<EOF
Usage: bash scripts/read-task-sheet.sh [--file <xlsx>] [--format tsv|json] [--no-auto-install]

Options:
  --file <xlsx>         Read the specified dated task sheet.
  --format <fmt>        Output format: tsv (default) or json.
  --no-auto-install     Do not try to install missing Python dependencies automatically.

Behavior:
  - Only accepts dated task sheets matching porting-tasks-YYYY-MM-DD.xlsx
  - Rejects the template file porting-tasks-模板.xlsx
  - Outputs only valid rows containing at least lib_name + repo_url
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

ensure_python3() {
  command -v python3 >/dev/null 2>&1 || fail "python3 is required to parse task sheets."
}

ensure_openpyxl() {
  if python3 - <<'PY' >/dev/null 2>&1
import openpyxl
PY
  then
    return 0
  fi

  if [[ "$AUTO_INSTALL" != "true" ]]; then
    fail "python3 module openpyxl is required."
  fi

  echo "openpyxl not found, trying to install it with python3 -m pip --user openpyxl ..."
  python3 -m pip install --user openpyxl >/dev/null || fail "failed to install openpyxl automatically."
}

find_latest_task_file() {
  local latest=""
  latest="$(find "$LIBS_DIR" -maxdepth 1 -type f -name 'porting-tasks-????-??-??.xlsx' | sort | tail -n 1 || true)"
  [[ -n "$latest" ]] || fail "no dated task sheet found under $LIBS_DIR"
  printf '%s\n' "$latest"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)
        [[ $# -ge 2 ]] || fail "--file requires a value."
        TASK_FILE="$2"
        shift 2
        ;;
      --format)
        [[ $# -ge 2 ]] || fail "--format requires a value."
        OUTPUT_FORMAT="$2"
        shift 2
        ;;
      --no-auto-install)
        AUTO_INSTALL="false"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "unknown argument: $1"
        ;;
    esac
  done

  case "$OUTPUT_FORMAT" in
    tsv|json) ;;
    *) fail "unsupported format: $OUTPUT_FORMAT" ;;
  esac
}

normalize_task_file() {
  if [[ -z "$TASK_FILE" ]]; then
    TASK_FILE="$(find_latest_task_file)"
  fi

  [[ -f "$TASK_FILE" ]] || fail "task sheet not found: $TASK_FILE"

  local base
  base="$(basename "$TASK_FILE")"
  [[ "$base" != "porting-tasks-模板.xlsx" ]] || fail "template file cannot be used as Phase 2 input: $TASK_FILE"
  [[ "$base" =~ ^porting-tasks-[0-9]{4}-[0-9]{2}-[0-9]{2}\.xlsx$ ]] || fail "task sheet must match porting-tasks-YYYY-MM-DD.xlsx: $TASK_FILE"
}

main() {
  parse_args "$@"
  normalize_task_file
  ensure_python3
  ensure_openpyxl

  python3 - "$TASK_FILE" "$OUTPUT_FORMAT" <<'PY'
import json
import sys
from pathlib import Path

from openpyxl import load_workbook

task_file = Path(sys.argv[1])
output_format = sys.argv[2]

header_alias = {
    "库名": "lib_name",
    "git仓库": "repo_url",
    "版本": "version",
    "状态": "status",
    "备注": "note",
    "lib_name": "lib_name",
    "repourl": "repo_url",
    "version": "version",
    "status": "status",
    "note": "note",
}

wb = load_workbook(task_file, data_only=True)
ws = wb.active
rows = list(ws.iter_rows(values_only=True))

if not rows:
    raise SystemExit("ERROR: task sheet is empty.")

raw_header = [("" if c is None else str(c).strip()) for c in rows[0]]
header = []
for cell in raw_header:
    normalized = cell.replace(" ", "").strip().lower()
    key = header_alias.get(normalized, "")
    header.append(key)

if "lib_name" not in header or "repo_url" not in header:
    raise SystemExit("ERROR: task sheet header must contain 库名 and Git 仓库.")

valid_rows = []
for row in rows[1:]:
    values = [("" if c is None else str(c).strip()) for c in row]
    item = {"lib_name": "", "repo_url": "", "version": "", "status": "", "note": ""}
    for idx, key in enumerate(header):
      if key and idx < len(values):
        item[key] = values[idx]
    if item["lib_name"] and item["repo_url"]:
        if not item["status"]:
            item["status"] = "待处理"
        valid_rows.append(item)

if not valid_rows:
    raise SystemExit("ERROR: no valid task rows found.")

if output_format == "json":
    print(json.dumps(valid_rows, ensure_ascii=False, indent=2))
else:
    for item in valid_rows:
        print("\t".join([
            item["lib_name"],
            item["repo_url"],
            item["version"],
            item["status"],
            item["note"],
        ]))
PY
}

main "$@"
