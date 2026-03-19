#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBS_DIR="$PORTING_ROOT/libs"
REPORTS_DIR="$PORTING_ROOT/reports"

TASK_FILE=""
LIB_NAME=""
APPROVAL_RESULT=""
ADAPTATION_STATUS=""
BUILD_STATUS=""
TEST_STATUS=""
NOTE=""

usage() {
  cat <<EOF
Usage: bash scripts/update-batch-status.sh --lib-name <name> [options]

Options:
  --file <xlsx>              Dated task sheet. Defaults to latest one.
  --approval-result <value>  One of: 待审批/通过/不通过/不需要审批
  --adaptation-status <v>    One of: 待处理/pass/fail/skip
  --build-status <v>         One of: 待处理/pass/fail/skip
  --test-status <v>          One of: 待处理/pass/fail/skip
  --note <text>              Failure reason or remarks
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

find_latest_task_file() {
  local latest=""
  latest="$(find "$LIBS_DIR" -maxdepth 1 -type f -name 'porting-tasks-????-??-??.xlsx' | sort | tail -n 1 || true)"
  [[ -n "$latest" ]] || fail "no dated task sheet found under $LIBS_DIR"
  printf '%s\n' "$latest"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      TASK_FILE="$2"
      shift 2
      ;;
    --lib-name)
      LIB_NAME="$2"
      shift 2
      ;;
    --approval-result)
      APPROVAL_RESULT="$2"
      shift 2
      ;;
    --adaptation-status)
      ADAPTATION_STATUS="$2"
      shift 2
      ;;
    --build-status)
      BUILD_STATUS="$2"
      shift 2
      ;;
    --test-status)
      TEST_STATUS="$2"
      shift 2
      ;;
    --note)
      NOTE="$2"
      shift 2
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

if [[ -z "$TASK_FILE" ]]; then
  TASK_FILE="$(find_latest_task_file)"
fi

[[ -f "$TASK_FILE" ]] || fail "task sheet not found: $TASK_FILE"

python3 - "$TASK_FILE" "$REPORTS_DIR" "$LIB_NAME" "$APPROVAL_RESULT" "$ADAPTATION_STATUS" "$BUILD_STATUS" "$TEST_STATUS" "$NOTE" <<'PY'
from pathlib import Path
import sys
import re
from openpyxl import load_workbook

task_file = Path(sys.argv[1])
reports_dir = Path(sys.argv[2])
lib_name = sys.argv[3]
approval_result = sys.argv[4]
adaptation_status = sys.argv[5]
build_status = sys.argv[6]
test_status = sys.argv[7]
note = sys.argv[8]

allowed_approval = {"", "待审批", "通过", "不通过", "不需要审批"}
allowed_state = {"", "待处理", "pass", "fail", "skip"}
if approval_result not in allowed_approval:
    raise SystemExit(f"ERROR: unsupported approval result: {approval_result}")
for field_name, value in [("adaptation", adaptation_status), ("build", build_status), ("test", test_status)]:
    if value not in allowed_state:
        raise SystemExit(f"ERROR: unsupported {field_name} status: {value}")

wb = load_workbook(task_file)
ws = wb.active

def norm_header(text: str) -> str:
    value = (text or "").strip()
    value = value.replace("（", "(").replace("）", ")")
    value = re.sub(r"\(.*?\)", "", value)
    return value

headers = [norm_header(str(ws.cell(1, c).value or "")) for c in range(1, ws.max_column + 1)]
index = {header: i + 1 for i, header in enumerate(headers)}

required_headers = ["库名", "审批结果", "适配状态", "编译状态", "测试状态", "失败原因/备注", "是否需要用户审批方案"]
for header in required_headers:
    if header not in index:
        raise SystemExit(f"ERROR: missing header in task sheet: {header}")

target_row = None
for row in range(2, ws.max_row + 1):
    if str(ws.cell(row, index["库名"]).value or "").strip() == lib_name:
        target_row = row
        break

if target_row is None:
    raise SystemExit(f"ERROR: library not found in task sheet: {lib_name}")

if approval_result:
    ws.cell(target_row, index["审批结果"]).value = approval_result
if adaptation_status:
    ws.cell(target_row, index["适配状态"]).value = adaptation_status
if build_status:
    ws.cell(target_row, index["编译状态"]).value = build_status
if test_status:
    ws.cell(target_row, index["测试状态"]).value = test_status
if note:
    ws.cell(target_row, index["失败原因/备注"]).value = note

wb.save(task_file)

date_match = re.search(r"(\d{4}-\d{2}-\d{2})", task_file.name)
if not date_match:
    raise SystemExit("ERROR: failed to derive batch report date from task file name")
batch_report = reports_dir / f"batch-{date_match.group(1)}.md"

rows = []
for row in range(2, ws.max_row + 1):
    lib = str(ws.cell(row, index["库名"]).value or "").strip()
    repo = str(ws.cell(row, index.get("Git 仓库", 0)).value or "").strip() if index.get("Git 仓库", 0) else ""
    if not lib or not repo:
        continue
    rows.append({
        "lib": lib,
        "approval_required": str(ws.cell(row, index["是否需要用户审批方案"]).value or "是").strip() or "是",
        "approval_result": str(ws.cell(row, index["审批结果"]).value or "").strip(),
        "adaptation_status": str(ws.cell(row, index["适配状态"]).value or "").strip() or "待处理",
        "build_status": str(ws.cell(row, index["编译状态"]).value or "").strip() or "待处理",
        "test_status": str(ws.cell(row, index["测试状态"]).value or "").strip() or "待处理",
        "note": str(ws.cell(row, index["失败原因/备注"]).value or "").strip(),
    })

all_libs = "、".join(f"`{row['lib']}`" for row in rows)
table_lines = [
    "| 库名 | 是否需要用户审批方案 | 审批结果 | 适配状态 | 编译状态 | 测试状态 | 失败原因/备注 |",
    "|------|----------------------|----------|----------|----------|----------|----------------|",
]
for row in rows:
    table_lines.append(
        f"| {row['lib']} | {row['approval_required']} | {row['approval_result']} | "
        f"{row['adaptation_status']} | {row['build_status']} | {row['test_status']} | {row['note']} |"
    )

content = f"""# 批次汇总报告（{date_match.group(1)}）

## 1. 批次概览

- 本轮批次库：{all_libs}

## 2. 库级结果汇总

{chr(10).join(table_lines)}

## 3. 关键风险与阻塞

- 待补……

## 4. 交付总结

- 待补……
"""

batch_report.write_text(content, encoding="utf-8")
print(f"updated: {task_file}")
print(f"updated: {batch_report}")
PY
