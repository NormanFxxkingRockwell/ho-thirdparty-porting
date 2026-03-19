# Phase 1-2：准备任务表

目标：
- 生成或确认任务模板
- 让用户填写待移植三方库信息
- 为多库批次执行准备任务表与批次汇总报告

## 输入

- 已完成环境检查

## 输出

- `libs/porting-tasks-YYYY-MM-DD.xlsx`
- `reports/batch-YYYY-MM-DD.md`

## AI 执行步骤

### 1. 检查 `libs/` 下是否已有当天正式任务表

命名规则：

```text
porting-tasks-YYYY-MM-DD.xlsx
```

### 2. 如无正式任务表则生成

推荐执行：

```bash
bash scripts/prepare-task-sheet.sh
```

说明：
- 该脚本会把 `libs/porting-tasks-模板.xlsx` 复制为当天正式任务表
- 同时初始化 `reports/batch-YYYY-MM-DD.md`
- `libs/porting-tasks-模板.xlsx` 只作为模板，不允许直接作为 Phase 2 输入

### 3. 模板字段

模板至少包含这些字段：

| 字段 | 必填 | 可选值/说明 |
|------|------|-------------|
| 库名 | 是 | 三方库名称 |
| Git 仓库 | 是 | 源码仓库地址 |
| 版本 | 否 | tag / branch / commit，可留空 |
| 是否需要用户审批方案 | 否 | `是/否`，不填默认 `是` |
| 审批结果 | 否 | `待审批/通过/不通过/不需要审批` |
| 适配状态 | 否 | `待处理/pass/fail/skip` |
| 编译状态 | 否 | `待处理/pass/fail/skip` |
| 测试状态 | 否 | `待处理/pass/fail/skip` |
| 失败原因/备注 | 否 | 特殊依赖、失败原因、编译说明等 |

### 4. 提示用户填写

提示要点：
- 硬规则：当前工作流仅支持多库串行执行，不支持并行执行
- 禁止并行处理多个库，禁止并行写任务表、批次报告、lycium 共享目录与共享缓存
- 多库模式下当前只支持串行，不支持并行主流程
- AI 会先处理 `是否需要用户审批方案=否` 的库
- 再处理 `是` 或留空的库
- 对需要审批的库，会先统一做到 Phase 3，再等待用户批量审批

## 建议反馈模板

```text
任务模板已准备完成：libs/porting-tasks-YYYY-MM-DD.xlsx
批次汇总报告已初始化：reports/batch-YYYY-MM-DD.md
模板文件 libs/porting-tasks-模板.xlsx 不直接参与后续阶段。
请填写待移植库信息，完成后回复“填好了”。
```

## STOP

Phase 1 完成后：
- 清空 TODO
- 停止继续执行
- 等待用户回复“填好了”

## 下一步

用户确认填写完成后，进入 [03-read-tasks.md](./03-read-tasks.md)。
