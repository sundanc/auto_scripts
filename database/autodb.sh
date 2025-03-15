#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Advanced database maintenance script with backup, optimization, and reporting

DB_HOST="localhost"
DB_USER="dbadmin"
DB_PASS=$(cat /etc/db_credentials)
BACKUP_DIR="/var/backups/databases"
LOG_DIR="/var/log/db-maintenance"
MAX_BACKUP_AGE=7  # days
EMAIL_RECIPIENTS="dba@example.com"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="${LOG_DIR}/${TODAY}-maintenance.log"
ERROR_COUNT=0

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [${level}] ${message}" | tee -a "$LOG_FILE"
    
    if [[ "$level" == "ERROR" ]]; then
        ((ERROR_COUNT++))
    fi
}

# Function to check database connections
check_connections() {
    log "INFO" "Checking database connections..."
    
    # Get current connection count
    CONN_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SELECT COUNT(*) FROM information_schema.processlist;" | tail -1)
    
    # Get max connections
    MAX_CONN=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SHOW VARIABLES LIKE 'max_connections';" | grep max_connections | awk '{print $2}')
    
    # Check connection ratio
    CONN_RATIO=$(echo "scale=2; $CONN_COUNT / $MAX_CONN" | bc)
    log "INFO" "Current connections: $CONN_COUNT/$MAX_CONN ($CONN_RATIO)"
    
    if (( $(echo "$CONN_RATIO > 0.7" | bc -l) )); then
        log "WARNING" "High connection ratio: $CONN_RATIO"
        
        # Get connection details
        log "INFO" "Top users by connection count:"
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
            "SELECT user, host, COUNT(*) as count FROM information_schema.processlist GROUP BY user, host ORDER BY count DESC LIMIT 10;" | tee -a "$LOG_FILE"
    fi
}

# Function to check database size and growth
check_size() {
    log "INFO" "Checking database sizes..."
    
    # Get database sizes
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables GROUP BY table_schema ORDER BY size_mb DESC;" | tee -a "$LOG_FILE"
    
    # Check for large tables
    log "INFO" "Checking for large tables..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SELECT table_schema, table_name, ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables ORDER BY size_mb DESC LIMIT 10;" | tee -a "$LOG_FILE"
}

# Function to perform database backups
perform_backup() {
    log "INFO" "Starting database backups..."
    
    # Get list of databases
    DATABASES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema")
    
    for db in $DATABASES; do
        BACKUP_FILE="${BACKUP_DIR}/${db}-${TODAY}.sql.gz"
        log "INFO" "Backing up database: $db to $BACKUP_FILE"
        
        # Perform backup with compression
        mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --single-transaction \
            --routines --triggers --events "$db" | gzip > "$BACKUP_FILE"
        
        # Check if backup was successful
        if [[ $? -eq 0 ]]; then
            log "INFO" "Backup of $db completed successfully"
            
            # Create checksum for verification
            md5sum "$BACKUP_FILE" > "${BACKUP_FILE}.md5"
        else
            log "ERROR" "Backup of $db failed"
        fi
    done
    
    # Remove old backups
    log "INFO" "Removing backups older than $MAX_BACKUP_AGE days"
    find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +$MAX_BACKUP_AGE -delete
    find "$BACKUP_DIR" -type f -name "*.md5" -mtime +$MAX_BACKUP_AGE -delete
}

# Function to perform database optimization
perform_optimization() {
    log "INFO" "Starting database optimization..."
    
    # Get list of databases
    DATABASES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema")
    
    for db in $DATABASES; do
        log "INFO" "Checking for tables to optimize in $db"
        
        # Find tables that need optimization
        TABLES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
            "SELECT table_name FROM information_schema.tables WHERE table_schema = '$db' AND data_free > 0 AND NOT engine='InnoDB';" | grep -v "table_name")
        
        if [[ -n "$TABLES" ]]; then
            for table in $TABLES; do
                log "INFO" "Optimizing table: $db.$table"
                mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "OPTIMIZE TABLE $db.$table;" | tee -a "$LOG_FILE"
            done
        else
            log "INFO" "No tables need optimization in $db"
        fi
        
        # Analyze tables for better query planning
        log "INFO" "Analyzing tables in $db"
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
            "SELECT CONCAT('ANALYZE TABLE ', table_schema, '.', table_name, ';') AS analyze_statement FROM information_schema.tables WHERE table_schema = '$db';" | \
            grep -v "analyze_statement" | mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS"
    done
}

