#!/bin/bash
# IT Arsenal - One-stop shop for IT automation
# Author: @sundanc
# GitHub: https://github.com/sundanc/auto_scripts

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
# Remove unused MAGENTA or add a comment explaining its purpose
# MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script locations
SCRIPTS_ROOT="$(dirname "$(readlink -f "$0")")"
SYSTEM_DIR="$SCRIPTS_ROOT/system"
DEV_DIR="$SCRIPTS_ROOT/development"
DEVOPS_DIR="$SCRIPTS_ROOT/devops"
DB_DIR="$SCRIPTS_ROOT/database"
CONFIG_DIR="$SCRIPTS_ROOT/config"
LOGS_DIR="$SCRIPTS_ROOT/logs"
LIB_DIR="$SCRIPTS_ROOT/lib"

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR" "$LOGS_DIR"

# Configuration file
CONFIG_FILE="$CONFIG_DIR/arsenal.conf"
# Use LOG_FILE in at least one function or add a comment explaining why it's defined
LOG_FILE="$LOGS_DIR/arsenal_$(date +%Y%m%d).log"
# Example: log "INFO" "Arsenal started" > "$LOG_FILE"

# Include common library functions
# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"

# Source compatibility checker
# shellcheck source=lib/compatibility_checker.sh
source "$LIB_DIR/compatibility_checker.sh" || {
    echo "Error: Could not source compatibility checker"
}

# Check for first-time setup
first_time_setup() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        display_header
        echo -e "${YELLOW}Welcome to IT Arsenal!${NC}"
        echo -e "It looks like this is your first time running the arsenal."
        echo -e "Let's set up a few basics to get you started."
        echo ""
        
        # Ask for admin email
        echo -ne "${YELLOW}Enter admin email for notifications [admin@example.com]: ${NC}"
        read -r admin_email
        admin_email=${admin_email:-"admin@example.com"}
        
        # Ask for environment
        echo -e "${YELLOW}Select environment:${NC}"
        echo -e "  1. Development"
        echo -e "  2. Staging"
        echo -e "  3. Production"
        echo -ne "Choice [3]: "
        read -r env_choice
        
        case $env_choice in
            1) environment="development" ;;
            2) environment="staging" ;;
            *) environment="production" ;;
        esac
        
        # Ask for backup directory
        echo -ne "${YELLOW}Enter backup directory [$HOME/backups]: ${NC}"
        read -r backup_dir
        backup_dir=${backup_dir:-"$HOME/backups"}
        
        # Create the config file
        arsenal_create_default_config
        arsenal_set_config "ADMIN_EMAIL" "$admin_email"
        arsenal_set_config "DEFAULT_ENVIRONMENT" "$environment"
        arsenal_set_config "DEFAULT_BACKUP_DIR" "$backup_dir"
        
        echo ""
        echo -e "${GREEN}Setup complete! Configuration saved to: $CONFIG_FILE${NC}"
        echo -e "${YELLOW}You can modify additional settings in the configuration menu.${NC}"
        echo ""
        read -rp "Press Enter to continue..."
    fi
}

# Check dependencies for arsenal
check_arsenal_dependencies() {
    arsenal_check_dependencies bash date grep sed awk find || true
}

# Initialize configuration
initialize_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        arsenal_create_default_config
    fi
    
    # Always source the configuration
    # shellcheck source=/dev/null
    arsenal_load_config
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    arsenal_log "$level" "$message" "arsenal"
}

