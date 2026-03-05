# Phase 1-2: 表格准备

当用户提出三方库鸿蒙化需求时，AI 生成模板让用户填写。

---

## 触发条件

用户提出类似需求：
- "帮我编译 xxx 库"
- "我想把 xxx 移植到鸿蒙"
- "鸿蒙化这个库：xxx"

---

## 执行流程

### 步骤 1：检查 libs/ 目录

检查是否存在当天日期的表格：

```bash
ls -la libs/
```

---

### 步骤 2：生成模板

根据当天日期生成模板文件：

```
porting-tasks-YYYY-MM-DD.xlsx
```

例如：`porting-tasks-2026-03-02.xlsx`

**模板结构**：

| 库名 | Git 仓库 | 版本 | 状态 | 备注 |
|------|-----------|------|------|------|
| (待填写) | (待填写) | (留空=最新) | 待编译 | (可选) |

---

### 步骤 3：提示用户填写

告诉用户：
1. 模板已生成在 `libs/YYYY-MM-DD.xlsxporting-tasks-`
2. 请填写需要鸿蒙化的库信息
3. 版本留空自动获取最新（通过 git branch 和 tag）
4. 填写完成后告知 AI

---

### 步骤 4：用户填写完成后

AI 读取表格，开始执行编译流程。

---

## 读取表格（供后续阶段使用）

读取当天日期的表格：

```python
import openpyxl
from datetime import datetime

today = datetime.now().strftime('%Y-%m-%d')
filename = f'libs/porting-tasks-{today}.xlsx'

wb = openpyxl.load_workbook(filename)
ws = wb.active

# 读取每一行
for row in ws.iter_rows(min_row=2, values_only=True):
    lib_name, repo_url, version, status, note = row
    if lib_name:  # 跳过空行
        print(f"库: {lib_name}, 仓库: {repo_url}, 版本: {version}")
```

---

## 自动获取最新版本

当版本字段留空时，通过 git 自动获取：

```bash
# 获取最新 tag（作为版本号）
git fetch --tags
latest_tag=$(git describe --tags --abbrev=0)
echo $latest_tag

# 或获取最新 commit hash（短）
latest_commit=$(git rev-parse --short HEAD)
echo $latest_commit
```

---

## 状态值规范

| 状态 | 说明 |
|------|------|
| 待编译 | 等待处理 |
| 克隆中 | 正在克隆仓库 |
| 适配中 | 正在修改代码 |
| 编译中 | 正在编译 |
| 已完成 | 编译成功 |
| 失败 | 编译失败 |

---

## TODO 管理（重要！）

**当前 Phase 完成后**：

1. 清空 TODO 列表：`todowrite([])`
2. 发送完成消息
3. 🛑 **STOP - 等待用户确认**

**完成消息示例**：

```
"✅ Phase 1 完成！模板已生成在 `libs/porting-tasks-2026-03-05.xlsx`

请填写需要鸿蒙化的库信息：
- 库名：必需
- Git 仓库：必需
- 版本：留空=获取最新

填写完成后告诉我'填好了'，我将继续 Phase 2-3"
```

> ⚠️ **AI 注意**：不要创建 Phase 2-3 的 TODO！等待用户说"填好了"再说。

---

## 下一步

用户填写完成后，进入 **2-1 拉取代码** 阶段。
