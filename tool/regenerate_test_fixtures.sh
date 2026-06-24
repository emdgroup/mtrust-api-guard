#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE_BASE="$ROOT/.test_scaffolds/package_base"
PLUGIN_BASE="$ROOT/.test_scaffolds/plugin_base"

clear_dir_contents() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -mindepth 1 -delete
  fi
}

create_package_base() {
  rm -rf "$PACKAGE_BASE"
  mkdir -p "$PACKAGE_BASE"
  (
    cd "$PACKAGE_BASE"
    flutter create . --template package --project-name api_guard_test
    clear_dir_contents lib
    rm -rf test .dart_tool
    mkdir -p lib
  )
}

create_plugin_base() {
  rm -rf "$PLUGIN_BASE"
  mkdir -p "$PLUGIN_BASE"
  (
    cd "$PLUGIN_BASE"
    flutter create . --template plugin --project-name api_guard_test
    clear_dir_contents lib
    rm -rf test example .dart_tool
    mkdir -p lib
  )
}

create_package_base
create_plugin_base

# Remove legacy scaffold locations that flutter test would discover as tests.
rm -rf "$ROOT/test/fixtures/package_base" "$ROOT/test/fixtures/plugin_base"
