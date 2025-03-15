#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
HOST="google.com"
OUTPUT_FILE="/home/username/output.txt"
# Check the connectivity
if ping -c 1 $HOST &> /dev/null
then 
echo "$HOST is reachable" >> $OUTPUT_FILE
else
echo "$HOST is not reachable" >> $OUTPUT_FILE
fi
