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
BUILD_DIR="$PROJECT_DIR/build"
INSTALL_DIR="$PROJECT_DIR/install"
OUTPUT_DIR="$ROOT_DIR/outputs/__LIB_NAME__"

mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

cmake --build "$BUILD_DIR" --parallel "$(nproc)"
cmake --install "$BUILD_DIR"

find "$INSTALL_DIR" -name '*.so*' -exec cp -f {} "$OUTPUT_DIR"/ \;
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
OUTPUT_DIR="$ROOT_DIR/outputs/__LIB_NAME__"

export CC="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang"
export CXX="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang++"
export AR="${OHOS_SDK}/native/llvm/bin/llvm-ar"
export RANLIB="${OHOS_SDK}/native/llvm/bin/llvm-ranlib"
export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"

mkdir -p "$OUTPUT_DIR"

cd "$PROJECT_DIR"
./configure --host=aarch64-linux-ohos --enable-shared --disable-static --prefix="$PROJECT_DIR/install"
make -j"$(nproc)"
make install

find "$PROJECT_DIR/install" -name '*.so*' -exec cp -f {} "$OUTPUT_DIR"/ \;
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
OUTPUT_DIR="$ROOT_DIR/outputs/__LIB_NAME__"

mkdir -p "$OUTPUT_DIR"

cd "$PROJECT_DIR"
make CC="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang" \
  CXX="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang++" \
  CFLAGS="-fPIC" \
  CXXFLAGS="-fPIC" \
  -j"$(nproc)"

find "$PROJECT_DIR" -name '*.so*' -exec cp -f {} "$OUTPUT_DIR"/ \;
EOF
)
    ;;
  gn)
    TEMPLATE=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$ROOT_DIR/outputs/__LIB_NAME__"

mkdir -p "$OUTPUT_DIR"

echo "GN fallback requires project-specific args.gn and toolchain adjustments."
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
