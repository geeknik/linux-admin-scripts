# linux-admin-scripts

Collection of practical Linux administration scripts with safer defaults, explicit validation, and operationally friendly CLI usage.

## Included scripts

| Script | Purpose | Runs as root? |
|---|---|---|
| `add_users_from_csv.sh` | Create local users from `username,email` CSV, generate random password, force password reset on first login, optional welcome email. | Yes |
| `authorized_keys_audit.sh` | Audit `.ssh` and `authorized_keys` permissions/ownership for local users; optional `--fix` remediation. | Yes |
| `system_health_snapshot.sh` | One-shot host health check (disk, memory, optional service checks) with non-zero exit on degraded state. | No |
| `random_password_generator.sh` | Generate random passwords with configurable length/character class. | No |
| `multi_scp.sh` | Copy one local file to many hosts from a host list. | No |
| `disk_usage_alert.sh` | Send email alert when root filesystem usage exceeds threshold. | Usually |
| `clean_kernels.sh` | Remove outdated kernel packages while preserving running/newest kernels. | Yes |

## Security posture

These scripts intentionally apply conservative defaults:

- `set -euo pipefail` to fail fast and avoid hidden errors.
- Input and argument validation before privileged operations.
- Defensive quoting to reduce command-injection risks.
- Minimal output that avoids logging secrets.

## Prerequisites

Most scripts require standard GNU/Linux tooling (`bash`, `awk`, `df`, `stat`, `mail`, `scp`, `systemctl`, `apt`) depending on script path. Use `-h` / `--help` on each script to view command-specific requirements.

## Quick usage

```bash
# Generate a 24-character password
./random_password_generator.sh -l 24

# Create users from CSV (no credential email by default)
sudo ./add_users_from_csv.sh --csv ./users.csv --password-length 20

# Audit SSH key permissions
sudo ./authorized_keys_audit.sh

# Audit + remediate SSH key permission issues
sudo ./authorized_keys_audit.sh --fix

# One-shot health snapshot (disk/memory + selected services)
./system_health_snapshot.sh -d 80 -m 85 -s ssh,cron

# Copy a file to all hosts in hosts.txt
./multi_scp.sh ./agent.conf /etc/agent/agent.conf ./hosts.txt ~/.ssh/id_ed25519

# Send alert when root filesystem exceeds 85%
./disk_usage_alert.sh -t 85 -e ops@example.com

# Remove old kernels safely (Debian/Ubuntu)
./clean_kernels.sh
```

## Recommended operating model

- Run write/privileged scripts via `sudo` from a controlled jump host.
- Store CSV input and host inventories with restricted file permissions.
- Execute scripts from CI/cron with explicit command arguments (no hidden defaults in wrappers).
- Review output and exit codes; non-zero exit means intervention is required.
