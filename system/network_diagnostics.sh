#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Network Diagnostics Tool - Comprehensive network troubleshooting

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Create temporary results directory
TEMP_DIR=$(mktemp -d)
RESULTS_FILE="$TEMP_DIR/network_results.txt"
TARGET_HOSTS=("google.com" "cloudflare.com" "github.com")
DNS_SERVERS=("8.8.8.8" "1.1.1.1")

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
    echo -e "=== $1 ===" >> $RESULTS_FILE
}

# Function to run a test and capture output
run_test() {
    local cmd="$1"
    local description="$2"
    local success_pattern="${3:-}"
    
    echo -e "${YELLOW}$description...${NC}"
    echo -e "\n--- $description ---\n" >> $RESULTS_FILE
    
    # Run the command and capture output
    output=$(eval $cmd 2>&1)
    status=$?
    
    # Save output to results file
    echo "$output" >> $RESULTS_FILE
    
    # Check for success
    if [[ $status -eq 0 ]]; then
        if [[ -z "$success_pattern" || "$output" =~ $success_pattern ]]; then
            echo -e "${GREEN}✓ Success${NC}"
        else
            echo -e "${YELLOW}⚠ Completed with potential issues${NC}"
        fi
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    
    # Return a snippet of the output
    echo "$output" | head -n 3
    if [[ $(echo "$output" | wc -l) -gt 3 ]]; then
        echo "..."
    fi
}

# Print diagnostic start info
echo -e "${BOLD}Network Diagnostics Tool${NC}"
echo -e "Starting comprehensive network diagnostics. This may take a minute..."
echo "Network Diagnostics Report - $(date)" > $RESULTS_FILE
echo "System: $(hostname)" >> $RESULTS_FILE
echo "Date: $(date)" >> $RESULTS_FILE
echo "-----------------------------------" >> $RESULTS_FILE

# 1. Network Interface Information
print_header "NETWORK INTERFACES"
run_test "ip addr show" "Checking network interfaces"

# 2. DNS Resolution Tests
print_header "DNS RESOLUTION"
for host in "${TARGET_HOSTS[@]}"; do
    run_test "dig +short $host" "Testing DNS resolution for $host" "^[0-9]"
done

# 3. Ping Tests
print_header "CONNECTIVITY TESTS"
for host in "${TARGET_HOSTS[@]}"; do
    run_test "ping -c 4 -W 2 $host" "Testing connectivity to $host" "0% packet loss"
done

# 4. DNS Server Tests
print_header "DNS SERVER TESTS"
for dns in "${DNS_SERVERS[@]}"; do
    run_test "dig @$dns +short google.com" "Testing DNS server $dns" "^[0-9]"
done

# 5. Default Gateway Test
print_header "DEFAULT GATEWAY"
gateway=$(ip route | grep default | awk '{print $3}')
if [[ -n "$gateway" ]]; then
    run_test "ping -c 4 -W 2 $gateway" "Testing connectivity to default gateway ($gateway)" "0% packet loss"
else
    echo -e "${RED}No default gateway found!${NC}"
    echo "No default gateway found!" >> $RESULTS_FILE
fi

# 6. Traceroute to Primary Target
print_header "ROUTE ANALYSIS"
run_test "traceroute -m 15 google.com" "Analyzing network route to google.com"

# 7. Internet Speed Test (if speedtest-cli is installed)
print_header "INTERNET SPEED"
if command -v speedtest-cli &> /dev/null; then
    run_test "speedtest-cli --simple" "Testing internet speed"
else
    echo -e "${YELLOW}speedtest-cli not installed. Skipping speed test.${NC}"
    echo "speedtest-cli not installed. Skipping speed test." >> $RESULTS_FILE
    echo -e "To install: ${BLUE}pip install speedtest-cli${NC}"
fi

# 8. Network Ports Scan
print_header "OPEN PORTS"
run_test "ss -tuln" "Checking for listening ports"

# 9. Network Load
print_header "NETWORK LOAD"
run_test "sar -n DEV 1 3" "Checking network load" || 
    run_test "netstat -i" "Checking network interface statistics"

# 10. Network Hardware Status
print_header "NETWORK HARDWARE"
run_test "ethtool $(ip route show default | awk '{print $5}')" "Checking network adapter status" ||
    echo -e "${YELLOW}ethtool not available. Skipping hardware check.${NC}"

# Final report
final_report="$HOME/network_diagnostics_$(date +%Y%m%d_%H%M%S).txt"
cp $RESULTS_FILE $final_report
echo -e "\n${GREEN}${BOLD}Diagnostics Complete!${NC}"
echo -e "Detailed report saved to: ${BLUE}$final_report${NC}"

# Cleanup
rm -rf $TEMP_DIR
