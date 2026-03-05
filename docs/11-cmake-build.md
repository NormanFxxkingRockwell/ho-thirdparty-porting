# Phase 5: 构建与编译

## Phase 5-2: CMake 构建系统编译（Phase 5 续）

**定位**：AI 使用 CMake 编译第三方库到 HarmonyOS 的完整流程

**前置条件**：
- 代码适配已完成（Phase 4）
- 构建系统已识别为 CMake（`docs/10-build-system-detect.md`）
- 工具链文件已生成

**输入**：
- 已适配的库源码（`libs/<库名>/`）
- 工具链文件（`toolchain-ohos-arm64.cmake`）

**输出**：
- 编译产物（`.so` 文件，位于 `outputs/<库名>/`）
- 编译报告（`reports/<库名>-build-report.md`）

---

## AI 工作流程

```
1. 准备构建目录 → 2. 配置 CMake → 3. 执行编译 → 
4. 安装产物 → 5. 验证编译结果 → 6. 生成编译报告
```

---

## 步骤 1: 准备构建目录

**创建标准构建目录结构**：

```bash
cd libs/<库名>/

# 清理旧构建（如果存在）
rm -rf build/ install/

# 创建新目录
mkdir -p build install outputs

# 复制工具链文件到项目根目录（如果还没有）
if [ ! -f "toolchain-ohos-arm64.cmake" ]; then
    cp ../../toolchain-ohos-arm64.cmake .
fi
```

---

## 步骤 2: 配置 CMake

**标准配置命令**：

```bash
cd build/

# 配置 CMake
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../toolchain-ohos-arm64.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_LIBDIR=lib
```

**参数说明**：

| 参数 | 值 | 说明 |
|------|-----|------|
| `CMAKE_TOOLCHAIN_FILE` | `../toolchain-ohos-arm64.cmake` | HarmonyOS 工具链 |
| `CMAKE_BUILD_TYPE` | `Release` | 发布版本（优化） |
| `CMAKE_INSTALL_PREFIX` | `../install` | 安装路径 |
| `BUILD_TESTING` | `OFF` | 不编译测试（节省时间） |
| `BUILD_SHARED_LIBS` | `ON` | 编译动态库（.so） |
| `CMAKE_INSTALL_LIBDIR` | `lib` | 库文件目录 |

**配置成功标志**：

```
-- Configuring done
-- Generating done
-- Build files have been written to: /path/to/build
```

