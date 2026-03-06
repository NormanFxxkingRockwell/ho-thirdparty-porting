# 路径配置

本文档由 AI 在环境检查时自动生成和维护。

---

## 资源清单

AI 需要管理和配置以下资源：

| 资源 | 说明 | 默认目标路径 |
|------|------|-------------|
| **command-line-tools** | HarmonyOS 编译工具链 | `/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools/` |
| **docs_index** | HarmonyOS 文档索引 | `/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/docs_index/` |

---

## 路径变量

```bash
# HarmonyOS 编译工具链 (WSL 路径)
export COMMAND_LINE_TOOLS_ROOT="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools"
export OHOS_SDK_ROOT="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools/sdk/default/openharmony/native/llvm"
export ARM64_CC="aarch64-unknown-linux-ohos-clang"
export ARM_CC="armv7-unknown-linux-ohos-clang"

# HarmonyOS 文档索引 (WSL 路径)
export DOCS_INDEX_ROOT="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/docs_index"

# 三方库编译项目 (WSL 路径)
export PORTING_ROOT="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/ho-thirdparty-porting/"
```

---

## 资源下载地址

| 资源 | 下载地址 |
|------|---------|
| **command-line-tools** | https://developer.huawei.com/consumer/cn/download/ |
| **docs_index** | https://github.com/NormanFxxkingRockwell/docs_index |

---

## 使用方法

1. AI 读取本文档，提取路径变量
2. 执行 bash 命令验证路径是否有效
3. 如无效，在常见位置搜索资源
4. 如未找到，询问用户处理方式
5. 验证成功后，更新本文档中的路径
