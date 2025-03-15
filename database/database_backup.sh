#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Do not forget to install MySQL
# sudo apt install mysql-server
# Set your MySQL password:
# ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY'root';
# FLUSH PRIVILEGES
# Be sure about DB_NAME and BACKUP_DIR
DB_NAME="mydatabase"
BACKUP_DIR="/path/to/your/backup"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
mysqldump -u root -p $DB_NAME > $BACKUP_DIR/$DB_NAME-$DATE.sql
# Check backup success
if [ $? -eq 0 ]; then
  echo "Database backup completed successfully: $BACKUP_DIR/$DB_NAME-$DATE.sql"
else
  echo "Database backup failed!"
fi
