#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_DISK_THRESHOLD=85
readonly DEFAULT_MEMORY_THRESHOLD=90

usage() {
  cat <<USAGE
Usage: $0 [-d disk_threshold] [-m memory_threshold] [-s service1,service2]

Create a point-in-time health snapshot and exit non-zero if a threshold/service check fails.

Options:
  -d N    Disk usage threshold percent for / (default: ${DEFAULT_DISK_THRESHOLD})
  -m N    Memory usage threshold percent (default: ${DEFAULT_MEMORY_THRESHOLD})
  -s CSV  Comma-separated systemd service names to verify (default: ssh)
  -h      Show help
USAGE
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "Missing required command: ${command_name}" >&2
    exit 1
  }
}

validate_percent() {
  local label="$1"
  local value="$2"
  if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value < 1 || value > 99 )); then
    echo "${label} must be an integer between 1 and 99" >&2
    exit 1
  fi
}

calc_memory_percent() {
  local mem_total_kb
  local mem_available_kb
  mem_total_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
  mem_available_kb="$(awk '/MemAvailable/ {print $2}' /proc/meminfo)"
  awk -v total="$mem_total_kb" -v available="$mem_available_kb" 'BEGIN { printf "%d", ((total-available)/total)*100 }'
}

disk_threshold="$DEFAULT_DISK_THRESHOLD"
memory_threshold="$DEFAULT_MEMORY_THRESHOLD"
services_csv="ssh"

while getopts ':d:m:s:h' opt; do
  case "$opt" in
    d) disk_threshold="$OPTARG" ;;
    m) memory_threshold="$OPTARG" ;;
    s) services_csv="$OPTARG" ;;
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

validate_percent "Disk threshold" "$disk_threshold"
validate_percent "Memory threshold" "$memory_threshold"
require_command df
require_command awk
require_command systemctl

root_disk_usage="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"
mem_usage="$(calc_memory_percent)"
hostname_value="$(hostname -f 2>/dev/null || hostname)"
timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

status="ok"
systemd_available="false"
if [[ -d /run/systemd/system ]] && systemctl show-environment >/dev/null 2>&1; then
  systemd_available="true"
fi

printf 'timestamp=%s host=%s disk=%s%% memory=%s%%\n' "$timestamp" "$hostname_value" "$root_disk_usage" "$mem_usage"

if (( root_disk_usage > disk_threshold )); then
  echo "WARN: root disk usage ${root_disk_usage}% exceeds threshold ${disk_threshold}%" >&2
  status="degraded"
fi

if (( mem_usage > memory_threshold )); then
  echo "WARN: memory usage ${mem_usage}% exceeds threshold ${memory_threshold}%" >&2
  status="degraded"
fi

IFS=',' read -r -a services <<< "$services_csv"
if [[ "$systemd_available" != "true" ]]; then
  echo "WARN: systemd is not available; skipping service checks" >&2
else
  for service_name in "${services[@]}"; do
    service_name="$(printf '%s' "$service_name" | xargs)"
    [[ -z "$service_name" ]] && continue
    if systemctl is-active --quiet "$service_name"; then
      echo "service=${service_name} state=active"
    else
      echo "WARN: service=${service_name} state=inactive" >&2
      status="degraded"
    fi
  done
fi

[[ "$status" == "ok" ]]
