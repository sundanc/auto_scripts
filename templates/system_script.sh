#!/bin/bash
# IT Arsenal - System Administration Script Template
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

# Color definitions (if not using common.sh)
# GREEN='\033[0;32m'
# RED='\033[0;31m'
# YELLOW='\033[1;33m'
# BLUE='\033[0;34m'
# NC='\033[0m' # No Color

# Display usage information
usage() {
    echo "Usage: $SCRIPT_NAME [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --parameter VALUE   Description of the parameter"
    echo "  -f, --flag              Enable some feature"
    echo "  -o, --output FILE       Output file (default: stdout)"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -h, --help              Display this help and exit"
    echo "  --version               Display version information and exit"
    echo
    echo "Examples:"
    echo "  $SCRIPT_NAME --parameter value --flag"
    echo "  $SCRIPT_NAME --output results.txt"
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
    log "INFO" "Script started with args: $*"
    
    # Check required dependencies
    if command -v arsenal_check_dependencies &>/dev/null; then
        arsenal_check_dependencies bash grep sed awk || {
            log "ERROR" "Missing required dependencies"
            exit 1
        }
    else
        # Fallback dependency check if common.sh isn't available
        for cmd in bash grep sed awk; do
            command -v "$cmd" >/dev/null 2>&1 || {
                log "ERROR" "Required command not found: $cmd"
                exit 1
            }
        done
    fi
}

# Clean up before exit
cleanup() {
    log "INFO" "Script completed"
    # Add any cleanup operations here
}

# Parse command-line arguments
parse_arguments() {
    PARAMETER=""
    FLAG=false
    OUTPUT_FILE=""
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--parameter)
                PARAMETER="$2"
                shift 2
                ;;
            -f|--flag)
                FLAG=true
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$PARAMETER" && "$REQUIRE_PARAMETER" == "true" ]]; then
        echo "Error: Parameter is required"
        usage
        exit 1
    fi
}

# Main function that contains core functionality
main() {
    log "INFO" "Starting main function"
    
    # If verbose mode is enabled, show additional information
    if $VERBOSE; then
        log "INFO" "Verbose mode enabled"
        log "INFO" "Parameter: $PARAMETER"
        log "INFO" "Flag: $FLAG"
        log "INFO" "Output file: ${OUTPUT_FILE:-stdout}"
    fi
    
    # Your main script logic here
    echo "Hello from system script template!"
    echo "This is where your script functionality would go."
    
    # Example operation with output handling
    local result="Operation completed successfully"
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
