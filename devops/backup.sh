#!/bin/bash

SOURCE="/home/username/project"
DESTINATION="/home/username/backup"
DATE=$( date +%Y-%m-%d_%H-%M-%S )
# BACKUP DIRECTORY
mkdir -p $DESTINATION/$DATE
cp -r "$SOURCE" "$DESTINATION/$DATE"
echo "Backup of $SOURCE completed!"
echo "Backup saved in $DESTINATION/$DATE directory"
