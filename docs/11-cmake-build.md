# Phase 5-2：构建编译执行

说明：
- 本文件名保留为 `11-cmake-build.md`
- 内容表示 Phase 5 的通用构建执行流程

目标：
- 优先使用 `lycium`
- `lycium` 是主构建流程，只有在证明不可行时才允许 fallback
- `lycium` 先预检查、预修正，再执行
- 合适时进入 fallback
- fallback 也先预检查、预修正，再执行
- 允许边编译边修代码，直到产出 `.so`
- 尽量同时产出测试 binary
- 设备测试阶段默认优先调用 `harmonyos-dev-mcp`，失败再 fallback 到 `hdc`

## 输入

- `libs/<库名>/`
- 构建系统识别结果
- `reports/<库名>/adaptation-report.md`

## 输出

- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>/build-report.md`
- 必要时：`libs/<库名>/build.sh`

## 标准主路径

```text
lycium 优先
-> recipe 预检查
-> recipe 预修正
-> 清理当前库旧构建状态
-> 执行 lycium
-> 失败分类
-> fallback 预检查
-> fallback 预修正
-> 执行 fallback
-> 边编译边修
-> 产出 .so
-> install 产物中的上游 test program
-> build 目录里的上游 test program
-> 上游 CLI 能力校验
-> 若无现成测试入口则记录“无测试用例”
-> mcp 设备测试
-> 失败则 hdc fallback
```

## lycium 执行前的固定检查

进入 `lycium` 前至少检查：
- `HPKBUILD`
- `SHA512SUM`
- `packagename`
- 实际下载包名
- `builddir`
- 上游是否存在可复用的 `test program`
- 若无合适 `test program`，是否存在可复用的 `CLI`
- recipe 是否把 tests/examples/binary 关闭
- recipe 是否具备 install binary 或后续收集逻辑

要求：
- `SHA512SUM` 中记录的包名必须与 `packagename` 一致
- 下载链接最终包名必须与 `packagename` 一致
- `builddir` 不能为空

硬规则：
- 如果上游存在可复用 binary，而 recipe 只是默认关闭相关构建选项，优先修 recipe 配置项
- 不允许仅因为当前 recipe 默认没带出 binary 就直接进入 fallback
- 不允许仅因为现成 recipe 的版本、依赖、包名、`SHA512SUM` 或 `builddir` 与目标不一致就直接进入 fallback
- 发现同库或近似库的现成 recipe 后，优先复制、升级、依赖修正和开关修正，再执行 `lycium`

## lycium 执行前的固定预修正

预检查发现问题后，优先在执行前修正：
- 修正 `HPKBUILD`
- 修正 `SHA512SUM`
- 修正 `packagename`、下载包名、`builddir`
- 基于旧 recipe 升级到目标版本
- 基于当前版本修正依赖关系
- 打开上游 binary 目标相关构建选项
- 补齐 binary install 或收集逻辑

只有完成预修正后，才进入实际 `lycium` 构建。

## lycium 执行前的固定清理

每次当前库开始构建前，都要把“历史构建状态”和“本轮构建状态”切开：
- 清掉 `lycium/usr/hpk_build.csv` 中当前库的历史记录
- 清掉 `lycium/usr/<pkgname>/` 下当前库旧产物
- 必要时清掉 recipe 目录下当前库旧的 `builddir`

说明：
- 这样做是为了避免 `lycium` 误以为“之前编过 = 这次也算编过”
- 本轮构建结束后，再以当前真实产物作为唯一依据

## 中量级库的额外检查

对 `libxml2`、`curl`、`freetype`、`harfbuzz` 这一档库，进入 `lycium` 前要先做一轮 recipe 漂移检查：
- 现成 `HPKBUILD` 的版本是否落后于当前任务目标版本
- 现成依赖是否已经过时，或仅对旧版本有效
- 现成功能开关是否会把 binary 入口关掉
- 现成下载源是否仍然可访问

如果发现 recipe 漂移明显：
- 先做最小升级，再尝试 `lycium`
- 不要直接因为“仓库里有 HPKBUILD”就盲目开编

## fallback 执行前的固定检查与预修正

进入 fallback 前，不允许直接生成 `build.sh` 开始尝试，必须先检查：
- 上游真实构建系统与共享库开关
- 上游是否存在 test program
- 若无合适 test program，是否存在 CLI
- 测试程序是否依赖资源文件
- 需要关闭哪些 feature，保留哪些 binary
- install 路径、binary 收集路径和设备测试路径

预检查后优先修正：
- 原生构建参数
- feature 开关
- binary 收集路径
- 必要的最小 install/拷贝逻辑

只有完成这些预修正后，才执行 fallback 构建。

## binary 收集规则

binary 收集优先级固定如下：

1. install 产物中的上游 test program
2. 构建目录里的上游 test program
3. 上游 CLI

说明：
- 如果 install 产物中没有 binary，但构建目录里已经生成上游 test program，不应直接判定 `binary-pass` 失败
- 应优先从构建目录回收该 binary 到 `outputs/<库名>/bin/`
- 如果 test program 不适合设备侧运行，但上游存在 CLI，则应优先使用 CLI 做真实能力校验，不能只跑 `--version` / `-V`
- CLI 能力校验必须至少覆盖一条真实功能路径，例如压缩/解压回环、解析/转换、输入输出处理等
- 如果上游没有现成 test program 或 CLI，则不再生成最小测试驱动，直接在报告中记录“无测试用例”

## 设备测试

设备测试主通道：
- `harmonyos-dev-mcp`

补充 fallback：
- `hdc`

要求：
- 真实推送到设备
- 真实执行
- 记录实际使用的是 `harmonyos-dev-mcp` 还是 `hdc fallback`
- 记录设备侧执行结果

设备侧结果记录规则：
- 优先记录明确的数字返回码
- 如果执行环境只能给出布尔结果或成功/失败标记，也允许记录
- 同时必须记录关键输出，避免只写一个 `True` 或 `False`
- 如果命令无报错且关键输出符合预期，可判定 device-pass 成功

典型 `hdc` fallback 动作：

```bash
hdc file send outputs/<库名>/bin/<binary> /data/local/tmp/<库名>/
hdc shell chmod +x /data/local/tmp/<库名>/<binary>
hdc shell /data/local/tmp/<库名>/<binary> [args...]
```

## 构建报告要求

构建报告必须明确记录：
- `build-pass`
- `binary-pass`
- `device-pass`
- binary 来源类型是 `test program` / `CLI`，或明确记录“无测试用例”
- binary 是来自 install 目录还是构建目录
- 设备测试通道是 `harmonyos-dev-mcp` 还是 `hdc fallback`
- 执行命令
- 设备侧执行结果
- 关键输出

## 完成标准

- [ ] 最终已生成 `.so`
- [ ] `.so` 架构为 `arm64-v8a / AArch64`
- [ ] `.so` 已放入 `outputs/<库名>/lib/`
- [ ] 若存在 binary，已放入 `outputs/<库名>/bin/`
- [ ] build report 中已明确 binary 来源类型
- [ ] build report 中已明确 binary 收集来源
- [ ] 若无现成测试入口，build report 中已明确记录“无测试用例”
- [ ] build report 中已明确设备测试通道
- [ ] 结论以 `arm64-v8a` 产物为准，其他架构仅作附带结果
- [ ] 未发现新的 `.rej` 文件
- [ ] 关键日志未出现未处理失败信号
