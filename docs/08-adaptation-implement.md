# Phase 4-1：实施业务代码适配方案

目标：
- 按用户批准的方案修改源码
- 为 Phase 5 编译打下业务代码基础

## 输入

- `reports/<库名>-adaptation-plan.md`
- 用户已明确批准方案
- `libs/<库名>/`

## 输出

- 修改后的源码
- 业务适配实施记录

## 处理原则

- 只实施已批准的业务适配内容
- 优先做最小修改
- 保持变更可读、可回溯
- 不在本阶段编写复杂的编译策略

## AI 执行步骤

### 1. 按方案逐项实施

每项修改应记录：
- 修改文件
- 修改目的
- 是否新增 HarmonyOS 条件分支

### 2. 做基础自检

建议检查：
- 语法层面是否明显错误
- 头文件是否仍能解析
- 平台宏是否闭合

### 3. 准备交给 Phase 5

说明：
- Phase 4 完成后直接进入 Phase 5
- Phase 4 与 Phase 5 中间不再 STOP

## 下一步

完成实施后，生成业务适配报告：
- [09-adaptation-report.md](./09-adaptation-report.md)

随后进入：
- [10-build-system-detect.md](./10-build-system-detect.md)

