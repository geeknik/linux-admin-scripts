#!/usr/bin/env bash
set -euo pipefail

# Create local users from a CSV file.
# CSV format: username,email
#
# Security notes:
# - Passwords are generated randomly and set immediately.
# - By default passwords are NOT emailed to avoid credential leakage.
# - Use --send-email only in environments with trusted mail transport.

readonly DEFAULT_CSV_FILE="users.csv"
readonly DEFAULT_PASSWORD_LENGTH=16

usage() {
  cat <<USAGE
Usage: $0 [--csv FILE] [--password-length N] [--send-email]

Options:
  --csv FILE            Path to CSV file (default: ${DEFAULT_CSV_FILE})
  --password-length N   Password length (default: ${DEFAULT_PASSWORD_LENGTH})
  --send-email          Send welcome email containing credentials
  -h, --help            Show this help text
USAGE
}

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log "Missing required command: ${command_name}"
    exit 1
  fi
}

generate_password() {
  local length="$1"
  set +o pipefail
  tr -dc 'A-Za-z0-9_@%+=:,./-' </dev/urandom | head -c "$length"
  set -o pipefail
}

validate_username() {
  local username="$1"
  [[ "$username" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]
}

create_user() {
  local username="$1"
  local email="$2"
  local password="$3"

  if id "$username" >/dev/null 2>&1; then
    log "User already exists, skipping: ${username}"
    return
  fi

  useradd -m -- "$username"
  printf '%s:%s\n' "$username" "$password" | chpasswd
  chage -d 0 -- "$username"
  log "Created user: ${username}"

  if [[ "$SEND_EMAIL" == "true" ]]; then
    local email_subject="Welcome to the Linux server"
    local email_body
    email_body="Hello ${username},\n\nYour account has been created.\n\nUsername: ${username}\nPassword: ${password}\n\nPlease change your password at first login."
    printf '%b\n' "$email_body" | mail -s "$email_subject" -- "$email"
    log "Sent welcome email to: ${email}"
  fi
}

CSV_FILE="$DEFAULT_CSV_FILE"
PASSWORD_LENGTH="$DEFAULT_PASSWORD_LENGTH"
SEND_EMAIL="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv)
      CSV_FILE="${2:-}"
      shift 2
      ;;
    --password-length)
      PASSWORD_LENGTH="${2:-}"
      shift 2
      ;;
    --send-email)
      SEND_EMAIL="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$CSV_FILE" ]]; then
  log "CSV file not found: ${CSV_FILE}"
  exit 1
fi

if ! [[ "$PASSWORD_LENGTH" =~ ^[0-9]+$ ]] || (( PASSWORD_LENGTH < 12 )); then
  log "Password length must be an integer >= 12"
  exit 1
fi

require_command useradd
require_command chpasswd
if [[ "$SEND_EMAIL" == "true" ]]; then
  require_command mail
fi

# Skip header and parse username,email pairs.
# shellcheck disable=SC2162
while IFS=',' read -r raw_username raw_email; do
  username="$(printf '%s' "$raw_username" | xargs)"
  email="$(printf '%s' "$raw_email" | xargs)"

  if [[ -z "$username" || -z "$email" ]]; then
    log "Skipping malformed row"
    continue
  fi

  if ! validate_username "$username"; then
    log "Invalid username format, skipping: ${username}"
    continue
  fi

  password="$(generate_password "$PASSWORD_LENGTH")"
  create_user "$username" "$email" "$password"
done < <(tail -n +2 -- "$CSV_FILE")

log "Completed CSV user processing"
