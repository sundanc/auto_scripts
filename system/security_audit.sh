#!/bin/bash
# filepath: /home/ary/Documents/auto_scripts/system/security_audit.sh
# GitHub: https://github.com/sundanc/auto_scripts
#
# Security Audit Script - Scans for common security vulnerabilities and configuration issues

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if the system is Linux-based
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}Error: This script is designed for Linux systems only.${NC}"
    exit 1
fi

# Load configuration from arsenal.conf if available
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/../config/arsenal.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Default configuration (can be overridden by arsenal.conf)
REPORT_DIR="${SECURITY_REPORT_DIR:-$(pwd)}"
SECURITY_LEVEL="${SECURITY_LEVEL:-normal}" # Options: basic, normal, thorough
SKIP_NETWORK_SCAN="${SKIP_NETWORK_SCAN:-false}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"
EMAIL_REPORT="${EMAIL_REPORT:-false}"

# Output files
REPORT_FILE="$REPORT_DIR/security_audit_$(date +%Y%m%d_%H%M%S).txt"
ISSUES_FOUND=0
CHECKS_PERFORMED=0
CHECKS_SKIPPED=0

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            REPORT_DIR="$2"
            REPORT_FILE="$REPORT_DIR/security_audit_$(date +%Y%m%d_%H%M%S).txt"
            shift 2
            ;;
        -l|--level)
            SECURITY_LEVEL="$2"
            shift 2
            ;;
        --skip-network)
            SKIP_NETWORK_SCAN=true
            shift
            ;;
        -e|--email)
            EMAIL_REPORT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -o, --output DIR    Directory to save report (default: current directory)"
            echo "  -l, --level LEVEL   Security level: basic, normal, thorough (default: normal)"
            echo "  --skip-network      Skip network security checks"
            echo "  -e, --email         Send report by email (requires configured ADMIN_EMAIL)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}Warning: This script should be run as root for complete results${NC}"
   echo -e "${YELLOW}Some checks will be limited or skipped${NC}"
   echo ""
fi

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Check dependencies
check_dependencies() {
    local missing_tools=()
    
    for tool in ss grep find stat awk; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warning: Missing tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Some security checks might be skipped${NC}"
    fi
}

# Ensure required credentials are provided (if applicable)
arsenal_prompt_missing_credentials "ADMIN_EMAIL" "Enter admin email for notifications"

# Header function
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Result reporting function with enhanced parameter handling
report() {
    local status=${1:-"INFO"}
    local message=${2:-"No message provided"}
    local details=${3:-""}
    local skip_if_nonroot=${4:-false}
    
    # Skip check if it requires root and we're not root
    if [[ "$skip_if_nonroot" == true && $EUID -ne 0 ]]; then
        ((CHECKS_SKIPPED++))
        echo -e "[${YELLOW}SKIP${NC}] $message (requires root)"
        echo "[SKIP] $message (requires root)" >> "$REPORT_FILE"
        return
    fi
    
    ((CHECKS_PERFORMED++))
    
    # Fix for missing closing block - ensure all if statements are properly closed
    if [[ "$status" == "PASS" ]]; then
        echo -e "[${GREEN}PASS${NC}] $message"
    elif [[ "$status" == "WARN" ]]; then
        echo -e "[${YELLOW}WARN${NC}] $message"
        ((ISSUES_FOUND++))
        echo -e "       ${YELLOW}$details${NC}"
    elif [[ "$status" == "FAIL" ]]; then
        echo -e "[${RED}FAIL${NC}] $message"
        ((ISSUES_FOUND++))
        echo -e "       ${RED}$details${NC}"
    elif [[ "$status" == "INFO" ]]; then
        echo -e "[${BLUE}INFO${NC}] $message"
        [[ -n "$details" ]] && echo -e "       ${BLUE}$details${NC}"
    fi
    
    # Also write to report file
    if [[ "$status" == "PASS" ]]; then
        echo "[PASS] $message" >> "$REPORT_FILE"
    elif [[ "$status" == "INFO" ]]; then
        echo "[INFO] $message" >> "$REPORT_FILE"
        [[ -n "$details" ]] && echo "       $details" >> "$REPORT_FILE"
    else
        echo "[$status] $message" >> "$REPORT_FILE"
        echo "       $details" >> "$REPORT_FILE"
    fi
}

