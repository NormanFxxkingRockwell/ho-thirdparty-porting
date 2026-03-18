# HarmonyOS 三方库移植流程

本目录用于指导 AI 在当前仓库中执行 HarmonyOS 三方库移植流程。

仓库定位：
- 这是流程仓库，不是业务应用代码仓库。
- 目标是让 AI 可以按照固定流程完成三方库获取、业务代码适配、构建编译、产物交付与测试。
- 当前优先保证流程可执行、可复用、可迁移。

编译与测试约束：
- 编译只在 Linux 或 WSL 这类类 Linux 环境中进行。
- 默认目标架构是 `arm64-v8a`。
- `.so` 是必须产物。
- binary 是强烈推荐产物，用于后续设备侧快速验证。
- Phase 5 的编译策略是：`lycium` 优先，失败后分类，再进入原生 fallback。
- `lycium` 不是直接消费 `libs/<库名>/` 源码目录的工具，它以 `HPKBUILD` recipe 为核心输入。
- 设备测试主通道是 `harmonyos-dev-mcp`，`hdc` 仅作补充 fallback。
- `harmonyos-dev-mcp` 的安装和配置由用户负责，流程仓库只负责在测试阶段优先调用它。

成功分级：
- `build-pass`：成功生成目标 `.so`
- `binary-pass`：成功生成测试 binary
- `device-pass`：binary 成功推送到设备并执行

## 核心原则

### 1. Phase 职责边界必须清晰

- `Phase 1`：路径配置、环境检查、任务模板准备
- `Phase 2`：读取任务并获取源码
- `Phase 3`：输出 HarmonyOS 业务代码适配方案报告
- `Phase 4`：实施业务代码适配方案，并生成业务适配报告
- `Phase 5`：构建编译，允许边编译边修代码，直到产出 `.so`，并尽量补出测试 binary
- `Phase 6`：交付、归档与测试结果汇总

### 2. STOP 点只保留两个

- `STOP 1`：Phase 1 完成后，等待用户填写任务表
- `STOP 2`：Phase 3 完成后，等待用户批准业务代码适配方案

说明：
- Phase 4 和 Phase 5 连续执行，中间不再停顿。
- Phase 5 完成后不再 STOP，直接进入 Phase 6。
- 测试流程时也必须严格执行 STOP。

### 3. TODO 管理

- 只创建当前阶段的 TODO，不提前创建后续阶段 TODO。
- 一个阶段结束后，先清空 TODO，再决定是否进入 STOP。
- Phase 4 和 Phase 5 视为连续执行阶段，但仍应在 TODO 中分别标识任务。

## 流程总览

### Phase 1：准备

涉及文档：
- [00-paths.md](./00-paths.md)
- [01-env-check.md](./01-env-check.md)
- [02-prepare-tasks.md](./02-prepare-tasks.md)

完成条件：
- 路径变量可推导
- Linux 或 WSL 环境可用
- 已找到 HarmonyOS SDK
- 已找到 `tpc_c_cplusplus`
- 已确认基础交叉编译环境可用
- 已区分 `base-ready` 与 `lycium-ready` 状态
- 已输出基础设备连接状态：`HDC_READY`、`DEVICE_CONNECTED`
- 已生成正式任务表

### Phase 2：获取源码

涉及文档：
- [03-read-tasks.md](./03-read-tasks.md)
- [04-clone-code.md](./04-clone-code.md)
- [05-verify-code.md](./05-verify-code.md)

### Phase 3：业务代码适配方案分析

涉及文档：
- [06-code-analysis.md](./06-code-analysis.md)

输出物：
- `reports/<库名>-adaptation-plan.md`

### Phase 4：业务代码适配实施

涉及文档：
- [08-adaptation-implement.md](./08-adaptation-implement.md)
- [09-adaptation-report.md](./09-adaptation-report.md)

输出物：
- `reports/<库名>-adaptation-report.md`

### Phase 5：构建编译

涉及文档：
- [10-build-system-detect.md](./10-build-system-detect.md)
- [11-cmake-build.md](./11-cmake-build.md)

输出物：
- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>-build-report.md`
- 必要时生成 `libs/<库名>/build.sh`
- 必要时生成 `libs/<库名>/test-driver/`

策略：
- 先尝试 `lycium`
- `lycium` 失败后分类
- 合适时进入 fallback
- 编译期间允许根据报错继续修改代码
- 优先复用上游 test program；若没有，再生成最小测试驱动
- 设备测试时默认优先调用 `harmonyos-dev-mcp`，失败再 fallback 到 `hdc`

### Phase 6：交付与归档

涉及文档：
- [12-delivery-archive.md](./12-delivery-archive.md)

说明：
- 汇总 `.so`、binary、报告、测试命令与设备执行结果
- 更新任务表状态和报告路径
- 明确汇总本轮是 `build-pass`、`binary-pass` 还是 `device-pass`

## 默认路径约定

- 当前仓库根目录：`PORTING_ROOT`
- `lycium` 仓库目录：`$PORTING_ROOT/tpc_c_cplusplus`
- HarmonyOS SDK 根目录变量：`COMMAND_LINE_TOOLS_ROOT`
- 兼容给 `lycium` 的变量：`OHOS_SDK=$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony`
- 库产物目录：`outputs/<库名>/lib/`
- 测试 binary 目录：`outputs/<库名>/bin/`
- 设备推送目录：`/data/local/tmp/<库名>/`

## 推荐脚本

- `scripts/check-env.sh`
- `scripts/check-device-test-env.sh`
- `scripts/prepare-task-sheet.sh`
- `scripts/read-task-sheet.sh`
- `scripts/init-report-templates.sh`
- `scripts/run-lycium-build.sh`
- `scripts/init-build-script.sh`
- `scripts/init-test-driver.sh`

## AI 执行检查清单

- [ ] 当前阶段职责是否正确
- [ ] 是否只在 Phase 1 做环境检查
- [ ] Phase 3 是否只产出业务代码适配方案
- [ ] Phase 5 是否遵循 `lycium -> 失败分类 -> fallback -> 边编译边修 -> 产出 .so`
- [ ] Phase 5 是否优先尝试复用上游 test program
- [ ] Phase 5 若生成最小测试驱动，是否在 build report 中明确标记 `minimal test driver`
- [ ] 设备测试阶段是否默认优先调用 `harmonyos-dev-mcp`
- [ ] 遇到 STOP 后是否真正停止并等待用户继续
