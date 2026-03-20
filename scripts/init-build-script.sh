#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --lib-name <name> --build-system <cmake|configure|make|gn>
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LIB_NAME=""
BUILD_SYSTEM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lib-name)
      LIB_NAME="$2"
      shift 2
      ;;
    --build-system)
      BUILD_SYSTEM="$2"
      shift 2
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

[[ -n "$LIB_NAME" ]] || { usage; exit 1; }
[[ -n "$BUILD_SYSTEM" ]] || { usage; exit 1; }

TARGET_DIR="$PORTING_ROOT/libs/$LIB_NAME"
TARGET_FILE="$TARGET_DIR/build.sh"

mkdir -p "$TARGET_DIR"

case "$BUILD_SYSTEM" in
  cmake)
    TEMPLATE=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-$ROOT_DIR/../command-line-tools}"
OHOS_SDK="${OHOS_SDK:-$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony}"
OHOS_ARCH="${OHOS_ARCH:-arm64-v8a}"
TOOLCHAIN_FILE="${TOOLCHAIN_FILE:-$OHOS_SDK/native/build/cmake/ohos.toolchain.cmake}"
BUILD_DIR="$PROJECT_DIR/build"
INSTALL_DIR="$PROJECT_DIR/install"
OUTPUT_ROOT="$ROOT_DIR/outputs/__LIB_NAME__"
LIB_OUTPUT_DIR="$OUTPUT_ROOT/lib"
BIN_OUTPUT_DIR="$OUTPUT_ROOT/bin"

mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$LIB_OUTPUT_DIR" "$BIN_OUTPUT_DIR"

"$OHOS_SDK/native/build-tools/cmake/bin/cmake" -S "$PROJECT_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DOHOS_ARCH="$OHOS_ARCH" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

"$OHOS_SDK/native/build-tools/cmake/bin/cmake" --build "$BUILD_DIR" --parallel "$(nproc)"
"$OHOS_SDK/native/build-tools/cmake/bin/cmake" --install "$BUILD_DIR"

find "$INSTALL_DIR" -name '*.so*' -exec cp -f {} "$LIB_OUTPUT_DIR"/ \;
find "$INSTALL_DIR/bin" -maxdepth 1 -type f -perm -111 -exec cp -f {} "$BIN_OUTPUT_DIR"/ \; 2>/dev/null || true

echo "Fallback build finished."
echo "Library artifacts: $LIB_OUTPUT_DIR"
echo "Binary artifacts: $BIN_OUTPUT_DIR"
echo "Prefer upstream test program first; if unavailable, use upstream CLI for real capability validation."
EOF
)
    ;;
  configure)
    TEMPLATE=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-$ROOT_DIR/../command-line-tools}"
OHOS_SDK="${OHOS_SDK:-$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony}"
OUTPUT_ROOT="$ROOT_DIR/outputs/__LIB_NAME__"
LIB_OUTPUT_DIR="$OUTPUT_ROOT/lib"
BIN_OUTPUT_DIR="$OUTPUT_ROOT/bin"

export CC="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang"
export CXX="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang++"
export AR="${OHOS_SDK}/native/llvm/bin/llvm-ar"
export RANLIB="${OHOS_SDK}/native/llvm/bin/llvm-ranlib"
export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"

mkdir -p "$LIB_OUTPUT_DIR" "$BIN_OUTPUT_DIR"

cd "$PROJECT_DIR"
./configure --host=aarch64-linux-ohos --enable-shared --disable-static --prefix="$PROJECT_DIR/install"
make -j"$(nproc)"
make install

find "$PROJECT_DIR/install" -name '*.so*' -exec cp -f {} "$LIB_OUTPUT_DIR"/ \;
find "$PROJECT_DIR/install/bin" -maxdepth 1 -type f -perm -111 -exec cp -f {} "$BIN_OUTPUT_DIR"/ \; 2>/dev/null || true

echo "Fallback build finished."
echo "Library artifacts: $LIB_OUTPUT_DIR"
echo "Binary artifacts: $BIN_OUTPUT_DIR"
echo "Prefer upstream test program first; if unavailable, use upstream CLI for real capability validation."
EOF
)
    ;;
  make)
    TEMPLATE=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-$ROOT_DIR/../command-line-tools}"
OHOS_SDK="${OHOS_SDK:-$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony}"
OUTPUT_ROOT="$ROOT_DIR/outputs/__LIB_NAME__"
LIB_OUTPUT_DIR="$OUTPUT_ROOT/lib"
BIN_OUTPUT_DIR="$OUTPUT_ROOT/bin"

mkdir -p "$LIB_OUTPUT_DIR" "$BIN_OUTPUT_DIR"

cd "$PROJECT_DIR"
make CC="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang" \
  CXX="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang++" \
  CFLAGS="-fPIC" \
  CXXFLAGS="-fPIC" \
  -j"$(nproc)"

find "$PROJECT_DIR" -name '*.so*' -exec cp -f {} "$LIB_OUTPUT_DIR"/ \;
find "$PROJECT_DIR" -maxdepth 2 -type f -perm -111 ! -name '*.so*' -exec cp -f {} "$BIN_OUTPUT_DIR"/ \; 2>/dev/null || true

echo "Fallback build finished."
echo "Library artifacts: $LIB_OUTPUT_DIR"
echo "Binary artifacts: $BIN_OUTPUT_DIR"
echo "Prefer upstream test program first; if unavailable, use upstream CLI for real capability validation."
EOF
)
    ;;
  gn)
    TEMPLATE=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ROOT="$ROOT_DIR/outputs/__LIB_NAME__"
LIB_OUTPUT_DIR="$OUTPUT_ROOT/lib"
BIN_OUTPUT_DIR="$OUTPUT_ROOT/bin"

mkdir -p "$LIB_OUTPUT_DIR" "$BIN_OUTPUT_DIR"

echo "GN fallback requires project-specific args.gn and toolchain adjustments."
echo "Reserve output directories:"
echo "  $LIB_OUTPUT_DIR"
echo "  $BIN_OUTPUT_DIR"
echo "Customize this script before running."
exit 1
EOF
)
    ;;
  *)
    echo "Unsupported build system: $BUILD_SYSTEM" >&2
    exit 1
    ;;
esac

TEMPLATE="${TEMPLATE//__LIB_NAME__/$LIB_NAME}"

printf '%s\n' "$TEMPLATE" > "$TARGET_FILE"
chmod +x "$TARGET_FILE"

echo "Generated fallback build script: $TARGET_FILE"
