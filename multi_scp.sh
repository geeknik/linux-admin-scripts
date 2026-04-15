#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 <source_file> <target_path> <hosts_file> <ssh_key>
USAGE
  exit 1
}

if [[ $# -ne 4 ]]; then
  usage
fi

source_file="$1"
target_path="$2"
hosts_file="$3"
ssh_key="$4"

[[ -f "$source_file" ]] || { echo "Source file not found: $source_file" >&2; exit 1; }
[[ -f "$hosts_file" ]] || { echo "Hosts file not found: $hosts_file" >&2; exit 1; }
[[ -f "$ssh_key" ]] || { echo "SSH key not found: $ssh_key" >&2; exit 1; }

while IFS= read -r raw_host; do
  host="$(printf '%s' "$raw_host" | xargs)"

  # Ignore blank lines and comments.
  [[ -z "$host" || "$host" =~ ^# ]] && continue

  echo "Transferring to $host ..."
  scp -i "$ssh_key" -p \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -- "$source_file" "${host}:$target_path"
done < "$hosts_file"
