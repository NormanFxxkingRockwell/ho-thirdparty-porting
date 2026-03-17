#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LYCIUM_ROOT="${LYCIUM_ROOT:-$PORTING_ROOT/tpc_c_cplusplus}"
DEFAULT_ARCH="${DEFAULT_OHOS_ARCH:-arm64-v8a}"

find_command_line_tools_root() {
  if [[ -n "${COMMAND_LINE_TOOLS_ROOT:-}" && -d "${COMMAND_LINE_TOOLS_ROOT}" ]]; then
    printf '%s\n' "${COMMAND_LINE_TOOLS_ROOT}"
    return 0
  fi

  local candidates=(
    "$PORTING_ROOT/../command-line-tools"
    "$HOME/command-line-tools"
    "/opt/command-line-tools"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ensure_lycium_repo() {
  if [[ -f "$LYCIUM_ROOT/lycium/build.sh" ]]; then
    return 0
  fi

  echo "lycium repository not found at: $LYCIUM_ROOT"
  echo "Trying to clone tpc_c_cplusplus into the current repository..."
  git clone https://gitcode.com/openharmony-sig/tpc_c_cplusplus.git "$LYCIUM_ROOT"
}

main() {
  local uname_s
  uname_s="$(uname -s)"
  local is_wsl="false"
  if grep -qi microsoft /proc/version 2>/dev/null; then
    is_wsl="true"
  fi

  if [[ "$uname_s" != "Linux" ]]; then
    echo "ERROR: Linux or WSL is required. Current system: $uname_s" >&2
    exit 1
  fi

  local clr
  if ! clr="$(find_command_line_tools_root)"; then
    echo "ERROR: COMMAND_LINE_TOOLS_ROOT not found automatically." >&2
    echo "Please update docs/00-paths.md or export COMMAND_LINE_TOOLS_ROOT first." >&2
    exit 1
  fi

  export COMMAND_LINE_TOOLS_ROOT="$clr"
  export OHOS_SDK="${OHOS_SDK:-$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony}"
  export OHOS_NDK_ROOT="${OHOS_NDK_ROOT:-$OHOS_SDK/native}"

  if [[ ! -x "$OHOS_SDK/native/llvm/bin/clang" ]]; then
    echo "ERROR: clang not found under OHOS_SDK: $OHOS_SDK" >&2
    exit 1
  fi

  if [[ ! -e "$OHOS_SDK/native/llvm/bin/aarch64-linux-ohos-clang" && ! -e "$OHOS_SDK/native/llvm/bin/aarch64-unknown-linux-ohos-clang" ]]; then
    echo "ERROR: no ARM64 HarmonyOS compiler found under: $OHOS_SDK/native/llvm/bin" >&2
    exit 1
  fi

  ensure_lycium_repo

  if [[ ! -f "$LYCIUM_ROOT/lycium/template/HPKBUILD" ]]; then
    echo "ERROR: lycium template/HPKBUILD is missing." >&2
    exit 1
  fi

  cat <<EOF
Environment check passed.
PORTING_ROOT=$PORTING_ROOT
COMMAND_LINE_TOOLS_ROOT=$COMMAND_LINE_TOOLS_ROOT
OHOS_SDK=$OHOS_SDK
OHOS_NDK_ROOT=$OHOS_NDK_ROOT
LYCIUM_ROOT=$LYCIUM_ROOT
DEFAULT_OHOS_ARCH=$DEFAULT_ARCH
IS_WSL=$is_wsl
EOF
}

main "$@"

