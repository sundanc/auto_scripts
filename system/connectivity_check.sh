#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
HOST="google.com"
OUTPUT_FILE=""
PING_COUNT=3
TIMEOUT=5
VERBOSE=false

# Load configuration from arsenal.conf if available
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/../config/arsenal.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    # Use DEFAULT_CONNECTIVITY_HOST from config if defined
    [ -n "$DEFAULT_CONNECTIVITY_HOST" ] && HOST="$DEFAULT_CONNECTIVITY_HOST"
    [ -n "$DEFAULT_LOG_DIR" ] && OUTPUT_FILE="$DEFAULT_LOG_DIR/connectivity_$(date +%Y%m%d).log"
fi

# Function to display usage information
usage() {
    echo "Usage: $0 [-h host] [-o output_file] [-c ping_count] [-t timeout] [-v]"
    echo "  -h: Host to check connectivity (default: $HOST)"
    echo "  -o: Output file (default: console only)"
    echo "  -c: Number of pings to send (default: $PING_COUNT)"
    echo "  -t: Timeout in seconds (default: $TIMEOUT)"
    echo "  -v: Verbose output"
    echo "  --help: Show this help"
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -c|--count)
            PING_COUNT="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
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
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Ensure host is specified
if [ -z "$HOST" ]; then
    echo -e "${RED}Error: No host specified${NC}"
    usage
    exit 1
fi

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    local color=""
    
    case "$level" in
        "INFO") color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "ERROR") color="$RED" ;;
        "WARNING") color="$YELLOW" ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
    
    if [ -n "$OUTPUT_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$OUTPUT_FILE"
    fi
}

log "INFO" "Checking connectivity to $HOST (count=$PING_COUNT, timeout=$TIMEOUT)"

# Check the connectivity
if $VERBOSE; then
    ping -c $PING_COUNT -W $TIMEOUT $HOST
    PING_STATUS=$?
else
    ping -c $PING_COUNT -W $TIMEOUT $HOST &> /dev/null
    PING_STATUS=$?
fi

# Output results
if [ $PING_STATUS -eq 0 ]; then
    log "SUCCESS" "$HOST is reachable"
    
    # Get more details if verbose mode is on
    if $VERBOSE; then
        log "INFO" "Performing traceroute to $HOST..."
        if command -v traceroute &> /dev/null; then
            traceroute -m 15 $HOST
        else
            log "WARNING" "traceroute command not found"
        fi
    fi
    
    exit 0
else
    log "ERROR" "$HOST is not reachable"
    
    # Suggest possible issues
    log "INFO" "Checking local network..."
    ip link | grep "state UP" &> /dev/null
    if [ $? -ne 0 ]; then
        log "WARNING" "No active network interfaces found"
    fi
    
    log "INFO" "Checking DNS resolution..."
    host $HOST &> /dev/null
    if [ $? -ne 0 ]; then
        log "WARNING" "DNS resolution for $HOST failed"
    fi
    
    exit 1
fi
