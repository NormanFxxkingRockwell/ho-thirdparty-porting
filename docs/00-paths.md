# 路径配置

本文件记录当前仓库在本机上的关键路径约定。

目标：
- 当前仓库可迁移到其他机器
- AI 和脚本优先通过仓库相对关系推导路径
- 只有无法自动推导时，才要求用户显式填写

## 必须理解的变量

### PORTING_ROOT

当前仓库根目录。

约定：
- 由当前仓库位置自动推导
- 不需要用户手填

示例：

```bash
export PORTING_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

### LYCIUM_ROOT

当前仓库内的 `tpc_c_cplusplus` 目录。

约定：

```bash
export LYCIUM_ROOT="$PORTING_ROOT/tpc_c_cplusplus"
```

说明：
- 当前仓库已通过 `.gitignore` 忽略 `tpc_c_cplusplus/`
- 如果目录不存在，AI 可尝试自动拉取

### COMMAND_LINE_TOOLS_ROOT

HarmonyOS Command Line Tools 根目录。

说明：
- 这是主变量
- 如果 AI 无法自动找到，则应要求用户提供

示例：

```bash
export COMMAND_LINE_TOOLS_ROOT="/path/to/command-line-tools"
```

### OHOS_SDK

供 `lycium` 使用的兼容变量。

约定：

```bash
export OHOS_SDK="$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony"
```

### OHOS_NDK_ROOT

供 fallback 原生构建使用的兼容变量。

约定：

```bash
export OHOS_NDK_ROOT="$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony/native"
```

## 推荐导出模板

```bash
export PORTING_ROOT="/absolute/path/to/ho-thirdparty-porting"
export LYCIUM_ROOT="$PORTING_ROOT/tpc_c_cplusplus"
export COMMAND_LINE_TOOLS_ROOT="/absolute/path/to/command-line-tools"
export OHOS_SDK="$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony"
export OHOS_NDK_ROOT="$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony/native"
export DEFAULT_OHOS_ARCH="arm64-v8a"
export DEFAULT_OUTPUT_KIND="shared"
```

## 自动推导优先级

### 1. `PORTING_ROOT`

- 当前仓库根目录

### 2. `LYCIUM_ROOT`

- `$PORTING_ROOT/tpc_c_cplusplus`

### 3. `COMMAND_LINE_TOOLS_ROOT`

优先搜索：
- 环境变量 `COMMAND_LINE_TOOLS_ROOT`
- `$PORTING_ROOT/../command-line-tools`
- `$HOME/command-line-tools`
- `/opt/command-line-tools`

### 4. `OHOS_SDK`

- 由 `COMMAND_LINE_TOOLS_ROOT` 推导
- 不单独手填，除非路径布局特殊

## AI 处理规则

- 不要在文档、脚本、报告中写死某台机器的个人路径
- 任何新增脚本都必须先推导 `PORTING_ROOT`
- 当 `COMMAND_LINE_TOOLS_ROOT` 自动发现失败时，再提示用户补充
- 当 `LYCIUM_ROOT` 缺失时，优先尝试自动拉取 `tpc_c_cplusplus`

## 校验命令

```bash
test -d "$PORTING_ROOT"
test -d "$LYCIUM_ROOT"
test -d "$COMMAND_LINE_TOOLS_ROOT"
test -d "$OHOS_SDK/native/llvm"
```

