#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/clean-workspace.sh [--dry-run]

Default behavior:
  - clean outputs/, reports/, tmp/
  - clean generated library workspaces under libs/
  - keep task-sheet templates in libs/
  - clean build caches and logs under tpc_c_cplusplus/

Options:
  --dry-run   Show what would be removed without deleting anything.
  -h, --help  Show this help message.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN="false"

log_remove() {
  local path="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Would remove: $path"
  else
    echo "Removing: $path"
    rm -rf -- "$path"
  fi
}

should_keep_libs_entry() {
  local name="$1"
  case "$name" in
    .gitkeep|porting-tasks-template.xlsx|porting-tasks-模板.xlsx)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

clean_top_level_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  local entry
  for entry in "$dir"/* "$dir"/.*; do
    [[ -e "$entry" ]] || continue
    [[ "$(basename "$entry")" == "." || "$(basename "$entry")" == ".." ]] && continue
    [[ "$(basename "$entry")" == ".gitkeep" ]] && continue
    log_remove "$entry"
  done
}

clean_libs_dir() {
  local dir="$PORTING_ROOT/libs"
  [[ -d "$dir" ]] || return 0

  local entry name
  for entry in "$dir"/* "$dir"/.*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    if should_keep_libs_entry "$name"; then
      continue
    fi
    log_remove "$entry"
  done
}

clean_lycium_cache() {
  local root="$PORTING_ROOT/tpc_c_cplusplus"
  [[ -d "$root" ]] || return 0

  find "$root" -type d \
    \( -name build -o -name install -o -name CMakeFiles -o -name Testing -o -name '*-build' \
       -o -name arm64-v8a-build -o -name armeabi-v7a-build -o -name x86_64-build \) \
    -print0 |
  while IFS= read -r -d '' path; do
    log_remove "$path"
  done

  find "$root" -type f \( -name '*.log' -o -name '*.rej' \) -print0 |
  while IFS= read -r -d '' path; do
    log_remove "$path"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN="true"
      shift
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

clean_top_level_dir "$PORTING_ROOT/outputs"
clean_top_level_dir "$PORTING_ROOT/reports"
clean_top_level_dir "$PORTING_ROOT/tmp"
clean_libs_dir
clean_lycium_cache

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete."
else
  echo "Workspace cleanup complete."
fi
