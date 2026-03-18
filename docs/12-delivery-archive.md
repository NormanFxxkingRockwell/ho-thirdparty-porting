# Phase 6：交付与归档

目标：
- 汇总本轮 `.so`、binary、报告和关键修改
- 更新任务表状态
- 向用户交付最终结果

## 输入

- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>-adaptation-report.md`
- `reports/<库名>-build-report.md`
- `libs/<库名>/`

## 输出

- 可交付的 `.so` 产物
- 若存在则交付测试 binary
- 最终交付说明
- 更新后的任务表状态

## 面向用户交付时必须明确

- `.so` 是否已完成
- binary 是否已完成
- 设备测试是否已完成
- binary 来源是 `test program` 还是 `minimal test driver`
- 设备测试通道是 `harmonyos-dev-mcp` 还是 `hdc fallback`

## 完成标准

- [ ] `.so` 产物已整理
- [ ] binary 产物状态已明确
- [ ] 两份报告已生成
- [ ] 任务表已更新状态
- [ ] 已向用户明确交付路径
- [ ] 已汇总 `build-pass` / `binary-pass` / `device-pass`