# Function to display header
display_header() {
    clear
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${YELLOW}${BOLD}                 IT ARSENAL COMMAND CENTER${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo -e "  ${CYAN}Version: $ARSENAL_VERSION${NC}            ${CYAN}Author: @sundanc${NC}"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo ""
}

# Function to display main menu
display_main_menu() {
    display_header
    echo -e "${BOLD}CATEGORIES:${NC}"
    echo -e "  ${GREEN}1.${NC} System Administration Tools"
    echo -e "  ${GREEN}2.${NC} Development Tools"
    echo -e "  ${GREEN}3.${NC} DevOps & Deployment Tools"
    echo -e "  ${GREEN}4.${NC} Database Management Tools"
    echo -e ""
    echo -e "  ${GREEN}5.${NC} Configuration & Settings"
    echo -e "  ${GREEN}6.${NC} View Logs"
    echo -e "  ${GREEN}7.${NC} Update Arsenal"
    echo -e "  ${GREEN}8.${NC} About"
    echo -e "  ${GREEN}9.${NC} Check System Compatibility"
    echo -e "  ${GREEN}0.${NC} Exit"
    echo -e ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -ne "Enter your choice [0-9]: "
}

# Function to display system tools menu
display_system_menu() {
    display_header
    echo -e "${BOLD}SYSTEM ADMINISTRATION TOOLS:${NC}"
    echo -e "  ${GREEN}1.${NC} Security Audit (security_audit.sh)"
    echo -e "  ${GREEN}2.${NC} VM Detection (vm.sh)"
    echo -e "  ${GREEN}3.${NC} System Health Monitor (syshealth.sh)"
    echo -e "  ${GREEN}4.${NC} Disk Usage Monitor (disk_usage.sh)"
    echo -e "  ${GREEN}5.${NC} System Monitor (sys_monitor.sh)"
    echo -e "  ${GREEN}6.${NC} Service Health Check (health_check.sh)"
    echo -e "  ${GREEN}7.${NC} Connectivity Check (connectivity_check.sh)"
    echo -e "  ${GREEN}8.${NC} System Update & Upgrade (updateupgrade.sh)"
    echo -e "  ${GREEN}9.${NC} Display Uptime (uptime.sh)"
    echo -e "  ${GREEN}10.${NC} Network Diagnostics (network_diagnostics.sh)"
    echo -e "  ${GREEN}11.${NC} Log Analyzer (log_analyzer.sh)"
    echo -e "  ${GREEN}12.${NC} System Benchmark (system_benchmark.sh)"
    echo -e "  ${GREEN}13.${NC} Script Syntax Check (syntax_check.sh)"
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -ne "Enter your choice [0-13]: "
}

# Function to display development tools menu
display_dev_menu() {
    display_header
    echo -e "${BOLD}DEVELOPMENT TOOLS:${NC}"
    echo -e "  ${GREEN}1.${NC} Git Branch Manager (git_branch_management.sh)"
    echo -e "  ${GREEN}2.${NC} Auto Git (autogit.sh)"
    echo -e "  ${GREEN}3.${NC} Create Python Environment (create_env.sh)"
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -e ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -ne "Enter your choice [0-3]: "
}

# Function to display DevOps tools menu
display_devops_menu() {
    display_header
    echo -e "${BOLD}DEVOPS & DEPLOYMENT TOOLS:${NC}"
    echo -e "  ${GREEN}1.${NC} CI/CD Automation (ci_cd_auto.sh)"
    echo -e "  ${GREEN}2.${NC} Deployment Tool (deploy.sh)"
    echo -e "  ${GREEN}3.${NC} Backup Tool (backup.sh)"
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -e ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -ne "Enter your choice [0-3]: "
}

# Function to display database tools menu
display_db_menu() {
    display_header
    echo -e "${BOLD}DATABASE MANAGEMENT TOOLS:${NC}"
    echo -e "  ${GREEN}1.${NC} Database Backup (database_backup.sh)"
    echo -e "  ${GREEN}2.${NC} Advanced Database Management (autodb.sh)"
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -e ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -ne "Enter your choice [0-2]: "
}

# Function to configure arsenal settings
configure_settings() {
    display_header
    echo -e "${BOLD}ARSENAL CONFIGURATION:${NC}"
    echo -e "Current settings:"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    # Replace useless cat with < redirection
    grep -v "^#" < "$CONFIG_FILE" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            key=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2- | tr -d '"')
            echo -e "  ${YELLOW}${key}:${NC} ${value}"
        fi
    done
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    
    echo -e "\nOptions:"
    echo -e "  ${GREEN}1.${NC} Edit configuration file"
    echo -e "  ${GREEN}2.${NC} Reset to defaults"
    echo -ne "Enter your choice [0-2]: "
    
    read -r choice
    case $choice in
        1)
            if command -v nano &>/dev/null; then
                nano "$CONFIG_FILE"
            elif command -v vi &>/dev/null; then
                vi "$CONFIG_FILE"
            else
                echo "No text editor found. Please install nano or vi."
                read -rp "Press Enter to continue..."
            fi
            # shellcheck source=/dev/null
            source "$CONFIG_FILE"
            ;;
        2)
            read -rp "Are you sure you want to reset configuration to defaults? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$CONFIG_FILE"
                initialize_config
                echo "Configuration reset to defaults."
            fi
            read -rp "Press Enter to continue..."
            ;;
        *)
            # Return to main menu
            ;;
    esac
}

