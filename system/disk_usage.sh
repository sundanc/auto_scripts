#!/bin/bash

THRESHOLD=85

df -P | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5, $1 }' | while read -r usage partition; do
    usage=${usage%\%}  # Remove % sign

    if [[ "$usage" -ge "$THRESHOLD" ]]; then
        echo " Disk usage on $partition is at ${usage}% "
    fi
done

