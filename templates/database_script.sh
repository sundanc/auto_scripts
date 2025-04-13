#!/bin/bash
# IT Arsenal - Database Management Script Template
# GitHub: https://github.com/sundanc/auto_scripts
#
# SCRIPT NAME: [Your Script Name]
# DESCRIPTION: [Brief description of what this script does]
# AUTHOR: [Your Name]
# VERSION: 1.0

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../lib/common.sh" || {
    echo "Error: Could not source common library functions"
    exit 1
}

# Script variables
VERSION="1.0"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="${LOGS_DIR:-/tmp}/$(basename "$0" .sh)_$(date +%Y%m%d).log"

# Default database connection parameters
DB_HOST="${DB_DEFAULT_HOST:-localhost}"
DB_PORT="${DB_DEFAULT_PORT:-3306}"
DB_USER="${DB_DEFAULT_USER:-root}"
DB_NAME=""
DB_PASSWORD=""
CREDENTIALS_FILE="$CONFIG_DIR/credentials/db_credentials.conf"

# Display usage information
usage() {
    echo "Usage: $SCRIPT_NAME [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --host HOST         Database host (default: $DB_HOST)"
    echo "  -P, --port PORT         Database port (default: $DB_PORT)"
    echo "  -u, --user USER         Database user (default: $DB_USER)"
    echo "  -p, --password PASSWORD Database password (or will prompt)"
    echo "  -d, --database DB       Database name (required)"
    echo "  -o, --output FILE       Output file for results (default: stdout)"
    echo "  -v, --verbose           Enable verbose output"
    echo "  --help                  Display this help and exit"
    echo "  --version               Display version information and exit"
    echo
    echo "Examples:"
    echo "  $SCRIPT_NAME --database mydb --user dbuser"
    echo "  $SCRIPT_NAME --host dbserver --port 3307 --database mydb"
}

# Display version information
show_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

# Log message to file and console
log() {
    local level="$1"
    local message="$2"
    
    # Use arsenal_log if common.sh is loaded
    if command -v arsenal_log &>/dev/null; then
        arsenal_log "$level" "$message" "$SCRIPT_NAME"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
    fi
}

# Initialize the script
initialize() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    
    # Log script start
    log "INFO" "Database script started with args: $*"
    
    # Load database credentials if available
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        source "$CREDENTIALS_FILE"
        log "INFO" "Loaded database credentials from $CREDENTIALS_FILE"
    fi
    
    # Check for required database tools
    for cmd in mysql mysqldump; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "Required command not found: $cmd"
            echo "Error: $cmd not found. Please install MySQL client tools." >&2
            exit 1
        }
    done
}

# Clean up before exit
cleanup() {
    log "INFO" "Database script completed"
    # Add any cleanup operations here
}

# Parse command-line arguments
parse_arguments() {
    OUTPUT_FILE=""
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                DB_HOST="$2"
                shift 2
                ;;
            -P|--port)
                DB_PORT="$2"
                shift 2
                ;;
            -u|--user)
                DB_USER="$2"
                shift 2
                ;;
            -p|--password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            -d|--database)
                DB_NAME="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$DB_NAME" ]]; then
        echo "Error: Database name is required" >&2
        usage
        exit 1
    fi
    
    # If password not provided, check environment variable or prompt
    if [[ -z "$DB_PASSWORD" ]]; then
        if [[ -n "$MYSQL_PWD" ]]; then
            DB_PASSWORD="$MYSQL_PWD"
        elif [[ -n "$DB_PASS" ]]; then
            DB_PASSWORD="$DB_PASS"
        else
            read -sp "Enter password for MySQL user $DB_USER: " DB_PASSWORD
            echo
        fi
    fi
    
    # Export password as environment variable for MySQL clients
    export MYSQL_PWD="$DB_PASSWORD"
}

# Test database connection
test_connection() {
    log "INFO" "Testing database connection to $DB_HOST:$DB_PORT"
    
    if $VERBOSE; then
        log "INFO" "Connection parameters: Host=$DB_HOST, Port=$DB_PORT, User=$DB_USER, Database=$DB_NAME"
    fi
    
    # Try to connect and run a simple query
    if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -e "SELECT 1" >/dev/null 2>&1; then
        log "ERROR" "Failed to connect to database"
        echo "Error: Could not connect to database server" >&2
        return 1
    fi
    
    # Check if specified database exists
    if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -e "USE $DB_NAME" >/dev/null 2>&1; then
        log "ERROR" "Database '$DB_NAME' does not exist or access denied"
        echo "Error: Database '$DB_NAME' does not exist or access denied" >&2
        return 1
    fi
    
    log "INFO" "Database connection successful"
    return 0
}

# Main function that contains core functionality
main() {
    log "INFO" "Starting database operations"
    
    # Test database connection
    test_connection || return 1
    
    # Your main database script logic here
    echo "Hello from database script template!"
    echo "This is where your database operations would go."
    
    # Example database operation
    local result
    result=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "SHOW TABLES;" 2>&1)
    
    # Handle the output
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$result" > "$OUTPUT_FILE"
        log "INFO" "Results written to $OUTPUT_FILE"
    else
        echo "$result"
        log "INFO" "Results displayed to stdout"
    fi
    
    return 0
}

# Trap for cleanup on exit
trap cleanup EXIT

# Initialize and parse arguments
initialize "$@"
parse_arguments "$@"

# Execute main function and capture exit code
main
exit $?
