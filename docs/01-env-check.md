# 环境检查

在开始三方库鸿蒙化编译之前，需要先检查环境是否就绪。

---

## 执行流程（AI 行动指南）

AI 按以下步骤执行：

1. **读取 00-paths.md** - 获取已记录的路径变量
2. **验证路径** - 直接执行 bash 命令验证资源是否存在
3. **如无效，搜索** - 在常见位置查找资源
4. **如未找到，询问用户** - 是否已准备？输入路径还是下载？
5. **验证通过** - 更新 00-paths.md，继续下一步

---

## 检查步骤

### 步骤 1：读取已记录路径

AI 首先读取 `docs/00-paths.md`，提取路径变量：

```bash
# 读取示例
cat docs/00-paths.md
```

提取以下变量：
- `COMMAND_LINE_TOOLS_ROOT` - 编译工具链路径
- `DOCS_INDEX_ROOT` - 文档索引路径
- `PORTING_ROOT` - 编译项目根目录

---

### 步骤 2：验证路径有效性

使用已记录的路径，直接执行 bash 命令验证：

**验证 command-line-tools**：
```bash
# 替换 $COMMAND_LINE_TOOLS_ROOT 为实际路径
ls -la $COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony/native/llvm/bin/aarch64-unknown-linux-ohos-clang
ls -la $COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony/native/llvm/bin/armv7-unknown-linux-ohos-clang
```

**验证 docs_index**：
```bash
# 替换 $DOCS_INDEX_ROOT 为实际路径
ls -la $DOCS_INDEX_ROOT/docs/
```

**通过标准**：命令执行成功，文件存在

---

### 步骤 3：如路径无效，搜索资源

如果验证失败，在常见位置搜索：

**搜索 command-line-tools**：
```bash
ls -la /home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools/
ls -la ~/command-line-tools/
ls -la /opt/command-line-tools/
```

**搜索 docs_index**：
```bash
ls -la /home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/docs_index/
ls -la ~/docs_index/
ls -la /opt/docs_index/
```

---

### 步骤 4：如未找到，询问用户

按以下流程处理：

```
未找到资源
    │
    ▼
询问用户："你是否已经准备好了该环境？"
    │
    ├─ 用户说"是" → 请求用户输入路径 → 验证 → 更新 00-paths.md
    │
    └─ 用户说"否" → 尝试自动下载
          ├─ docs_index: git clone
          └─ command-line-tools: 提示手动下载
```

---

### 步骤 5：更新 00-paths.md

验证成功后，更新 `docs/00-paths.md` 中的路径变量：

```bash
# 更新示例
export COMMAND_LINE_TOOLS_ROOT="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools"
export DOCS_INDEX_ROOT="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/docs_index"
```

---

## 资源下载地址

| 资源 | 下载地址 |
|------|---------|
| **command-line-tools** | https://developer.huawei.com/consumer/cn/download/ |
| **docs_index** | https://github.com/NormanFxxkingRockwell/docs_index |

---

## 验证清单

| 检查项 | 状态 | 路径 |
|--------|------|------|
| WSL | ☐ | - |
| Git | ☐ | - |
| Python + openpyxl | ☐ | - |
| command-line-tools | ☐ | `COMMAND_LINE_TOOLS_ROOT=`<路径> |
| docs_index | ☐ | `DOCS_INDEX_ROOT=`<路径> |

---

## 下一步

环境检查全部通过后，即可进入 **Phase 1-2: 任务准备**（`docs/02-prepare-tasks.md`）。
