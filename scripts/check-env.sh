#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LYCIUM_ROOT="${LYCIUM_ROOT:-$PORTING_ROOT/tpc_c_cplusplus}"
DEFAULT_ARCH="${DEFAULT_OHOS_ARCH:-arm64-v8a}"
DEVICE_TARGET_DIR_BASE="/data/local/tmp"
MODE="base"
HOST_TOOLS=(
  gcc
  g++
  cmake
  make
  pkg-config
  autoconf
  autoreconf
  automake
  patch
  unzip
  tar
  git
  ninja
  curl
  sha512sum
  wget
)

usage() {
  cat <<EOF
Usage: bash scripts/check-env.sh [--mode base|lycium]

Modes:
  base    Check Linux/WSL, Command Line Tools, OHOS_SDK, ARM64 toolchain, SDK cmake, toolchain file,
          and basic device connection state.
  lycium  Run base checks, then additionally check lycium host-side prerequisites.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        [[ $# -ge 2 ]] || { echo "ERROR: --mode requires a value." >&2; exit 1; }
        MODE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "ERROR: unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$MODE" in
    base|lycium) ;;
    *)
      echo "ERROR: unsupported mode: $MODE" >&2
      usage >&2
      exit 1
      ;;
  esac
}

find_command_line_tools_root() {
  if [[ -n "${COMMAND_LINE_TOOLS_ROOT:-}" && -x "${COMMAND_LINE_TOOLS_ROOT}/sdk/default/openharmony/native/llvm/bin/clang" ]]; then
    printf '%s\n' "${COMMAND_LINE_TOOLS_ROOT}"
    return 0
  fi

  local candidates=(
    "$PORTING_ROOT/../command-line-tools"
    "$PORTING_ROOT/command-line-tools"
    "$HOME/command-line-tools"
    "/opt/command-line-tools"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate/sdk/default/openharmony/native/llvm/bin/clang" ]]; then
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

check_host_tools() {
  local missing=()
  local tool
  for tool in "${HOST_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "ERROR: missing host build tools required by lycium:" >&2
    printf '  - %s\n' "${missing[@]}" >&2
    exit 1
  fi
}

collect_hdc_candidates() {
  local candidates=()

  if [[ -n "${HDC_PATH:-}" && -x "${HDC_PATH}" ]]; then
    candidates+=("${HDC_PATH}")
  fi

  if command -v hdc >/dev/null 2>&1; then
    candidates+=("$(command -v hdc)")
  fi

  local defaults=(
    "$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony/toolchains/hdc"
    "/mnt/c/Users/aoqiduan/Desktop/env/OH_SDK/ohos-sdk/toolchains/hdc.exe"
  )

  local candidate
  for candidate in "${defaults[@]}"; do
    if [[ -x "$candidate" ]]; then
      candidates+=("$candidate")
    fi
  done

  printf '%s\n' "${candidates[@]}" | awk 'NF && !seen[$0]++'
}

list_hdc_targets() {
  local hdc_bin="$1"
  "$hdc_bin" list targets 2>/dev/null | tr -d '\r' | sed '/^[[:space:]]*$/d' || true
}

main() {
  parse_args "$@"

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
  local sdk_cmake="$OHOS_SDK/native/build-tools/cmake/bin/cmake"
  local toolchain_file="$OHOS_SDK/native/build/cmake/ohos.toolchain.cmake"

  [[ -x "$OHOS_SDK/native/llvm/bin/clang" ]] || { echo "ERROR: clang not found under OHOS_SDK: $OHOS_SDK" >&2; exit 1; }
  if [[ ! -e "$OHOS_SDK/native/llvm/bin/aarch64-linux-ohos-clang" && ! -e "$OHOS_SDK/native/llvm/bin/aarch64-unknown-linux-ohos-clang" ]]; then
    echo "ERROR: no ARM64 HarmonyOS compiler found under: $OHOS_SDK/native/llvm/bin" >&2
    exit 1
  fi
  [[ -x "$sdk_cmake" ]] || { echo "ERROR: SDK cmake not found at: $sdk_cmake" >&2; exit 1; }
  [[ -f "$toolchain_file" ]] || { echo "ERROR: HarmonyOS toolchain file not found at: $toolchain_file" >&2; exit 1; }

  ensure_lycium_repo
  [[ -f "$LYCIUM_ROOT/lycium/template/HPKBUILD" ]] || { echo "ERROR: lycium template/HPKBUILD is missing." >&2; exit 1; }

  local lycium_ready="skipped"
  if [[ "$MODE" == "lycium" ]]; then
    check_host_tools
    lycium_ready="true"
  fi

  local hdc_path=""
  local hdc_ready="false"
  local device_connected="false"
  local hdc_targets="none"
  local hdc_device_test_ready="false"
  local fallback_hdc_path=""
  local fallback_hdc_targets="none"
  local candidate
  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    hdc_ready="true"
    local targets_raw
    targets_raw="$(list_hdc_targets "$candidate")"
    local targets
    targets="$(printf '%s\n' "$targets_raw" | tr '\n' ',' | sed 's/,$//')"

    if [[ -z "$fallback_hdc_path" ]]; then
      fallback_hdc_path="$candidate"
      if [[ -n "$targets" && "$targets" != "[Empty]" ]]; then
        fallback_hdc_targets="$targets"
      fi
    fi

    if [[ -n "$targets" && "$targets" != "[Empty]" ]]; then
      hdc_path="$candidate"
      hdc_targets="$targets"
      device_connected="true"
      hdc_device_test_ready="true"
      break
    fi
  done < <(collect_hdc_candidates)

  if [[ -z "$hdc_path" && -n "$fallback_hdc_path" ]]; then
    hdc_path="$fallback_hdc_path"
    hdc_targets="$fallback_hdc_targets"
  fi

  cat <<EOF
Environment check passed.
MODE=$MODE
PORTING_ROOT=$PORTING_ROOT
COMMAND_LINE_TOOLS_ROOT=$COMMAND_LINE_TOOLS_ROOT
OHOS_SDK=$OHOS_SDK
OHOS_NDK_ROOT=$OHOS_NDK_ROOT
OHOS_CMAKE=$sdk_cmake
OHOS_TOOLCHAIN_FILE=$toolchain_file
LYCIUM_ROOT=$LYCIUM_ROOT
DEFAULT_OHOS_ARCH=$DEFAULT_ARCH
IS_WSL=$is_wsl
BASE_ENV_READY=true
LYCIUM_ENV_READY=$lycium_ready
HDC_PATH=${hdc_path:-not-found}
HDC_READY=$hdc_ready
HDC_TARGETS=$hdc_targets
DEVICE_CONNECTED=$device_connected
HDC_DEVICE_TEST_READY=$hdc_device_test_ready
DEVICE_TEST_READY=$hdc_device_test_ready
DEVICE_TARGET_DIR_BASE=$DEVICE_TARGET_DIR_BASE
EOF
}

main "$@"
