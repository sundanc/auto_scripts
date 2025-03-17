#!/bin/bash
# Integration functions for IT Arsenal
# GitHub: https://github.com/sundanc/auto_scripts

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"

# =============================================
# CROSS-SCRIPT INTEGRATION FUNCTIONS
# =============================================

# Function to run a security audit and then update/upgrade the system
arsenal_secure_and_update() {
  local security_audit="$ARSENAL_ROOT/system/security_audit.sh"
  local update_script="$ARSENAL_ROOT/system/updateupgrade.sh"
  
  if [[ -f "$security_audit" && -f "$update_script" ]]; then
    echo "Running security audit before system update..."
    "$security_audit"
    
    # Only update if the user confirms
    if arsenal_confirm "Security audit complete. Proceed with system update?"; then
      "$update_script"
      echo "System security and updates have been applied."
    else
      echo "Update cancelled by user."
    fi
  else
    echo "Required scripts not found."
    return 1
  fi
}

# Function to create backup and run database maintenance
arsenal_backup_and_maintain_db() {
  local backup_script="$ARSENAL_ROOT/database/database_backup.sh" 
  local db_maintenance="$ARSENAL_ROOT/database/autodb.sh"
  
  if [[ -f "$backup_script" && -f "$db_maintenance" ]]; then
    echo "Creating database backup before maintenance..."
    "$backup_script"
    
    # Only proceed if backup was successful
    if [[ $? -eq 0 ]]; then
      echo "Backup successful. Running database maintenance..."
      "$db_maintenance"
      echo "Database backup and maintenance complete."
    else
      echo "Backup failed. Skipping maintenance for safety."
      return 1
    fi
  else
    echo "Required scripts not found."
    return 1
  fi
}

# Function to check system health and fix common issues
arsenal_health_check_and_repair() {
  local syshealth="$ARSENAL_ROOT/system/syshealth.sh"
  local disk_check="$ARSENAL_ROOT/system/disk_usage.sh"
  local service_check="$ARSENAL_ROOT/system/health_check.sh"
  
  echo "Running comprehensive system health check..."
  
  # Check if scripts exist and run them
  [[ -f "$syshealth" ]] && "$syshealth"
  [[ -f "$disk_check" ]] && "$disk_check"
  [[ -f "$service_check" ]] && "$service_check"
  
  # Check for common issues
  echo "Checking for common system issues..."
  
  # Check disk space and clean if necessary
  local disk_usage=$(arsenal_get_disk_usage "/")
  if [[ $disk_usage -gt 85 ]]; then
    echo "Disk usage is high ($disk_usage%). Cleaning package cache..."
    if arsenal_command_exists apt-get; then
      sudo apt-get clean
      sudo apt-get autoremove -y
    elif arsenal_command_exists yum; then
      sudo yum clean all
    fi
    echo "Cleaned package cache."
  fi
  
  # Check system load
  local load_avg=$(arsenal_get_load_avg)
  if (( $(echo "$load_avg > 2.0" | bc -l) )); then
    echo "System load is high ($load_avg). Checking top processes..."
    ps aux --sort=-%cpu | head -10
  fi
  
  echo "System health check and repairs complete."
}

# Function to setup a complete development environment
arsenal_setup_dev_environment() {
  local create_env="$ARSENAL_ROOT/development/create_env.sh"
  local git_setup="$ARSENAL_ROOT/development/autogit.sh"
  
  echo "Setting up development environment..."
  
  # Create Python environment if script exists
  if [[ -f "$create_env" ]]; then
    echo "Setting up Python environment..."
    source "$create_env"
  fi
  
  # Configure Git if available
  if arsenal_command_exists git; then
    echo "Configuring Git..."
    
    # Prompt for Git configuration if not already set
    if [[ -z "$(git config --global user.name)" ]]; then
      local git_name=$(arsenal_prompt "Enter your name for Git commits")
      git config --global user.name "$git_name"
    fi
    
    if [[ -z "$(git config --global user.email)" ]]; then
      local git_email=$(arsenal_prompt "Enter your email for Git commits") 
      git config --global user.email "$git_email"
    fi
    
    # Set up additional helpful Git configurations
    git config --global color.ui auto
    git config --global pull.rebase false
    git config --global init.defaultBranch main
    
    echo "Git configured successfully."
  fi
  
  echo "Development environment setup complete."
}

