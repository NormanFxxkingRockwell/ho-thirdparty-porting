# Phase 3-1: 代码分析

**定位**：AI 在克隆代码后、适配前的分析阶段工作指南

**输入**：
- 已克隆的库源码（`libs/<库名>/`）
- 任务表格信息（库名、仓库、版本）

**输出**：
- 代码分析报告（`reports/<库名>-analysis.md`）
- 修改点清单（用于后续适配阶段）
- 库类型分类（日志/网络/加密/其他）

---

## AI 工作流程

```
1. 目录结构扫描 → 2. 库类型识别 → 3. 文档检索 → 
4. 修改点扫描 → 5. 构建系统识别 → 6. 生成分析报告
```

---

## 步骤 1: 目录结构扫描

**目的**：快速了解项目的组织结构和规模

**执行命令**：
```bash
# 进入库目录
cd libs/<库名>/

# 统计代码规模
find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | wc -l
# 输出：源代码文件总数

# 查看目录结构（深度 3 层）
tree -L 3 -I '.git|tests|docs|examples'

# 识别关键目录
ls -la | grep -E 'include|src|lib|core'
```

**分析要点**：
- 是否有 `include/` 目录？（公共头文件）
- 是否有 `src/` 目录？（实现代码）
- 是否有 `tests/` 目录？（测试代码，适配时可跳过）
- 是否有 `examples/` 目录？（示例代码，适配后可参考）

**记录到报告**：
```markdown
## 1. 项目结构

| 项目 | 值 |
|------|-----|
| 源代码文件数 | N |
| 头文件数 | N |
| 主要目录 | include/, src/, ... |
| 测试目录 | 有/无 |
| 示例目录 | 有/无 |
```

---

## 步骤 2: 库类型识别

**目的**：识别库的功能类型，用于后续文档检索策略

**识别方法**：

### 2.1 通过 README/文档识别

```bash
# 读取 README 前 50 行
head -50 README.md
head -50 README.txt

# 查找描述性关键词
grep -i "logging\|log" README.md      # 日志库
grep -i "network\|http\|socket" README.md  # 网络库
grep -i "crypto\|encrypt\|ssl\|tls" README.md  # 加密库
grep -i "json\|xml\|parse" README.md  # 解析库
grep -i "thread\|async\|event" README.md  # 并发库
```

### 2.2 通过代码特征识别

**日志库特征**：
```bash
# 搜索日志相关函数
grep -r "printf\|fprintf\|syslog\|OutputDebugString" src/ | head -10
```

**网络库特征**：
```bash
# 搜索网络相关 API
grep -r "socket\|connect\|send\|recv\|bind\|listen" src/ | head -10
```

**加密库特征**：
```bash
# 搜索加密相关函数
grep -r "AES\|RSA\|SHA\|MD5\|encrypt\|decrypt" src/ | head -10
```

**解析库特征**：
```bash
# 搜索解析相关函数
grep -r "parse\|serialize\|json\|xml\|yaml" src/ | head -10
```

**并发库特征**：
```bash
# 搜索线程相关 API
grep -r "pthread_create\|thread\|mutex\|lock\|unlock" src/ | head -10
```

### 2.3 库类型分类

根据识别结果，将库分类为：

| 类型 | 关键词 | 适配重点 |
|------|--------|----------|
| **日志库** | logging, printf, syslog | 输出目标适配（HiLog） |
| **网络库** | socket, http, tcp | 网络 API 适配（HarmonyOS 网络栈） |
| **加密库** | crypto, ssl, aes | 加密 API 适配（Huks） |
| **解析库** | json, xml, parse | 通常无需适配（纯计算） |
| **并发库** | thread, mutex, async | 线程 API 适配（PThreads 兼容） |
| **通用库** | 无明确特征 | 按需适配 |

**记录到报告**：
```markdown
## 2. 库类型识别

**类型**：日志库 / 网络库 / 加密库 / 解析库 / 并发库 / 通用库

**识别依据**：
- README 关键词：xxx
- 代码特征：xxx
- 主要功能：xxx
```

---

## 步骤 3: HarmonyOS 文档检索

**目的**：根据库类型，检索 HarmonyOS 对应的官方 API 文档

**执行策略**：

### 3.1 调用 docs_index MCP

