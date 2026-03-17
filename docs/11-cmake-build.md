# Phase 5-2：构建编译执行

说明：
- 本文件名保留为 `11-cmake-build.md` 以兼容现有结构
- 但内容已改为 Phase 5 的通用构建执行流程

目标：
- 优先使用 `lycium` 构建
- 失败后分类
- 需要时进入原生 fallback
- 允许边编译边修代码，直到产出 `.so`

## 输入

- `libs/<库名>/`
- 构建系统识别结果
- `reports/<库名>-adaptation-report.md`

## 输出

- `outputs/<库名>/`
- `reports/<库名>-build-report.md`
- 必要时：`libs/<库名>/build.sh`

## 标准主路径

```text
lycium 优先
-> 失败分类
-> 适合则 fallback
-> 边编译边修
-> 产出 .so
```

## 第一步：准备 lycium 执行脚本

模板脚本：

```text
scripts/run-lycium-build.sh
```

实际执行前：
- 复制一份按库名命名的脚本
- 例如：`scripts/run-lycium-build-zlib.sh`
- 由 AI 填入本库专用变量

建议填写内容：
- `LIB_NAME`
- `ARCH=arm64-v8a`
- `HPK_DIR`
- `SOURCE_DIR`

## 第二步：优先尝试 lycium

典型做法：

1. 复用已有 `HPKBUILD`
2. 若无现成 `HPKBUILD`，从模板复制并填写最小可用版本
3. 在 `tpc_c_cplusplus/lycium/` 下执行：

```bash
./build.sh <pkgname>
```

其中 `<pkgname>` 对应 `HPKBUILD` 所在目录名。

## 第三步：记录 lycium 结果

无论成功或失败，都要在 `reports/<库名>-build-report.md` 中记录：
- 使用的 `HPKBUILD` 路径
- 是否复用现有 recipe
- 是否新建或修改 recipe
- 关键命令
- 结果与报错摘要

## 第四步：失败分类

按 [10-build-system-detect.md](./10-build-system-detect.md) 中定义的四类分类：
- 环境缺失
- HPKBUILD / recipe 问题
- 源码问题
- 构建系统 / 工具链问题

## 第五步：决定是否 fallback

### 不进入 fallback

情形：
- 环境缺失，需用户处理
- recipe 问题仍值得再修一次

### 进入 fallback

情形：
- `lycium` 无法表达当前库构建逻辑
- 继续修 recipe 成本过高
- 源码与构建系统更适合直接原生命令

## 第六步：生成原生 build.sh

通过：

```bash
scripts/init-build-script.sh
```

生成：

```text
libs/<库名>/build.sh
```

按构建系统生成模板：
- `cmake`
- `configure`
- `make`
- `gn`

## 第七步：执行 fallback 编译

执行：

```bash
bash libs/<库名>/build.sh
```

执行时允许持续迭代：
- 遇到编译报错
- 分析报错属于源码问题、构建配置问题还是链接问题
- 做最小必要 patch
- 重新执行编译

## 第八步：边编译边修

允许修复的典型问题：
- 缺少 `-fPIC`
- 共享库构建选项未开启
- HarmonyOS 头文件或接口差异
- CMake / Make / configure 的平台判断问题
- 链接项缺失
- 源码中暴露出来的平台不兼容点

这些修改必须写入：
- `reports/<库名>-build-report.md`

## 第九步：产物校验

至少校验以下内容：

### 1. 文件存在

```bash
ls -lh outputs/<库名>/
```

### 2. 架构正确

```bash
file outputs/<库名>/*.so
```

期望：
- `AArch64`

### 3. ELF 类型正确

```bash
readelf -h outputs/<库名>/*.so
```

期望：
- `Type: DYN`

### 4. 导出符号存在

```bash
nm -D outputs/<库名>/*.so | head
```

## 第十步：输出构建报告

建议报告结构：

```markdown
# <库名> 构建报告

## 1. 构建系统识别结果
## 2. lycium 尝试记录
## 3. 失败分类与决策
## 4. fallback 执行记录
## 5. 编译驱动型代码修改
## 6. 产物校验结果
## 7. 最终产物路径
```

## 完成标准

- [ ] 最终已生成 `.so`
- [ ] 架构为 `arm64-v8a / AArch64`
- [ ] 产物已放入 `outputs/<库名>/`
- [ ] `reports/<库名>-build-report.md` 已生成

## 下一步

Phase 5 完成后，不再 STOP，直接进入 [12-delivery-archive.md](./12-delivery-archive.md)。