# Execute a security check function if appropriate for current security level
run_security_check() {
    local check_function="$1"
    local required_level="$2"
    local description="$3"
    
    case "$SECURITY_LEVEL" in
        basic)
            [[ "$required_level" == "basic" ]] && $check_function
            ;;
        normal)
            [[ "$required_level" == "basic" || "$required_level" == "normal" ]] && $check_function
            ;;
        thorough)
            $check_function
            ;;
        *)
            echo "Invalid security level: $SECURITY_LEVEL"
            exit 1
            ;;
    esac
}

echo -e "${BOLD}Security Audit Started: $(date)${NC}"
echo "Security Audit Report - $(date)" > "$REPORT_FILE"
echo "Security Level: $SECURITY_LEVEL" >> "$REPORT_FILE"
echo "=============================" >> "$REPORT_FILE"

check_dependencies

# Check system updates
print_header "System Updates"
if command -v apt-get &> /dev/null; then
    apt_updates=$(apt-get -s upgrade | grep -i "upgraded," | awk '{print $1}')
    if [[ $apt_updates -gt 0 ]]; then
        report "WARN" "System updates available" "$apt_updates packages can be updated"
    else
        report "PASS" "System is up to date" 
    fi
elif command -v yum &> /dev/null; then
    yum_updates=$(yum check-update --quiet | grep -v "^$" | wc -l)
    if [[ $yum_updates -gt 0 ]]; then
        report "WARN" "System updates available" "$yum_updates packages can be updated"
    else
        report "PASS" "System is up to date"
    fi
fi

# Check open ports
print_header "Network Security"
if command -v ss &> /dev/null; then
    open_ports=$(ss -tuln | grep LISTEN)
    report "INFO" "Open ports detected" "$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -n | tr '\n' ' ')"
    
    # Check for specific dangerous ports
    if echo "$open_ports" | grep -q ":23 "; then
        report "FAIL" "Telnet port (23) is open" "Telnet is insecure and should be disabled"
    fi
fi

# SSH Configuration
print_header "SSH Configuration"
if [[ -f /etc/ssh/sshd_config ]]; then
    # Check root login
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        report "FAIL" "SSH root login enabled" "PermitRootLogin should be set to 'no' or 'prohibit-password'"
    else
        report "PASS" "SSH root login disabled"
    fi
    
    # Check password authentication
    if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
        report "WARN" "SSH password authentication enabled" "Consider using key-based authentication only"
    else
        report "PASS" "SSH password authentication disabled"
    fi
    
    # Check SSH Protocol version
    if grep -q "^Protocol 1" /etc/ssh/sshd_config; then
        report "FAIL" "SSH Protocol 1 enabled" "Protocol 1 is insecure, use Protocol 2 only"
    else
        report "PASS" "SSH using secure protocol version"
    fi
else
    report "INFO" "No SSH server configuration found" "SSH may not be installed"
fi

# Firewall status
print_header "Firewall Configuration"
if command -v ufw &> /dev/null; then
    ufw_status=$(ufw status | grep Status | awk '{print $2}')
    if [[ "$ufw_status" == "active" ]]; then
        report "PASS" "UFW firewall is active"
    else
        report "WARN" "UFW firewall is not active" "Consider enabling the firewall"
    fi
elif command -v iptables &> /dev/null; then
    iptables_rules=$(iptables -L | grep -v "Chain" | grep -v "target" | grep -v "^$" | wc -l)
    if [[ $iptables_rules -gt 0 ]]; then
        report "PASS" "Iptables firewall has rules configured"
    else
        report "WARN" "Iptables has no rules configured" "Firewall may not be properly set up"
    fi
else
    report "FAIL" "No firewall detected" "Consider installing and configuring a firewall"
fi

# User account security
print_header "User Account Security"
# Check for empty passwords
empty_pass=$(grep -v ':x:' /etc/passwd | cut -d: -f1)
if [[ -n "$empty_pass" ]]; then
    report "FAIL" "Users with empty passwords found" "$empty_pass"
else
    report "PASS" "No users with empty passwords"
fi

