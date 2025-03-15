#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

SERVICE="nginx"

## Check if service is running and start it if it's not running

if systemctl is-active --quiet $SERVICE; then
echo "$SERVICE is running"
else
echo "$SERVICE is not running"
systemctl start $SERVICE
fi

