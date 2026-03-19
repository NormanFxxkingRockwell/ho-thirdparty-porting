#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/init-batch-report.sh [--date YYYY-MM-DD] [--force]

Creates a batch summary report:
  reports/batch-YYYY-MM-DD.md
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$PORTING_ROOT/reports"

DATE_STAMP="$(date +%F)"
FORCE="false"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      DATE_STAMP="$2"
      shift 2
      ;;
    --force)
      FORCE="true"
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

mkdir -p "$REPORTS_DIR"

TARGET_FILE="$REPORTS_DIR/batch-$DATE_STAMP.md"
if [[ -e "$TARGET_FILE" && "$FORCE" != "true" ]]; then
  echo "Batch report already exists: $TARGET_FILE"
  exit 0
fi

cat > "$TARGET_FILE" <<EOF
# 批次汇总报告（$DATE_STAMP）

## 1. 批次概览

- 待补……

## 2. 库级结果汇总

| 库名 | 是否需要用户审批方案 | 审批结果 | 适配状态 | 编译状态 | 测试状态 | 失败原因/备注 |
|------|----------------------|----------|----------|----------|----------|----------------|

## 3. 关键风险与阻塞

- 待补……

## 4. 交付总结

- 待补……
EOF

echo "Created batch report: $TARGET_FILE"
