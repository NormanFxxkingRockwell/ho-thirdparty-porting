#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LYCIUM_ROOT="${LYCIUM_ROOT:-$PORTING_ROOT/tpc_c_cplusplus}"
DEFAULT_ARCH="${DEFAULT_OHOS_ARCH:-arm64-v8a}"
DEVICE_TARGET_DIR_BASE="/data/local/tmp"
HAP_TEMPLATE="$PORTING_ROOT/templates/soTest-template.zip"
HAP_WORKDIR_BASE="$PORTING_ROOT/tmp/hap-test"
HAP_SIGNTOOLS_PATH="${HAP_SIGNTOOLS_PATH:-$PORTING_ROOT/signTools/hapsigner.zip}"
DEVECO_STUDIO_HOME="${DEVECO_STUDIO_HOME:-}"
HAP_OHPM_PATH="${HAP_OHPM_PATH:-}"
HAP_HVIGOR_PATH="${HAP_HVIGOR_PATH:-}"
HAP_JAVA_PATH="${HAP_JAVA_PATH:-}"
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

find_deveco_studio() {
  local candidates=()

  if [[ -n "$DEVECO_STUDIO_HOME" ]]; then
    candidates+=(
      "$DEVECO_STUDIO_HOME/bin/devecostudio"
      "$DEVECO_STUDIO_HOME/bin/devecostudio64.exe"
      "$DEVECO_STUDIO_HOME/bin/devecostudio.exe"
    )
  fi

  if command -v devecostudio >/dev/null 2>&1; then
    candidates+=("$(command -v devecostudio)")
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    local win_deveco
    win_deveco="$(
      powershell.exe -NoProfile -NonInteractive -Command "\
        \$cmd = Get-Command devecostudio64.exe -ErrorAction SilentlyContinue; \
        if (-not \$cmd) { \$cmd = Get-Command devecostudio.exe -ErrorAction SilentlyContinue }; \
        if (\$cmd) { \$cmd.Source }" 2>/dev/null | tr -d '\r' | sed -n '1p'
    )"
    if [[ -n "$win_deveco" ]]; then
      candidates+=("$win_deveco")
    fi
  fi

  candidates+=(
    "/mnt/c/Program Files/Huawei/DevEco Studio/bin/devecostudio64.exe"
    "/mnt/c/Program Files/Huawei/DevEco Studio/bin/devecostudio.exe"
    "/mnt/d/Program Files/Huawei/DevEco Studio/bin/devecostudio64.exe"
    "/mnt/d/Program Files/Huawei/DevEco Studio/bin/devecostudio.exe"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -e "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

find_cross_host_command() {
  local env_name="$1"
  shift
  local configured="${!env_name:-}"
  local candidate

  if [[ -n "$configured" ]]; then
    printf 'configured|%s\n' "$configured"
    return 0
  fi

  for candidate in "$@"; do
    if [[ "$candidate" == */* || "$candidate" == *\\* ]]; then
      if [[ -e "$candidate" ]]; then
        if [[ "$candidate" == *.exe || "$candidate" == *.bat ]]; then
          printf 'windows|%s\n' "$candidate"
        else
          printf 'wsl|%s\n' "$candidate"
        fi
        return 0
      fi
      continue
    fi

    if command -v "$candidate" >/dev/null 2>&1; then
      printf 'wsl|%s\n' "$(command -v "$candidate")"
      return 0
    fi
  done

  if command -v powershell.exe >/dev/null 2>&1; then
    local win_command
    for candidate in "$@"; do
      [[ "$candidate" == */* || "$candidate" == *\\* ]] && continue
      win_command="$(
        powershell.exe -NoProfile -NonInteractive -Command "\$cmd = Get-Command '$candidate' -ErrorAction SilentlyContinue; if (\$cmd) { \$cmd.Source }" 2>/dev/null \
          | tr -d '\r' \
          | sed -n '1p'
      )"
      if [[ -n "$win_command" ]]; then
        printf 'windows|%s\n' "$win_command"
        return 0
      fi
    done
  fi

  return 1
}

