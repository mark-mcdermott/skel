#!/usr/bin/env bash

show_instruction_line=1
INDENT_WIDTH=2
current_depth=0
VERSION="0.2.0"

print_help() {
  cat <<'HELP'
Skel

Create files and directories from an indented tree.

Usage:
  skel.sh
  skel.sh < structure.txt

Options:
  -h, --help     Show help
  -v, --version  Show version

Rules:
  - Use 2 spaces per indent level
  - Tabs are not allowed
  - Blank line finishes interactive mode
  - Directories can be implied by indentation
  - Empty directories must end with /
  - Blank lines are not allowed in piped/heredoc input

Example:
  skel.sh <<EOF
src
  components
    Button.tsx
  index.ts
README.md
EOF
HELP
}

get_indent() {
  local line="$1"
  local whitespace

  if [[ "$line" =~ ^([[:space:]]*) ]]; then
    whitespace="${BASH_REMATCH[1]}"
    echo "${#whitespace}"
  fi
}

has_unsafe_path() {
  local line="$1"
  local name

  name=$(trimmed_line "$line")

  [[ "$name" == /* ]] && return 0
  [[ "$name" == ".." ]] && return 0
  [[ "$name" == ../* ]] && return 0
  [[ "$name" == */../* ]] && return 0
  [[ "$name" == */.. ]] && return 0

  return 1
}

trimmed_line() {
  local line="$1"
  local leading_whitespace_trimmed="${line#"${line%%[![:space:]]*}"}"
  local trailing_slash_trimmed="${leading_whitespace_trimmed%/}"
  echo "$trailing_slash_trimmed"
}

is_dir() {
  local line="$1"
  local next_line="$2"

  [[ "$line" =~ /$ ]] && return 0

  local cur_indent
  local next_indent

  cur_indent=$(get_indent "$line")
  next_indent=$(get_indent "$next_line")

  (( next_indent > cur_indent ))
}

cd_up_if_necessary() {
  local target_depth="$1"

  while (( current_depth > target_depth )); do
    cd .. || exit 1
    ((current_depth--))
  done
}

error() {
  echo "Error on line $1: $2" >&2
  exit 1
}

is_blank_line() {
  local line="$1"
  [[ -z "${line//[[:space:]]/}" ]]
}

has_tabs() {
  local line="$1"
  [[ "$line" == *$'\t'* ]]
}

validate_lines() {
  local previous_indent=0

  for ((i = 0; i < ${#lines[@]}; i++)); do
    local line="${lines[$i]}"
    local line_number=$((i + 1))
    local cur_indent

    is_blank_line "$line" && error "$line_number" "blank lines are not allowed"
    has_tabs "$line" && error "$line_number" "tabs are not allowed. Use 2 spaces per indent."

    if has_unsafe_path "$line"; then
      error "$line_number" "unsafe paths are not allowed"
    fi

    cur_indent=$(get_indent "$line")

    if (( cur_indent % INDENT_WIDTH != 0 )); then
      error "$line_number" "indent must use multiples of $INDENT_WIDTH spaces"
    fi

    if (( cur_indent > previous_indent + INDENT_WIDTH )); then
      error "$line_number" "cannot jump multiple indent levels"
    fi

    previous_indent=$cur_indent
  done
}

process_line() {
  local line="$1"
  local next_line="$2"

  local cur_indent
  local target_depth
  local dir_or_file_name

  cur_indent=$(get_indent "$line")
  target_depth=$(( cur_indent / INDENT_WIDTH ))

  cd_up_if_necessary "$target_depth"

  dir_or_file_name=$(trimmed_line "$line")

  if is_dir "$line" "$next_line"; then
    mkdir -p -- "$dir_or_file_name"
    cd -- "$dir_or_file_name" || exit 1
    ((current_depth++))
  else
    touch -- "$dir_or_file_name"
  fi
}

case "$1" in
  -h|--help)
    print_help
    exit 0
    ;;
  -v|--version)
    echo "skel $VERSION"
    exit 0
    ;;
esac

lines=()

if [[ -t 0 ]]; then
  if [[ $show_instruction_line == 1 ]]; then
    echo "Enter file structure. Blank line to finish."
  fi

  while IFS= read -r line; do
    [[ -z "${line//[[:space:]]/}" ]] && break
    lines+=("$line")
  done
else
  line_number=0

  while IFS= read -r line; do
    ((line_number++))

    if is_blank_line "$line"; then
      error "$line_number" "blank lines are not allowed in piped/heredoc input"
    fi

    lines+=("$line")
  done
fi

if (( ${#lines[@]} == 0 )); then
  echo "Error: no input provided" >&2
  exit 1
fi

validate_lines

for ((i = 0; i < ${#lines[@]}; i++)); do
  line="${lines[$i]}"
  next_line="${lines[$((i + 1))]}"
  process_line "$line" "$next_line"
done