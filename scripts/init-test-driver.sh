#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/init-test-driver.sh --lib-name <name> [--language c|cpp] [--force]

Creates:
  libs/<lib>/test-driver/main.<c|cpp>
  libs/<lib>/test-driver/build-test-binary.sh

The generated binary is expected at:
  outputs/<lib>/bin/<lib>-smoke
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LIB_NAME=""
LANGUAGE="c"
FORCE="false"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

write_file() {
  local path="$1"
  local content="$2"

  if [[ -e "$path" && "$FORCE" != "true" ]]; then
    echo "Skip existing file: $path"
    return 0
  fi

  printf '%s\n' "$content" > "$path"
  echo "Created: $path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lib-name)
      LIB_NAME="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "$LIB_NAME" ]] || { usage; fail "--lib-name is required."; }
[[ "$LANGUAGE" == "c" || "$LANGUAGE" == "cpp" ]] || fail "--language must be c or cpp."

DRIVER_DIR="$PORTING_ROOT/libs/$LIB_NAME/test-driver"
OUTPUT_BIN_DIR="$PORTING_ROOT/outputs/$LIB_NAME/bin"
mkdir -p "$DRIVER_DIR" "$OUTPUT_BIN_DIR"

if [[ "$LANGUAGE" == "c" ]]; then
  MAIN_FILE="$DRIVER_DIR/main.c"
  MAIN_CONTENT=$(cat <<EOF
#include <stdio.h>

int main(void) {
  puts("$LIB_NAME minimal test driver: replace this with a real API call.");
  return 0;
}
EOF
)
  DRIVER_CC='${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang'
  DRIVER_FLAGS='-fPIC'
else
  MAIN_FILE="$DRIVER_DIR/main.cpp"
  MAIN_CONTENT=$(cat <<EOF
#include <iostream>

int main() {
  std::cout << "$LIB_NAME minimal test driver: replace this with a real API call." << std::endl;
  return 0;
}
EOF
)
  DRIVER_CC='${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang++'
  DRIVER_FLAGS='-fPIC -std=c++17'
fi

BUILD_SCRIPT="$DRIVER_DIR/build-test-binary.sh"
BUILD_CONTENT=$(cat <<EOF
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../../.." && pwd)"
COMMAND_LINE_TOOLS_ROOT="\${COMMAND_LINE_TOOLS_ROOT:-\$ROOT_DIR/../command-line-tools}"
OHOS_SDK="\${OHOS_SDK:-\$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony}"
OUTPUT_BIN_DIR="\$ROOT_DIR/outputs/$LIB_NAME/bin"
TARGET_BIN="\$OUTPUT_BIN_DIR/$LIB_NAME-smoke"

mkdir -p "\$OUTPUT_BIN_DIR"

$DRIVER_CC \\
  $DRIVER_FLAGS \\
  "\$(dirname "\${BASH_SOURCE[0]}")/$(basename "$MAIN_FILE")" \\
  -o "\$TARGET_BIN"

echo "Generated minimal test binary: \$TARGET_BIN"
echo "Add include paths, library paths, and -l flags for $LIB_NAME before using this driver in Phase 5."
EOF
)

write_file "$MAIN_FILE" "$MAIN_CONTENT"
write_file "$BUILD_SCRIPT" "$BUILD_CONTENT"
chmod +x "$BUILD_SCRIPT"
