# Phase 1-1：环境检查

本阶段只在 Phase 1 执行一次。

目标：
- 确认当前环境适合进行 HarmonyOS 三方库交叉编译
- 自动发现 HarmonyOS SDK 和 `lycium`
- 区分“基础交叉编译环境”与“lycium 额外前置”
- 输出基础设备连接状态
- 输出 HAP 验证模板状态

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

### HAP 验证状态

这是 `device-pass` 之上的增强验证条件，不是编译门槛。

检查目标：
- `templates/soTest-template.zip` 是否存在
- 后续是否可在 `tmp/hap-test/<库名>/` 解压临时工程
- DevEco Studio 是否可发现
- `ohpm` 是否可用
- `hvigor` / `hvigorw` 是否可用
- `java` 是否可用
- 模板工程是否已包含签名配置
- `signTools/hapsigner.zip` 是否存在且包含外部签名所需文件
- 设备是否满足 HAP 安装与启动验证的基础连接条件

说明：
- HAP 构建依赖 DevEco/Hvigor/签名等本机环境，这些环境不作为 Phase 1 的硬阻塞项。
- 在 WSL 场景下，DevEco Studio、`ohpm`、`hvigor`、签名配置通常位于 Windows 侧，不应要求安装到 WSL。
- Phase 1 脚本只负责从 WSL 探测 Windows 侧可见状态，例如 `/mnt/c`、`/mnt/d`、`powershell.exe Get-Command` 和显式环境变量。
- `HAP_SIGNING_READY=true` 可以来自两条正式路径：
  - 模板工程自带 `build-profile.json5` 签名配置
  - 仓库内 `signTools/hapsigner.zip` 外部签名包，加上可调用的 `java`
- `HAP_SIGNING_MODE` 用于区分当前应走 `project-config` 还是 `external-signTools`。
- 如果 HAP 环境不可用，后续 HAP 验证可记录为 `skip`，但不影响 `.so` 编译和原有 binary 设备测试。
- `HAP_ENV_READY=false` 只说明 Phase 5-3 可能无法自动完成，不代表 Phase 1 基础环境失败。

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
- `HAP_TEMPLATE_READY`
- `HAP_PROJECT_CONFIG_READY`
- `HAP_DEVECO_READY`
- `HAP_WINDOWS_BRIDGE_READY`
- `HAP_OHPM_READY`
- `HAP_OHPM_HOST`
- `HAP_HVIGOR_READY`
- `HAP_HVIGOR_HOST`
- `HAP_JAVA_READY`
- `HAP_JAVA_HOST`
- `HAP_SIGNTOOLS_READY`
- `HAP_PROJECT_SIGNING_READY`
- `HAP_SIGNING_MODE`
- `HAP_AUTOMATED_BUILD_READY`
- `HAP_SIGNING_READY`
- `HAP_DEVICE_READY`
- `HAP_ENV_READY`

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
- `HAP_TEMPLATE_READY`
- `HAP_DEVECO_READY`
- `HAP_WINDOWS_BRIDGE_READY`
- `HAP_OHPM_READY`
- `HAP_HVIGOR_READY`
- `HAP_JAVA_READY`
- `HAP_SIGNTOOLS_READY`
- `HAP_SIGNING_MODE`
- `HAP_SIGNING_READY`
- `HAP_ENV_READY`

并明确说明：
- 哪些状态会阻塞后续适配和编译
- 哪些状态只会影响后续 `device-pass`
- 哪些状态只会影响后续 `hap-device-pass`
- 如果 `HAP_OHPM_HOST` 或 `HAP_HVIGOR_HOST` 为 `windows`，后续 HAP 构建命令应通过 Windows/PowerShell/DevEco 路径执行，而不是在 WSL 中直接调用
- 如果 `HAP_SIGNING_MODE=external-signTools`，后续应明确走 `signTools/hapsigner.zip` 外部签名链，而不是要求模板工程自带 signingConfigs
- 设备测试阶段默认优先走 `harmonyos-dev-mcp`

## 通过标准

- [ ] 当前环境是 Linux 或 WSL
- [ ] `COMMAND_LINE_TOOLS_ROOT` 已确定
- [ ] `OHOS_SDK` 可由 `COMMAND_LINE_TOOLS_ROOT` 推导
- [ ] SDK 自带 `cmake` 存在
- [ ] `ohos.toolchain.cmake` 存在
- [ ] 默认架构使用 `arm64-v8a`
- [ ] `tpc_c_cplusplus/lycium/build.sh` 存在
- [ ] 已输出 `HAP_TEMPLATE_READY`
- [ ] 已输出 `HAP_ENV_READY`
