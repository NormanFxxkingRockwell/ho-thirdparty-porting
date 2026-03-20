#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/init-report-templates.sh --lib-name <name> [--force]

Creates these report skeletons under reports/<lib>/:
  - adaptation-plan.md
  - adaptation-report.md
  - build-report.md
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

LIB_REPORT_DIR="$REPORTS_DIR/$LIB_NAME"
mkdir -p "$LIB_REPORT_DIR"

ADAPTATION_PLAN_FILE="$LIB_REPORT_DIR/adaptation-plan.md"
ADAPTATION_REPORT_FILE="$LIB_REPORT_DIR/adaptation-report.md"
BUILD_REPORT_FILE="$LIB_REPORT_DIR/build-report.md"

ADAPTATION_PLAN_CONTENT=$(cat <<EOF
# $LIB_NAME 业务代码适配方案

## 1. 项目结构概览

- 待补……

## 2. 平台相关代码识别

- 待补……

## 3. HarmonyOS 业务适配点

- 待补……

## 4. 建议修改清单

- 待补……

## 5. 风险与假设

- 待补……

## 6. 可复用测试入口与指导

- 上游 test program：待补……
- 若无合适 test program，上游 CLI：待补……
- 优先推荐的运行命令：待补……
- 若无现成入口，是否无测试用例：待补……

## 7. 给 Phase 5 的最小交接摘要

- 构建系统类型：待补……
- 是否发现现成 \`HPKBUILD\`：待补……
- 是否更适合优先尝试 \`lycium\`：待补……
- 是否预计需要 fallback：待补……
- 已知高风险依赖或构建障碍：待补……
EOF
)

ADAPTATION_REPORT_CONTENT=$(cat <<EOF
# $LIB_NAME 业务适配报告

## 1. 输入方案

- 输入方案文件：\`reports/$LIB_NAME/adaptation-plan.md\`

## 2. 已实施修改

- 待补……

## 3. 与方案的差异

- 待补……

## 4. 遗留业务适配问题

- 待补……

## 5. 测试入口与使用建议

- 优先 test program 路径：待补……
- 若无合适 test program，优先 CLI 能力校验路径：待补……
- 若仍无现成入口，明确记录无测试用例：待补……
- 关键 API / 参数 / 样例输入：待补……

## 6. 交接给 Phase 5 的说明

- 待补……
EOF
)

BUILD_REPORT_CONTENT=$(cat <<EOF
# $LIB_NAME 构建报告

## 1. 构建系统识别结果

- 待补……

## 2. lycium 尝试记录

- 待补……

## 3. 失败分类与决策

- 待补……

## 4. fallback 执行记录

- 待补……

## 5. 编译驱动型代码与脚本修改

- 待补……

## 6. 产物概览

- build-pass：待补……
- binary-pass：待补……
- device-pass：待补……
- \`.so\` 路径：待补……
- binary 路径：待补……

## 7. binary 验证方式

- binary 来源类型：\`test program\` / \`CLI\` / \`无测试用例\`
- 运行命令：待补……
- 设备侧执行结果：待补……
- 关键输出：待补……

## 8. 设备测试记录

- hdc 推送目录：\`/data/local/tmp/$LIB_NAME/\`
- hdc 推送命令：待补……
- 设备执行命令：待补……
- 设备侧输出：待补……

## 9. 产物校验结果

- 待补……

## 10. 最终产物路径

- 待补……
EOF
)

write_file "$ADAPTATION_PLAN_FILE" "$ADAPTATION_PLAN_CONTENT"
write_file "$ADAPTATION_REPORT_FILE" "$ADAPTATION_REPORT_CONTENT"
write_file "$BUILD_REPORT_FILE" "$BUILD_REPORT_CONTENT"
