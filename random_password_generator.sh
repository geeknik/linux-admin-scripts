#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_PASS_LEN=30
readonly DEFAULT_CHAR_SET='A-Za-z0-9_@%+=:,./-'

usage() {
  cat <<USAGE
Usage: $0 [-l LENGTH] [-c CHARSET]

Options:
  -l LENGTH    Password length (default: ${DEFAULT_PASS_LEN})
  -c CHARSET   Characters to allow in password generation (tr character class)
  -h           Show this help
USAGE
}

pass_len="$DEFAULT_PASS_LEN"
char_set="$DEFAULT_CHAR_SET"

while getopts ':l:c:h' opt; do
  case "$opt" in
    l) pass_len="$OPTARG" ;;
    c) char_set="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "Missing value for -$OPTARG" >&2
      usage
      exit 1
      ;;
    ?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$pass_len" =~ ^[0-9]+$ ]] || (( pass_len < 12 )); then
  echo "Password length must be an integer >= 12." >&2
  exit 1
fi

set +o pipefail
password="$(tr -dc "$char_set" </dev/urandom | head -c "$pass_len")"
set -o pipefail

if (( ${#password} < pass_len )); then
  echo "Unable to generate password with requested settings. Try a broader character set." >&2
  exit 1
fi

printf 'Your random password is: %s\n' "$password"
