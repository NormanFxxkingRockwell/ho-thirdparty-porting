# Phase 6：交付与归档

目标：
- 汇总本轮 `.so`、binary、报告和关键修改
- 更新任务表状态
- 更新批次汇总报告
- 向用户交付最终结果

## 输入

- `outputs/<库名>/lib/`
- `outputs/<库名>/bin/`
- `reports/<库名>/adaptation-report.md`
- `reports/<库名>/build-report.md`
- `reports/batch-YYYY-MM-DD.md`
- `libs/<库名>/`

## 输出

- 可交付的 `.so` 产物
- 若存在则交付测试 binary
- 最终交付说明
- 更新后的任务表状态
- 更新后的批次汇总报告

## 面向用户交付时必须明确

- `.so` 是否已完成
- binary 是否已完成
- 设备测试是否已完成
- binary 来源是“上游自带、可独立运行的测试入口” / `CLI`，或明确记录“无测试用例”
- 若最终使用 CLI，必须说明为什么上游自带测试入口不适合设备侧验证
- 设备测试通道是 `harmonyos-dev-mcp` 还是 `hdc fallback`

## 多库模式下的额外要求

- 每个库完成后，都要回写任务表：
  - `适配状态`
  - `编译状态`
  - `测试状态`
  - `失败原因/备注`
- 同时更新 `reports/batch-YYYY-MM-DD.md`
- 单个库失败不阻塞整个批次，但必须明确失败阶段和原因

推荐执行：

```bash
bash scripts/update-batch-status.sh --lib-name <库名> --adaptation-status pass --build-status pass --test-status pass --note "..."
```

## 完成标准

- [ ] `.so` 产物已整理
- [ ] binary 产物状态已明确
- [ ] 两份库级报告已生成
- [ ] 任务表已更新状态
- [ ] 批次汇总报告已更新
- [ ] 已向用户明确交付路径
- [ ] 已汇总 `build-pass` / `binary-pass` / `device-pass`
