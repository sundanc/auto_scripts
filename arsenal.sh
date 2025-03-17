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
MAGENTA='\033[0;35m'
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

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR" "$LOGS_DIR"

# Configuration file
CONFIG_FILE="$CONFIG_DIR/arsenal.conf"
LOG_FILE="$LOGS_DIR/arsenal_$(date +%Y%m%d).log"

# Initialize configuration if it doesn't exist
initialize_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "# IT Arsenal Configuration" > "$CONFIG_FILE"
        echo "ADMIN_EMAIL=\"admin@example.com\"" >> "$CONFIG_FILE"
        echo "NOTIFICATION_ENABLED=\"yes\"" >> "$CONFIG_FILE"
        echo "LOG_LEVEL=\"INFO\"" >> "$CONFIG_FILE"
        echo "DEFAULT_BACKUP_DIR=\"$HOME/backups\"" >> "$CONFIG_FILE"
        echo "DEFAULT_ENVIRONMENT=\"production\"" >> "$CONFIG_FILE"
        echo "MONITOR_INTERVAL=\"5\"" >> "$CONFIG_FILE"
        echo "HEALTH_CHECK_THRESHOLD=\"85\"" >> "$CONFIG_FILE"
        echo "Created default configuration file: $CONFIG_FILE"
    fi
    
    # Source the configuration
    source "$CONFIG_FILE"
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [${level}] ${message}" | tee -a "$LOG_FILE"
    
    # Send critical errors via email if configured
    if [[ "$level" == "CRITICAL" && "$NOTIFICATION_ENABLED" == "yes" ]]; then
        if command -v mail &>/dev/null; then
            echo "$message" | mail -s "IT Arsenal - CRITICAL ALERT" "$ADMIN_EMAIL"
        fi
    fi
}

# Function to display header
display_header() {
    clear
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${YELLOW}${BOLD}                 IT ARSENAL COMMAND CENTER${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo -e "  ${CYAN}Version: 1.0${NC}            ${CYAN}Author: @sundanc${NC}"
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
    echo -e "  ${GREEN}0.${NC} Exit"
    echo -e ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -ne "Enter your choice [0-8]: "
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
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -e ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -ne "Enter your choice [0-9]: "
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
    cat "$CONFIG_FILE" | grep -v "^#" | while IFS= read -r line; do
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
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -e ""
    echo -ne "Enter your choice [0-2]: "
    
    read choice
    case $choice in
        1)
            if command -v nano &>/dev/null; then
                nano "$CONFIG_FILE"
            elif command -v vi &>/dev/null; then
                vi "$CONFIG_FILE"
            else
                echo "No text editor found. Please install nano or vi."
                read -p "Press Enter to continue..."
            fi
            source "$CONFIG_FILE"
            ;;
        2)
            read -p "Are you sure you want to reset configuration to defaults? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$CONFIG_FILE"
                initialize_config
                echo "Configuration reset to defaults."
            fi
            read -p "Press Enter to continue..."
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
    echo -e "  ${GREEN}0.${NC} Back to Main Menu"
    echo -e ""
    echo -ne "Enter your choice: "
    
    read choice
    case $choice in
        [Vv])
            echo -ne "Enter the number of the log file to view: "
            read log_number
            
            counter=1
            for log in "$LOGS_DIR"/*; do
                if [[ -f "$log" && $counter -eq $log_number ]]; then
                    if command -v less &>/dev/null; then
                        less "$log"
                    else
                        cat "$log" | more
                    fi
                    break
                fi
                ((counter++))
            done
            ;;
        [Cc])
            read -p "Are you sure you want to clear all logs? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$LOGS_DIR"/*
                echo "All logs cleared."
            fi
            ;;
    esac
    
    read -p "Press Enter to continue..."
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
    
    read -p "Press Enter to continue..."
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
    
    read -p "Press Enter to continue..."
}

# Execute a script with proper error handling
execute_script() {
    local script="$1"
    local script_name=$(basename "$script")
    
    if [[ ! -f "$script" ]]; then
        echo -e "${RED}Error: Script not found: $script${NC}"
        log "ERROR" "Script not found: $script"
        read -p "Press Enter to continue..."
        return 1
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
    fi
    
    read -p "Press Enter to continue..."
}

# Handle system tools menu
handle_system_menu() {
    while true; do
        display_system_menu
        read choice
        
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
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle development tools menu
handle_dev_menu() {
    while true; do
        display_dev_menu
        read choice
        
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
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle devops tools menu
handle_devops_menu() {
    while true; do
        display_devops_menu
        read choice
        
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
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle database tools menu
handle_db_menu() {
    while true; do
        display_db_menu
        read choice
        
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
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main function
main() {
    initialize_config
    log "INFO" "IT Arsenal started"
    
    while true; do
        display_main_menu
        read choice
        
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
            0)
                echo -e "${GREEN}Thank you for using IT Arsenal. Goodbye!${NC}"
                log "INFO" "IT Arsenal exited"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the application
main
