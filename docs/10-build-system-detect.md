# Phase 4-1: 构建系统识别

**定位**：AI 在代码适配完成后，识别并使用正确的构建系统进行编译

**输入**：
- 已适配的库源码（`libs/<库名>/`）
- 适配报告（`reports/<库名>-adaptation-report.md`）

**输出**：
- 构建系统类型确认
- 构建配置文件（工具链文件/环境变量）
- 编译命令清单

---

## AI 工作流程

```
1. 构建系统检测 → 2. 生成配置文件 → 3. 配置构建环境 → 
4. 输出编译命令 → 5. 验证配置正确性
```

---

## 构建系统检测算法

**检测优先级**（按顺序检查）：

```
1. CMake     → 检查 CMakeLists.txt
2. Autotools → 检查 configure.ac + configure
3. Makefile  → 检查 Makefile + Makefile.am
4. GN        → 检查 BUILD.gn
5. 其他      → 需要人工介入
```

---

## 1. CMake 构建系统

### 1.1 检测条件

**存在以下文件**：
- `CMakeLists.txt`（根目录）
- 可选：`cmake/` 子目录（CMake 模块）

**检测命令**：
```bash
cd libs/<库名>/

# 检查 CMakeLists.txt
if [ -f "CMakeLists.txt" ]; then
    echo "✓ CMake build system detected"
    
    # 检查是否有 cmake 子目录
    if [ -d "cmake" ]; then
        echo "  - Has cmake/ subdirectory"
    fi
    
    # 统计 CMake 文件数量
    find . -name "CMakeLists.txt" | wc -l
fi
```

### 1.2 配置文件生成

**生成 HarmonyOS 工具链文件**：

创建 `toolchain-ohos-arm64.cmake`：

```cmake
# HarmonyOS ARM64 Cross-Compilation Toolchain
# 生成时间：YYYY-MM-DD HH:MM

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Cross-compiler toolchain
set(CMAKE_C_COMPILER aarch64-unknown-linux-ohos-clang)
set(CMAKE_CXX_COMPILER aarch64-unknown-linux-ohos-clang++)
set(CMAKE_AR aarch64-unknown-linux-ohos-ar)
set(CMAKE_RANLIB aarch64-unknown-linux-ohos-ranlib)
set(CMAKE_STRIP aarch64-unknown-linux-ohos-strip)

# NDK paths
set(OHOS_NDK_ROOT "$ENV{OHOS_NDK_ROOT}")
if(NOT OHOS_NDK_ROOT)
    set(OHOS_NDK_ROOT "/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools")
endif()

set(OHOS_SYSROOT "${OHOS_NDK_ROOT}/sdk/default/openharmony/native/llvm/sysroot")

# Include and library paths
set(CMAKE_SYSROOT ${OHOS_SYSROOT})
set(CMAKE_FIND_ROOT_PATH ${OHOS_SYSROOT})

# Search strategy
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -march=armv8-a")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -march=armv8-a")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pie")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -shared")

# Cross-compiling flag
set(CMAKE_CROSSCOMPILING TRUE)

message(STATUS "HarmonyOS ARM64 Toolchain configured")
message(STATUS "  Sysroot: ${OHOS_SYSROOT}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  CXX Compiler: ${CMAKE_CXX_COMPILER}")
```

### 1.3 构建配置命令

**标准 CMake 配置流程**：

```bash
# 创建构建目录
mkdir -p build && cd build

# 配置（使用工具链文件）
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../toolchain-ohos-arm64.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON

# 或者：命令行直接指定编译器
cmake .. \
    -DCMAKE_C_COMPILER=aarch64-unknown-linux-ohos-clang \
    -DCMAKE_CXX_COMPILER=aarch64-unknown-linux-ohos-clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../install
```

### 1.4 CMakeLists.txt 适配检查

**检查项**：

```bash
# 1. 检查是否有 Windows 特定配置
grep -n "WIN32\|_WIN32\|MSVC" CMakeLists.txt

# 2. 检查是否有平台相关编译选项
grep -n "if(.*WIN\|if(.*LINUX\|if(.*APPLE" CMakeLists.txt

# 3. 检查依赖查找
grep -n "find_package\|find_library" CMakeLists.txt
```

**适配建议**：

如果检测到 Windows 特定配置，在 CMakeLists.txt 中添加：

```cmake
# 在原有的 if(WIN32) 块附近添加
if(__OHOS__)
    message(STATUS "Building for HarmonyOS")
    # HarmonyOS 特定配置
    target_link_libraries(your_target PRIVATE libhilog_ndk.z.so)
endif()
```

---

## 2. Autotools 构建系统

### 2.1 检测条件

**存在以下文件**：
- `configure.ac` 或 `configure.in`
- `Makefile.am`
- 可选：`configure` 脚本（已生成）

