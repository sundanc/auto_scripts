#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration from arsenal.conf if available
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/../config/arsenal.conf"
CREDENTIALS_FILE="$SCRIPT_DIR/../config/db_credentials.conf"

# Default configuration
DB_NAME=""
BACKUP_DIR="${HOME}/backups/database"
DB_USER="root"
DB_HOST="localhost"
DB_PORT="3306"
DB_PASS=""
COMPRESS=true
INCLUDE_ALL_DATABASES=false
BACKUP_RETENTION_DAYS=30

# Load arsenal.conf if available
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    # Override defaults with values from configuration
    [ -n "$DEFAULT_BACKUP_DIR" ] && BACKUP_DIR="$DEFAULT_BACKUP_DIR/database"
    [ -n "$DB_BACKUP_RETENTION" ] && BACKUP_RETENTION_DAYS="$DB_BACKUP_RETENTION"
    [ -n "$DB_DEFAULT_USER" ] && DB_USER="$DB_DEFAULT_USER"
    [ -n "$DB_DEFAULT_HOST" ] && DB_HOST="$DB_DEFAULT_HOST"
    [ -n "$DB_DEFAULT_PORT" ] && DB_PORT="$DB_DEFAULT_PORT"
fi

# Load database credentials if available
if [ -f "$CREDENTIALS_FILE" ]; then
    source "$CREDENTIALS_FILE"
fi

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --database NAME     Database name to backup (default: all databases if not specified)"
    echo "  -o, --output DIR        Backup directory (default: $BACKUP_DIR)"
    echo "  -u, --user USER         Database username (default: $DB_USER)"
    echo "  -h, --host HOST         Database hostname (default: $DB_HOST)"
    echo "  -p, --port PORT         Database port (default: $DB_PORT)"
    echo "  -a, --all-databases     Backup all databases (default: $INCLUDE_ALL_DATABASES)"
    echo "  -n, --no-compression    Disable compression (default: compression enabled)"
    echo "  -r, --retention DAYS    Backup retention in days (default: $BACKUP_RETENTION_DAYS)"
    echo "  --help                  Show this help"
    echo ""
    echo "Note: Database password can be provided via:"
    echo "  1. DB_PASSWORD environment variable"
    echo "  2. Configuration file: $CREDENTIALS_FILE"
    echo "  3. Interactive prompt (if neither of the above is provided)"
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -o|--output)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -p|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -a|--all-databases)
            INCLUDE_ALL_DATABASES=true
            shift
            ;;
        -n|--no-compression)
            COMPRESS=false
            shift
            ;;
        -r|--retention)
            BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create backup directory: $BACKUP_DIR${NC}"
    exit 1
fi

# Check required tools
if ! command -v mysqldump &> /dev/null; then
    echo -e "${RED}Error: mysqldump command not found${NC}"
    echo -e "${YELLOW}Please install MySQL client tools:${NC}"
    echo -e "  Debian/Ubuntu: sudo apt install mysql-client"
    echo -e "  CentOS/RHEL: sudo yum install mysql"
    exit 1
fi

# If no DB_PASSWORD, check environment variable
if [ -z "$DB_PASSWORD" ] && [ -n "$DB_PASS" ]; then
    DB_PASSWORD="$DB_PASS"
fi

# If still no password and not using socket authentication, prompt for it
if [ -z "$DB_PASSWORD" ] && [ "$DB_USER" != "root" -o "$DB_HOST" != "localhost" ]; then
    echo -ne "${YELLOW}Enter password for MySQL user $DB_USER: ${NC}"
    read -s DB_PASSWORD
    echo ""
fi

# Prepare MySQL credentials for command line
if [ -n "$DB_PASSWORD" ]; then
    MYSQL_PWD="$DB_PASSWORD"
    export MYSQL_PWD
    AUTH_PARAMS="-u$DB_USER -h$DB_HOST -P$DB_PORT"
else
    AUTH_PARAMS="-u$DB_USER -h$DB_HOST -P$DB_PORT"
fi

# Build the backup command
DATE=$(date +%Y-%m-%d_%H-%M-%S)
if [ "$INCLUDE_ALL_DATABASES" = true -o -z "$DB_NAME" ]; then
    BACKUP_FILENAME="all_databases-$DATE"
    MYSQLDUMP_CMD="mysqldump $AUTH_PARAMS --events --routines --triggers --all-databases"
    echo -e "${BLUE}Backing up all databases...${NC}"
else
    BACKUP_FILENAME="$DB_NAME-$DATE"
    MYSQLDUMP_CMD="mysqldump $AUTH_PARAMS --events --routines --triggers --databases $DB_NAME"
    echo -e "${BLUE}Backing up database: $DB_NAME${NC}"
fi

# Execute the backup
if [ "$COMPRESS" = true ]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME.sql.gz"
    echo -e "${BLUE}Creating compressed backup at: $BACKUP_FILE${NC}"
    $MYSQLDUMP_CMD | gzip > "$BACKUP_FILE"
else
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME.sql"
    echo -e "${BLUE}Creating backup at: $BACKUP_FILE${NC}"
    $MYSQLDUMP_CMD > "$BACKUP_FILE"
fi

# Check backup success
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Database backup completed successfully: $BACKUP_FILE${NC}"
    
    # Create checksum for verification
    md5sum "$BACKUP_FILE" > "$BACKUP_FILE.md5"
    
    # Clean up old backups if retention is enabled
    if [ $BACKUP_RETENTION_DAYS -gt 0 ]; then
        echo -e "${BLUE}Cleaning up backups older than $BACKUP_RETENTION_DAYS days...${NC}"
        find "$BACKUP_DIR" -name "*.sql*" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
        find "$BACKUP_DIR" -name "*.md5" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
    fi
    
    exit 0
else
    echo -e "${RED}Database backup failed!${NC}"
    exit 1
fi
