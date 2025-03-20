#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Log Analyzer - Identify patterns and issues in system logs

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default configuration
LOG_DIR="/var/log"
REPORT_FILE="$HOME/log_analysis_$(date +%Y%m%d_%H%M%S).txt"
MAX_ENTRIES=1000
DEFAULT_LOGS=("syslog" "auth.log" "dmesg" "kern.log" "messages")
CUSTOM_LOG=""

# Print help message
show_help() {
    echo -e "${BOLD}Log Analyzer - Usage:${NC}"
    echo -e "  $0 [options]"
    echo -e ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  -h, --help          Show this help message"
    echo -e "  -l, --log FILE      Analyze a specific log file"
    echo -e "  -d, --days DAYS     Analyze logs from the last DAYS days (default: all)"
    echo -e "  -o, --output FILE   Save report to FILE (default: $REPORT_FILE)"
    echo -e "  -m, --max ENTRIES   Maximum entries to analyze per log (default: $MAX_ENTRIES)"
    echo -e ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  $0 --log /var/log/syslog"
    echo -e "  $0 --days 3 --output /tmp/report.txt"
    exit 0
}

# Process command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -l|--log)
            CUSTOM_LOG="$2"
            shift 2
            ;;
        -d|--days)
            DAYS="$2"
            shift 2
            ;;
        -o|--output)
            REPORT_FILE="$2"
            shift 2
            ;;
        -m|--max)
            MAX_ENTRIES="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Function to print headers
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
    echo -e "\n=== $1 ===\n" >> "$REPORT_FILE"
}

