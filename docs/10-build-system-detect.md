# Phase 5-1：识别构建系统并制定编译路径

目标：
- 识别目标库的构建系统
- 先完成 `lycium` 的 recipe 预检查与预修正
- 若需要 fallback，再先完成原生构建方案预检查与预修正
- 确定本库进入 `lycium` 还是 fallback 的决策路径

注意：
- Phase 1 已完成环境检查
- Phase 5 不再单独做环境检查阶段
- 如执行中暴露环境缺失，应作为构建失败的一类原因记录

## 输入

- `libs/<库名>/`
- `reports/<库名>/adaptation-report.md`
- `reports/<库名>/adaptation-plan.md` 中的 Phase 5 最小交接摘要

## 输出

- 构建系统识别结果
- `lycium` recipe 预检查结果
- `lycium` 预修正项
- fallback 触发条件
- fallback 构建方案预检查结果
- fallback 预修正项

## 第一步：识别构建系统

优先按下列顺序识别：

1. `CMakeLists.txt` -> `cmake`
2. `configure` / `configure.ac` / `configure.in` -> `configure`
3. `Makefile` / `makefile` -> `make`
4. `BUILD.gn` / `.gn` -> `gn`
5. 其他 -> `unknown`

## 第二步：判断 `lycium` 起点并做 recipe 预检查

AI 必须先判断：

### 1. 是否已有现成 HPKBUILD

优先检查：
- `tpc_c_cplusplus/thirdparty/<库名>/HPKBUILD`
- `tpc_c_cplusplus/community/<库名>/HPKBUILD`

说明：
- 这里的 `<库名>` 不一定与 `libs/<库名>/` 完全同名
- 允许 AI 根据已有 recipe 名称、上游项目名、pkgname 做映射判断
- 只要找到了同库或近似库的现成 recipe，就应优先把它视为升级与修正的起点，而不是直接放弃 `lycium`

### 2. 若有现成 HPKBUILD，必须先做 recipe 预检查

进入实际 `lycium` 构建前，至少检查：
- `HPKBUILD` 版本是否匹配当前任务目标版本
- `SHA512SUM` 是否与当前下载包一致
- `packagename`、下载包名、`builddir` 是否一致
- 上游是否存在可复用的 `test program`
- 若无合适 `test program`，是否存在可复用的 `CLI`
- recipe 是否把这些目标关掉
- recipe 是否缺少 install binary 或 binary 收集逻辑

硬规则：
- 如果上游本来有可复用 binary，但 recipe 只是把相关选项关掉，优先修 recipe 配置项
- 不允许仅因为当前 recipe 默认关闭 tests/examples/binary 就直接进入 fallback
- 不允许仅因为现成 recipe 的版本、依赖、包名或 `builddir` 与目标任务不一致，就直接进入 fallback
- 对同库或近似库的现成 recipe，应优先执行复制、升级、依赖修正和开关修正

### 3. 若无现成 HPKBUILD，是否适合新建

适合新建的典型条件：
- 构建系统明确
- 源码来源明确
- 依赖不复杂
- 目标为标准 `.so`

### 4. 若源码依赖极复杂或构建方式高度定制

- 可先尝试一次 `lycium`
- 但应提前标注 fallback 风险高

## 第三步：执行前的 recipe 预修正

如果预检查发现问题，优先在执行前修正，例如：
- 补齐或升级 `HPKBUILD`
- 修正 `SHA512SUM`
- 修正 `packagename`、下载包名、`builddir`
- 打开上游已有 binary 目标需要的构建选项
- 补齐 binary install 或后续收集路径

只有完成预修正后，才进入实际 `lycium` 执行。

## 第四步：定义失败分类

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

## 第五步：fallback 触发条件

满足任一条件时进入 fallback：
- `lycium` 两轮内仍无法完成
- 失败明确属于构建系统 / 工具链能力不足
- 需要定制原生构建命令
- 使用 `build.sh` 的成本明显低于继续修 HPKBUILD

说明：
- 如果问题只是 recipe 配置项、install 逻辑或 binary 收集逻辑不完整，不应直接触发 fallback
- 如果问题只是旧 recipe 与当前目标版本、依赖或包名不一致，也不应直接触发 fallback，应先完成一轮合理的 recipe 升级与修正

## 第六步：fallback 预检查与预修正

进入 fallback 前，不允许直接写 `build.sh` 开始编，必须先完成原生构建方案预检查：
- 上游真实构建系统是什么
- 是否存在共享库开关
- 是否存在可执行测试入口
- 测试程序是否依赖额外资源文件
- 哪些 feature 应关闭，哪些 binary 应保留
- install 路径和收集路径如何设计

若发现问题，优先先修正构建参数、开关和收集路径，再生成 `build.sh`。

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
