#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/init-report-templates.sh --lib-name <name> [--force]

Creates these report skeletons under reports/:
  - <lib>-adaptation-plan.md
  - <lib>-adaptation-report.md
  - <lib>-build-report.md
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$PORTING_ROOT/reports"

LIB_NAME=""
FORCE="false"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

write_file() {
  local path="$1"
  local content="$2"

  if [[ -e "$path" && "$FORCE" != "true" ]]; then
    echo "Skip existing file: $path"
    return 0
  fi

  printf '%s\n' "$content" > "$path"
  echo "Created report template: $path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lib-name)
      LIB_NAME="$2"
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

[[ -n "$LIB_NAME" ]] || { usage; fail "--lib-name is required."; }

mkdir -p "$REPORTS_DIR"

ADAPTATION_PLAN_FILE="$REPORTS_DIR/$LIB_NAME-adaptation-plan.md"
ADAPTATION_REPORT_FILE="$REPORTS_DIR/$LIB_NAME-adaptation-report.md"
BUILD_REPORT_FILE="$REPORTS_DIR/$LIB_NAME-build-report.md"

ADAPTATION_PLAN_CONTENT=$(cat <<EOF
# $LIB_NAME 业务代码适配方案

## 1. 项目结构概览

- 待补充

## 2. 平台相关代码识别

- 待补充

## 3. HarmonyOS 业务适配点

- 待补充

## 4. 建议修改清单

- 待补充

## 5. 风险与假设

- 待补充

## 6. 给 Phase 5 的最小交接摘要

- 构建系统类型：待补充
- 是否发现现成 \`HPKBUILD\`：待补充
- 是否更适合优先尝试 \`lycium\`：待补充
- 是否预计需要 fallback：待补充
- 已知高风险依赖或构建障碍：待补充
EOF
)

ADAPTATION_REPORT_CONTENT=$(cat <<EOF
# $LIB_NAME 业务适配报告

## 1. 输入方案

- 输入方案文件：\`reports/$LIB_NAME-adaptation-plan.md\`

## 2. 已实施修改

- 待补充

## 3. 与方案的差异

- 待补充

## 4. 遗留业务适配问题

- 待补充

## 5. 交接给 Phase 5 的说明

- 待补充
EOF
)

BUILD_REPORT_CONTENT=$(cat <<EOF
# $LIB_NAME 构建报告

## 1. 构建系统识别结果

- 待补充

## 2. lycium 尝试记录

- 待补充

## 3. 失败分类与决策

- 待补充

## 4. fallback 执行记录

- 待补充

## 5. 编译驱动型代码与脚本修改

- 待补充

## 6. 产物校验结果

- 待补充

## 7. 最终产物路径

- 待补充
EOF
)

write_file "$ADAPTATION_PLAN_FILE" "$ADAPTATION_PLAN_CONTENT"
write_file "$ADAPTATION_REPORT_FILE" "$ADAPTATION_REPORT_CONTENT"
write_file "$BUILD_REPORT_FILE" "$BUILD_REPORT_CONTENT"
