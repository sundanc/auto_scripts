#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

while true; do
  date >> system.log
  top -bn1 | head -n 8 >> system.log
  free -m >> system.log
  echo "---" >> system.log
  sleep 5
done
