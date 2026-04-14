#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 [--fix]

Audit SSH authorized_keys ownership and permissions for all local users.

Options:
  --fix    Correct insecure ownership and permissions automatically.
  -h       Show help
USAGE
}

auto_fix="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix)
      auto_fix="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if (( EUID != 0 )); then
  echo "Run as root to inspect all user homes." >&2
  exit 1
fi

issues_found=0

while IFS=':' read -r username _ uid gid _ home shell_path; do
  [[ "$uid" -lt 1000 && "$uid" -ne 0 ]] && continue
  [[ ! -d "$home" ]] && continue
  [[ "$shell_path" == "/usr/sbin/nologin" || "$shell_path" == "/bin/false" ]] && continue

  ssh_dir="${home}/.ssh"
  auth_keys_file="${ssh_dir}/authorized_keys"

  [[ -d "$ssh_dir" ]] || continue

  current_ssh_mode="$(stat -c '%a' "$ssh_dir")"
  current_ssh_owner="$(stat -c '%U:%G' "$ssh_dir")"

  if [[ "$current_ssh_mode" != "700" || "$current_ssh_owner" != "${username}:${username}" ]]; then
    echo "ISSUE user=${username} path=${ssh_dir} mode=${current_ssh_mode} owner=${current_ssh_owner} expected=700 ${username}:${username}"
    issues_found=1
    if [[ "$auto_fix" == "true" ]]; then
      chmod 700 "$ssh_dir"
      chown "${username}:${username}" "$ssh_dir"
      echo "FIXED user=${username} path=${ssh_dir}"
    fi
  fi

  if [[ -f "$auth_keys_file" ]]; then
    current_key_mode="$(stat -c '%a' "$auth_keys_file")"
    current_key_owner="$(stat -c '%U:%G' "$auth_keys_file")"

    if [[ "$current_key_mode" != "600" || "$current_key_owner" != "${username}:${username}" ]]; then
      echo "ISSUE user=${username} path=${auth_keys_file} mode=${current_key_mode} owner=${current_key_owner} expected=600 ${username}:${username}"
      issues_found=1
      if [[ "$auto_fix" == "true" ]]; then
        chmod 600 "$auth_keys_file"
        chown "${username}:${username}" "$auth_keys_file"
        echo "FIXED user=${username} path=${auth_keys_file}"
      fi
    fi
  fi
done < /etc/passwd

if (( issues_found == 0 )); then
  echo "No SSH key permission issues found."
fi

exit "$issues_found"