根据库类型，检索对应的 HarmonyOS API：

**日志库**：
```
查询："HiLog NDK API 使用方法"
查询："HarmonyOS 日志系统 NDK"
查询："hilog/log.h API 参考"
```

**网络库**：
```
查询："HarmonyOS NDK 网络 API socket"
查询："HarmonyOS NDK HTTP 客户端"
```

**加密库**：
```
查询："Huks NDK API 使用方法"
查询："HarmonyOS 加密库 NDK"
```

**线程/并发**：
```
查询："HarmonyOS PThreads 兼容性"
查询："HarmonyOS NDK 线程 API"
```

### 3.2 检索结果整理

对每个检索结果，记录：

1. **API 名称**（如 `HiLog::Info()`）
2. **头文件**（如 `hilog/log.h`）
3. **编译依赖**（如 `hiviewdfx:libhilog`）
4. **使用示例**（代码片段）
5. **注意事项**（如隐私标识要求）

**记录到报告**：
```markdown
## 3. HarmonyOS API 检索

### 3.1 主要 API

| API | 用途 | 头文件 | 编译依赖 |
|-----|------|--------|----------|
| HiLog::Info() | INFO 级别日志 | hilog/log.h | hiviewdfx:libhilog |
| HiLog::Error() | ERROR 级别日志 | hilog/log.h | hiviewdfx:libhilog |

### 3.2 使用示例

```cpp
#include "hilog/log.h"

static constexpr OHOS::HiviewDFX::HiLogLabel LABEL = {
    LOG_CORE, 0xD003200, "MYLIB"
};

HiLog::Info(LABEL, "Info message: %{public}s", data);
```
```

---

## 步骤 4: 修改点扫描

**目的**：识别代码中需要适配的平台相关代码

**核心原则**：**不硬编码具体检测模式，使用通用扫描策略**

### 4.1 平台检测宏扫描

**扫描工具**：使用 `ripgrep (rg)` 或 `grep`

**扫描模式**：
```bash
# 平台检测宏
rg "#ifdef (WIN32|_WIN32|_MSC_VER|__BORLANDC__|__linux__|__APPLE__|__ANDROID__)" --type-add 'cpp:*.{c,cpp,h,hpp}' --type cpp

# 条件编译块
rg "#if defined\(" --type cpp

# 排除鸿蒙宏（已适配的）
rg "#ifdef __OHOS__" --type cpp
```

**记录每个检测点**：
- 文件路径
- 行号
- 宏名称
- 所属平台（Windows/Linux/macOS）

### 4.2 系统 API 调用扫描

**分类扫描**：

**Windows API**：
```bash
# Windows 特有 API
rg "(CreateFile|ReadFile|WriteFile|OutputDebugString|Win32|_win32)" --type cpp
```

**POSIX API**（HarmonyOS 兼容）：
```bash
# POSIX 线程
rg "pthread_(create|mutex|cond)" --type cpp

# POSIX 文件 I/O
rg "(open|read|write|close|opendir|readdir)" --type cpp

# POSIX 日志
rg "syslog\(" --type cpp
```

**标准库**（通常无需适配）：
```bash
# C++ 标准库
rg "std::(thread|mutex|lock|filesystem)" --type cpp
```

### 4.3 构建配置文件扫描

**扫描目标**：识别构建系统的平台相关配置

**CMakeLists.txt**：
```bash
# Windows 特定配置
rg "WIN32|_WIN32|MSVC" CMakeLists.txt

# 平台相关编译选项
rg "if\(.*WIN|if\(.*LINUX|if\(.*APPLE" CMakeLists.txt
```

**Makefile**：
```bash
# 平台检测
rg "uname|WIN32|_WIN32|MSYS" Makefile
```

### 4.4 修改点分类

对每个识别的修改点，分类为：

| 类别 | 说明 | 适配策略 |
|------|------|----------|
| **A 类** | HarmonyOS 有原生 API | 替换为 HarmonyOS API |
| **B 类** | POSIX 兼容 API | 保留，使用默认分支 |
| **C 类** | Windows 特有，无替代 | 排除编译（`#ifndef __OHOS__`） |
| **D 类** | 功能未知，需调研 | 标记为风险，单独处理 |

