#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_THRESHOLD=80
readonly DEFAULT_EMAIL="admin@example.com"

usage() {
  cat <<USAGE
Usage: $0 [-t threshold_percent] [-e email]

Options:
  -t threshold_percent   Alert threshold (default: ${DEFAULT_THRESHOLD})
  -e email               Alert destination (default: ${DEFAULT_EMAIL})
  -h                     Show help
USAGE
}

threshold="$DEFAULT_THRESHOLD"
email="$DEFAULT_EMAIL"

while getopts ':t:e:h' opt; do
  case "$opt" in
    t) threshold="$OPTARG" ;;
    e) email="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "Missing value for -$OPTARG" >&2
      exit 1
      ;;
    ?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if ! [[ "$threshold" =~ ^[0-9]+$ ]] || (( threshold < 1 || threshold > 99 )); then
  echo "Threshold must be an integer between 1 and 99." >&2
  exit 1
fi

if ! command -v mail >/dev/null 2>&1; then
  echo "mail command is required but not installed." >&2
  exit 1
fi

usage_percent="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"

if (( usage_percent > threshold )); then
  printf 'Disk usage on %s is %s%% (threshold: %s%%).\n' "$(hostname)" "$usage_percent" "$threshold" \
    | mail -s "Disk Usage Alert" -- "$email"
fi