# Check for UID 0 accounts other than root
uid0=$(awk -F: '($3 == 0) {print $1}' /etc/passwd | grep -v root)
if [[ -n "$uid0" ]]; then
    report "FAIL" "Users with UID 0 (root) other than root" "$uid0"
else
    report "PASS" "No additional users with root UID"
fi

# Password policy
print_header "Password Policy"
if [[ -f /etc/pam.d/common-password ]]; then
    if grep -q "pam_pwquality.so" /etc/pam.d/common-password || grep -q "pam_cracklib.so" /etc/pam.d/common-password; then
        report "PASS" "Password quality requirements enforced"
    else
        report "WARN" "No password quality requirements" "Consider installing libpam-pwquality"
    fi
elif [[ -f /etc/security/pwquality.conf ]]; then
    report "PASS" "Password quality configuration exists"
else
    report "WARN" "No password quality requirements found" "Password policy may be insufficient"
fi

# File permissions
print_header "File Permissions"
# Check permissions on /etc/shadow
shadow_perms=$(stat -c "%a %u %g" /etc/shadow 2>/dev/null)
if [[ "$shadow_perms" == "640 0 0" || "$shadow_perms" == "600 0 0" ]]; then
    report "PASS" "/etc/shadow has secure permissions"
else
    report "FAIL" "/etc/shadow has insecure permissions" "Current: $shadow_perms, should be 640 or 600"
fi

# Check permissions on /etc/passwd
passwd_perms=$(stat -c "%a %u %g" /etc/passwd 2>/dev/null)
if [[ "$passwd_perms" == "644 0 0" ]]; then
    report "PASS" "/etc/passwd has secure permissions"
else
    report "FAIL" "/etc/passwd has insecure permissions" "Current: $passwd_perms, should be 644"
fi

# Check world-writable files
world_writable=$(find /etc -type f -perm -002 2>/dev/null | wc -l)
if [[ $world_writable -gt 0 ]]; then
    report "WARN" "World-writable files found in /etc" "$world_writable files are world-writable"
else
    report "PASS" "No world-writable files in /etc"
fi

# Kernel security parameters
print_header "Kernel Security Parameters"
if [[ -f /proc/sys/kernel/randomize_va_space ]]; then
    aslr=$(cat /proc/sys/kernel/randomize_va_space)
    if [[ "$aslr" == "2" ]]; then
        report "PASS" "Address Space Layout Randomization (ASLR) enabled"
    else
        report "WARN" "ASLR not fully enabled" "Value: $aslr, should be 2"
    fi
fi

# Check core dumps restriction
if [[ -f /proc/sys/fs/suid_dumpable ]]; then
    dumpable=$(cat /proc/sys/fs/suid_dumpable)
    if [[ "$dumpable" == "0" ]]; then
        report "PASS" "SUID core dumps restricted"
    else
        report "WARN" "SUID core dumps enabled" "This could expose sensitive information"
    fi
fi

# Summary
print_header "Audit Summary"
echo -e "${BOLD}Checks performed:${NC} $CHECKS_PERFORMED"
echo -e "${BOLD}Checks skipped:${NC} $CHECKS_SKIPPED"
echo -e "${BOLD}Issues found:${NC} $ISSUES_FOUND"
echo -e "${BOLD}Report saved to:${NC} $REPORT_FILE"

if [[ $ISSUES_FOUND -gt 0 ]]; then
    echo -e "\n${YELLOW}${BOLD}Remediation needed!${NC} Please review the report and address the identified issues."
else
    echo -e "\n${GREEN}${BOLD}No issues found!${NC} System appears to be well configured."
fi

# Send email if configured
if [[ "$EMAIL_REPORT" == "true" && -n "$ADMIN_EMAIL" ]]; then
    if command -v mail &> /dev/null; then
        cat "$REPORT_FILE" | mail -s "Security Audit Report - $(hostname) - $(date +%Y-%m-%d)" "$ADMIN_EMAIL"
        echo -e "${BLUE}Report sent to $ADMIN_EMAIL${NC}"
    else
        echo -e "${YELLOW}mail command not found. Cannot send email report.${NC}"
    fi
fi

echo -e "\nSecurity Audit Completed: $(date)"