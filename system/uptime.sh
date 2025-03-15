#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
#
UPTIME=$(uptime -s)
DAYS=$(awk '{print int($1/86400)}' /proc/uptime)
HOURS=$(awk '{print int(($1%86400)/3600)}' /proc/uptime)
MINUTES=$(awk '{print int(($1%3600)/60)}' /proc/uptime)

echo "Uptime: $DAYS days, $HOURS hours, $MINUTES minutes"
echo "Boot Time: $UPTIME"
