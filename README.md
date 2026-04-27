# ho-thirdparty-porting

HarmonyOS 第三方库鸿蒙化编译工具。

详细工作流程见 `docs/README.md`。

## 目录

| 目录 | 说明 |
|------|------|
| docs/ | 操作指南 |
| libs/ | 库源码 |
| outputs/ | 编译产物 |
| reports/ | 编译报告 |
| dashboard/ | 本地看板前端 |
| templates/ | HAP 设备验证模板 |
| signTools/ | HAP 外部签名资源 |

## 本地看板

可以启动一个本地实时看板，持续观察最新任务表和历史批次状态：

```bash
python3 scripts/run-dashboard.py
```

默认地址：

```text
http://127.0.0.1:8765
```

看板会：
- 汇总所有正式任务表中的库状态
- 同时展示历史批次汇总
- 未完成库和最近更新库优先靠前展示
- 每 5 秒自动刷新
- 根据 `libs/`、`outputs/`、`reports/` 和任务表状态识别“已完成 / 进行中 / 已编译未测试 / 失败 / 异常”

## 给 AI 的执行提示词

建议在让 AI 开始工作前，先把下面这段提示词发给它：

```text
你现在在一个 HarmonyOS 三方库移植流程仓库中工作，不是业务应用代码仓库。你的唯一行为准则是严格遵循仓库 docs/README.md 定义的流程，不允许自行发散、跳步、改流程、并行推进多个库，或用你自己的习惯替代文档。

强制规则：
1. 先完整阅读 docs/README.md，再按其中引用的 phase 文档执行。
2. 必须严格按 Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 执行。
3. 必须严格执行 STOP：
   - Phase 1 完成后必须停止，等待用户继续。
   - 只有“需要用户审批方案”的库，Phase 3 完成后才进入 STOP 2。
4. 多库场景必须严格串行：
   - 绝不允许并行处理多个库。
   - 绝不允许并行写任务表、批次报告、lycium 共享目录与共享缓存。
   - 即使你有子 agent，子 agent 也只能做只读分析、检索、校验，不能并行推进多个库主流程。
5. Phase 5 必须坚持 lycium-first：
   - lycium 是主构建流程。
   - 先做 recipe 预检查，再做预修正，再执行 lycium。
   - 发现同库或近似库现成 recipe 后，优先复制、升级、修正。
   - 不允许仅因版本不一致、依赖不一致、包名不一致、SHA512SUM 不一致、builddir 不一致、配置项没开对，就直接 fallback。
   - 只有在证明 lycium 不可行后，才允许进入 fallback。
6. fallback 也不能直接开编：
   - 必须先做原生构建方案预检查和预修正，再执行 build.sh。
7. 测试规则必须严格：
   - 优先使用上游自带、可独立运行的测试入口，不要把目录名写死成 tests/。
   - 这类入口可能位于 test/、tests/、testing/、example/、examples/、sample/、samples/、tools/、programs/ 或其他自定义目录；判断标准是能否独立编译、独立运行、适合设备侧验证，而不是目录名。
   - 若没有合适的测试入口，再使用上游 CLI 做真实能力校验。
   - CLI 不能只跑 --version / -V，必须覆盖至少一条真实功能路径。
   - 若最终改用 CLI，必须在报告中明确说明为什么上游自带测试入口不适合设备侧验证。
   - 若既没有合适的测试入口也没有可用 CLI，明确记录“无测试用例”。
8. HAP 高可信设备验证是 device-pass 之上的增强验证：
   - 现有 binary 设备测试仍然必须先完成，HAP 不替代 device-pass。
   - HAP 验证前必须检查 Phase 1 输出的 HAP_ENV_READY 及其缺失项。
   - 当流程进入 HAP 验证时，必须先从 templates/soTest-template.zip 重新解压临时工程。
   - HAP 验证路径必须按库选择：有小型静态资源、fixture、expected 输出或 roundtrip 语义时，优先做 fixture-driven HAP；能低成本封装进 NAPI 的上游测试/示例逻辑其次复用；只有没有可用资源/expected/roundtrip 或资源无法稳定打包时，才降级为“最小但真实”的 API smoke path。
   - 资源目录不是降级 smoke 的理由；应优先使用 rawfile、resfile 或 sandbox copy 把资源交给 NAPI/native，并在 UI 或日志中输出用例数、通过数、失败数和资源来源。
   - HAP 准备阶段不能只拷贝顶层 .so；如果存在 `.so.*` 版本化 SONAME 文件或额外非系统运行时依赖，必须一并打包并核对 NEEDED。
   - WSL 场景下不要要求把 DevEco/ohpm/hvigor/签名安装到 WSL；这些通常在 Windows 侧，应按 HAP_OHPM_HOST / HAP_HVIGOR_HOST 指示选择 Windows/PowerShell/DevEco 执行路径。
   - 如果 Phase 1 输出 `HAP_SIGNING_MODE=external-signTools`，允许使用 signTools/hapsigner.zip 对 unsigned HAP 做外部签名，不要误判成“HAP 不可执行”。
   - 外部签名优先使用 scripts/sign-hap-with-sign-tools.sh；如果出现 signAlg 缺失、参数不成对等错误，先按参数引用/当前目录/profile 匹配问题排查，不能直接归类为 Java 环境问题。
   - 如果 profile 模板未变且已有 ohos_provision_debug.p7b，可以先尝试直接 sign-app 验证签名链路。
   - 如果在 WSL 中调用 Windows hdc.exe，file send 应使用 Windows / UNC 本地路径和显式远端文件名，不要依赖相对路径发送。
   - 必须通过 ArkTS -> NAPI -> 三方库 .so 的真实调用链验证，UI 或日志中必须能看到可审计结果。
   - 不允许只跑模板默认 add 示例，不允许只启动 HAP，不允许只检查 .so 文件存在。
   - 如果 DevEco/Hvigor/ohpm/签名/设备条件不足，必须记录 skip 或 fail，不允许伪造 HAP 通过。
   - HAP 验证失败或跳过时，不能反向否定已完成的 build-pass / binary-pass / device-pass，但必须记录 hap-device-pass 的结论和原因。
9. 只在文档允许的范围内修改：
   - 不要因为临时方便就发明新流程。
   - 不要跳过文档中的检查、预修正、失败分类、报告更新。
10. 输出和记录必须符合仓库规则：
   - 源码在 libs/<库名>/
   - 产物在 outputs/<库名>/{lib,bin}/
   - 报告在 reports/<库名>/
   - 多库批次报告在 reports/batch-YYYY-MM-DD.md
   - HAP 临时工程在 tmp/hap-test/<库名>/soTest/
   - HAP patch 和验证资料在 reports/<库名>/hap-device/
   - HAP 外部签名包在 signTools/hapsigner.zip
11. 如果你发现当前执行意图与 docs/README.md 冲突，优先服从 docs/README.md，并明确指出冲突点，而不是自己绕过去。

执行方式：
- 每进入一个 phase，都先说明“当前处于哪个 phase、依据哪份文档执行”。
- 每做一次关键决策，都说明依据的是哪条文档规则。
- 不要使用“我觉得更方便”“我先试试”这类脱离流程的行为。
- 除非文档明确允许，否则不要自行补充额外自动化、额外脚本、额外测试路线。

现在先从 docs/README.md 开始读取，并只按当前仓库文档行事。
```
