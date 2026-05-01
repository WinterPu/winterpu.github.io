#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTENT_DIR="$ROOT_DIR/content"
STATIC_DIR="$ROOT_DIR/static"
STATE_DIR="$ROOT_DIR/.content-assets-sync"
MANIFEST_FILE="$STATE_DIR/targets.txt"

mkdir -p "$STATIC_DIR"
mkdir -p "$STATE_DIR"

if [[ -f "$MANIFEST_FILE" ]]; then
  while IFS= read -r target_dir; do
    [[ -n "$target_dir" ]] && rm -rf "$target_dir"
  done < "$MANIFEST_FILE"
fi

find "$STATIC_DIR" -type f -name ".content-assets-sync" -delete

declare -a managed_targets=()

record_target() {
  local target_dir="$1"
  managed_targets+=("$target_dir")
}

copy_directory() {
  local source_dir="$1"
  local target_dir="$2"
  mkdir -p "$(dirname "$target_dir")"
  cp -R "$source_dir" "$target_dir"
}

while IFS= read -r source_dir; do
  rel_path="${source_dir#"$CONTENT_DIR/"}"
  target_dir="$STATIC_DIR/$rel_path"
  parent_dir="$(dirname "$source_dir")"
  rel_parent="${parent_dir#"$CONTENT_DIR/"}"
  has_base_assets=0

  while IFS= read -r child_path; do
    child_name="$(basename "$child_path")"
    if [[ -f "$child_path" ]]; then
      mkdir -p "$target_dir"
      cp "$child_path" "$target_dir/"
      has_base_assets=1
      continue
    fi

    if [[ -d "$child_path" && -f "$parent_dir/$child_name.md" ]]; then
      page_assets_dir="$STATIC_DIR/$rel_parent/$child_name/assets"
      copy_directory "$child_path" "$page_assets_dir/$child_name"
      record_target "$page_assets_dir"
      continue
    fi

    if [[ -d "$child_path" ]]; then
      copy_directory "$child_path" "$target_dir/$child_name"
      has_base_assets=1
    fi
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 | sort)

  if [[ $has_base_assets -eq 1 ]]; then
    record_target "$target_dir"
  fi
done < <(find "$CONTENT_DIR" -type d -name assets | sort)

printf '%s\n' "${managed_targets[@]}" | sort -u > "$MANIFEST_FILE"
