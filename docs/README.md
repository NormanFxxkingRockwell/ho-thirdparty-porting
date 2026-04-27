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
- HAP 验证是 `device-pass` 之上的更高可信验证，不替代现有 binary 设备测试。
- `signTools/hapsigner.zip` 可以作为长期保留的外部 HAP 签名资源。

成功分级：
- `build-pass`：成功生成目标 `.so`
- `binary-pass`：成功生成测试 binary
- `device-pass`：binary 成功推送到设备并执行
- `hap-device-pass`：HAP 通过 ArkTS -> NAPI -> 三方库 `.so` 链路完成真实调用并展示结果

## 核心原则

### 1. Phase 职责边界必须清晰

- `Phase 1`：路径配置、环境检查、任务模板准备
- `Phase 2`：读取任务并获取源码
- `Phase 3`：输出 HarmonyOS 业务代码适配方案报告
- `Phase 4`：实施业务代码适配方案，并生成业务适配报告
- `Phase 5`：构建编译、binary 设备测试，并可选执行 HAP 高可信设备验证
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
- 已输出 HAP 增强验证状态：`HAP_DEVECO_READY`、`HAP_WINDOWS_BRIDGE_READY`、`HAP_OHPM_READY`、`HAP_OHPM_HOST`、`HAP_HVIGOR_READY`、`HAP_HVIGOR_HOST`、`HAP_JAVA_READY`、`HAP_JAVA_HOST`、`HAP_SIGNTOOLS_READY`、`HAP_SIGNING_MODE`、`HAP_SIGNING_READY`、`HAP_ENV_READY`
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

### Phase 5：构建编译与设备验证

涉及文档：
- [10-build-system-detect.md](./10-build-system-detect.md)
- [11-cmake-build.md](./11-cmake-build.md)
- [12-hap-device-test.md](./12-hap-device-test.md)

