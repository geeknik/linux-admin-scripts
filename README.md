# linux-admin-scripts

Practical Linux administration scripts with safer defaults, input validation, and clearer usage.

## Scripts

- `add_users_from_csv.sh` — creates users from a CSV (`username,email`) with generated passwords, forced password reset at first login, and optional email delivery.
- `random_password_generator.sh` — generates strong random passwords with configurable length and character set.
- `multi_scp.sh` — securely copies one file to many hosts from a host list.
- `disk_usage_alert.sh` — checks root filesystem usage and sends an alert when threshold is exceeded.
- `clean_kernels.sh` — removes outdated kernel packages while keeping the running kernel.

## Security and privacy posture

These scripts follow a few guardrails:

- strict shell mode (`set -euo pipefail`) to fail fast;
- argument and input validation where user input exists;
- safer quoting and command invocation to reduce injection risk;
- minimal operational output that avoids printing sensitive values except where explicitly requested.

## Quick examples

```bash
# Generate a 24-char password
./random_password_generator.sh -l 24

# Create users from a custom CSV without sending credentials over email
sudo ./add_users_from_csv.sh --csv ./users.csv

# Copy a local file to many hosts listed in hosts.txt
./multi_scp.sh ./agent.conf /etc/agent/agent.conf ./hosts.txt ~/.ssh/id_ed25519

# Alert if root filesystem is over 85%
./disk_usage_alert.sh -t 85 -e ops@example.com

# Remove old kernels (Debian/Ubuntu)
./clean_kernels.sh
```