**检测命令**：
```bash
cd libs/<库名>/

# 检查 Autotools 文件
if [ -f "configure.ac" ] || [ -f "configure.in" ]; then
    echo "✓ Autotools build system detected"
    
    # 检查是否需要生成 configure
    if [ ! -f "configure" ]; then
        echo "  - configure script missing, need to run autoreconf"
    fi
fi
```

### 2.2 配置环境变量

**设置交叉编译环境变量**：

```bash
# 编译器
export CC=aarch64-unknown-linux-ohos-clang
export CXX=aarch64-unknown-linux-ohos-clang++

# 编译工具
export AR=aarch64-unknown-linux-ohos-ar
export RANLIB=aarch64-unknown-linux-ohos-ranlib
export STRIP=aarch64-unknown-linux-ohos-strip

# 编译标志
export CFLAGS="--target=aarch64-linux-ohos -march=armv8-a -fPIC -O2"
export CXXFLAGS="--target=aarch64-linux-ohos -march=armv8-a -fPIC -O2"
export LDFLAGS="--target=aarch64-linux-ohos --sysroot=${OHOS_SYSROOT}"

# 包含路径
export CPPFLAGS="-I${OHOS_SYSROOT}/include"

# 库路径
export LIBS="-L${OHOS_SYSROOT}/lib"
```

### 2.3 configure 配置命令

**标准 Autotools 配置流程**：

```bash
# 如果需要，先生成 configure 脚本
autoreconf -fi

# 配置交叉编译
./configure \
    --host=aarch64-unknown-linux-ohos \
    --build=x86_64-unknown-linux-gnu \
    --target=aarch64-unknown-linux-ohos \
    --prefix=$(pwd)/install \
    --disable-static \
    --enable-shared \
    CC=aarch64-unknown-linux-ohos-clang \
    CXX=aarch64-unknown-linux-ohos-clang++ \
    CFLAGS="--target=aarch64-linux-ohos -march=armv8-a -fPIC -O2" \
    CXXFLAGS="--target=aarch64-linux-ohos -march=armv8-a -fPIC -O2" \
    LDFLAGS="--target=aarch64-linux-ohos --sysroot=${OHOS_SYSROOT}"

# 如果 configure 不支持某些标志，尝试简化
./configure \
    --host=aarch64-linux-ohos \
    --prefix=$(pwd)/install \
    CC=aarch64-unknown-linux-ohos-clang \
    CFLAGS="-fPIC -O2"
```

### 2.4 常见问题处理

**问题 1：configure 检测失败**

```bash
# 查看 config.log 诊断
tail -100 config.log

# 如果编译器检测失败，尝试
export ac_cv_func_malloc_0_nonnull=yes
export ac_cv_func_realloc_0_nonnull=yes
./configure --host=aarch64-linux-ohos
```

**问题 2：交叉编译标志不被识别**

```bash
# 尝试简化配置
./configure \
    --host=aarch64-linux-ohos \
    CC=aarch64-unknown-linux-ohos-clang \
    CFLAGS="-fPIC"
```

---

## 3. Makefile 构建系统

### 3.1 检测条件

**存在以下文件**：
- `Makefile` 或 `makefile`
- 可选：`Makefile.am`（Autotools 生成）
- 可选：`*.mk` 文件

**检测命令**：
```bash
cd libs/<库名>/

# 检查 Makefile
if [ -f "Makefile" ] || [ -f "makefile" ]; then
    echo "✓ Makefile build system detected"
    
    # 检查是否有 Makefile.am（说明是 Autotools 生成的）
    if [ -f "Makefile.am" ]; then
        echo "  - Has Makefile.am (Autotools-generated)"
    fi
fi
```

### 3.2 环境变量设置

**设置交叉编译变量**：

```bash
# 编译器
export CC=aarch64-unknown-linux-ohos-clang
export CXX=aarch64-unknown-linux-ohos-clang++
export AR=aarch64-unknown-linux-ohos-ar
export RANLIB=aarch64-unknown-linux-ohos-ranlib

# 编译标志
export CFLAGS="-fPIC -march=armv8-a -O2"
export CXXFLAGS="-fPIC -march=armv8-a -O2"
export LDFLAGS=""

# 或者直接覆盖 Makefile 中的变量
```

### 3.3 Makefile 适配检查

**检查 Makefile 中的平台检测**：

```bash
# 检查平台检测逻辑
grep -n "uname\|WIN32\|_WIN32\|MSYS\|Linux" Makefile

# 检查编译器设置
grep -n "^CC\|^CXX" Makefile
```

**如果需要，修改 Makefile**：

```makefile
# 在 Makefile 开头添加
# HarmonyOS Cross-Compilation
CC = aarch64-unknown-linux-ohos-clang
CXX = aarch64-unknown-linux-ohos-clang++
AR = aarch64-unknown-linux-ohos-ar
CFLAGS = -fPIC -march=armv8-a -O2
CXXFLAGS = -fPIC -march=armv8-a -O2
```

