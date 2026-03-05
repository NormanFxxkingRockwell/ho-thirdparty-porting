# HarmonyOS 三方库移植

**定位**：AI 可执行的第三方 C/C++ 库鸿蒙化编译工作流

---

## 完整工作流程（6 个阶段，3 个用户决策点）

### Phase 1: 前期准备（3 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 1-1 | [00-paths.md](./00-paths.md) | 路径配置 |
| 1-2 | [01-env-check.md](./01-env-check.md) | 环境检查 |
| 1-3 | [02-prepare-tasks.md](./02-prepare-tasks.md) | 任务准备 |

> 🛑 **STOP - 等待用户决策 1**：请填写任务表格，完成后告知

---

### Phase 2: 代码获取（3 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | 拉取代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | 验证版本 |

> ✅ 自动继续（无需用户决策）

---

### Phase 3: 代码分析与适配方案（2 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 3-1 | [06-analyze-code.md](./06-analyze-code.md) | 代码分析 |
| 3-2 | [07-adaptation-plan.md](./07-adaptation-plan.md) | 生成方案 |

> 🛑 **STOP - 等待用户决策 2**：适配方案已生成，请审核批准

---

### Phase 4: 适配实施与报告（2 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 4-1 | [08-adaptation-implement.md](./08-adaptation-implement.md) | 实施修改 |
| 4-2 | [09-adaptation-report.md](./09-adaptation-report.md) | 生成报告 |

> ✅ 自动继续（无需用户决策）

---

### Phase 5: 构建与编译（2 个文档）⚠️

| 步骤 | 文档 | 说明 |
|------|------|------|
| 5-1 | [10-build-system-detect.md](./10-build-system-detect.md) | 构建系统识别 |
| 5-2 | [11-cmake-build.md](./11-cmake-build.md) | CMake 编译 |

> 🛑 **STOP - 等待用户决策 3**：编译完成，请确认结果

---

### Phase 6: 交付与归档（1 个文档，待完善）

待编写

---

## 快速索引

- **Phase 1 准备** → [01-env-check.md](./01-env-check.md)
- **Phase 2 获取** → [05-verify-code.md](./05-verify-code.md)
- **Phase 3 分析 + 方案** → [07-adaptation-plan.md](./07-adaptation-plan.md)
- **Phase 4 实施 + 报告** → [09-adaptation-report.md](./09-adaptation-report.md)
- **Phase 5 编译** → [11-cmake-build.md](./11-cmake-build.md)

---

## 用户决策点

| 决策点 | 位置 | 用户需要做什么 | 过渡 |
|--------|------|----------------|------|
| **决策 1** | Phase 1 完成 | 填写 Excel 表格，确认"填好了" | Phase 1 → Phase 2 |
| **决策 2** | Phase 3 完成 | 审核批准适配方案 | Phase 3 → Phase 4 |
| **决策 3** | Phase 5 完成 | 确认编译结果，决定交付方式 | Phase 5 → Phase 6 |

---

*最后更新：2026-03-05*
