# HarmonyOS 三方库移植流程

本目录用于指导 AI 在当前仓库中执行 HarmonyOS 三方库移植流程。

仓库定位：
- 这是流程仓库，不是业务应用代码仓库。
- 目标是让 AI 可以按照固定流程完成三方库获取、业务代码适配、构建编译、产物交付。
- 当前优先保证流程可执行、可复用、可迁移，业务适配准确性不是本轮重点。

编译约束：
- 编译只在 Linux 或 WSL 这类类 Linux 环境中进行。
- 默认目标产物是 `.so`。
- 默认目标架构是 `arm64-v8a`。
- Phase 5 的编译策略是：`lycium` 优先，失败后分类，再进入原生 fallback。

## 核心原则

### 1. Phase 职责边界必须清晰

- `Phase 1`：路径配置、环境检查、任务模板准备
- `Phase 2`：读取任务并获取源码
- `Phase 3`：输出 HarmonyOS 业务代码适配方案报告
- `Phase 4`：实施业务代码适配方案，并生成业务适配报告
- `Phase 5`：构建编译，允许边编译边修代码，直到产出 `.so`
- `Phase 6`：交付与归档

### 2. STOP 点只保留两个

- `STOP 1`：Phase 1 完成后，等待用户填写任务表
- `STOP 2`：Phase 3 完成后，等待用户批准业务代码适配方案

说明：
- Phase 4 和 Phase 5 连续执行，中间不再停顿。
- Phase 5 完成后不再 STOP，直接进入 Phase 6。

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
- 已找到 HarmonyOS SDK，或者已要求用户补充 `COMMAND_LINE_TOOLS_ROOT`
- 已找到 `tpc_c_cplusplus`，或者已尝试自动拉取
- 已生成任务模板

完成后动作：
- 清空 Phase 1 TODO
- STOP，等待用户说“填好了”

### Phase 2：获取源码

涉及文档：
- [03-read-tasks.md](./03-read-tasks.md)
- [04-clone-code.md](./04-clone-code.md)
- [05-verify-code.md](./05-verify-code.md)

完成条件：
- 已读取任务表
- 已克隆或下载目标库源码到 `libs/<库名>/`
- 已核对版本、分支或 commit

### Phase 3：业务代码适配方案分析

涉及文档：
- [06-code-analysis.md](./06-code-analysis.md)

输出物：
- `reports/<库名>-adaptation-plan.md`

说明：
- 本阶段只分析 HarmonyOS 业务代码适配点。
- 本阶段不输出编译构建方案。
- 本阶段的目标是识别需要替换的系统接口、平台宏、头文件、平台能力调用等。

完成后动作：
- 清空 Phase 2-3 TODO
- STOP，等待用户批准方案

### Phase 4：业务代码适配实施

涉及文档：
- [08-adaptation-implement.md](./08-adaptation-implement.md)
- [09-adaptation-report.md](./09-adaptation-report.md)

输出物：
- `reports/<库名>-adaptation-report.md`

说明：
- 只实施已批准的业务代码适配方案。
- 本阶段的修改记录在业务适配报告中。

### Phase 5：构建编译

涉及文档：
- [10-build-system-detect.md](./10-build-system-detect.md)
- [11-cmake-build.md](./11-cmake-build.md)

输出物：
- `outputs/<库名>/`
- `reports/<库名>-build-report.md`
- 必要时生成 `libs/<库名>/build.sh`

策略：
- 先尝试 `lycium`
- `lycium` 失败后，先分类失败原因
- 只有适合进入 fallback 时，才生成原生 `build.sh`
- 编译期间允许根据报错继续修改代码，直到生成 `.so`

### Phase 6：交付与归档

涉及文档：
- [12-delivery-archive.md](./12-delivery-archive.md)

说明：
- 汇总产物、报告、源码修改
- 提醒用户关注两个报告：
  - `reports/<库名>-adaptation-report.md`
  - `reports/<库名>-build-report.md`
- 更新任务表状态和报告路径

## 默认路径约定

- 当前仓库根目录：`PORTING_ROOT`
- `lycium` 仓库目录：`$PORTING_ROOT/tpc_c_cplusplus`
- HarmonyOS SDK 根目录变量：`COMMAND_LINE_TOOLS_ROOT`
- 兼容给 `lycium` 的变量：`OHOS_SDK=$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony`

具体规则见 [00-paths.md](./00-paths.md)。

## 推荐脚本

- `scripts/check-env.sh`
- `scripts/run-lycium-build.sh`
- `scripts/init-build-script.sh`

说明：
- `run-lycium-build.sh` 是模板脚本。
- AI 应复制出按库名命名的脚本，例如 `scripts/run-lycium-build-zlib.sh`，填写后再执行。

## AI 执行检查清单

- [ ] 当前阶段职责是否正确，没有跨阶段输出错误内容
- [ ] 是否只在 Phase 1 做环境检查
- [ ] Phase 3 是否只产出业务代码适配方案
- [ ] Phase 5 是否遵循 `lycium -> 失败分类 -> fallback -> 边编译边修 -> 产出 .so`
- [ ] Phase 5 完成后是否直接进入交付
- [ ] 是否避免写死机器绝对路径

