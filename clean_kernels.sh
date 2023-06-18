#/bin/bash
dpkg -l 'linux-image-*' | awk '/^ii/{print $2}' | grep -v `uname -r` | xargs sudo apt remove -y && sudo update-grub
