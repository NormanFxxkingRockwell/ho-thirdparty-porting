#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/init-report-templates.sh --lib-name <name> [--force]

Creates these report skeletons under reports/<lib>/:
  - adaptation-plan.md
  - adaptation-report.md
  - build-report.md
  - hap-device-report.md
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
HAP_DEVICE_REPORT_FILE="$LIB_REPORT_DIR/hap-device-report.md"

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
- 样例输入 / fixture / expected 输出：待补……
- Phase 5-2 设备测试是否依赖静态文件、标准输入、工作目录、输出文件或 roundtrip：待补……
- 可用于 HAP 验证的真实 API 调用路径：待补……
- HAP 静态资源承载建议：\`rawfile\` / \`resfile\` / \`sandbox copy\` / \`hdc pushed fixture\` / \`none\`
- 若只能做最小 API smoke，原因：待补……
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
- HAP 验证建议调用路径：待补……
- 可打入 HAP 的资源 / fixture / expected 输出：待补……
- 推荐资源承载方式：\`rawfile\` / \`resfile\` / \`sandbox copy\` / \`hdc pushed fixture\` / \`none\`
- 如果建议降级 smoke，原因：待补……

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
- 是否继续 HAP 验证：待补……
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

HAP_DEVICE_REPORT_CONTENT=$(cat <<EOF
# $LIB_NAME HAP 高可信设备验证报告

## 1. 验证定位

- 本报告对应 Phase 5-3 HAP 高可信设备验证。
- HAP 验证是 \`device-pass\` 之上的增强验证，不替代 binary 设备测试。

## 2. 输入产物

- \`.so\` 路径：待补……
- HAP 验证策略：\`fixture-driven HAP\` / \`复用上游测试逻辑\` / \`最小真实 API smoke\` / \`skip\`
- 未直接复用上游测试入口的原因：待补……
- 如果使用 smoke，为什么没有使用 fixture/resource/roundtrip：待补……
- 模板来源：\`templates/soTest-template.zip\`
- 临时工程路径：\`tmp/hap-test/$LIB_NAME/soTest/\`

## 3. HAP 工程修改

- 修改文件：待补……
- 运行时依赖处理（\`.so\` / \`.so.*\` / 其他共享库）：待补……
- 资源/配置文件处理：待补……
- 静态资源来源路径：待补……
- 资源承载方式：\`rawfile\` / \`resfile\` / \`sandbox copy\` / \`hdc pushed fixture\` / \`none\`
- HAP 内资源路径或设备侧路径：待补……
- 资源文件数量或清单：待补……
- patch 路径：\`reports/$LIB_NAME/hap-device/hap-test.patch\`

## 4. NAPI 调用链

- ArkTS 调用入口：待补……
- NAPI 导出方法：待补……
- native 调用的三方库 API：待补……
- 样例输入：待补……
- 预期输出：待补……
- expected 校验方式：待补……

## 4.1 fixture / 资源验证结果

- 用例总数：待补……
- 通过数：待补……
- 失败数：待补……
- 失败样例：待补……
- 审计字符串示例：待补……

## 5. HAP 构建记录

- 构建方式：DevEco / ohpm + hvigor / 其他
- 构建命令：待补……
- HAP 产物：待补……
- 构建结果：待补……

## 6. HAP 签名记录

- 签名模式：project-config / external-signTools / skip
- 推荐签名脚本：\`scripts/sign-hap-with-sign-tools.sh\`
- 签名命令或脚本输出：待补……
- signed HAP：待补……
- 签名结果：待补……
- 如果签名失败，失败分类：参数解析 / profile 不匹配 / Java 不可用 / 签名文件缺失 / 其他
- 如果签名失败，是否已尝试推荐脚本：待补……
- 如果已有 \`ohos_provision_debug.p7b\`，是否尝试直接 \`sign-app\`：待补……

## 7. 设备安装与启动

- 测试通道：\`harmonyos-dev-mcp\` / \`hdc fallback\`
- 设备序列号：待补……
- 安装命令：待补……
- 启动命令：待补……
- 启动结果：待补……

## 8. UI / 日志验证结果

- UI 显示：待补……
- 关键日志：待补……
- 是否包含明确成功标记：待补……

## 9. 结论

- hap-device-pass：\`待处理\`
- 失败或跳过原因：待补……
EOF
)

write_file "$ADAPTATION_PLAN_FILE" "$ADAPTATION_PLAN_CONTENT"
write_file "$ADAPTATION_REPORT_FILE" "$ADAPTATION_REPORT_CONTENT"
write_file "$BUILD_REPORT_FILE" "$BUILD_REPORT_CONTENT"
write_file "$HAP_DEVICE_REPORT_FILE" "$HAP_DEVICE_REPORT_CONTENT"
