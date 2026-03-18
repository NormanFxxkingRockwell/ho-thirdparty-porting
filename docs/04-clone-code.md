# Phase 2-2：获取源码

目标：
- 将目标三方库源码放入当前仓库的 `libs/` 目录

## 输入

- 任务表中的库名、仓库地址、版本信息

## 输出

- `libs/<库名>/`

## 目录规则

源码统一放到：

```text
libs/<库名>/
```

说明：
- 不要把源码放到 `outputs/`、`reports/` 或仓库外其他临时目录
- 允许覆盖重新拉取，但要先确认不会误删用户已有重要修改
- 当前目录主要服务于：
  - Phase 3 代码分析
  - Phase 4 业务适配
  - Phase 5 fallback 原生构建
- 如果 Phase 5 走 `lycium`，该目录不自动等于 `lycium` 的实际输入目录

## AI 执行步骤

### 1. 检查源码目录是否已存在

若已存在：
- 检查是否为同一仓库
- 若是，进入版本校验
- 若不是，停止并提示用户确认

### 2. 克隆或下载源码

推荐：

```bash
git clone <repo_url> libs/<lib_name>
```

### 3. 如任务表中指定版本，则切换版本

支持：
- tag
- branch
- commit

### 4. 记录源码与 recipe 的关系

如果后续准备走 `lycium`，AI 需要额外判断：
- 是否已有现成 `HPKBUILD`
- 是否需要根据 `libs/<库名>/` 的分析结果新建或修正 recipe

## 失败处理

- 仓库地址不可访问：向用户报错并停止
- 版本不存在：记录后进入 [05-verify-code.md](./05-verify-code.md) 做最终判断

## 下一步

进入 [05-verify-code.md](./05-verify-code.md)。

