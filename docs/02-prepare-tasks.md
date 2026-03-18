# Phase 1-2：准备任务表

目标：
- 生成或确认任务模板
- 让用户填写待移植三方库信息

## 输入

- 已完成环境检查

## 输出

- `libs/porting-tasks-YYYY-MM-DD.xlsx`

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
- 该脚本会把 `libs/porting-tasks-模板.xlsx` 复制为当天正式任务表。
- `libs/porting-tasks-模板.xlsx` 只作为模板，不允许直接作为 Phase 2 输入。

模板至少包含这些字段：

| 字段 | 必填 | 说明 |
|------|------|------|
| 库名 | 是 | 三方库名称 |
| Git 仓库 | 是 | 源码仓库地址 |
| 版本 | 否 | tag / branch / commit，可留空 |
| 状态 | 否 | 初始为“待处理” |
| 备注 | 否 | 特殊依赖、编译说明、来源说明 |

### 3. 提示用户填写

提示要点：
- 版本留空时，AI 会尽量按默认分支或最新可用版本处理
- 当前流程默认目标是 `arm64-v8a` 和 `.so`
- 用户填写完成后再继续 Phase 2

## 建议反馈模板

```text
任务模板已准备完成：libs/porting-tasks-YYYY-MM-DD.xlsx
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