# Function to analyze a log file
analyze_log() {
    local log_file="$1"
    local log_name=$(basename "$log_file")
    
    # Skip if file doesn't exist or isn't readable
    if [[ ! -f "$log_file" || ! -r "$log_file" ]]; then
        echo -e "${YELLOW}Skipping $log_name: Not found or not readable${NC}"
        return
    fi
    
    echo -e "${CYAN}Analyzing $log_name...${NC}"
    print_header "$log_name Analysis"
    
    # If days specified, use only recent logs
    if [[ -n "$DAYS" ]]; then
        log_content=$(find "$log_file" -mtime -"$DAYS" -exec cat {} \; 2>/dev/null | tail -n $MAX_ENTRIES)
        echo -e "Analyzing logs from the past $DAYS days..." >> "$REPORT_FILE"
    else
        log_content=$(cat "$log_file" 2>/dev/null | tail -n $MAX_ENTRIES)
    fi
    
    # Error pattern detection
    echo -e "${YELLOW}Looking for error patterns...${NC}"
    echo -e "\n--- Error Patterns ---\n" >> "$REPORT_FILE"
    
    # General errors
    errors=$(echo "$log_content" | grep -i "error\|fail\|critical\|emergency\|alert" | sort | uniq -c | sort -nr)
    if [[ -n "$errors" ]]; then
        echo -e "${RED}Found error patterns:${NC}"
        echo "$errors" | head -10
        echo "$errors" >> "$REPORT_FILE"
    else
        echo -e "${GREEN}No common error patterns found${NC}"
        echo "No common error patterns found" >> "$REPORT_FILE"
    fi
    
    # Authentication failures
    if [[ "$log_name" == "auth.log" ]]; then
        echo -e "\n${YELLOW}Checking for authentication failures...${NC}"
        echo -e "\n--- Authentication Failures ---\n" >> "$REPORT_FILE"
        
        auth_failures=$(echo "$log_content" | grep -i "authentication failure\|failed password\|invalid user")
        if [[ -n "$auth_failures" ]]; then
            failed_count=$(echo "$auth_failures" | wc -l)
            echo -e "${RED}Found $failed_count authentication failures${NC}"
            
            # Extract usernames and IP addresses
            failed_users=$(echo "$auth_failures" | grep -oE "user [a-zA-Z0-9_-]+" | sort | uniq -c | sort -nr)
            failed_ips=$(echo "$auth_failures" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -nr)
            
            echo -e "Top failed usernames:" >> "$REPORT_FILE"
            echo "$failed_users" >> "$REPORT_FILE"
            echo -e "\nTop source IPs:" >> "$REPORT_FILE"
            echo "$failed_ips" >> "$REPORT_FILE"
            
            echo -e "${RED}Top 5 failed usernames:${NC}"
            echo "$failed_users" | head -5
            echo -e "${RED}Top 5 source IPs:${NC}"
            echo "$failed_ips" | head -5
        else
            echo -e "${GREEN}No authentication failures found${NC}"
            echo "No authentication failures found" >> "$REPORT_FILE"
        fi
    fi
    
    # Service restarts
    echo -e "\n${YELLOW}Checking for service restarts...${NC}"
    echo -e "\n--- Service Restarts ---\n" >> "$REPORT_FILE"
    
    restarts=$(echo "$log_content" | grep -i "restart\|started\|starting\|stopped\|stopping" | grep -v "kernel" | sort | uniq -c | sort -nr)
    if [[ -n "$restarts" ]]; then
        echo -e "${MAGENTA}Service restart activities:${NC}"
        echo "$restarts" | head -10
        echo "$restarts" >> "$REPORT_FILE"
    else
        echo -e "${GREEN}No service restart activity found${NC}"
        echo "No service restart activity found" >> "$REPORT_FILE"
    fi
    
    # Time-based analysis
    echo -e "\n${YELLOW}Performing time-based analysis...${NC}"
    echo -e "\n--- Time Distribution ---\n" >> "$REPORT_FILE"
    
    # Extract hours if timestamps exist
    hour_distribution=$(echo "$log_content" | grep -oE "([0-9]{2}:){2}[0-9]{2}" | cut -d: -f1 | sort | uniq -c | sort -k2n)
    if [[ -n "$hour_distribution" ]]; then
        echo -e "${CYAN}Log activity distribution by hour:${NC}"
        echo "$hour_distribution"
        echo "$hour_distribution" >> "$REPORT_FILE"
        
        # Find the hour with most activity
        max_hour=$(echo "$hour_distribution" | sort -nr | head -1)
        echo -e "${YELLOW}Peak activity: $max_hour${NC}"
        echo -e "Peak activity: $max_hour" >> "$REPORT_FILE"
    else
        echo -e "${YELLOW}Could not determine time distribution${NC}"
        echo "Could not determine time distribution" >> "$REPORT_FILE"
    fi
    
    # Resource issues
    echo -e "\n${YELLOW}Checking for resource issues...${NC}"
    echo -e "\n--- Resource Issues ---\n" >> "$REPORT_FILE"
    
    resource_issues=$(echo "$log_content" | grep -i "out of memory\|low on memory\|disk full\|no space\|high load\|cpu usage")
    if [[ -n "$resource_issues" ]]; then
        issue_count=$(echo "$resource_issues" | wc -l)
        echo -e "${RED}Found $issue_count potential resource issues${NC}"
        echo "$resource_issues" | head -10
        echo "$resource_issues" >> "$REPORT_FILE"
    else
        echo -e "${GREEN}No resource issues detected${NC}"
        echo "No resource issues detected" >> "$REPORT_FILE"
    fi
}

# Initialize report file
echo "Log Analysis Report" > "$REPORT_FILE"
echo "Generated on: $(date)" >> "$REPORT_FILE"
echo "System: $(hostname)" >> "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"

# Banner
echo -e "${BOLD}${BLUE}=================================${NC}"
echo -e "${BOLD}${BLUE}      LOG ANALYZER TOOL         ${NC}"
echo -e "${BOLD}${BLUE}=================================${NC}"

# If custom log specified, analyze only that one
if [[ -n "$CUSTOM_LOG" ]]; then
    if [[ -f "$CUSTOM_LOG" ]]; then
        analyze_log "$CUSTOM_LOG"
    else
        echo -e "${RED}Error: Specified log file '$CUSTOM_LOG' not found${NC}"
        exit 1
    fi
else
    # Analyze default log files
    echo -e "${CYAN}Starting analysis of standard system logs...${NC}"
    for log in "${DEFAULT_LOGS[@]}"; do
        analyze_log "$LOG_DIR/$log"
    done
    
    # Additional standard logs if they exist
    if [[ -d "$LOG_DIR/apache2" ]]; then
        analyze_log "$LOG_DIR/apache2/error.log"
    fi
    
    if [[ -d "$LOG_DIR/nginx" ]]; then
        analyze_log "$LOG_DIR/nginx/error.log"
    fi
fi

# Report summary
echo -e "\n${GREEN}${BOLD}Analysis Complete!${NC}"
echo -e "Detailed report saved to: ${BLUE}$REPORT_FILE${NC}"
