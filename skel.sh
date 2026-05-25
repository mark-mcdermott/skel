#!/usr/bin/env bash

last_indent=0

get_indent() {
  local line="$1"
  local num_spaces=0
  if [[ "$line" =~ ^([[:space:]]*) ]]; then
    local spaces="${BASH_REMATCH[1]}"
    num_spaces=${#spaces}
  fi
  echo "$num_spaces"
}

trimmed_line() {
  local line="$1"
  local leading_whitespace_trimmed="${line#"${line%%[![:space:]]*}"}"
  local trailing_slash_trimmed="${leading_whitespace_trimmed%/}"
  echo "$trailing_slash_trimmed"
}

is_dir() {
  local line="$1"
  [[ "$line" =~ \/$ ]]
}

get_num_dirs_higher() {
  local cur_indent="$1"
  echo $(( (last_indent - cur_indent) / 2))
}

cd_up_if_necessary() {
  local cur_indent="$1"
  if (( cur_indent < last_indent )); then
    for ((i = 0; i < $(get_num_dirs_higher "$cur_indent"); i++)); do
      cd .. || exit 1
    done
  fi
}

while IFS= read -r line; do
  cur_indent=$(get_indent "$line")
  cd_up_if_necessary "$cur_indent"
  dir_or_file_name=$(trimmed_line "$line")
  if is_dir "$line"; then
    mkdir -p "$dir_or_file_name"
    cd "$dir_or_file_name" || exit 1
  else
    touch "$dir_or_file_name"
  fi
  last_indent=$cur_indent
done