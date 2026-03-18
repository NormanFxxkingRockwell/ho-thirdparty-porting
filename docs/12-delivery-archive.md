# Phase 6：交付与归档

目标：
- 汇总本轮产物、报告和关键修改
- 更新任务表状态
- 向用户交付最终结果

## 输入

- `outputs/<库名>/`
- `reports/<库名>-adaptation-report.md`
- `reports/<库名>-build-report.md`
- `libs/<库名>/`

## 输出

- 可交付的 `.so` 产物
- 最终交付说明
- 更新后的任务表状态

## AI 执行步骤

### 1. 整理交付物

至少确认：
- `.so` 产物位置
- 如有头文件，头文件位置
- 如有 `build.sh`，其位置
- 两份报告已存在

### 2. 更新任务表

建议更新这些字段：
- 状态：`已完成` 或 `失败`
- 备注：记录最终实际版本、主要问题、是否使用 fallback
- 可选新增列：
  - `业务适配报告`
  - `构建报告`
  - `产物路径`

### 3. 面向用户交付

必须提醒用户查看这两个文件：
- `reports/<库名>-adaptation-report.md`
- `reports/<库名>-build-report.md`

### 4. 归档结论

建议总结：
- 是否成功产出 `.so`
- 是否使用 `lycium`
- 是否进入 fallback
- 是否存在残留风险

## 建议交付信息

```text
已完成交付。
请重点查看：
1. reports/<库名>-adaptation-report.md
2. reports/<库名>-build-report.md

产物目录：
outputs/<库名>/
```

## 完成标准

- [ ] 产物已整理
- [ ] 两份报告已生成
- [ ] 任务表已更新状态
- [ ] 已向用户明确交付路径

