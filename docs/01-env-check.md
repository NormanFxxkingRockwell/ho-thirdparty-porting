# Phase 1-1：环境检查

本阶段只在 Phase 1 执行一次。

目标：
- 确认当前环境适合进行 HarmonyOS 三方库交叉编译
- 自动发现 HarmonyOS SDK 和 `lycium`
- 区分“基础交叉编译环境”与“lycium 额外前置”
- 仅在自动发现失败时要求用户介入

## 检查分层

### base 检查

这是整个流程的基础门槛。

通过后表示：
- 可以继续进入 Phase 2 到 Phase 4
- 可以为 Phase 5 的 fallback 原生构建做准备

### lycium 检查

这是 `lycium` 路径的额外门槛，不应回写为整个仓库的统一硬前置。

通过后表示：
- Phase 5 可以优先尝试 `lycium`

未通过时：
- 不阻塞 Phase 2 到 Phase 4
- 不阻塞 Phase 5 的 fallback 原生构建
- 只阻塞 `lycium` 路径

## 检查项

### 1. Linux 或 WSL

必须通过。

检查方式：
- `uname -s`
- `/proc/version`

判定：
- Linux 原生环境：通过
- WSL：通过
- 非 Linux / 非 WSL：中断

### 2. HarmonyOS SDK 与交叉编译工具链

必须最终可定位。

检查目标：
- `COMMAND_LINE_TOOLS_ROOT`
- 推导出的 `OHOS_SDK`
- ARM64 交叉编译器存在
- SDK 自带 `cmake` 存在
- `ohos.toolchain.cmake` 存在

关键文件：

```bash
$OHOS_SDK/native/llvm/bin/clang
$OHOS_SDK/native/llvm/bin/aarch64-linux-ohos-clang
$OHOS_SDK/native/build-tools/cmake/bin/cmake
$OHOS_SDK/native/build/cmake/ohos.toolchain.cmake
```

说明：
- 这一层是 HarmonyOS 交叉编译主链路
- 官方 CMake 文档直接使用 SDK 自带 `cmake`
- 因此不能把宿主机 PATH 上是否已有 `cmake`，当成整个仓库 Phase 1 的统一硬门槛

### 3. lycium 仓库

检查目标：
- `tpc_c_cplusplus/`
- `tpc_c_cplusplus/lycium/build.sh`
- `tpc_c_cplusplus/lycium/template/HPKBUILD`
- `tpc_c_cplusplus/lycium/Buildtools/toolchain.tar.gz`

### 4. lycium 额外前置

这一组检查只在准备进入 `lycium` 路径前使用。

原因：
- HarmonyOS 原生 fallback 构建主要依赖 SDK 交叉编译工具链
- 但 `lycium` 当前实现还会额外检查宿主机命令

至少检查：
- `gcc`
- `g++`
- `cmake`
- `make`
- `pkg-config`
- `autoconf`
- `autoreconf`
- `automake`
- `patch`
- `unzip`
- `tar`
- `git`
- `ninja`
- `curl`
- `sha512sum`
- `wget`

说明：
- 这是 `lycium` 当前实现约束
- 不是所有 HarmonyOS 交叉编译路径的统一前置

## 标准执行方式

基础环境检查：

```bash
bash scripts/check-env.sh --mode base
```

准备进入 `lycium` 前再执行：

```bash
bash scripts/check-env.sh --mode lycium
```

脚本职责：
- 推导 `PORTING_ROOT`
- 自动搜索 `COMMAND_LINE_TOOLS_ROOT`
- 自动推导 `OHOS_SDK`
- 检查 SDK 自带 `cmake` 和 `ohos.toolchain.cmake`
- 检查 `tpc_c_cplusplus`
- 若缺失 `tpc_c_cplusplus`，尝试自动拉取
- 在 `--mode lycium` 下，额外检查 `lycium` 所需宿主机命令

## AI 处理逻辑

### Linux / WSL 检查失败

- 立即中断
- 提示用户切换到 Linux 或 WSL 环境

### HarmonyOS SDK 自动发现失败

- 提示用户补充 `COMMAND_LINE_TOOLS_ROOT`
- 然后更新 [00-paths.md](./00-paths.md)

### lycium 缺失

优先尝试：

```bash
git clone https://gitcode.com/openharmony-sig/tpc_c_cplusplus.git tpc_c_cplusplus
```

如果拉取失败：
- 中断
- 提示用户手动准备 `tpc_c_cplusplus/`

### lycium 宿主机构建工具缺失

- 记录缺失命令列表
- 不阻塞 Phase 2 到 Phase 4
- 不阻塞 fallback 原生构建路径
- 只阻塞 `lycium` 路径
- 明确告诉用户：当前是 `lycium` 运行前置不完整，不等于 HarmonyOS SDK 交叉编译链缺失

## 通过标准

- [ ] 当前环境是 Linux 或 WSL
- [ ] `COMMAND_LINE_TOOLS_ROOT` 已确定
- [ ] `OHOS_SDK` 可由 `COMMAND_LINE_TOOLS_ROOT` 推导
- [ ] SDK 自带 `cmake` 存在
- [ ] `ohos.toolchain.cmake` 存在
- [ ] 默认架构使用 `arm64-v8a`
- [ ] `tpc_c_cplusplus/lycium/build.sh` 存在

补充状态：
- `base` 通过：允许继续到 Phase 2
- `lycium` 通过：允许在 Phase 5 优先尝试 `lycium`

## 结果输出

建议向用户明确反馈：
- 当前是否在 Linux/WSL
- HarmonyOS SDK 最终路径
- 基础交叉编译环境是否就绪
- `lycium` 是否就绪
- 如果是自动发现或自动拉取成功，要明确说明

## 下一步

环境通过后，进入 [02-prepare-tasks.md](./02-prepare-tasks.md)。
