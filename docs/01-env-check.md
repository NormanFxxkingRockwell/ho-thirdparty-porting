# Phase 1-1：环境检查

本阶段只在 Phase 1 执行一次。

目标：
- 确认当前环境适合进行 HarmonyOS 三方库交叉编译
- 自动发现 HarmonyOS SDK 和 `lycium`
- 区分“基础交叉编译环境”与“lycium 额外前置”
- 输出基础设备连接状态

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

### 设备连接状态

这是设备侧测试的基础连接状态，不是编译门槛。

检查目标：
- `hdc` 是否可用
- 是否有已连接设备

说明：
- `harmonyos-dev-mcp` 作为设备测试主通道，由用户负责预先配置
- 流程仓库不承担 `mcp` 环境治理职责
- 设备测试执行阶段默认优先走 `harmonyos-dev-mcp`，失败再 fallback 到 `hdc`

## 检查项

### 1. Linux 或 WSL

必须通过。

### 2. HarmonyOS SDK 与交叉编译工具链

必须最终可定位。

关键文件：

```bash
$OHOS_SDK/native/llvm/bin/clang
$OHOS_SDK/native/llvm/bin/aarch64-linux-ohos-clang
$OHOS_SDK/native/build-tools/cmake/bin/cmake
$OHOS_SDK/native/build/cmake/ohos.toolchain.cmake
```

### 3. lycium 仓库

检查目标：
- `tpc_c_cplusplus/`
- `tpc_c_cplusplus/lycium/build.sh`
- `tpc_c_cplusplus/lycium/template/HPKBUILD`

### 4. lycium 额外前置

只在准备进入 `lycium` 路径前检查。

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

### 5. 基础设备连接状态

输出状态：
- `HDC_READY`
- `DEVICE_CONNECTED`
- `HDC_DEVICE_TEST_READY`
- `DEVICE_TEST_READY`

## 标准执行方式

基础环境检查：

```bash
bash scripts/check-env.sh --mode base
```

准备进入 `lycium` 前再执行：

```bash
bash scripts/check-env.sh --mode lycium
```

## AI 处理逻辑

### Linux / WSL 检查失败

- 立刻中断

### HarmonyOS SDK 自动发现失败

- 提示用户补充 `COMMAND_LINE_TOOLS_ROOT`

### lycium 缺失

优先尝试自动拉取，失败后提示用户手动准备。

### lycium 宿主机构建工具缺失

- 记录缺失命令列表
- 不阻塞 Phase 2 到 Phase 4
- 不阻塞 fallback 原生构建路径
- 只阻塞 `lycium` 路径

### 设备连接不完整

- 不阻塞适配和编译
- 只需如实汇报当前设备连接状态

## STOP 1 汇报建议

Phase 1 完成后，建议向用户汇报：
- `BASE_ENV_READY`
- `LYCIUM_ENV_READY`
- `HDC_READY`
- `DEVICE_CONNECTED`
- `HDC_DEVICE_TEST_READY`

并明确说明：
- 哪些状态会阻塞后续适配和编译
- 哪些状态只会影响后续 `device-pass`
- 设备测试阶段默认优先走 `harmonyos-dev-mcp`

## 通过标准

- [ ] 当前环境是 Linux 或 WSL
- [ ] `COMMAND_LINE_TOOLS_ROOT` 已确定
- [ ] `OHOS_SDK` 可由 `COMMAND_LINE_TOOLS_ROOT` 推导
- [ ] SDK 自带 `cmake` 存在
- [ ] `ohos.toolchain.cmake` 存在
- [ ] 默认架构使用 `arm64-v8a`
- [ ] `tpc_c_cplusplus/lycium/build.sh` 存在