**记录到报告**：
```markdown
## 4. 修改点识别

### 4.1 平台检测宏

| 文件 | 行号 | 宏 | 平台 | 适配策略 |
|------|------|-----|------|----------|
| include/config.h | 15 | _WIN32 | Windows | 添加 __OHOS__ 分支 |

### 4.2 系统 API

| 文件 | 行号 | API | 类型 | 适配策略 |
|------|------|-----|------|----------|
| src/logger.cpp | 42 | syslog() | POSIX | 替换为 HiLog |
| src/file.cpp | 78 | CreateFile() | Windows | 排除编译 |

### 4.3 构建配置

| 文件 | 行号 | 配置 | 适配策略 |
|------|------|------|----------|
| CMakeLists.txt | 25 | if(WIN32) | 添加 elseif(__OHOS__) |
```

---

## 步骤 5: 构建系统识别

**目的**：识别项目使用的构建系统，为 Phase 4 编译做准备

**识别算法**（按优先级）：

### 5.1 检测流程

```
1. 检查 CMakeLists.txt → CMake 构建系统
2. 检查 configure.ac + Makefile.am → Autotools
3. 检查 Makefile → GNU Make
4. 检查 BUILD.gn → GN 构建系统
5. 其他 → 需要人工介入
```

### 5.2 检测命令

```bash
# 1. CMake 检测
if [ -f "CMakeLists.txt" ]; then
    echo "Build System: CMake"
    # 检查是否有 cmake/ 子目录
    if [ -d "cmake" ]; then
        echo "  - Has cmake/ subdirectory"
    fi
fi

# 2. Autotools 检测
if [ -f "configure.ac" ] || [ -f "configure.in" ]; then
    echo "Build System: Autotools"
    # 检查是否有 configure 脚本
    if [ -f "configure" ]; then
        echo "  - configure script exists"
    fi
fi

# 3. Makefile 检测
if [ -f "Makefile" ] || [ -f "makefile" ]; then
    echo "Build System: Makefile"
fi

# 4. GN 检测
if [ -f "BUILD.gn" ]; then
    echo "Build System: GN"
fi
```

### 5.3 构建系统特征

| 构建系统 | 检测文件 | 配置文件 | 编译命令 |
|----------|----------|----------|----------|
| **CMake** | CMakeLists.txt | CMakeLists.txt | `cmake --build .` |
| **Autotools** | configure.ac | configure | `make` |
| **Makefile** | Makefile | Makefile | `make` |
| **GN** | BUILD.gn | args.gn | `ninja -C out/` |

**记录到报告**：
```markdown
## 5. 构建系统识别

**类型**：CMake / Autotools / Makefile / GN

**检测文件**：
- CMakeLists.txt（存在/不存在）
- configure.ac（存在/不存在）
- Makefile（存在/不存在）
- BUILD.gn（存在/不存在）

**编译命令**：`<对应编译命令>`

**特殊配置**：
- 有/无 cmake/ 子目录
- 有/无 pkg-config 依赖
- 有/无外部依赖查找
```

---

## 步骤 6: 生成分析报告

**报告模板**：

```markdown
# <库名> 代码分析报告

**生成时间**：YYYY-MM-DD HH:MM
**库版本**：vX.Y.Z
**仓库**：https://github.com/xxx/xxx

---

## 1. 项目结构

| 项目 | 值 |
|------|-----|
| 源代码文件数 | N |
| 头文件数 | N |
| 主要目录 | include/, src/, ... |
| 测试目录 | 有/无 |
| 示例目录 | 有/无 |

---

## 2. 库类型识别

**类型**：日志库

**识别依据**：
- README 关键词："logging library", "log4cpp"
- 代码特征：大量 printf/syslog 调用
- 主要功能：C++ 日志框架，支持多级别日志、多输出目标

---

## 3. HarmonyOS API 检索

### 3.1 主要 API

| API | 用途 | 头文件 | 编译依赖 |
|-----|------|--------|----------|
| HiLog::Debug() | DEBUG 级别日志 | hilog/log.h | hiviewdfx:libhilog |
| HiLog::Info() | INFO 级别日志 | hilog/log.h | hiviewdfx:libhilog |
| HiLog::Warn() | WARN 级别日志 | hilog/log.h | hiviewdfx:libhilog |
| HiLog::Error() | ERROR 级别日志 | hilog/log.h | hiviewdfx:libhilog |
| HiLog::Fatal() | FATAL 级别日志 | hilog/log.h | hiviewdfx:libhilog |

### 3.2 使用示例

```cpp
#include "hilog/log.h"

