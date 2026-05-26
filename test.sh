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

run_failing_test() {
  local test_name="$1"
  local input="$2"
  local expected_message="$3"
  local test_dir
  local output
  local status

  test_dir="$(mktemp -d)"
  TEST_DIRS+=("$test_dir")

  cp "$SKEL_SCRIPT" "$test_dir/skel.sh"

  set +e

  if [[ -z "$input" ]]; then
    output="$(
      cd "$test_dir"
      bash ./skel.sh < /dev/null 2>&1
    )"
  else
    output="$(
      cd "$test_dir"
      bash ./skel.sh <<< "$input" 2>&1
    )"
  fi

  status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    fail "$test_name should have failed"
  fi

  [[ "$output" == *"$expected_message"* ]] || fail "$test_name expected message: $expected_message"

  pass "$test_name"
}

run_failing_command_test() {
  local test_name="$1"
  local expected_message="$2"
  shift 2

  local test_dir output status

  test_dir="$(mktemp -d)"
  TEST_DIRS+=("$test_dir")

  cp "$SKEL_SCRIPT" "$test_dir/skel.sh"

  set +e
  output="$(cd "$test_dir" && bash ./skel.sh "$@" < /dev/null 2>&1)"
  status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    fail "$test_name should have failed"
  fi

  [[ "$output" == *"$expected_message"* ]] || fail "$test_name expected message: $expected_message"

  pass "$test_name"
}

assert_output_contains() {
  local output="$1"
  local expected="$2"

  [[ "$output" == *"$expected"* ]] || fail "Expected output to contain: $expected"
}

run_command_test() {
  local test_name="$1"
  local expected_output="$2"
  shift 2

  local test_dir
  local output

  test_dir="$(mktemp -d)"
  TEST_DIRS+=("$test_dir")

  cp "$SKEL_SCRIPT" "$test_dir/skel.sh"

  output="$(
    cd "$test_dir"
    bash ./skel.sh "$@"
  )"

  assert_output_contains "$output" "$expected_output"

  pass "$test_name"
}

run_test() {
  local test_name="$1"
  local input="$2"
  local test_dir

  test_dir="$(mktemp -d)"
  TEST_DIRS+=("$test_dir")

  cp "$SKEL_SCRIPT" "$test_dir/skel.sh"

  (
    cd "$test_dir"
    bash ./skel.sh <<< "$input"
    "$test_name"
  )

  pass "$test_name"
}

run_test_with_flags() {
  local test_name="$1"
  local input="$2"
  local test_dir
  shift 2

  test_dir="$(mktemp -d)"
  TEST_DIRS+=("$test_dir")

  cp "$SKEL_SCRIPT" "$test_dir/skel.sh"

  (
    cd "$test_dir"
    bash ./skel.sh "$@" <<< "$input"
    "$test_name"
  )

  pass "$test_name"
}

test_nested_structure_assertions() {
  assert_file_exists "file1.txt"
  assert_dir_exists "directory1"
  assert_file_exists "directory1/file2.txt"
  assert_dir_exists "directory1/directory2"
  assert_file_exists "directory1/directory2/file3.txt"
  assert_file_exists "directory1/file4.txt"
  assert_file_exists "file5.txt"
}

test_empty_directory_assertions() {
  assert_dir_exists "empty-directory"
  assert_file_exists "file.txt"
}

test_nested_then_root_file_assertions() {
  assert_dir_exists "src"
  assert_dir_exists "src/components"
  assert_file_exists "src/components/Button.tsx"
  assert_file_exists "src/index.ts"
  assert_file_exists "package.json"
  assert_file_exists "README.md"
}

test_custom_indent_assertions() {
  assert_dir_exists "src"
  assert_file_exists "src/index.ts"
}

run_test test_nested_structure_assertions "file1.txt
directory1
  file2.txt
  directory2
    file3.txt
  file4.txt
file5.txt"

run_test test_empty_directory_assertions "empty-directory/
file.txt"

run_test test_nested_then_root_file_assertions "src
  components
    Button.tsx
  index.ts
package.json
README.md"

run_test_with_flags "test_custom_indent_assertions" $'src\n    index.ts' -i 4

run_failing_test "test_single_space_indent" $'src\n file.txt' "indent must use multiples of 2 spaces"
run_failing_test "test_tab_indent" $'src\n\tfile.txt' "tabs are not allowed"
run_failing_test "test_multiple_indent_jump" $'src\n    file.txt' "cannot jump multiple indent levels"
run_failing_test "test_blank_line_in_heredoc" $'src\n\nfile.txt' "blank lines are not allowed"
run_failing_test "test_four_space_jump_from_root" $'src\n    index.ts' "cannot jump multiple indent levels"
run_failing_test "test_six_space_jump_from_two" $'src\n  components\n      Button.tsx' "cannot jump multiple indent levels"
run_failing_test "test_three_space_indent" $'src\n   file.txt' "indent must use multiples of 2 spaces"
run_failing_test "test_tab_after_spaces" $'src\n  \tfile.txt' "tabs are not allowed"
run_failing_test "test_whitespace_only_line" $'src\n   \nfile.txt' "blank lines are not allowed"
run_failing_test "test_empty_input" $'' "no input provided"
run_failing_test "test_parent_directory_path" $'../outside.txt' "unsafe paths are not allowed"
run_failing_test "test_absolute_path" $'/tmp/outside.txt' "unsafe paths are not allowed"
run_failing_test "test_nested_parent_directory_path" $'src/../bad.txt' "unsafe paths are not allowed"
run_failing_test "test_tilde_path" $'~' "unsafe paths are not allowed"
run_failing_test "test_tilde_subpath" $'~/foo.txt' "unsafe paths are not allowed"
run_failing_test "test_dot_entry" $'.' "unsafe paths are not allowed"
run_failing_test "test_duplicate_path" $'file.txt\nfile.txt' "duplicate path"
run_failing_test "test_duplicate_nested_path" $'src\n  file.txt\n  file.txt' "duplicate path"
run_failing_command_test "test_indent_zero" "positive integer" --indent 0
run_failing_command_test "test_indent_invalid" "positive integer" --indent foo
run_command_test "test_help_flag" "Create files and directories from an indented tree" --help
run_command_test "test_short_help_flag" "Usage:" -h
run_command_test "test_version_flag" "skel 0.3.1" --version
run_command_test "test_short_version_flag" "skel 0.3.1" -v

echo
echo "All tests passed."