# Function to run monitoring dashboard (combining multiple monitoring scripts)
arsenal_monitoring_dashboard() {
  local monitor_script="$ARSENAL_ROOT/system/sys_monitor.sh"
  local interval=$(arsenal_get_config "MONITOR_INTERVAL" "5")
  
  echo "Starting IT Arsenal Monitoring Dashboard"
  echo "Press Ctrl+C to exit"
  echo "--------------------------------------"
  
  # Run monitoring in a loop
  while true; do
    clear
    echo "IT ARSENAL MONITORING - $(date)"
    echo "--------------------------------------"
    
    echo "SYSTEM LOAD: $(arsenal_get_load_avg "1") (1m), $(arsenal_get_load_avg "5") (5m), $(arsenal_get_load_avg "15") (15m)"
    echo "CPU USAGE: $(arsenal_get_cpu_usage)%"
    echo "MEMORY USAGE: $(arsenal_get_mem_usage)%"
    echo "DISK USAGE: $(arsenal_get_disk_usage "/")% of /"
    
    echo "--------------------------------------"
    echo "TOP PROCESSES:"
    ps aux --sort=-%cpu | head -6
    
    echo "--------------------------------------"
    echo "LISTENING PORTS:"
    ss -tuln | grep LISTEN | head -5
    
    echo "--------------------------------------"
    echo "RECENT LOGS:"
    if [[ -d "$LOGS_DIR" ]]; then
      find "$LOGS_DIR" -type f -name "*.log" -mtime -1 | xargs tail -n 5 2>/dev/null | head -5
    fi
    
    echo "--------------------------------------"
    echo "Refreshing every $interval seconds... (Ctrl+C to exit)"
    sleep $interval
  done
}

# Create a complete deployment workflow (dev -> staging -> prod)
arsenal_deploy_workflow() {
  local deploy_script="$ARSENAL_ROOT/devops/deploy.sh"
  local cicd_auto="$ARSENAL_ROOT/devops/ci_cd_auto.sh"
  
  if [[ ! -f "$deploy_script" && ! -f "$cicd_auto" ]]; then
    echo "Required deployment scripts not found."
    return 1
  fi
  
  # Use more advanced CI/CD script if available
  if [[ -f "$cicd_auto" ]]; then
    echo "Starting CI/CD automation workflow..."
    "$cicd_auto"
    return $?
  fi
  
  # Otherwise use simple deployment workflow
  local environments=("development" "staging" "production")
  local current_env="development"
  
  arsenal_print_header "DEPLOYMENT WORKFLOW"
  
  # Ask which environment to deploy to
  echo "Available environments:"
  for i in "${!environments[@]}"; do
    echo "  $((i+1)). ${environments[$i]}"
  done
  
  echo -ne "\nSelect target environment [1-${#environments[@]}]: "
  read env_choice
  
  if [[ $env_choice =~ ^[0-9]+$ && $env_choice -ge 1 && $env_choice -le ${#environments[@]} ]]; then
    current_env="${environments[$((env_choice-1))]}"
  else
    echo "Invalid selection. Defaulting to development."
    current_env="development"
  fi
  
  echo -ne "Enter repository URL: "
  read repo_url
  
  echo -ne "Enter branch to deploy: "
  read branch
  
  echo -ne "Enter deployment directory: "
  read deploy_dir
  
  echo -ne "Service to restart (optional): "
  read service_name
  
  echo "Deploying $branch to $current_env environment..."
  
  # Build deployment command
  local deploy_cmd="$deploy_script -r \"$repo_url\" -b \"$branch\" -d \"$deploy_dir\""
  if [[ -n "$service_name" ]]; then
    deploy_cmd="$deploy_cmd -s \"$service_name\""
  fi
  
  # Execute deployment
  eval "$deploy_cmd"
  
  if [[ $? -eq 0 ]]; then
    echo "Deployment to $current_env completed successfully!"
  else
    echo "Deployment to $current_env failed."
    return 1
  fi
}
