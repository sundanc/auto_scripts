#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Check if the system is Linux-based
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}Error: This script is designed for Linux systems only.${NC}"
    exit 1
fi

THRESHOLD=85

df -P | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5, $1 }' | while read -r usage partition; do
    usage=${usage%\%}  # Remove % sign

    if [[ "$usage" -ge "$THRESHOLD" ]]; then
        echo " Disk usage on $partition is at ${usage}% "
    fi
done

