# Phase 2-3：校验源码版本

目标：
- 确认 `libs/<库名>/` 中的源码版本与任务表约定一致

## 输入

- 任务表中的版本字段
- 已获取的源码目录

## 输出

- 版本校验结果

## AI 执行步骤

### 1. 读取任务表版本

版本可能是：
- tag
- branch
- commit
- 空

### 2. 检查当前源码版本

推荐检查：

```bash
git rev-parse --short HEAD
git branch --show-current
git describe --tags --exact-match
```

### 3. 比对结果

#### 版本为空

- 视为可接受
- 在记录中标明实际使用的分支或 commit

#### 版本匹配

- 通过

#### 版本不匹配

- 优先尝试切换到正确版本
- 切换失败时，向用户说明版本不可用或仓库状态异常

## 通过标准

- [ ] 源码仓库正确
- [ ] 版本匹配，或版本为空但已记录实际版本

## 下一步

通过后进入 [06-code-analysis.md](./06-code-analysis.md)。

