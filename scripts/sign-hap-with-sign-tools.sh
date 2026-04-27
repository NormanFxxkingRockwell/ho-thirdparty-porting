#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: bash scripts/sign-hap-with-sign-tools.sh --unsigned-hap <path> [options]

Options:
  --unsigned-hap <path>   Unsigned HAP to sign. Required.
  --bundle-name <name>    Optional bundle name to write into UnsgnedDebugProfileTemplate.json.
  --sign-tools <zip>      signTools zip. Defaults to signTools/hapsigner.zip.
  --workdir <dir>         Signing workdir. Defaults to tmp/hap-sign/<hap-basename>.
  --java <path>           Java executable. Defaults to HAP_JAVA_PATH or java.
  --keep-existing         Do not remove an existing workdir before extraction.

Outputs:
  SIGN_RUN_DIR=<dir>
  SIGNED_PROFILE=<path>
  SIGNED_HAP=<path>

This wrapper intentionally uses shell arrays so key aliases containing spaces are
passed to hap-sign-tool.jar as single argument values.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

UNSIGNED_HAP=""
BUNDLE_NAME=""
SIGNTOOLS_ZIP="$PORTING_ROOT/signTools/hapsigner.zip"
WORKDIR=""
JAVA_BIN="${HAP_JAVA_PATH:-java}"
KEEP_EXISTING="false"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

safe_clean_workdir() {
  local target="$1"
  local base="$PORTING_ROOT/tmp/hap-sign"
  local target_abs
  local base_abs

  target_abs="$(realpath -m "$target")"
  base_abs="$(realpath -m "$base")"

  case "$target_abs" in
    "$base_abs"/*) rm -rf -- "$target_abs" ;;
    *) fail "refuse to clean path outside tmp/hap-sign: $target_abs" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --unsigned-hap)
      UNSIGNED_HAP="$2"
      shift 2
      ;;
    --bundle-name)
      BUNDLE_NAME="$2"
      shift 2
      ;;
    --sign-tools)
      SIGNTOOLS_ZIP="$2"
      shift 2
      ;;
    --workdir)
      WORKDIR="$2"
      shift 2
      ;;
    --java)
      JAVA_BIN="$2"
      shift 2
      ;;
    --keep-existing)
      KEEP_EXISTING="true"
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

[[ -n "$UNSIGNED_HAP" ]] || { usage; fail "--unsigned-hap is required."; }
[[ -f "$UNSIGNED_HAP" ]] || fail "unsigned HAP not found: $UNSIGNED_HAP"
[[ -f "$SIGNTOOLS_ZIP" ]] || fail "sign tools zip not found: $SIGNTOOLS_ZIP"
command -v unzip >/dev/null 2>&1 || fail "unzip is required."

if [[ "$JAVA_BIN" != */* && "$JAVA_BIN" != *\\* ]]; then
  command -v "$JAVA_BIN" >/dev/null 2>&1 || fail "java executable not found: $JAVA_BIN"
else
  [[ -x "$JAVA_BIN" || -f "$JAVA_BIN" ]] || fail "java executable not found: $JAVA_BIN"
fi

if [[ -z "$WORKDIR" ]]; then
  hap_base="$(basename "$UNSIGNED_HAP")"
  hap_base="${hap_base%.hap}"
  WORKDIR="$PORTING_ROOT/tmp/hap-sign/$hap_base"
fi

if [[ "$KEEP_EXISTING" != "true" && -e "$WORKDIR" ]]; then
  safe_clean_workdir "$WORKDIR"
fi

mkdir -p "$WORKDIR"
unzip -q "$SIGNTOOLS_ZIP" -d "$WORKDIR"

SIGNER_DIR="$(find "$WORKDIR" -maxdepth 3 -type f -name 'hap-sign-tool.jar' -printf '%h\n' | head -n 1 || true)"
[[ -n "$SIGNER_DIR" && -d "$SIGNER_DIR" ]] || fail "failed to locate hap-sign-tool.jar under: $WORKDIR"

cp "$UNSIGNED_HAP" "$SIGNER_DIR/entry-default-unsigned.hap"

PROFILE_TEMPLATE="$SIGNER_DIR/UnsgnedDebugProfileTemplate.json"
[[ -f "$PROFILE_TEMPLATE" ]] || fail "profile template not found: $PROFILE_TEMPLATE"

if [[ -n "$BUNDLE_NAME" ]]; then
  command -v python3 >/dev/null 2>&1 || fail "python3 is required to update bundle-name."
  python3 - "$PROFILE_TEMPLATE" "$BUNDLE_NAME" <<'PY'
import json
import sys

path = sys.argv[1]
bundle_name = sys.argv[2]
with open(path, "r", encoding="utf-8-sig") as f:
    data = json.load(f)
data.setdefault("bundle-info", {})["bundle-name"] = bundle_name
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write("\n")
PY
fi

pushd "$SIGNER_DIR" >/dev/null

profile_cmd=(
  "$JAVA_BIN" -jar hap-sign-tool.jar sign-profile
  -mode localSign
  -keyAlias "OpenHarmony Application Profile Debug"
  -keyPwd 123456
  -inFile UnsgnedDebugProfileTemplate.json
  -outFile ohos_provision_debug.p7b
  -keystoreFile OpenHarmony.p12
  -keystorePwd 123456
  -signAlg SHA256withECDSA
  -profileCertFile OpenHarmonyProfileDebug.pem
)

app_cmd=(
  "$JAVA_BIN" -jar hap-sign-tool.jar sign-app
  -keyAlias "openharmony application release"
  -signAlg SHA256withECDSA
  -mode localSign
  -appCertFile OpenHarmonyApplication.pem
  -profileFile ohos_provision_debug.p7b
  -inFile entry-default-unsigned.hap
  -keystoreFile OpenHarmony.p12
  -outFile signApp.hap
  -keyPwd 123456
  -keystorePwd 123456
)

"${profile_cmd[@]}"
"${app_cmd[@]}"

popd >/dev/null

cat <<EOF
SIGN_RUN_DIR=$SIGNER_DIR
SIGNED_PROFILE=$SIGNER_DIR/ohos_provision_debug.p7b
SIGNED_HAP=$SIGNER_DIR/signApp.hap
EOF
