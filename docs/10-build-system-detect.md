# Phase 5-1：识别构建系统并制定编译路径

目标：
- 识别目标库的构建系统
- 确定本库进入 `lycium` 还是 fallback 的决策路径

注意：
- Phase 1 已完成环境检查
- Phase 5 不再单独做环境检查阶段
- 如执行中暴露环境缺失，应作为构建失败的一类原因记录

## 输入

- `libs/<库名>/`
- `reports/<库名>-adaptation-report.md`
- `reports/<库名>-adaptation-plan.md` 中的 Phase 5 最小交接摘要

## 输出

- 构建系统识别结果
- `lycium` 尝试方案
- fallback 触发条件

## 第一步：识别构建系统

优先按下列顺序识别：

1. `CMakeLists.txt` -> `cmake`
2. `configure` / `configure.ac` / `configure.in` -> `configure`
3. `Makefile` / `makefile` -> `make`
4. `BUILD.gn` / `.gn` -> `gn`
5. 其他 -> `unknown`

## 第二步：判断 `lycium` 起点

AI 必须先判断：

### 1. 是否已有现成 HPKBUILD

优先检查：
- `tpc_c_cplusplus/thirdparty/<库名>/HPKBUILD`
- `tpc_c_cplusplus/community/<库名>/HPKBUILD`

说明：
- 这里的 `<库名>` 不一定与 `libs/<库名>/` 完全同名
- 允许 AI 根据已有 recipe 名称、上游项目名、pkgname 做映射判断

### 2. 若无现成 HPKBUILD，是否适合新建

适合新建的典型条件：
- 构建系统明确
- 源码来源明确
- 依赖不复杂
- 目标为标准 `.so`

### 3. 若源码依赖极复杂或构建方式高度定制

- 可先尝试一次 `lycium`
- 但应提前标注 fallback 风险高

## 第三步：定义失败分类

`lycium` 失败后，不允许直接无脑 fallback，必须先分类：

### A. 环境缺失

例如：
- `OHOS_SDK` 不可用
- `lycium` 宿主机前置缺失
- `lycium` 目录损坏

处理：
- 记录为环境类失败
- 向用户报告
- 不直接进入 fallback

说明：
- 这里的“环境缺失”是指 `lycium` 执行前置缺失
- 不应倒推为整个仓库在 Phase 1 的统一失败

### B. HPKBUILD / recipe 问题

例如：
- `HPKBUILD` 字段不完整
- `source` 填写错误
- 依赖声明错误

处理：
- AI 优先修正 `HPKBUILD`
- 允许重试 `lycium`

说明：
- `lycium` 的核心输入是 recipe，不是 `libs/<库名>/` 里的源码目录

### C. 源码问题

例如：
- 平台宏导致编译失败
- HarmonyOS 头文件或接口不兼容
- 缺少必要 patch

处理：
- AI 做最小 patch
- 可视情况重试 `lycium`
- 或转入 fallback

### D. 构建系统 / 工具链问题

例如：
- 当前库需要高度定制的原生命令
- `lycium` 无法表达该构建逻辑

处理：
- 进入 fallback

## 第四步：fallback 触发条件

满足任一条件时进入 fallback：
- `lycium` 两轮内仍无法完成
- 失败明确属于构建系统 / 工具链能力不足
- 需要定制原生构建命令
- 使用 `build.sh` 的成本明显低于继续修 HPKBUILD

## fallback 产物

fallback 时，AI 应生成：

```text
libs/<库名>/build.sh
```

该脚本要求：
- 优先输出 `.so`
- 默认架构 `arm64-v8a`
- 路径从 [00-paths.md](./00-paths.md) 推导
- 不硬编码机器绝对路径

说明：
- fallback 才直接以 `libs/<库名>/` 为主目录进行编译

## 下一步

识别完成后进入 [11-cmake-build.md](./11-cmake-build.md)。