**如果配置失败**，见 [常见问题排查](#常见问题排查)

---

## 步骤 3: 执行编译

**标准编译命令**：

```bash
# 使用所有 CPU 核心编译
cmake --build . --parallel $(nproc)

# 或者使用 make
make -j$(nproc)
```

**编译输出监控**：

观察编译输出，注意以下信息：

**成功标志**：
```
[100%] Built target <库名>
```

**警告（可忽略）**：
```
warning: unused variable 'xxx'
warning: 'xxx' is deprecated
```

**错误（需要处理）**：
```
error: undefined reference to 'xxx'
error: 'xxx' was not declared in this scope
fatal error: xxx.h: No such file or directory
```

**编译进度**：
```
[ 25%] Building C object CMakeFiles/<target>.c.o
[ 50%] Building CXX object CMakeFiles/<target>.cpp.o
[ 75%] Linking CXX shared library lib<库名>.so
[100%] Built target <库名>
```

---

## 步骤 4: 安装产物

**安装到指定目录**：

```bash
# 使用 cmake 安装
cmake --install . --prefix ../install

# 或者使用 make
make install
```

**安装后的目录结构**：

```
install/
├── lib/
│   ├── lib<库名>.so           # 动态库
│   └── lib<库名>.so.<version> # 版本化库
├── include/
│   └── <库名>/
│       └── *.h                # 头文件
└── lib/
    └── cmake/
        └── <库名>/
            └── *.cmake        # CMake 配置（如果有）
```

**复制产物到 outputs 目录**：

```bash
# 复制 .so 文件到 outputs 目录
cd ..
cp install/lib/lib<库名>.so* outputs/

# 或者直接从 build 目录复制
cp build/lib<库名>.so outputs/
```

---

## 步骤 5: 验证编译结果

**验证清单**：

### 5.1 文件存在性检查

```bash
# 检查 .so 文件是否存在
ls -lh outputs/lib<库名>.so

# 检查文件大小（应该 > 1KB）
stat --format="%s bytes" outputs/lib<库名>.so

# 如果文件太小（< 1KB），可能编译有问题
if [ $(stat --format="%s" outputs/lib<库名>.so) -lt 1024 ]; then
    echo "WARNING: Library file is suspiciously small"
fi
```

### 5.2 架构验证

```bash
# 检查架构（应该是 ARM64）
file outputs/lib<库名>.so

# 期望输出：
# lib<库名>.so: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked

# 验证命令
if file outputs/lib<库名>.so | grep -q "ARM aarch64"; then
    echo "✓ Architecture verified: ARM64"
else
    echo "✗ Architecture mismatch!"
    exit 1
fi
```

### 5.3 符号表检查

```bash
# 检查导出符号
nm -D outputs/lib<库名>.so | grep ' T ' | head -20

# 统计导出符号数量
EXPORT_COUNT=$(nm -D outputs/lib<库名>.so | grep ' T ' | wc -l)
echo "Exported symbols: $EXPORT_COUNT"

# 如果没有导出符号，库可能无法使用
if [ "$EXPORT_COUNT" -eq 0 ]; then
    echo "WARNING: No exported symbols!"
fi
```

### 5.4 依赖检查

```bash
# 查看动态依赖
readelf -d outputs/lib<库名>.so | grep NEEDED

# 或者使用 objdump
objdump -p outputs/lib<库名>.so | grep NEEDED

# 检查是否有未定义的符号
nm -D outputs/lib<库名>.so | grep ' U ' | head -20
```

### 5.5 ELF 头信息

```bash
# 查看 ELF 头
readelf -h outputs/lib<库名>.so

# 关键信息：
#   Class:                             ELF64
#   Data:                              2's complement, little endian
#   Machine:                           AArch64
#   Type:                              DYN (Shared object file)
```

---

## 步骤 6: 生成编译报告

**报告模板**：

```markdown
# <库名> 编译报告

**生成时间**：YYYY-MM-DD HH:MM
**库版本**：vX.Y.Z
**编译工具链**：HarmonyOS NDK ARM64

---

## 1. 编译配置

### 1.1 构建系统

| 项目 | 值 |
|------|-----|
| 构建系统 | CMake |
| CMake 版本 | 3.x.x |
| 工具链文件 | toolchain-ohos-arm64.cmake |

### 1.2 编译参数

```bash
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../toolchain-ohos-arm64.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON
```

### 1.3 编译器信息

```bash
aarch64-unknown-linux-ohos-clang --version
# 输出编译器版本
```

---

## 2. 编译过程

### 2.1 编译输出

```
[粘贴 cmake --build 的完整输出]
```

### 2.2 编译统计

| 项目 | 值 |
|------|-----|
| 编译文件数 | N |
| 编译时间 | X 分钟 |
| 产物大小 | X KB |

### 2.3 警告/错误

**警告**（如有）：
```
[粘贴警告信息]
```

**错误**（如有）：
```
[粘贴错误信息]
[说明如何解决]
```

---

## 3. 编译产物验证

### 3.1 文件信息

```
$ ls -lh outputs/lib<库名>.so
-rwxr-xr-x 1 user user X.XM MMM DD HH:MM outputs/lib<库名>.so
```

### 3.2 架构验证

```
$ file outputs/lib<库名>.so
lib<库名>.so: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked
✓ Architecture verified: ARM64
```

### 3.3 符号表

```
$ nm -D outputs/lib<库名>.so | grep ' T ' | wc -l
N exported symbols

[列出主要导出符号]
```

### 3.4 依赖检查

```
$ readelf -d outputs/lib<库名>.so | grep NEEDED
 0x0000000000000001 (NEEDED) Shared library: [libc.so]
 0x0000000000000001 (NEEDED) Shared library: [libm.so]
```

### 3.5 ELF 头

```
$ readelf -h outputs/lib<库名>.so
  Class:                             ELF64
  Machine:                           AArch64
  Type:                              DYN (Shared object file)
```

---

## 4. 验证结果

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 文件存在 | ✅ | 文件大小 X.X MB |
| 架构正确 | ✅ | ARM64 (AArch64) |
| 符号导出 | ✅ | N 个导出符号 |
| 依赖正常 | ✅ | 依赖 libc.so, libm.so |
| ELF 类型 | ✅ | DYN (Shared object) |

**综合判定**：✅ 编译成功

---

## 5. 产物清单

### 5.1 编译产物

| 文件 | 路径 | 大小 | 用途 |
|------|------|------|------|
| lib<库名>.so | outputs/lib<库名>.so | X.X MB | 动态库 |
| lib<库名>.so.X | outputs/lib<库名>.so.X | X.X MB | 版本化库 |

### 5.2 头文件

| 文件 | 路径 | 用途 |
|------|------|------|
| <库名>.h | install/include/<库名>.h | 公共头文件 |

---

## 6. 下一步

编译成功后 → **Phase 4-5: 产物验证**（`docs/13-verification.md`）

---

## 附录：编译环境

**操作系统**：WSL2 Ubuntu
**编译器**：aarch64-unknown-linux-ohos-clang
**CMake 版本**：3.x.x
**NDK 版本**：6.0.2.640
```

---

## 常见问题排查

### 问题 1: CMake 找不到工具链文件

**错误**：
```
CMake Error: Could not find toolchain file: ../toolchain-ohos-arm64.cmake
```

**解决**：
```bash
# 检查工具链文件路径
ls -la ../toolchain-ohos-arm64.cmake

# 使用绝对路径
cmake .. -DCMAKE_TOOLCHAIN_FILE=/absolute/path/to/toolchain-ohos-arm64.cmake
```

### 问题 2: 编译器找不到

**错误**：
```
CMake Error: The C compiler identification is unknown
```

**解决**：
```bash
# 检查编译器是否在 PATH 中
which aarch64-unknown-linux-ohos-clang

# 如果不在，设置 PATH
export PATH="/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools/bin:$PATH"

# 或者使用绝对路径
cmake .. -DCMAKE_C_COMPILER=/absolute/path/to/aarch64-unknown-linux-ohos-clang
```

### 问题 3: 头文件缺失

**错误**：
```
fatal error: xxx.h: No such file or directory
```

**解决**：
```bash
# 检查适配是否完成
grep -r "#include.*xxx.h" src/

# 如果是 HarmonyOS API，确保已链接对应库
# 在 CMakeLists.txt 中添加
target_link_libraries(your_target PRIVATE libhilog_ndk.z.so)
```

### 问题 4: 符号未定义

**错误**：
```
undefined reference to `xxx'
```

**解决**：
```bash
# 检查是否有未链接的库
grep -r "xxx" CMakeLists.txt

# 添加缺失的库
target_link_libraries(your_target PRIVATE missing_library)
```

### 问题 5: 架构不匹配

**错误**：
```
relocation R_X86_64 against `.rodata' can not be used when making a shared object
```

**解决**：
```bash
# 确保使用交叉编译器
cmake .. \
    -DCMAKE_C_COMPILER=aarch64-unknown-linux-ohos-clang \
    -DCMAKE_CXX_COMPILER=aarch64-unknown-linux-ohos-clang++

# 检查 CMakeCache.txt
grep CMAKE_C_COMPILER CMakeCache.txt
```

### 问题 6: CMake 缓存问题

**错误**：
```
CMake Error: The source directory does not appear to contain CMakeLists.txt
```

**解决**：
```bash
# 清理缓存
rm -rf CMakeCache.txt CMakeFiles/

# 重新配置
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-ohos-arm64.cmake
```

---

## AI 执行检查清单

在报告编译成功前，确认已完成：

- [ ] CMake 配置成功
- [ ] 编译完成无错误
- [ ] .so 文件已生成（outputs/目录）
- [ ] 架构验证通过（ARM64）
- [ ] 符号表检查通过
- [ ] 依赖检查通过
- [ ] 编译报告已生成（`reports/<库名>-build-report.md`）

---

## 下一步

编译完成后 → **Phase 6: 交付与归档**（`docs/12-delivery-archive.md`，待完善）

**TODO 管理**：清空 Phase 5 TODO，等待用户确认后创建 Phase 6 TODO
