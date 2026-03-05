# Phase 3-2: 生成适配方案（Phase 3 续）

**定位**：AI 根据代码分析结果，生成**详细的修改指令**

**前置条件**：
- 代码分析已完成（`reports/<库名>-analysis.md`）
- 用户尚未审核方案

**输入**：
- 代码分析报告
- 修改点清单
- HarmonyOS API 检索结果（docs_index）

**输出**：
- `reports/<库名>-adaptation-plan.md` - 适配方案（AI 执行指南 + 用户审核）

**关键原则**：
- ✅ 方案非常详细（文件 + 行号 + 操作类型 + 内容）
- ✅ 包含联动关系（修改组格式）
- ✅ 操作类型标准化（REPLACE_API, ADD_PLATFORM_CHECK 等）
- ✅ docs_index 查询结果必须准确（优先直接检索文档）
- ⭐ 用户必须明确批准后才能实施

---

## AI 工作流程

```
读取分析报告 → 识别修改点 → 查询 docs_index → 
生成修改指令 → 整理修改组 → 生成方案文档 → 提交用户审核
```

---

## 步骤 1: 读取分析报告

**执行命令**：

```bash
# 读取代码分析报告
cat reports/<库名>-analysis.md
```

**提取关键信息**：

1. **修改点清单**（文件路径、行号、修改类型）
2. **平台依赖**（Windows API / POSIX API / 标准库）
3. **联动关系**（哪些修改点互相关联）

---

## 步骤 2: 识别修改点并分类

**按操作类型分类**：

### 类型 1: REPLACE_PLATFORM_CHECK（替换平台检测）

**指令格式**：
```markdown
### 修改目的：添加 HarmonyOS 平台检测
### 文件：include/config.h
**行号**: 15-18
**操作**: REPLACE_PLATFORM_CHECK
**修改前**:
```cpp
#if defined(_MSC_VER)
    #define PLATFORM_WINDOWS 1
#endif
```
**修改后**:
```cpp
#if defined(__OHOS__)
    #define PLATFORM_OHOS 1
    #define LOG4CPP_USE_PTHREADS 1
#elif defined(_MSC_VER)
    #define PLATFORM_WINDOWS 1
#endif
```
```

---

### 类型 2: REPLACE_API（替换 API 调用）⭐ docs_index 使用

**查询 docs_index 流程**：

1. **理解原 API 功能**
2. **参考已实现平台的代码**
3. **查询 docs_index 获取 HarmonyOS 实现**（优先直接检索文档）
4. **生成修改指令**

**指令格式**：
```markdown
### 修改目的：替换 syslog 为 HiLog
### 文件：src/logger.cpp
**行号**: 42
**操作**: REPLACE_API
**原 API**: syslog()
**新 API**: HiLog::Info()
**修改前**:
```cpp
::syslog(priority, "%s", message);
```
**修改后**:
```cpp
#ifdef __OHOS__
    #include "hilog/log.h"
    static constexpr OHOS::HiviewDFX::HiLogLabel LABEL = {
        LOG_CORE, 0xD003200, "LOG4CPP"
    };
    switch (priority) {
        case LOG_DEBUG:   HiLog::Debug(LABEL, "%{public}s", message); break;
        case LOG_INFO:    HiLog::Info(LABEL, "%{public}s", message); break;
        case LOG_WARNING: HiLog::Warn(LABEL, "%{public}s", message); break;
        case LOG_ERR:     HiLog::Error(LABEL, "%{public}s", message); break;
        default:          HiLog::Info(LABEL, "%{public}s", message);
    }
#else
    ::syslog(priority, "%s", message);
#endif
```
**docs_index 来源**: 
- 查询："HiLog NDK API 使用方法"
- 文档：hilog/log.h API 参考
```

---

### 类型 3-6: 其他操作类型

| 操作类型 | 说明 | 示例 |
|----------|------|------|
| **ADD_INCLUDE** | 添加头文件 | `#include "hilog/log.h"` |
| **EXCLUDE_FILE** | 排除文件编译 | CMakeLists.txt 中排除 Windows 文件 |
| **ADD_CMAKE_CONFIG** | 添加 CMake 配置 | `target_link_libraries(xxx libhilog_ndk.z.so)` |
| **ADD_METHOD** | 新增方法 | 封装 HiLog 调用的工具方法 |

---

## 步骤 3: 整理联动关系（修改组格式）

**修改组格式**：

```markdown
## 修改组 1: HiLog 集成

**核心修改**: utils/Logger.cpp
- 新增 logMessage() 方法

**联动修改**:
- src/app.cpp 第 50 行：调用 logMessage()
- src/service.cpp 第 120 行：调用 logMessage()

**实施顺序**:
1. 先修改 utils/Logger.cpp（新增方法）
2. 再修改 src/app.cpp（调用方法）
3. 再修改 src/service.cpp（调用方法）
```

---

## 步骤 4: 生成方案文档

**完整模板结构**：

```markdown
# <库名> 鸿蒙化适配方案（待审核）

## 1. 适配概述
## 2. 修改指令清单
   - 修改组 1: HiLog 集成
   - 修改组 2: 平台检测宏适配
   - 修改组 3: 构建配置
## 3. 修改汇总
## 4. 实施顺序
## 5. 风险评估
## 6. 用户审核
```

---

## docs_index 使用规范

**严格按照 docs_index/README.md 指导行事**

### 查询流程

1. **理解原 API 功能**
2. **参考已实现平台的代码**
3. **查询 docs_index 获取 HarmonyOS 实现**（优先直接检索文档）
4. **验证查询结果**
5. **生成修改指令**

---

## AI 执行检查清单

在提交用户审核前，确认已完成：

- [ ] 所有修改点已识别并分类
- [ ] 每个修改点都有详细指令（文件 + 行号 + 操作 + 内容）
- [ ] 联动关系已整理（修改组格式）
- [ ] docs_index 查询已执行（优先直接检索文档）
- [ ] 实施顺序已安排
- [ ] 风险评估已完成
- [ ] 方案文档已生成
- [ ] 用户审核提示已发送

---

## 失败处理

**如果用户拒绝方案**：
1. 读取用户评论
2. 分析拒绝原因
3. 调整修改指令
4. 重新生成方案
5. 重新提交审核

**如果实施时发现方案错误**：
1. 停止实施
2. 分析错误原因
3. 重新生成方案
4. 重新提交审核

---

## 下一步

用户批准后 → **Phase 4: 适配实施与报告**（`docs/08-adaptation-implement.md`）

**TODO 管理**：清空 Phase 3 TODO，创建 Phase 4-5 的 TODO
