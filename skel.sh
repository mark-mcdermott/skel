#!/usr/bin/env bash

show_instruction_line=1
INDENT_WIDTH=2
current_depth=0
VERSION="0.3.2"

print_help() {
  cat <<'HELP'
Skel

Create files and directories from an indented tree.

Usage:
  skel
  skel < structure.txt
  skel -i 4 < structure.txt

Options:
  -h, --help        Show help
  -v, --version     Show version
  -i, --indent N    Indent width in spaces (default: 2)

Rules:
  - Use N spaces per indent level (default: 2)
  - Tabs are not allowed
  - Blank line finishes interactive mode
  - Directories can be implied by indentation
  - Empty directories must end with /
  - Blank lines are not allowed in piped/heredoc input
  - Duplicate paths are not allowed

Example:
  skel <<EOF
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
  [[ "$name" == "~" ]] && return 0
  [[ "$name" == "~/"* ]] && return 0
  [[ "$name" == "." ]] && return 0
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
  local path_stack=()
  local seen_paths=$'\n'

  for ((i = 0; i < ${#lines[@]}; i++)); do
    local line="${lines[$i]}"
    local line_number=$((i + 1))
    local cur_indent name target_depth full_path part

    is_blank_line "$line" && error "$line_number" "blank lines are not allowed"
    has_tabs "$line" && error "$line_number" "tabs are not allowed. Use $INDENT_WIDTH spaces per indent."
    has_unsafe_path "$line" && error "$line_number" "unsafe paths are not allowed"

    name=$(trimmed_line "$line")
    cur_indent=$(get_indent "$line")

    if (( cur_indent % INDENT_WIDTH != 0 )); then
      error "$line_number" "indent must use multiples of $INDENT_WIDTH spaces"
    fi

    if (( cur_indent > previous_indent + INDENT_WIDTH )); then
      error "$line_number" "cannot jump multiple indent levels"
    fi

    target_depth=$(( cur_indent / INDENT_WIDTH ))
    path_stack=("${path_stack[@]:0:$target_depth}")
    path_stack+=("$name")

    full_path=""
    for part in "${path_stack[@]}"; do
      [[ -n "$full_path" ]] && full_path="${full_path}/"
      full_path="${full_path}${part}"
    done

    if [[ "$seen_paths" == *$'\n'"$full_path"$'\n'* ]]; then
      error "$line_number" "duplicate path: $full_path"
    fi
    seen_paths="${seen_paths}${full_path}"$'\n'

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

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -v|--version)
      echo "skel $VERSION"
      exit 0
      ;;
    -i|--indent)
      if [[ -z "$2" || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: --indent requires a positive integer" >&2
        exit 1
      fi
      INDENT_WIDTH="$2"
      shift 2
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

lines=()

if [[ -t 0 ]]; then
  echo "Enter file structure (${INDENT_WIDTH} spaces/level, blank line to finish):"

  while IFS= read -e -r -p "> " line; do
    [[ -z "${line//[[:space:]]/}" ]] && break
    history -s "$line"
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
