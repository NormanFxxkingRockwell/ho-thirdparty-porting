# Phase 4: 适配实施与报告

## Phase 4-1: 适配实施

**定位**：AI **按用户批准的方案**实施代码修改

**前置条件**：
- 适配方案已生成（`reports/<库名>-adaptation-plan.md`）
- **用户已明确批准方案**（关键审核点）

**输入**：
- 用户批准的适配方案
- 已克隆的源码（`libs/<库名>/`）

**输出**：
- 修改后的源码
- 实施状态记录

**关键原则**：
- ✅ **严格按方案执行**，不修改方案外内容
- ✅ 使用条件编译隔离（`#ifdef __OHOS__`）
- ✅ 修改后验证语法
- ✅ 失败时重新生成方案（严格标准）

---

## AI 工作流程

```
用户批准 → 按方案逐条实施 → 验证语法 → 
失败处理 → 记录实施状态 → 生成简化报告
```

---

## 步骤 1: 确认用户批准

**检查适配方案状态**：

```bash
# 读取适配方案
cat reports/<库名>-adaptation-plan.md
```

**确认用户已批准**：
- ✅ 用户回复"批准"、"approved"、"可以"
- ✅ 用户在方案文档中签字确认
- ❌ 用户未回复 → 等待
- ❌ 用户要求修改 → 调整方案后重新审核

---

## 步骤 2: 按方案逐条实施

**按修改组顺序实施**：

### 实施流程

```markdown
For each 修改组 in 方案:
    For each 修改指令 in 修改组:
        1. 读取目标文件
        2. 定位修改行号
        3. 验证行号匹配（严格标准）
        4. 实施修改
        5. 验证语法
        6. 记录实施状态
```

---

### 类型 1: REPLACE_PLATFORM_CHECK

**实施流程**：

```bash
# 1. 读取目标文件
cat libs/<库名>/include/config.h

# 2. 定位修改行号
sed -n '15,18p' libs/<库名>/include/config.h

# 3. 验证行号匹配（严格标准）
# 如果行号不匹配 → 失败处理

# 4. 实施修改
# 按方案中的"修改后"内容替换

# 5. 验证语法
aarch64-unknown-linux-ohos-clang++ -fsyntax-only include/config.h
```

---

### 类型 2: REPLACE_API

**实施流程**：

```bash
# 1. 读取目标文件
cat libs/<库名>/src/logger.cpp

# 2. 定位修改行号
sed -n '40,45p' libs/<库名>/src/logger.cpp

# 3. 验证行号匹配（严格标准）
# 如果行号不匹配 → 失败处理

# 4. 实施修改
# 按方案中的"修改后"内容替换

# 5. 验证语法
aarch64-unknown-linux-ohos-clang++ -fsyntax-only src/logger.cpp

# 6. 验证 docs_index 查询的 API 正确
grep "hilog/log.h" src/logger.cpp
```

---

## 步骤 3: 验证所有修改

**执行验证清单**：

### 3.1 文件完整性检查

```bash
# 确认所有修改的文件都存在
cd libs/<库名>/
for file in include/config.h src/logger.cpp CMakeLists.txt; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
        exit 1
    fi
done
```

### 3.2 修改点验证

```bash
# 验证__OHOS__宏已添加
grep -n "__OHOS__" include/config.h

# 验证 HiLog 已包含
grep -n "hilog/log.h" src/logger.cpp

# 验证 Windows 文件已排除
grep -n "Win32Debug" CMakeLists.txt
```

### 3.3 语法验证

```bash
# C++ 语法检查
aarch64-unknown-linux-ohos-clang++ -fsyntax-only src/logger.cpp

# CMake 配置检查
cmake -S . -B build 2>&1 | head -20
```

---

## 步骤 4: 失败处理（严格标准）

**失败判定**：

- ❌ 行号不匹配（方案说 15-18 行，实际文件只有 12 行）
- ❌ 文件内容已变化（方案基于的代码与实际代码不一致）
- ❌ API 不存在（方案中的 HarmonyOS API 实际不存在）

**处理流程**：

```markdown
If 失败:
    1. 停止实施
    2. 分析失败原因
    3. 重新分析代码
    4. 重新查询 docs_index
    5. 重新生成方案
    6. 重新提交用户审核
```

---

## 步骤 5: 生成简化报告

**报告模板**：

```markdown
# <库名> 适配实施状态

**实施时间**：YYYY-MM-DD HH:MM  
**方案版本**：1.0  
**实施状态**：✅ 完成 / ❌ 失败

---

## 1. 实施汇总

| 修改组 | 修改数 | 成功数 | 失败数 |
|--------|--------|--------|--------|
| HiLog 集成 | 3 | 3 | 0 |
| 平台检测宏 | 1 | 1 | 0 |
| 构建配置 | 1 | 1 | 0 |
| **总计** | **5** | **5** | **0** |

---

## 2. 实施状态

### 修改 1.1: utils/Logger.cpp
- **状态**：✅ 完成
- **验证**：语法检查通过

### 修改 1.2: src/app.cpp
- **状态**：✅ 完成
- **验证**：语法检查通过

---

## 3. 遗留问题

| 问题 | 原因 | 状态 |
|------|------|------|
| （无） | - | - |

---

## 4. 下一步

实施完成 → Phase 4-1: 构建系统识别
```

---

## AI 执行检查清单

在报告实施完成前，确认已完成：

- [ ] 用户已批准适配方案
- [ ] 所有修改按方案执行
- [ ] 行号验证通过（严格标准）
- [ ] 语法验证通过
- [ ] 失败处理已执行（如有失败）
- [ ] 简化报告已生成

---

## 关键原则重申

### ✅ 必须遵守

1. **严格按方案执行** - 不修改方案外内容
2. **使用条件编译** - `#ifdef __OHOS__` 隔离
3. **验证语法** - 修改后检查编译
4. **失败重新生成方案** - 严格标准

### ❌ 严格禁止

1. **擅自修改** - 未经用户批准的修改
2. **破坏兼容性** - 影响其他平台的修改
3. **临时方案** - `as any`、`@ts-ignore` 等
4. **跳过验证** - 不验证语法就报告完成

---
## TODO 管理（重要！）

**Phase 4-5 连续执行原则**：

1. Phase 4-5 是**连续执行**的，中间不需要用户确认
2. 开始 Phase 4-5 前，确保已有用户批准的适配方案
3. Phase 4-5 完成后统一清空 TODO，然后 STOP

**TODO 创建示例**：

```typescript
// 用户说"批准方案"后创建 Phase 4-5 TODO
todowrite([
  { id: 1, content: "Phase 4-1: 适配实施" },
  { id: 2, content: "Phase 4-2: 生成适配报告" },
  { id: 3, content: "Phase 5-1: 构建系统识别" },
  { id: 4, content: "Phase 5-2: CMake 编译" },
])

// Phase 4-5 完成后清空
todowrite([])

// 🛑 STOP - 等待用户确认
```

> ⚠️ **AI 注意**：Phase 4-5 连续执行，但完成后必须 STOP 等待用户确认！

---


## 下一步

适配实施完成 → **Phase 4-1: 构建系统识别**（`docs/10-build-system-detect.md`）