### 3.4 编译命令

**标准 Make 编译流程**：

```bash
# 清理（可选）
make clean

# 编译
make -j$(nproc)

# 或者指定变量
make CC=aarch64-unknown-linux-ohos-clang \
     CXX=aarch64-unknown-linux-ohos-clang++ \
     CFLAGS="-fPIC -march=armv8-a" \
     -j$(nproc)

# 安装（如果需要）
make install PREFIX=$(pwd)/install
```

---

## 4. GN 构建系统

### 4.1 检测条件

**存在以下文件**：
- `BUILD.gn`
- `.gn` 文件（如 `args.gn`）

**检测命令**：
```bash
cd libs/<库名>/

# 检查 GN 文件
if [ -f "BUILD.gn" ]; then
    echo "✓ GN build system detected"
    
    # 检查是否有 args.gn
    if [ -f "args.gn" ]; then
        echo "  - Has args.gn configuration"
    fi
fi
```

### 4.2 args.gn 配置

**创建 HarmonyOS 配置**：

创建 `args-ohos.gn`：

```gn
# HarmonyOS ARM64 Configuration

target_os = "ohos"
target_cpu = "arm64"

# Compiler configuration
is_clang = true
clang_use_chrome_plugins = false

# C/C++ flags
cflags = [
  "--target=aarch64-linux-ohos",
  "-march=armv8-a",
  "-fPIC",
  "-O2",
]

cxxflags = [
  "--target=aarch64-linux-ohos",
  "-march=armv8-a",
  "-fPIC",
  "-O2",
]

# Sysroot
sysroot = "/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/command-line-tools/sdk/default/openharmony/native/llvm/sysroot"

# Disable features not needed
is_debug = false
use_custom_libcxx = false
```

### 4.5 GN 编译命令

**标准 GN 编译流程**：

```bash
# 生成构建文件
gn gen out/ohos-arm64 --args-file=args-ohos.gn

# 或者命令行指定
gn gen out/ohos-arm64 --args='
  target_os = "ohos"
  target_cpu = "arm64"
  is_clang = true
  sysroot = "/path/to/sysroot"
'

# 编译
ninja -C out/ohos-arm64

# 安装（如果需要）
ninja -C out/ohos-arm64 install
```

---

## 5. 构建系统决策树

```
开始
  │
  ▼
检查 CMakeLists.txt？
  │
  ├─ 是 → CMake 构建系统 → 生成 toolchain-ohos-arm64.cmake
  │
  └─ 否
      │
      ▼
  检查 configure.ac + configure？
      │
      ├─ 是 → Autotools 构建系统 → 设置环境变量
      │
      └─ 否
          │
          ▼
      检查 Makefile？
          │
          ├─ 是 → Makefile 构建系统 → 覆盖 CC/CXX 变量
          │
          └─ 否
              │
              ▼
          检查 BUILD.gn？
              │
              ├─ 是 → GN 构建系统 → 创建 args-ohos.gn
              │
              └─ 否 → ❌ 未知构建系统 → 询问用户
```

---

## 6. 配置验证

**在开始编译前，验证配置正确性**：

### 6.1 CMake 验证

```bash
cd build/

# 检查 CMakeCache.txt
grep "CMAKE_SYSTEM_NAME" CMakeCache.txt
# 应该输出：CMAKE_SYSTEM_NAME:STRING=Linux

grep "CMAKE_C_COMPILER" CMakeCache.txt
# 应该输出：CMAKE_C_COMPILER:FILEPATH=aarch64-unknown-linux-ohos-clang

grep "CMAKE_CROSSCOMPILING" CMakeCache.txt
# 应该输出：CMAKE_CROSSCOMPILING:INTERNAL=1
```

### 6.2 Autotools 验证

```bash
# 检查 config.status
grep "host" config.status
# 应该输出：s/host=aarch64-unknown-linux-ohos/

# 检查 config.log
grep "aarch64-unknown-linux-ohos-clang" config.log
# 应该找到编译器使用记录
```

### 6.3 Makefile 验证

```bash
# 输出编译器配置
make -n | head -20
# 应该显示 aarch64-unknown-linux-ohos-clang 而非 gcc
```

---

## 7. AI 执行检查清单

在开始编译前，确认已完成：

- [ ] 构建系统类型已识别
- [ ] 配置文件已生成（toolchain 文件 / args.gn）
- [ ] 环境变量已设置（如需要）
- [ ] Makefile/CMakeLists.txt 已检查（平台相关配置）
- [ ] 配置验证通过
- [ ] 编译命令已记录

---

## 下一步

构建系统配置完成后 → **Phase 4-2/3/4: 执行编译**

根据构建系统类型，进入对应的编译文档：
- CMake → `docs/10-cmake-build.md`
- Autotools → `docs/11-autotools-build.md`
- Makefile → `docs/12-makefile-build.md`
- GN → `docs/13-gn-build.md`