# Function to check slow queries
check_slow_queries() {
    log "INFO" "Checking for slow queries..."
    
    #!/bin/bash
# Advanced database maintenance script with backup, optimization, and reporting

DB_HOST="localhost"
DB_USER="dbadmin"
DB_PASS=$(cat /etc/db_credentials)
BACKUP_DIR="/var/backups/databases"
LOG_DIR="/var/log/db-maintenance"
MAX_BACKUP_AGE=7  # days
EMAIL_RECIPIENTS="dba@example.com"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="${LOG_DIR}/${TODAY}-maintenance.log"
ERROR_COUNT=0

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [${level}] ${message}" | tee -a "$LOG_FILE"
    
    if [[ "$level" == "ERROR" ]]; then
        ((ERROR_COUNT++))
    fi
}

# Function to check database connections
check_connections() {
    log "INFO" "Checking database connections..."
    
    # Get current connection count
    CONN_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SELECT COUNT(*) FROM information_schema.processlist;" | tail -1)
    
    # Get max connections
    MAX_CONN=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SHOW VARIABLES LIKE 'max_connections';" | grep max_connections | awk '{print $2}')
    
    # Check connection ratio
    CONN_RATIO=$(echo "scale=2; $CONN_COUNT / $MAX_CONN" | bc)
    log "INFO" "Current connections: $CONN_COUNT/$MAX_CONN ($CONN_RATIO)"
    
    if (( $(echo "$CONN_RATIO > 0.7" | bc -l) )); then
        log "WARNING" "High connection ratio: $CONN_RATIO"
        
        # Get connection details
        log "INFO" "Top users by connection count:"
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
            "SELECT user, host, COUNT(*) as count FROM information_schema.processlist GROUP BY user, host ORDER BY count DESC LIMIT 10;" | tee -a "$LOG_FILE"
    fi
}

# Function to check database size and growth
check_size() {
    log "INFO" "Checking database sizes..."
    
    # Get database sizes
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables GROUP BY table_schema ORDER BY size_mb DESC;" | tee -a "$LOG_FILE"
    
    # Check for large tables
    log "INFO" "Checking for large tables..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
        "SELECT table_schema, table_name, ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables ORDER BY size_mb DESC LIMIT 10;" | tee -a "$LOG_FILE"
}

# Function to perform database backups
perform_backup() {
    log "INFO" "Starting database backups..."
    
    # Get list of databases
    DATABASES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema")
    
    for db in $DATABASES; do
        BACKUP_FILE="${BACKUP_DIR}/${db}-${TODAY}.sql.gz"
        log "INFO" "Backing up database: $db to $BACKUP_FILE"
        
        # Perform backup with compression
        mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --single-transaction \
            --routines --triggers --events "$db" | gzip > "$BACKUP_FILE"
        
        # Check if backup was successful
        if [[ $? -eq 0 ]]; then
            log "INFO" "Backup of $db completed successfully"
            
            # Create checksum for verification
            md5sum "$BACKUP_FILE" > "${BACKUP_FILE}.md5"
        else
            log "ERROR" "Backup of $db failed"
        fi
    done
    
    # Remove old backups
    log "INFO" "Removing backups older than $MAX_BACKUP_AGE days"
    find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +$MAX_BACKUP_AGE -delete
    find "$BACKUP_DIR" -type f -name "*.md5" -mtime +$MAX_BACKUP_AGE -delete
}

# Function to perform database optimization
perform_optimization() {
    log "INFO" "Starting database optimization..."
    
    # Get list of databases
    DATABASES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema")
    
    for db in $DATABASES; do
        log "INFO" "Checking for tables to optimize in $db"
        
        # Find tables that need optimization
        TABLES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
            "SELECT table_name FROM information_schema.tables WHERE table_schema = '$db' AND data_free > 0 AND NOT engine='InnoDB';" | grep -v "table_name")
        
        if [[ -n "$TABLES" ]]; then
            for table in $TABLES; do
                log "INFO" "Optimizing table: $db.$table"
                mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "OPTIMIZE TABLE $db.$table;" | tee -a "$LOG_FILE"
            done
        else
            log "INFO" "No tables need optimization in $db"
        fi
        
        # Analyze tables for better query planning
        log "INFO" "Analyzing tables in $db"
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e \
            "SELECT CONCAT('ANALYZE TABLE ', table_schema, '.', table_name, ';') AS analyze_statement FROM information_schema.tables WHERE table_schema = '$db';" | \
            grep -v "analyze_statement" | mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS"
    done
}

# Function to check slow queries
check_slow_queries() {
    log "INFO" "Checking for slow queries..."
    
    