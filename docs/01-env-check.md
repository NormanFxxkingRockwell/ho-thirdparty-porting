# Phase 1-2：环境检查

本阶段只在 Phase 1 执行一次。

目标：
- 确认当前环境适合进行 HarmonyOS 三方库编译
- 自动发现 HarmonyOS SDK 和 `lycium`
- 仅在自动发现失败时要求用户介入

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

### 2. HarmonyOS SDK

必须最终可定位。

检查目标：
- `COMMAND_LINE_TOOLS_ROOT`
- 推导出的 `OHOS_SDK`
- 编译器存在

关键文件：

```bash
$OHOS_SDK/native/llvm/bin/clang
$OHOS_SDK/native/llvm/bin/aarch64-linux-ohos-clang
```

### 3. lycium 仓库

检查目标：
- `tpc_c_cplusplus/`
- `tpc_c_cplusplus/lycium/build.sh`
- `tpc_c_cplusplus/lycium/template/HPKBUILD`

## 标准执行方式

优先执行：

```bash
scripts/check-env.sh
```

脚本职责：
- 推导 `PORTING_ROOT`
- 自动搜索 `COMMAND_LINE_TOOLS_ROOT`
- 自动推导 `OHOS_SDK`
- 检查 `tpc_c_cplusplus`
- 若缺失 `tpc_c_cplusplus`，尝试自动拉取

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

## 通过标准

- [ ] 当前环境是 Linux 或 WSL
- [ ] `COMMAND_LINE_TOOLS_ROOT` 已确定
- [ ] `OHOS_SDK` 可由 `COMMAND_LINE_TOOLS_ROOT` 推导
- [ ] 默认架构使用 `arm64-v8a`
- [ ] `tpc_c_cplusplus/lycium/build.sh` 存在

## 结果输出

建议向用户明确反馈：
- 当前是否在 Linux/WSL
- HarmonyOS SDK 最终路径
- `lycium` 是否已就绪
- 如果是自动发现或自动拉取成功，要明确说明

## 下一步

环境通过后，进入 [02-prepare-tasks.md](./02-prepare-tasks.md)。

