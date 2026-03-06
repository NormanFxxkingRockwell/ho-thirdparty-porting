# ⚠️ 重要提示：给 AI 执行者的工作指南

**本文档是给 AI 执行的，不是给人阅读的！**

## 🚨 TODO 管理原则（AI 必须严格遵守）

**这是 AI 执行工作流的最重要原则，必须严格遵守！**

### ⭐ TODO 创建规则（核心原则）

```
❌ 错误做法：一次性创建所有 Phase 的 TODO
✅ 正确做法：只创建当前 Phase 的 TODO，完成后清空，等待用户确认

Phase 1 开始 → 创建 Phase 1 的 TODO → 完成 → 清空 TODO → 🛑 STOP
     ↓ 用户说"填好了"
Phase 2-3 开始 → 创建 Phase 2-3 的 TODO → 完成 → 清空 TODO → 🛑 STOP
     ↓ 用户说"批准方案"
Phase 4-5 开始 → 创建 Phase 4-5 的 TODO → 完成 → 清空 TODO → 🛑 STOP
     ↓ 用户确认
Phase 6 开始 → 创建 Phase 6 的 TODO → 完成
```

### 为什么这样做？

| 问题 | 错误做法 | 正确做法 |
|------|----------|----------|
| **TODO CONTINUATION 误触发** | 所有 TODO 都存在，系统会强制继续 | 下一个 Phase 的 TODO 根本不存在 |
| **AI 理解成本** | 需要记住复杂的 STOP 规则 | 自然理解"完成当前任务再说" |
| **实现难度** | 需要修改系统机制 | 只需改变 TODO 创建时机 |

### TODO 管理口诀

> **"一批一清，确认再建"**
> 
> - **一批**：只创建当前 Phase 的 TODO
> - **一清**：Phase 完成后清空 TODO
> - **确认再建**：用户确认后才创建下一批

### AI 执行者注意

**如果你在阅读本文档时准备开始工作：**

1. **不要一次性创建所有 TODO** - 这是最常见的错误
2. **只创建当前 Phase 的 TODO** - 例如 Phase 1 开始时只创建 Phase 1 的 3 个 TODO
3. **完成后立即清空 TODO** - 使用 `todowrite([])`
4. **然后 STOP** - 等待用户确认，不要继续
5. **用户确认后** - 才创建下一批 TODO

**示例**：

```typescript
// ✅ 正确：Phase 1 开始时
todowrite([
  { id: 1, content: "Phase 1-1: 路径配置" },
  { id: 2, content: "Phase 1-2: 环境检查" },
  { id: 3, content: "Phase 1-3: 生成任务模板" },
])

// Phase 1 完成后
todowrite([])  // 清空 TODO
// 🛑 STOP - 等待用户说"填好了"

// 用户说"填好了"后，才创建 Phase 2-3 的 TODO
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  // ...
])
```

---
# HarmonyOS 三方库移植

**定位**：AI 可执行的第三方 C/C++ 库鸿蒙化编译工作流

---

## ⭐ 核心原则：TODO 管理

**这是 AI 执行工作流的最重要原则，必须严格遵守！**

### TODO 创建规则

```
❌ 错误做法：一次性创建所有 Phase 的 TODO
✅ 正确做法：只创建当前 Phase 的 TODO，完成后清空，等待用户确认

Phase 1 开始 → 创建 Phase 1 的 TODO → 完成 → 清空 TODO → 🛑 STOP
     ↓ 用户说"填好了"
Phase 2-3 开始 → 创建 Phase 2-3 的 TODO → 完成 → 清空 TODO → 🛑 STOP
     ↓ 用户说"批准方案"
Phase 4-5 开始 → 创建 Phase 4-5 的 TODO → 完成 → 清空 TODO → 🛑 STOP
     ↓ 用户确认
Phase 6 开始 → 创建 Phase 6 的 TODO → 完成
```

### 为什么这样做？

| 问题 | 错误做法 | 正确做法 |
|------|----------|----------|
| **TODO CONTINUATION 误触发** | 所有 TODO 都存在，系统会强制继续 | 下一个 Phase 的 TODO 根本不存在 |
| **AI 理解成本** | 需要记住复杂的 STOP 规则 | 自然理解"完成当前任务再说" |
| **实现难度** | 需要修改系统机制 | 只需改变 TODO 创建时机 |

### TODO 管理口诀

> **"一批一清，确认再建"**
> 
> - **一批**：只创建当前 Phase 的 TODO
> - **一清**：Phase 完成后清空 TODO
> - **确认再建**：用户确认后才创建下一批

---

## 完整工作流程（6 个 Phase，3 个决策点）

### Phase 1: 前期准备（3 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 1-1 | [00-paths.md](./00-paths.md) | Phase 1-1: 路径配置 |
| 1-2 | [01-env-check.md](./01-env-check.md) | Phase 1-2: 环境检查 |
| 1-3 | [02-prepare-tasks.md](./02-prepare-tasks.md) | Phase 1-3: 生成任务模板 |

**TODO 管理**：
```typescript
// Phase 1 开始时创建
todowrite([
  { id: 1, content: "Phase 1-1: 路径配置" },
  { id: 2, content: "Phase 1-2: 环境检查" },
  { id: 3, content: "Phase 1-3: 生成任务模板" },
])

// Phase 1 完成后清空
todowrite([])

// 发送消息并 STOP
"✅ Phase 1 完成！模板已生成在 `libs/porting-tasks-2026-03-05.xlsx`
请填写后告诉我'填好了'，我将继续 Phase 2-3"
```

