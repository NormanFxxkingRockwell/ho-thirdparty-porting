# Phase 2-3: 验证代码版本

**定位**：验证克隆的代码版本与 Excel 表格一致

**前置条件**：
- 代码已克隆到 `libs/<库名>/`

**输入**：
- Excel 任务表格（库名、仓库、版本）
- 已克隆的源码目录

**输出**：
- 版本验证通过/失败

**关键原则**：
- ✅ 只验证版本是否匹配
- ✅ 失败自动重新拉取
- ❌ 不报告用户

---

## AI 工作流程

```
读取 Excel 版本 → 检查 Git 版本 → 对比 → 
通过：继续 Phase 3
失败：重新拉取 → 重新验证
```

---

## 验证步骤

### 1. 读取 Excel 中的版本

从任务表格中提取版本信息：

| 库名 | Git 仓库 | 版本 |
|------|----------|------|
| log4cpp | https://github.com/xxx/log4cpp.git | v1.2.3 |

**版本可能是**：
- Tag 名称：`v1.2.3`
- Commit Hash：`abc123f`
- Branch 名称：`main`

---

### 2. 检查 Git 版本

```bash
cd libs/<库名>/

# 获取当前版本
git describe --tags --exact-match 2>/dev/null
# 输出：当前 Tag

git rev-parse --short HEAD
# 输出：当前 Commit Hash

git branch --show-current
# 输出：当前分支
```

---

### 3. 对比版本

```bash
# Excel 版本
EXCEL_VERSION="v1.2.3"

# Git 版本
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null)
GIT_COMMIT=$(git rev-parse --short HEAD)

# 对比
if [ "$EXCEL_VERSION" = "$GIT_TAG" ] || [ "$EXCEL_VERSION" = "$GIT_COMMIT" ]; then
    echo "✅ 版本匹配"
else
    echo "❌ 版本不匹配，重新拉取"
    # 重新拉取
    cd ..
    rm -rf <库名>
    git clone <仓库地址> <库名>
    cd <库名>
    git checkout <版本>
    
    # 重新验证
    # 如果还失败，再次重新拉取（最多 3 次）
fi
```

---

## 重试机制

**最多重试 3 次**：

```
第 1 次失败 → 重新拉取
第 2 次失败 → 重新拉取
第 3 次失败 → 报告用户（网络问题或版本不存在）
```

---

## AI 执行检查清单

- [ ] 读取 Excel 版本
- [ ] 获取 Git 版本
- [ ] 对比版本
- [ ] 失败时重新拉取（最多 3 次）

---

## 下一步

验证通过 → **Phase 3-1: 代码分析**（`docs/06-analyze-code.md`）

验证失败（3 次）→ 报告用户（网络问题或版本不存在）
