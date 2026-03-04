# HarmonyOS 三方库移植

**定位**：AI 可执行的第三方 C/C++ 库鸿蒙化编译工作流

---

## 完整工作流程（5 个阶段，11 个文档）

### Phase 1: 前期准备（3 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 1-1 | [00-paths.md](./00-paths.md) | 路径配置 |
| 1-2 | [01-env-check.md](./01-env-check.md) | 环境检查 |
| 1-3 | [02-prepare-tasks.md](./02-prepare-tasks.md) | 任务准备 |

---

### Phase 2: 代码获取（3 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | 拉取代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | 验证版本 |

---

### Phase 3: 鸿蒙化适配（4 个文档）✅

| 步骤 | 文档 | 说明 |
|------|------|------|
| 3-1 | [06-analyze-code.md](./06-analyze-code.md) | 代码分析 |
| 3-2 | [07-adaptation-plan.md](./07-adaptation-plan.md) | 生成方案 |
| 3-3 | [08-adaptation-implement.md](./08-adaptation-implement.md) | 实施修改 |
| 3-4 | [09-adaptation-report.md](./09-adaptation-report.md) | 生成报告 |

---

### Phase 4: 构建与编译（2 个文档）⚠️

| 步骤 | 文档 | 说明 |
|------|------|------|
| 4-1 | [10-build-system-detect.md](./10-build-system-detect.md) | 构建系统识别 |
| 4-2 | [11-cmake-build.md](./11-cmake-build.md) | CMake 编译 |

---

### Phase 5: 交付与归档（0 个文档）❌

待编写

---

## 快速索引

- **Phase 1 准备** → [01-env-check.md](./01-env-check.md)
- **Phase 2 获取** → [05-verify-code.md](./05-verify-code.md)
- **Phase 3 适配** → [07-adaptation-plan.md](./07-adaptation-plan.md)
- **Phase 4 编译** → [11-cmake-build.md](./11-cmake-build.md)

---

*最后更新：2026-03-04*