> 🛑 **STOP - 等待用户决策 1**：等待用户说"填好了"

---

### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
### Phase 2-3: 代码获取 + 分析方案（4 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 2-1 | [03-read-tasks.md](./03-read-tasks.md) | Phase 2-1: 读取 Excel |
| 2-2 | [04-clone-code.md](./04-clone-code.md) | Phase 2-2: 克隆代码 |
| 2-3 | [05-verify-code.md](./05-verify-code.md) | Phase 2-3: 验证版本 |
| 3 | [06-code-analysis.md](./06-code-analysis.md) | Phase 3: 代码分析与适配方案 |

**TODO 管理**：
```typescript
// 用户说"填好了"后创建
todowrite([
  { id: 1, content: "Phase 2-1: 读取 Excel" },
  { id: 2, content: "Phase 2-2: 克隆代码" },
  { id: 3, content: "Phase 2-3: 验证版本" },
  { id: 4, content: "Phase 3: 代码分析与适配方案" },
])
```
// Phase 2-3 完成后清空
todowrite([])

// 发送消息并 STOP
"✅ 适配方案已生成！请审核 `reports/<库名>-adaptation-plan.md`
如无异议请回复'批准方案'，我将继续 Phase 4-5"
```

> 🛑 **STOP - 等待用户决策 2**：等待用户说"批准方案"

---

### Phase 4-5: 适配实施 + 构建编译（5 个子任务）✅

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 4-1 | [08-adaptation-implement.md](./08-adaptation-implement.md) | Phase 4-1: 适配实施 |
| 4-2 | [09-adaptation-report.md](./09-adaptation-report.md) | Phase 4-2: 生成适配报告 |
| 5-1 | [10-build-system-detect.md](./10-build-system-detect.md) | Phase 5-1: 构建系统识别 |
| 5-2 | [11-cmake-build.md](./11-cmake-build.md) | Phase 5-2: CMake 编译 |

**TODO 管理**：
```typescript
// 用户说"批准方案"后创建
todowrite([
  { id: 1, content: "Phase 4-1: 适配实施" },
  { id: 2, content: "Phase 4-2: 生成适配报告" },
  { id: 3, content: "Phase 5-1: 构建系统识别" },
  { id: 4, content: "Phase 5-2: CMake 编译" },
])

// Phase 4-5 完成后清空
todowrite([])

// 发送消息并 STOP
"✅ 编译完成！产物在 `outputs/<库名>/`
请确认结果后回复'继续 Phase 6'，我将进行交付归档"
```

> 🛑 **STOP - 等待用户决策 3**：等待用户确认

---

### Phase 6: 交付与归档（1 个子任务，待完善）

| 步骤 | 文档 | TODO 内容 |
|------|------|----------|
| 6-1 | [12-delivery-archive.md](./12-delivery-archive.md) | Phase 6: 交付与归档 |

**TODO 管理**：
```typescript
// 用户确认后创建
todowrite([
  { id: 1, content: "Phase 6: 交付与归档" },
])

// 完成后清空
todowrite([])

// 完成消息
"✅ 全部完成！产物已交付，项目已归档"
```

---

## 用户决策点总结

| 决策点 | Phase 过渡 | 用户需要做什么 | TODO 管理 |
|--------|------------|----------------|----------|
| **决策 1** | Phase 1 → Phase 2-3 | 填写 Excel 表格，确认"填好了" | 清空 Phase 1 TODO，创建 Phase 2-3 TODO |
| **决策 2** | Phase 2-3 → Phase 4-5 | 审核批准适配方案 | 清空 Phase 2-3 TODO，创建 Phase 4-5 TODO |
| **决策 3** | Phase 4-5 → Phase 6 | 确认编译结果，决定交付方式 | 清空 Phase 4-5 TODO，创建 Phase 6 TODO |

---

## 快速索引

- **Phase 1 准备** → [00-paths.md](./00-paths.md) → [01-env-check.md](./01-env-check.md) → [02-prepare-tasks.md](./02-prepare-tasks.md)
- **Phase 2-3 获取 + 分析** → [03-read-tasks.md](./03-read-tasks.md) → [04-clone-code.md](./04-clone-code.md) → [05-verify-code.md](./05-verify-code.md) → [06-code-analysis.md](./06-code-analysis.md)
- **Phase 4-5 实施 + 编译** → [08-adaptation-implement.md](./08-adaptation-implement.md) → [09-adaptation-report.md](./09-adaptation-report.md) → [10-build-system-detect.md](./10-build-system-detect.md) → [11-cmake-build.md](./11-cmake-build.md)
- **Phase 6 交付** → [12-delivery-archive.md](./12-delivery-archive.md)

---

## AI 执行检查清单

在开始每个 Phase 前，确认：

- [ ] 上一 Phase 的 TODO 已清空
- [ ] 用户已确认（决策点后）
- [ ] 只创建当前 Phase 的 TODO，不预先创建后续 Phase
- [ ] TODO 内容清晰明确（包含 Phase 编号和任务描述）

在每个 Phase 完成后，确认：

- [ ] 所有 TODO 已标记为 completed
- [ ] 清空 TODO 列表
- [ ] 发送完成消息
- [ ] 如果是决策点后，明确告知用户下一步操作

---

*最后更新：2026-03-05*
