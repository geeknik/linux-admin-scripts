#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt >/dev/null 2>&1; then
  echo "This script requires apt (Debian/Ubuntu systems)." >&2
  exit 1
fi

current_kernel="$(uname -r)"

# Keep the currently running kernel and the newest installed kernel package.
mapfile -t installed_kernels < <(dpkg -l 'linux-image-[0-9]*' | awk '/^ii/{print $2}' | sort -V)

if (( ${#installed_kernels[@]} <= 1 )); then
  echo "No old kernels found to remove."
  exit 0
fi

newest_kernel_pkg="${installed_kernels[-1]}"
packages_to_remove=()

for kernel_pkg in "${installed_kernels[@]}"; do
  if [[ "$kernel_pkg" == *"$current_kernel"* || "$kernel_pkg" == "$newest_kernel_pkg" ]]; then
    continue
  fi
  packages_to_remove+=("$kernel_pkg")
done

if (( ${#packages_to_remove[@]} == 0 )); then
  echo "No removable kernel packages found."
  exit 0
fi

echo "Removing old kernels: ${packages_to_remove[*]}"
sudo apt remove -y -- "${packages_to_remove[@]}"
sudo update-grub
