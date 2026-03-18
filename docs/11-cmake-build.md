# Phase 5-2：构建编译执行

说明：
- 本文件名保留为 `11-cmake-build.md`
- 内容表示 Phase 5 的通用构建执行流程

目标：
- 优先使用 `lycium`
- 失败后分类
- 合适时进入 fallback
- 允许边编译边修代码，直到产出 `.so`
- 尽量同时产出测试 binary
- 设备测试阶段默认优先调用 `harmonyos-dev-mcp`，失败再 fallback 到 `hdc`

## 输入

- `libs/<库名>/`
- 构建系统识别结果
- `reports/<库名>-adaptation-report.md`

## 输出

- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>-build-report.md`
- 必要时：`libs/<库名>/build.sh`
- 必要时：`libs/<库名>/test-driver/`

## 标准主路径

```text
lycium 优先
-> 失败分类
-> 适合则 fallback
-> 边编译边修
-> 产出 .so
-> 优先复用 test program
-> 必要时生成 minimal test driver
-> mcp 设备测试
-> 失败则 hdc fallback
```

## binary 生成策略

优先级固定如下：

1. 上游已有 test program / example / CLI
2. 上游已有可复用测试入口
3. 生成最小测试驱动

若没有现成入口，可执行：

```bash
bash scripts/init-test-driver.sh --lib-name <库名> --language c
```

或：

```bash
bash scripts/init-test-driver.sh --lib-name <库名> --language cpp
```

## 设备测试

设备测试主通道：
- `harmonyos-dev-mcp`

补充 fallback：
- `hdc`

要求：
- 真实推送到设备
- 真实执行
- 记录实际使用的是 `harmonyos-dev-mcp` 还是 `hdc fallback`
- 记录返回码和关键输出

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
- binary 来源类型是 `test program` 还是 `minimal test driver`
- 设备测试通道是 `harmonyos-dev-mcp` 还是 `hdc fallback`
- 执行命令
- 返回码
- 关键输出

## 完成标准

- [ ] 最终已生成 `.so`
- [ ] `.so` 架构为 `arm64-v8a / AArch64`
- [ ] `.so` 已放入 `outputs/<库名>/lib/`
- [ ] 若存在 binary，已放入 `outputs/<库名>/bin/`
- [ ] build report 中已明确 binary 来源类型
- [ ] build report 中已明确设备测试通道
- [ ] 未发现新的 `.rej` 文件
- [ ] 关键日志未出现未处理失败信号