输出：
- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>/build-report.md`
- `reports/<库名>/hap-device-report.md`（如果执行 HAP 验证）
- 必要时生成 `libs/<库名>/build.sh`

策略：
- `lycium` 是主构建流程，优先级高于 fallback
- `lycium` 先做 recipe 预检查与预修正，再执行实际构建
- 发现同库或近似库的现成 recipe 后，优先复制、升级并修正，不允许仅因版本或依赖不一致直接 fallback
- `lycium` 失败后必须先分类，不能因为配置项没开对、版本不一致或依赖不一致就直接 fallback
- 进入 fallback 前也必须先做原生构建方案预检查与预修正，再执行实际构建
- 编译期间允许根据报错继续修改代码
- 优先复用上游自带、可独立运行的测试入口；若没有合适的测试入口，再使用上游 CLI 做真实能力校验（CLI 能力校验）；若仍无现成测试入口，则明确记录“无测试用例”
- 设备测试时默认优先调用 `harmonyos-dev-mcp`，失败再 fallback 到 `hdc`
- 如果本轮要求更高可信验证，HAP 验证在 `device-pass` 之后执行，使用模板工程把 `.so` 放入应用，通过 ArkTS -> NAPI -> native 调用链验证
- HAP 验证路径必须按库选择：有小型静态资源、fixture、expected 输出或 roundtrip 语义时，优先做 `fixture-driven HAP`；能低成本包进 NAPI 的上游测试/示例逻辑其次复用；只有没有可用资源/expected/roundtrip 或资源无法稳定打包时，才降级为“最小但真实”的 API smoke path
- 资源目录不是降级 smoke 的理由；应优先使用 `rawfile`、`resfile` 或 sandbox copy 把资源交给 NAPI/native，并在日志或 UI 中输出用例数、通过数、失败数和资源来源
- HAP 准备阶段不能只看顶层 `.so`；如果存在 `*.so.*` 版本化 SONAME 文件或额外非系统运行时依赖，必须一并打包并核对 `NEEDED`
- 如果 `HAP_SIGNING_MODE=external-signTools`，允许使用 `signTools/hapsigner.zip` 对 unsigned HAP 做外部签名；这条路径不要求修改模板工程的签名源码或工具链源码
- 外部签名优先使用 `scripts/sign-hap-with-sign-tools.sh`；遇到 `signAlg` 缺失、参数不成对等错误时，应先按命令参数解析问题排查，不得直接归类为 Java 环境问题
- 如果 profile 模板未变且已有 `ohos_provision_debug.p7b`，可以先尝试直接 `sign-app`，不要因为 `sign-profile` 参数拼装失败就立即跳过 HAP 验证
- HAP 验证失败或跳过不反向否定已完成的 `build-pass` / `binary-pass` / `device-pass`，但必须记录 `hap-device-pass`
- `HAP_ENV_READY=false` 时，HAP 验证不得伪造通过，应记录 `skip` 或 `fail` 并说明缺失项
- WSL 场景下不要求 DevEco/ohpm/hvigor/签名安装到 WSL；如果检测到 `HAP_*_HOST=windows`，后续命令应走 Windows/PowerShell/DevEco
- 如果在 WSL 中调用 Windows `hdc.exe`，`file send` 应使用 Windows / UNC 本地路径和显式远端文件名，不要依赖相对路径发送

### Phase 6：交付与归档

涉及文档：
- [13-delivery-archive.md](./13-delivery-archive.md)

说明：
- 汇总 `.so`、binary、报告、测试命令、设备执行结果与 HAP 验证结果
- 更新任务表状态和报告路径
- 更新 `reports/batch-YYYY-MM-DD.md`
- 明确汇总本轮是 `build-pass`、`binary-pass`、`device-pass` 还是 `hap-device-pass`

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
- HAP 模板压缩包：`templates/soTest-template.zip`
- HAP 外部签名包：`signTools/hapsigner.zip`
- HAP 临时工程目录：`tmp/hap-test/<库名>/soTest/`
- HAP 验证资料目录：`reports/<库名>/hap-device/`

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
- `scripts/prepare-hap-test-project.sh`
- `scripts/sign-hap-with-sign-tools.sh`
- `scripts/collect-hap-test-artifacts.sh`

## AI 执行检查清单

- [ ] 当前阶段职责是否正确
- [ ] 是否只在 Phase 1 做环境检查
- [ ] Phase 3 是否只产出业务代码适配方案
- [ ] Phase 5 是否遵循 `lycium预检查/预修正 -> lycium执行 -> 失败分类 -> fallback预检查/预修正 -> fallback执行 -> 边编译边修 -> 产出.so`
- [ ] Phase 5 是否遵循“上游自带、可独立运行的测试入口优先，其次 `CLI` 能力校验，最后才是 `无测试用例`”的顺序
- [ ] 若无现成测试入口，是否已在 build report 中明确记录“无测试用例”
- [ ] 设备测试阶段是否默认优先调用 `harmonyos-dev-mcp`
- [ ] 若执行 HAP 验证，是否先从模板重新解压临时工程，而不是复用上轮工程
- [ ] 若执行 HAP 验证，是否先检查 `HAP_ENV_READY` 及其缺失项
- [ ] 若执行 HAP 验证，是否根据 `HAP_SIGNING_MODE` 选择模板内签名或 `signTools/hapsigner.zip` 外部签名
- [ ] 若外部签名失败，是否优先使用 `scripts/sign-hap-with-sign-tools.sh` 复现，并区分参数解析失败、profile 不匹配和真实环境缺失
- [ ] 若执行 HAP 验证，是否先盘点静态资源、fixture、expected 输出、roundtrip 语义和目标 API 输入形态
- [ ] 若执行 HAP 验证，是否根据当前库特征在 `fixture-driven HAP`、`复用上游测试/示例逻辑` 和 `最小真实 API smoke path` 之间做了明确选择，并说明理由
- [ ] 若存在可用 fixture/resource/roundtrip，是否优先使用 `rawfile`、`resfile` 或 sandbox copy 承载，而不是直接降级 smoke
- [ ] 若执行 HAP 验证，是否检查了 `*.so.*` 版本化 SONAME 文件和额外非系统运行时依赖，而不是只拷贝顶层 `.so`
- [ ] HAP 验证是否真实调用目标三方库 `.so`，而不是只跑模板默认 NAPI 示例
- [ ] 多库时是否遵守“先否后是、组内串行”的规则
- [ ] 需要审批的库是否统一写入 `审批结果`
- [ ] 遇到 STOP 后是否真正停止并等待用户继续