# View logs function
view_logs() {
    display_header
    echo -e "${BOLD}LOG FILES:${NC}"
    
    if [[ -d "$LOGS_DIR" ]]; then
        local log_files=("$LOGS_DIR"/*)
        if [[ ${#log_files[@]} -eq 0 || ( ${#log_files[@]} -eq 1 && ! -f "${log_files[0]}" ) ]]; then
            echo -e "${YELLOW}No log files found.${NC}"
        else
            local counter=1
            for log in "$LOGS_DIR"/*; do
                if [[ -f "$log" ]]; then
                    echo -e "  ${GREEN}${counter}.${NC} $(basename "$log") ($(du -h "$log" | cut -f1))"
                    ((counter++))
                fi
            done
        fi
    else
        echo -e "${YELLOW}Log directory not found.${NC}"
    fi
    
    echo -e ""
    echo -e "  ${GREEN}V.${NC} View a log file"
    echo -e "  ${GREEN}C.${NC} Clear all logs"
    echo -ne "Enter your choice: "
    
    read -r choice
    case $choice in
        [Vv])
            echo -ne "Enter the number of the log file to view: "
            read -r log_number
            
            counter=1
            for log in "$LOGS_DIR"/*; do
                if [[ -f "$log" && $counter -eq $log_number ]]; then
                    if command -v less &>/dev/null; then
                        less "$log"
                    else
                        # Replace useless cat with more direct command
                        more "$log"
                    fi
                    break
                fi
                ((counter++))
            done
            ;;
        [Cc])
            read -rp "Are you sure you want to clear all logs? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$LOGS_DIR"/*
                echo "All logs cleared."
            fi
            ;;
    esac
    
    read -rp "Press Enter to continue..."
}

# Update arsenal function
update_arsenal() {
    display_header
    echo -e "${BOLD}UPDATE IT ARSENAL:${NC}"
    
    if [[ -d "$SCRIPTS_ROOT/.git" ]]; then
        echo -e "Checking for updates..."
        
        # Backup local config
        cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
        
        if git -C "$SCRIPTS_ROOT" pull; then
            echo -e "${GREEN}Arsenal updated successfully!${NC}"
            
            # Restore local config
            if [[ -f "$CONFIG_FILE.bak" ]]; then
                mv "$CONFIG_FILE.bak" "$CONFIG_FILE"
            fi
        else
            echo -e "${RED}Update failed.${NC}"
        fi
    else
        echo -e "${YELLOW}This is not a git repository. Manual update required.${NC}"
    fi
    
    read -rp "Press Enter to continue..."
}

# About function
show_about() {
    display_header
    echo -e "${BOLD}ABOUT IT ARSENAL:${NC}"
    echo -e "  ${YELLOW}IT Arsenal${NC} is a comprehensive collection of automation scripts"
    echo -e "  designed to simplify system administration, development, DevOps,"
    echo -e "  and database management tasks."
    echo -e ""
    echo -e "${BOLD}VERSION:${NC} 1.0"
    echo -e "${BOLD}AUTHOR:${NC} @sundanc"
    echo -e "${BOLD}LICENSE:${NC} MIT"
    echo -e "${BOLD}REPOSITORY:${NC} https://github.com/sundanc/auto_scripts"
    echo -e ""
    echo -e "${BOLD}INSTALLED COMPONENTS:${NC}"
    echo -e "  - System Tools: $(find "$SYSTEM_DIR" -name "*.sh" | wc -l)"
    echo -e "  - Development Tools: $(find "$DEV_DIR" -name "*.sh" | wc -l)"
    echo -e "  - DevOps Tools: $(find "$DEVOPS_DIR" -name "*.sh" | wc -l)"
    echo -e "  - Database Tools: $(find "$DB_DIR" -name "*.sh" | wc -l)"
    echo -e ""
    
    read -rp "Press Enter to continue..."
}

# Execute a script with proper error handling
execute_script() {
    local script="$1"
    # Fix declaration and assignment to avoid SC2155
    local script_name
    script_name=$(basename "$script")
    
    if [[ ! -f "$script" ]]; then
        echo -e "${RED}Error: Script not found: $script${NC}"
        log "ERROR" "Script not found: $script"
        read -rp "Press Enter to continue..."
        return 1
    fi
    
    # Check script compatibility before execution
    if ! check_script_compatibility "$script_name" "false"; then
        echo -e "${YELLOW}⚠️ Warning: $script_name may not be fully compatible with your system${NC}"
        echo -e "${YELLOW}Checking compatibility...${NC}"
        check_script_compatibility "$script_name" "true"
        
        if ! confirm "Continue with execution anyway?" "n"; then
            echo -e "${YELLOW}Execution cancelled by user${NC}"
            read -rp "Press Enter to continue..."
            return 1
        fi
    fi
    
    if [[ ! -x "$script" ]]; then
        echo -e "${YELLOW}Making script executable: $script_name${NC}"
        chmod +x "$script"
    fi
    
    display_header
    echo -e "${BOLD}Executing: $script_name${NC}"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    
    log "INFO" "Starting script: $script_name"
    
    if [[ "$script" == "$DEV_DIR/create_env.sh" ]]; then
        # Special case for create_env.sh which needs to be sourced
        # shellcheck source=/dev/null
        source "$script"
    else
        # Normal execution
        "$script"
    fi
    
    local exit_code=$?
    
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}Script executed successfully.${NC}"
        log "INFO" "Script completed: $script_name (Success)"
    else
        echo -e "${RED}Script exited with error code: $exit_code${NC}"
        log "ERROR" "Script failed: $script_name (Exit code: $exit_code)"
        
        # Offer debugging help
        echo -e "${YELLOW}Would you like to run a compatibility check to debug issues?${NC}"
        if confirm "Run compatibility check?" "y"; then
            debug_script_requirements "$script_name"
        fi
    fi
    
    read -rp "Press Enter to continue..."
}

# Handle system tools menu
handle_system_menu() {
    while true; do
        display_system_menu
        read -r choice
        
        case $choice in
            1)
                execute_script "$SYSTEM_DIR/security_audit.sh"
                ;;
            2)
                execute_script "$SYSTEM_DIR/vm.sh"
                ;;
            3)
                execute_script "$SYSTEM_DIR/syshealth.sh"
                ;;
            4)
                execute_script "$SYSTEM_DIR/disk_usage.sh"
                ;;
            5)
                execute_script "$SYSTEM_DIR/sys_monitor.sh"
                ;;
            6)
                execute_script "$SYSTEM_DIR/health_check.sh"
                ;;
            7)
                execute_script "$SYSTEM_DIR/connectivity_check.sh"
                ;;
            8)
                execute_script "$SYSTEM_DIR/updateupgrade.sh"
                ;;
            9)
                execute_script "$SYSTEM_DIR/uptime.sh"
                ;;
            10)
                execute_script "$SYSTEM_DIR/network_diagnostics.sh"
                ;;
            11)
                execute_script "$SYSTEM_DIR/log_analyzer.sh"
                ;;
            12)
                execute_script "$SYSTEM_DIR/system_benchmark.sh"
                ;;
            13)
                execute_script "$SYSTEM_DIR/syntax_check.sh"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle development tools menu
handle_dev_menu() {
    while true; do
        display_dev_menu
        read -r choice
        
        case $choice in
            1)
                execute_script "$DEV_DIR/git_branch_management.sh"
                ;;
            2)
                execute_script "$DEV_DIR/autogit.sh"
                ;;
            3)
                execute_script "$DEV_DIR/create_env.sh"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle devops tools menu
handle_devops_menu() {
    while true; do
        display_devops_menu
        read -r choice
        
        case $choice in
            1)
                execute_script "$DEVOPS_DIR/ci_cd_auto.sh"
                ;;
            2)
                execute_script "$DEVOPS_DIR/deploy.sh"
                ;;
            3)
                execute_script "$DEVOPS_DIR/backup.sh"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle database tools menu
handle_db_menu() {
    while true; do
        display_db_menu
        read -r choice
        
        case $choice in
            1)
                execute_script "$DB_DIR/database_backup.sh"
                ;;
            2)
                execute_script "$DB_DIR/autodb.sh"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

# Enhanced main function
main() {
    check_arsenal_dependencies
    initialize_config
    first_time_setup
    
    log "INFO" "IT Arsenal started"
    
    while true; do
        display_main_menu
        read -r choice
        
        case $choice in
            1)
                handle_system_menu
                ;;
            2)
                handle_dev_menu
                ;;
            3)
                handle_devops_menu
                ;;
            4)
                handle_db_menu
                ;;
            5)
                configure_settings
                ;;
            6)
                view_logs
                ;;
            7)
                update_arsenal
                ;;
            8)
                show_about
                ;;
            9)
                display_header
                echo -e "${BOLD}SYSTEM COMPATIBILITY CHECK${NC}"
                # Initialize dependency database
                # shellcheck source=lib/compatibility_checker.sh
                source "$LIB_DIR/compatibility_checker.sh"
                init_dependency_database
                
                echo -e "${YELLOW}Running system-wide compatibility check...${NC}"
                check_system_compatibility "$SCRIPTS_ROOT" "true"
                read -rp "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}Thank you for using IT Arsenal. Goodbye!${NC}"
                log "INFO" "IT Arsenal exited"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the application
main