static constexpr OHOS::HiviewDFX::HiLogLabel LABEL = {
    LOG_CORE,
    0xD003200,  // Domain: 第三方库范围
    "MYLIB"
};

HiLog::Info(LABEL, "Message: %{public}s", data);
```

**注意事项**：
- 使用 `%{public}s` 而非 `%{private}s`（日志内容非敏感）
- Domain 使用 `0xD003200` 范围（第三方库专用）
- Tag 长度不超过 31 字节，仅使用 ASCII 字符

---

## 4. 修改点识别

### 4.1 平台检测宏

| # | 文件 | 行号 | 宏 | 平台 | 适配策略 |
|---|------|------|-----|------|----------|
| 1 | include/config.h | 15 | _WIN32 | Windows | 添加 __OHOS__ 分支 |
| 2 | src/logger.cpp | 23 | __linux__ | Linux | 保留，走默认分支 |

### 4.2 系统 API

| # | 文件 | 行号 | API | 类型 | 适配策略 |
|---|------|------|-----|------|----------|
| 1 | src/logger.cpp | 42 | syslog() | POSIX | 替换为 HiLog（A 类） |
| 2 | src/file.cpp | 78 | CreateFile() | Windows | 排除编译（C 类） |
| 3 | src/thread.cpp | 15 | pthread_create() | POSIX | 保留（B 类） |

### 4.3 构建配置

| # | 文件 | 行号 | 配置 | 适配策略 |
|---|------|------|------|----------|
| 1 | CMakeLists.txt | 25 | if(WIN32) | 添加 elseif(__OHOS__) |
| 2 | CMakeLists.txt | 40 | find_package(Threads) | 保留，HarmonyOS 兼容 |

### 4.4 修改点汇总

| 类别 | 数量 | 说明 |
|------|------|------|
| **A 类**（HarmonyOS API 替换） | N | 使用 HiLog 等原生 API |
| **B 类**（POSIX 兼容） | N | 无需修改，使用默认分支 |
| **C 类**（排除编译） | N | Windows 特有功能 |
| **D 类**（需调研） | N | 功能未知 |

---

## 5. 构建系统识别

**类型**：CMake

**检测文件**：
- CMakeLists.txt：✅ 存在
- configure.ac：❌ 不存在
- Makefile：❌ 不存在
- BUILD.gn：❌ 不存在

**编译命令**：`cmake --build .`

**特殊配置**：
- 有 cmake/ 子目录：是
- 有 pkg-config 依赖：否
- 有外部依赖查找：是（find_package(Threads)）

---

## 6. 适配建议

### 6.1 优先级排序

| 优先级 | 修改点 | 预计工作量 |
|--------|--------|------------|
| **P0** | syslog() → HiLog | 高 |
| **P1** | 添加 __OHOS__ 平台检测 | 中 |
| **P2** | 排除 Windows 特有功能 | 低 |

### 6.2 风险提示

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|----------|
| HiLog API 不兼容 | 低 | 高 | 已检索官方文档确认 |
| PThreads 兼容性 | 低 | 高 | HarmonyOS 完全兼容 POSIX |

---

## 7. 下一步

1. 进入 **Phase 3-2: 鸿蒙化适配**（`docs/07-adaptation.md`）
2. 根据修改点清单逐个实施适配
3. 生成适配报告（`docs/08-adaptation-report.md`）
```

---

## AI 执行检查清单

在生成报告前，确认已完成：

- [ ] 目录结构扫描完成
- [ ] 库类型识别完成
- [ ] HarmonyOS API 检索完成（调用 docs_index MCP）
- [ ] 平台检测宏扫描完成
- [ ] 系统 API 扫描完成
- [ ] 构建配置文件扫描完成
- [ ] 修改点分类完成
- [ ] 构建系统识别完成
- [ ] 分析报告生成到 `reports/<库名>-analysis.md`

---

## 下一步

代码分析完成后 → **Phase 3-2: 鸿蒙化适配**（`docs/07-adaptation.md`）
