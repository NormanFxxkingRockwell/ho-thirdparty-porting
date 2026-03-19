# HarmonyOS 三方库移植流程

本目录用于指导 AI 在当前仓库中执行 HarmonyOS 三方库移植流程。

仓库定位：
- 这是流程仓库，不是业务应用代码仓库。
- 目标是让 AI 可以按照固定流程完成三方库获取、业务代码适配、构建编译、设备测试与交付归档。
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

### 2. STOP 点

- `STOP 1`：Phase 1 完成后，等待用户填表
- `STOP 2`：只对“需要用户审批方案”的库生效，在 Phase 3 完成后等待审批

说明：
- Phase 4 和 Phase 5 连续执行，中间不再停顿。
- Phase 5 完成后不再 STOP，直接进入 Phase 6。
- 测试流程时也必须严格执行 STOP。

### 3. 多库模式

当前工作流仅支持多库串行执行，不支持并行执行。
- 硬规则：禁止并行处理多个库。

执行顺序：
- 先处理 `是否需要用户审批方案=否` 的库
- 再处理 `是否需要用户审批方案=是` 的库
- 没填默认按 `是`
- 硬规则：禁止并行写任务表、批次报告、lycium 共享目录与共享缓存
- 同组内按表格顺序串行

审批流：
- 不需要审批的库，直接串行跑到 Phase 6
- 需要审批的库，先统一跑到 Phase 3
- 任务表中写入 `审批结果=待审批`
- 用户可批量查看并审批
- `审批结果=通过` 的库继续进入 Phase 4/5/6
- `审批结果=不通过` 的库回到 Phase 3，重新出方案，再等待审批

失败策略：
- 单个库失败不阻塞整个批次
- 失败原因必须记录到任务表和批次汇总报告
- 后续库继续执行

### 4. 子 agent 使用原则

- 主 agent 负责流程推进、STOP、最终判断和核心修改收口
- 子 agent 适合承担只需要输出结果的任务，例如：
  - 读取源码结构
  - 查上游测试入口
  - 查现成 `HPKBUILD`
- 子 agent 只能做只读分析、检索、校验等不会修改共享状态的工作，不能并行推进多个库的主流程
  - 产物校验
- 不把同一个库的核心 recipe 或核心 build 脚本修改交给多个 agent 并行处理

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
- 已生成批次汇总报告

### Phase 2：获取源码

涉及文档：
- [03-read-tasks.md](./03-read-tasks.md)
- [04-clone-code.md](./04-clone-code.md)
- [05-verify-code.md](./05-verify-code.md)

输出：
- `libs/<库名>/`

### Phase 3：业务代码适配方案分析

涉及文档：
- [06-code-analysis.md](./06-code-analysis.md)

输出：
- `reports/<库名>/adaptation-plan.md`

### Phase 4：业务代码适配实施

涉及文档：
- [08-adaptation-implement.md](./08-adaptation-implement.md)
- [09-adaptation-report.md](./09-adaptation-report.md)

输出：
- `reports/<库名>/adaptation-report.md`

### Phase 5：构建编译

涉及文档：
- [10-build-system-detect.md](./10-build-system-detect.md)
- [11-cmake-build.md](./11-cmake-build.md)

输出：
- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>/build-report.md`
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
- 更新 `reports/batch-YYYY-MM-DD.md`
- 明确汇总本轮是 `build-pass`、`binary-pass` 还是 `device-pass`

## 默认路径约定

- 当前仓库根目录：`PORTING_ROOT`
- `lycium` 仓库目录：`$PORTING_ROOT/tpc_c_cplusplus`
- HarmonyOS SDK 根目录变量：`COMMAND_LINE_TOOLS_ROOT`
- 兼容给 `lycium` 的变量：`OHOS_SDK=$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony`
- 库产物目录：`outputs/<库名>/lib/`
- 测试 binary 目录：`outputs/<库名>/bin/`
- 库报告目录：`reports/<库名>/`
- 批次汇总报告：`reports/batch-YYYY-MM-DD.md`
- 设备推送目录：`/data/local/tmp/<库名>/`

## 推荐脚本

- `scripts/check-env.sh`
- `scripts/check-device-test-env.sh`
- `scripts/prepare-task-sheet.sh`
- `scripts/read-task-sheet.sh`
- `scripts/init-report-templates.sh`
- `scripts/init-batch-report.sh`
- `scripts/update-batch-status.sh`
- `scripts/run-lycium-build.sh`
- `scripts/init-build-script.sh`
- `scripts/init-test-driver.sh`

## AI 执行检查清单

- [ ] 当前阶段职责是否正确
- [ ] 是否只在 Phase 1 做环境检查
- [ ] Phase 3 是否只产出业务代码适配方案
- [ ] Phase 5 是否遵循 `lycium -> 失败分类 -> fallback -> 边编译边修 -> 产出 .so`
- [ ] Phase 5 是否优先尝试复用上游 test program
- [ ] 若生成最小测试驱动，是否在 build report 中明确标记 `minimal test driver`
- [ ] 设备测试阶段是否默认优先调用 `harmonyos-dev-mcp`
- [ ] 多库时是否遵守“先否后是、组内串行”的规则
- [ ] 需要审批的库是否统一写入 `审批结果`
- [ ] 遇到 STOP 后是否真正停止并等待用户继续
