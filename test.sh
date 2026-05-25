#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKEL_SCRIPT="$ROOT_DIR/skel.sh"

TEST_DIRS=()

cleanup() {
  for dir in "${TEST_DIRS[@]}"; do
    rm -rf "$dir"
  done
}

trap cleanup EXIT

fail() {
  echo "❌ $1"
  exit 1
}

pass() {
  echo "✅ $1"
}

assert_file_exists() {
  test -f "$1" || fail "Expected file: $1"
}

assert_dir_exists() {
  test -d "$1" || fail "Expected directory: $1"
}

run_test() {
  local test_name="$1"
  local test_dir

  test_dir="$(mktemp -d)"
  TEST_DIRS+=("$test_dir")

  cp "$SKEL_SCRIPT" "$test_dir/skel.sh"

  (
    cd "$test_dir"

    "$test_name"
  )

  pass "$test_name"
}

test_basic_structure() {
  bash ./skel.sh <<EOF
file1.txt
directory1/
  file2.txt
  directory2/
    file3.txt
  file4.txt
file5.txt
EOF

  assert_file_exists "file1.txt"
  assert_dir_exists "directory1"
  assert_file_exists "directory1/file2.txt"
  assert_dir_exists "directory1/directory2"
  assert_file_exists "directory1/directory2/file3.txt"
  assert_file_exists "directory1/file4.txt"
  assert_file_exists "file5.txt"
}

test_empty_directory() {
  bash ./skel.sh <<EOF
empty-directory/
EOF

  assert_dir_exists "empty-directory"
}

test_deeper_structure() {
  bash ./skel.sh <<EOF
src/
  main/
    index.ts
  renderer/
    App.tsx
    styles/
      global.css
README.md
EOF

  assert_dir_exists "src"
  assert_dir_exists "src/main"
  assert_file_exists "src/main/index.ts"
  assert_dir_exists "src/renderer"
  assert_file_exists "src/renderer/App.tsx"
  assert_dir_exists "src/renderer/styles"
  assert_file_exists "src/renderer/styles/global.css"
  assert_file_exists "README.md"
}

run_test test_basic_structure
run_test test_empty_directory
run_test test_deeper_structure

echo
echo "All tests passed."