find_deveco_java() {
  local deveco_bin="$1"
  [[ -n "$deveco_bin" && "$deveco_bin" == /mnt/* ]] || return 1

  local studio_root
  studio_root="$(cd "$(dirname "$deveco_bin")/.." && pwd)"
  local candidates=(
    "$studio_root/jbr/bin/java"
    "$studio_root/jbr/bin/java.exe"
    "$studio_root/jre/bin/java"
    "$studio_root/jre/bin/java.exe"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -e "$candidate" ]]; then
      printf 'windows|%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

check_hap_template_project() {
  [[ -f "$HAP_TEMPLATE" ]] || return 1
  unzip -l "$HAP_TEMPLATE" >/dev/null 2>&1 || return 1
  local zip_list
  zip_list="$(unzip -Z1 "$HAP_TEMPLATE" 2>/dev/null || true)"
  [[ "$zip_list" == *"soTest/entry/src/main/cpp/CMakeLists.txt"* ]] || return 1
  [[ "$zip_list" == *"soTest/entry/src/main/cpp/napi_init.cpp"* ]] || return 1
  [[ "$zip_list" == *"soTest/entry/src/main/ets/pages/Index.ets"* ]] || return 1
}

check_hap_project_signing() {
  [[ -f "$HAP_TEMPLATE" ]] || return 1
  local profile
  profile="$(unzip -p "$HAP_TEMPLATE" 'soTest/build-profile.json5' 2>/dev/null | tr -d '[:space:]' || true)"
  [[ -n "$profile" ]] || return 1
  [[ "$profile" == *'"signingConfigs":[]'* ]] && return 1
  [[ "$profile" == *'"signingConfigs":['* ]] || return 1
}

check_hap_signtools_bundle() {
  [[ -f "$HAP_SIGNTOOLS_PATH" ]] || return 1
  unzip -l "$HAP_SIGNTOOLS_PATH" >/dev/null 2>&1 || return 1

  local zip_list
  zip_list="$(unzip -Z1 "$HAP_SIGNTOOLS_PATH" 2>/dev/null || true)"
  local required=(
    "hapsigner/hap-sign-tool.jar"
    "hapsigner/OpenHarmony.p12"
    "hapsigner/OpenHarmonyApplication.pem"
    "hapsigner/OpenHarmonyProfileDebug.pem"
    "hapsigner/UnsgnedDebugProfileTemplate.json"
  )
  local entry
  for entry in "${required[@]}"; do
    [[ "$zip_list" == *"$entry"* ]] || return 1
  done
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

  local hap_template_ready="false"
  local hap_project_config_ready="false"
  local hap_project_signing_ready="false"
  local hap_signtools_ready="false"
  local hap_signing_mode="not-ready"
  local hap_signing_ready="false"
  local hap_deveco_path="not-found"
  local hap_deveco_ready="false"
  local hap_ohpm_path
  local hap_hvigor_path
  local hap_java_path="not-found"
  local hap_ohpm_host="not-found"
  local hap_hvigor_host="not-found"
  local hap_java_host="not-found"
  local hap_ohpm_ready="false"
  local hap_hvigor_ready="false"
  local hap_java_ready="false"
  local hap_automated_build_ready="false"
  local hap_device_ready="$hdc_device_test_ready"
  local hap_env_ready="false"
  local hap_windows_bridge_ready="false"
  local found_command

  if command -v powershell.exe >/dev/null 2>&1; then
    hap_windows_bridge_ready="true"
  fi

  if [[ -f "$HAP_TEMPLATE" ]]; then
    hap_template_ready="true"
  fi
  if check_hap_template_project; then
    hap_project_config_ready="true"
  fi
  if check_hap_project_signing; then
    hap_project_signing_ready="true"
  fi
  if check_hap_signtools_bundle; then
    hap_signtools_ready="true"
  fi
  if hap_deveco_path="$(find_deveco_studio)"; then
    hap_deveco_ready="true"
  else
    hap_deveco_path="not-found"
  fi

  if found_command="$(find_cross_host_command HAP_OHPM_PATH "$COMMAND_LINE_TOOLS_ROOT/bin/ohpm" "$COMMAND_LINE_TOOLS_ROOT/bin/ohpm.bat" ohpm ohpm.bat)"; then
    hap_ohpm_host="${found_command%%|*}"
    hap_ohpm_path="${found_command#*|}"
    hap_ohpm_ready="true"
  else
    hap_ohpm_path="not-found"
  fi
  if found_command="$(find_cross_host_command HAP_HVIGOR_PATH "$COMMAND_LINE_TOOLS_ROOT/bin/hvigorw" "$COMMAND_LINE_TOOLS_ROOT/bin/hvigorw.bat" "$COMMAND_LINE_TOOLS_ROOT/bin/hvigor" "$COMMAND_LINE_TOOLS_ROOT/bin/hvigor.bat" hvigorw hvigorw.bat hvigor)"; then
    hap_hvigor_host="${found_command%%|*}"
    hap_hvigor_path="${found_command#*|}"
    hap_hvigor_ready="true"
  else
    hap_hvigor_path="not-found"
  fi
  if found_command="$(find_cross_host_command HAP_JAVA_PATH java java.exe java.cmd)"; then
    hap_java_host="${found_command%%|*}"
    hap_java_path="${found_command#*|}"
    hap_java_ready="true"
  elif [[ "$hap_deveco_ready" == "true" ]] && found_command="$(find_deveco_java "$hap_deveco_path")"; then
    hap_java_host="${found_command%%|*}"
    hap_java_path="${found_command#*|}"
    hap_java_ready="true"
  fi
  if [[ "$hap_ohpm_ready" == "true" && "$hap_hvigor_ready" == "true" && "$hap_java_ready" == "true" ]]; then
    hap_automated_build_ready="true"
  fi
  if [[ "$hap_project_signing_ready" == "true" ]]; then
    hap_signing_mode="project-config"
    hap_signing_ready="true"
  elif [[ "$hap_signtools_ready" == "true" ]]; then
    hap_signing_mode="external-signTools"
    if [[ "$hap_java_ready" == "true" ]]; then
      hap_signing_ready="true"
    fi
  fi
  if [[ "$hap_project_config_ready" == "true" && "$hap_automated_build_ready" == "true" && "$hap_signing_ready" == "true" && "$hap_device_ready" == "true" ]]; then
    hap_env_ready="true"
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
HAP_TEMPLATE_PATH=$HAP_TEMPLATE
HAP_TEMPLATE_READY=$hap_template_ready
HAP_PROJECT_CONFIG_READY=$hap_project_config_ready
HAP_WORKDIR_BASE=$HAP_WORKDIR_BASE
HAP_DEVECO_READY=$hap_deveco_ready
HAP_DEVECO_PATH=$hap_deveco_path
HAP_WINDOWS_BRIDGE_READY=$hap_windows_bridge_ready
HAP_OHPM_READY=$hap_ohpm_ready
HAP_OHPM_HOST=$hap_ohpm_host
HAP_OHPM_PATH=$hap_ohpm_path
HAP_HVIGOR_READY=$hap_hvigor_ready
HAP_HVIGOR_HOST=$hap_hvigor_host
HAP_HVIGOR_PATH=$hap_hvigor_path
HAP_JAVA_READY=$hap_java_ready
HAP_JAVA_HOST=$hap_java_host
HAP_JAVA_PATH=$hap_java_path
HAP_AUTOMATED_BUILD_READY=$hap_automated_build_ready
HAP_SIGNTOOLS_PATH=$HAP_SIGNTOOLS_PATH
HAP_SIGNTOOLS_READY=$hap_signtools_ready
HAP_PROJECT_SIGNING_READY=$hap_project_signing_ready
HAP_SIGNING_MODE=$hap_signing_mode
HAP_SIGNING_READY=$hap_signing_ready
HAP_DEVICE_READY=$hap_device_ready
HAP_ENV_READY=$hap_env_ready
EOF
}

main "$@"
