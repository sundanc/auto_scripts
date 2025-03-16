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

# Output files
REPORT_FILE="security_audit_$(date +%Y%m%d_%H%M%S).txt"
ISSUES_FOUND=0
CHECKS_PERFORMED=0

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}Warning: This script should be run as root for complete results${NC}"
   echo -e "${YELLOW}Some checks will be limited or skipped${NC}"
   echo ""
fi

# Header function
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Result reporting function
report() {
    local status=$1
    local message=$2
    local details=$3
    ((CHECKS_PERFORMED++))
    
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
    fi
    
    # Also write to report file
    if [[ "$status" == "PASS" ]]; then
        echo "[PASS] $message" >> $REPORT_FILE
    else
        echo "[$status] $message" >> $REPORT_FILE
        echo "       $details" >> $REPORT_FILE
    fi
}

echo -e "${BOLD}Security Audit Started: $(date)${NC}"
echo "Security Audit Report - $(date)" > $REPORT_FILE
echo "=============================" >> $REPORT_FILE

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
echo -e "${BOLD}Issues found:${NC} $ISSUES_FOUND"
echo -e "${BOLD}Report saved to:${NC} $REPORT_FILE"

if [[ $ISSUES_FOUND -gt 0 ]]; then
    echo -e "\n${YELLOW}${BOLD}Remediation needed!${NC} Please review the report and address the identified issues."
else
    echo -e "\n${GREEN}${BOLD}No issues found!${NC} System appears to be well configured."
fi

echo -e "\nSecurity Audit Completed: $(date)"