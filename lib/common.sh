#!/bin/bash
# Common utility functions for IT Arsenal scripts
# GitHub: https://github.com/sundanc/auto_scripts

# =============================================
# COMMON VARIABLES
# =============================================
ARSENAL_VERSION="1.0"
ARSENAL_ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
CONFIG_DIR="$ARSENAL_ROOT/config"
LOGS_DIR="$ARSENAL_ROOT/logs"
CONFIG_FILE="$CONFIG_DIR/arsenal.conf"
CREDS_DIR="$CONFIG_DIR/credentials"

# =============================================
# COLOR DEFINITIONS
# =============================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================
# CONFIGURATION FUNCTIONS
# =============================================

# Load arsenal configuration
arsenal_load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    return 0
  else
    echo -e "${YELLOW}Warning: Configuration file not found: $CONFIG_FILE${NC}" >&2
    echo -e "${YELLOW}Creating default configuration...${NC}" >&2
    arsenal_create_default_config
    return 1
  fi
}

# Create default configuration file
arsenal_create_default_config() {
  mkdir -p "$CONFIG_DIR"
  
  cat > "$CONFIG_FILE" << EOF
# IT Arsenal Configuration (auto-generated)
ADMIN_EMAIL="admin@example.com"
NOTIFICATION_ENABLED="no"
LOG_LEVEL="INFO"
DEFAULT_BACKUP_DIR="$HOME/backups"
DEFAULT_LOG_DIR="$LOGS_DIR"
DEFAULT_ENVIRONMENT="production"
MONITOR_INTERVAL="5"
HEALTH_CHECK_THRESHOLD="85"
SECURITY_LEVEL="normal"
DB_DEFAULT_USER="root"
DB_DEFAULT_HOST="localhost"
DB_DEFAULT_PORT="3306"
DB_BACKUP_RETENTION="30"
DEFAULT_CONNECTIVITY_HOST="google.com"
EOF

  echo -e "${BLUE}Default configuration created at: $CONFIG_FILE${NC}" >&2
}

# Get a configuration value with default fallback
arsenal_get_config() {
  local key="$1"
  local default="$2"
  local value
  
  # Load config if not already loaded
  if [[ -z "$ADMIN_EMAIL" && -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  fi
  
  # Use eval to get the value from variable name
  eval "value=\${$key}"
  
  if [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi
  
  # Try to get from config file directly
  if [[ -f "$CONFIG_FILE" ]]; then
    value=$(grep "^$key=" "$CONFIG_FILE" | cut -d'=' -f2- | tr -d '"')
    if [[ -n "$value" ]]; then
      echo "$value"
      return 0
    fi
  fi
  
  echo "$default"
  return 0
}

# Set a configuration value
arsenal_set_config() {
  local key="$1"
  local value="$2"
  
  arsenal_load_config &>/dev/null
  
  if [[ -f "$CONFIG_FILE" ]]; then
    if grep -q "^$key=" "$CONFIG_FILE"; then
      # Update existing value
      sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_FILE"
    else
      # Add new value
      echo "$key=\"$value\"" >> "$CONFIG_FILE"
    fi
  else
    arsenal_create_default_config
    arsenal_set_config "$key" "$value"  # Recursively call after creating config
  fi
}

# =============================================
# LOGGING FUNCTIONS
# =============================================

# Log a message with specified level
arsenal_log() {
  local level="$1"
  local message="$2"
  local script="$3"
  local log_file
  
  # Ensure log directory exists
  mkdir -p "$LOGS_DIR"
  
  # Determine log file
  if [[ -n "$script" ]]; then
    script_name=$(basename "$script" .sh)
    log_file="$LOGS_DIR/${script_name}_$(date +%Y%m%d).log"
  else
    log_file="$LOGS_DIR/arsenal_$(date +%Y%m%d).log"
  fi
  
  # Write to log file
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] [${level}] ${message}" >> "$log_file"
  
  # Send critical notifications if configured
  if [[ "$level" == "CRITICAL" ]]; then
    arsenal_notify "CRITICAL: $message" "$script"
  fi
  
  return 0
}

# Send notification
arsenal_notify() {
  local message="$1"
  local script="$2"
  local script_name
  
  if [[ -n "$script" ]]; then
    script_name=$(basename "$script" .sh)
  else
    script_name="IT Arsenal"
  fi
  
  # Load configuration
  local notification_enabled=$(arsenal_get_config "NOTIFICATION_ENABLED" "no")
  local admin_email=$(arsenal_get_config "ADMIN_EMAIL" "admin@example.com")
  
  if [[ "$notification_enabled" == "yes" ]] && command -v mail &>/dev/null; then
    echo "$message" | mail -s "[$script_name] Alert" "$admin_email"
  fi
  
  return 0
}

# =============================================
# NEW CREDENTIAL MANAGEMENT
# =============================================

# Securely store a credential
arsenal_store_credential() {
  local credential_name="$1"
  local credential_value="$2"
  local credential_file="$CREDS_DIR/$credential_name.cred"
  
  # Ensure credentials directory exists with proper permissions
  mkdir -p "$CREDS_DIR"
  chmod 700 "$CREDS_DIR"
  
  # Store credential with restricted permissions
  echo "$credential_value" > "$credential_file"
  chmod 600 "$credential_file"
  
  echo "Credential stored securely in $credential_file"
}

# Retrieve a stored credential
arsenal_get_credential() {
  local credential_name="$1"
  local credential_file="$CREDS_DIR/$credential_name.cred"
  
  if [[ -f "$credential_file" ]]; then
    cat "$credential_file"
    return 0
  else
    return 1
  fi
}

# Prompt for missing credentials
arsenal_prompt_missing_credentials() {
  local credential_name="$1"
  local prompt_message="$2"
  local credential_value

  # Check if the credential is already set
  if [[ -z "${!credential_name}" ]]; then
    echo -ne "${YELLOW}${prompt_message}: ${NC}"
    read -s credential_value
    echo ""
    export "$credential_name"="$credential_value"
  fi
}

# Example usage:
# arsenal_prompt_missing_credentials "DB_PASSWORD" "Enter database password"

# =============================================
# DEPENDENCY CHECKING
# =============================================

# Check if required tools are installed
arsenal_check_dependencies() {
  local tools=("$@")
  local missing_tools=()
  
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Warning: Missing required tools: ${missing_tools[*]}${NC}" >&2
    
    # Provide installation instructions based on detected OS
    if [[ -f /etc/debian_version ]]; then
      echo -e "${YELLOW}Install on Debian/Ubuntu with: sudo apt install ${missing_tools[*]}${NC}" >&2
    elif [[ -f /etc/redhat-release ]]; then
      echo -e "${YELLOW}Install on CentOS/RHEL with: sudo yum install ${missing_tools[*]}${NC}" >&2
    elif [[ -f /etc/arch-release ]]; then
      echo -e "${YELLOW}Install on Arch Linux with: sudo pacman -S ${missing_tools[*]}${NC}" >&2
    fi
    
    return 1
  fi
  
  return 0
}

# =============================================
# UTILITY FUNCTIONS
# =============================================

# Check if a command exists
arsenal_command_exists() {
  command -v "$1" &>/dev/null
  return $?
}

# Print a header
arsenal_print_header() {
  local title="$1"
  local width=${2:-60}
  
  local padding=$(( (width - ${#title}) / 2 ))
  local line=$(printf "%${width}s" | tr " " "=")
  
  echo -e "${BLUE}${line}${NC}"
  printf "${YELLOW}%${padding}s${BOLD}%s${NC}${YELLOW}%${padding}s${NC}\n" "" "$title" ""
  echo -e "${BLUE}${line}${NC}"
  echo ""
}

# Print in the center
arsenal_print_centered() {
  local message="$1"
  local width=${2:-60}
  
  local padding=$(( (width - ${#message}) / 2 ))
  printf "%${padding}s%s%${padding}s\n" "" "$message" ""
}

# Confirm action with the user
arsenal_confirm() {
  local message="$1"
  local default=${2:-"n"}
  
  if [[ "$default" == "y" ]]; then
    prompt="[Y/n]"
  else
    prompt="[y/N]"
  fi
  
  echo -ne "${YELLOW}$message $prompt ${NC}"
  read response
  
  if [[ -z "$response" ]]; then
    response=$default
  fi
  
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 0
  else
    return 1
  fi
}

# Get input with optional default value and validation
arsenal_prompt() {
  local message="$1"
  local default="$2"
  local validate_func="$3"
  local input
  
  while true; do
    if [[ -n "$default" ]]; then
      echo -ne "${YELLOW}$message [${default}]: ${NC}"
    else
      echo -ne "${YELLOW}$message: ${NC}"
    fi
    
    read input
    
    if [[ -z "$input" && -n "$default" ]]; then
      input="$default"
    fi
    
    if [[ -z "$validate_func" || -z "$input" ]]; then
      echo "$input"
      return 0
    elif eval "$validate_func \"$input\""; then
      echo "$input"
      return 0
    else
      echo -e "${RED}Invalid input. Please try again.${NC}"
    fi
  done
}

# Check if script is being run with root/sudo
arsenal_check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}" >&2
    return 1
  fi
  return 0
}

# Check operating system
arsenal_get_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "$ID"
  elif [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  else
    uname | tr '[:upper:]' '[:lower:]'
  fi
}

# Get operating system details
arsenal_get_os_info() {
  local os_info=()
  
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    os_info+=("ID=$ID")
    os_info+=("VERSION_ID=$VERSION_ID")
    os_info+=("NAME=$NAME")
    os_info+=("PRETTY_NAME=$PRETTY_NAME")
  else
    os=$(uname -s)
    os_info+=("ID=$os")
    os_info+=("NAME=$os")
  fi
  
  # Add kernel version
  kernel=$(uname -r)
  os_info+=("KERNEL=$kernel")
  
  echo "${os_info[*]}"
}

# Get IP address
arsenal_get_ip() {
  local interface=${1:-""}
  
  if [[ -z "$interface" ]]; then
    # Get default route interface
    interface=$(ip route | grep default | awk '{print $5}' | head -n1)
  fi
  
  if [[ -n "$interface" ]]; then
    ip addr show "$interface" | grep -Eo 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2}'
  fi
}

# Format bytes to human-readable
arsenal_format_bytes() {
  local bytes=$1
  local precision=${2:-2}
  
  if [[ $bytes -lt 1024 ]]; then
    echo "${bytes}B"
  elif [[ $bytes -lt 1048576 ]]; then
    echo "$(echo "scale=$precision; $bytes/1024" | bc)KB"
  elif [[ $bytes -lt 1073741824 ]]; then
    echo "$(echo "scale=$precision; $bytes/1048576" | bc)MB"
  elif [[ $bytes -lt 1099511627776 ]]; then
    echo "$(echo "scale=$precision; $bytes/1073741824" | bc)GB"
  else
    echo "$(echo "scale=$precision; $bytes/1099511627776" | bc)TB"
  fi
}

# Run with spinner (show progress animation while running command)
arsenal_run_with_spinner() {
  local cmd="$1"
  local message="${2:-"Working..."}"
  
  # Start spinner in background
  arsenal_spinner "$message" &
  local spinner_pid=$!
  
  # Run the command
  eval "$cmd"
  local result=$?
  
  # Kill the spinner
  kill $spinner_pid &>/dev/null
  wait $spinner_pid &>/dev/null
  
  # Return the command's exit code
  return $result
}

# Display a spinner with a message
arsenal_spinner() {
  local message="$1"
  local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
  local charwidth=3
  
  echo -n "$message "
  
  while true; do
    for (( i=0; i<${#spin}; i+=$charwidth )); do
      echo -ne "\b${spin:$i:$charwidth}"
      sleep 0.1
    done
  done
}

# Check existence of a file with proper error handling
arsenal_check_file() {
  local file_path="$1"
  local required=${2:-true}
  
  if [[ -f "$file_path" ]]; then
    return 0
  elif [[ "$required" == "true" ]]; then
    echo -e "${RED}Error: Required file not found: $file_path${NC}" >&2
    return 1
  else
    echo -e "${YELLOW}Warning: Optional file not found: $file_path${NC}" >&2
    return 1
  fi
}

# Enhanced version detection for tools
arsenal_get_tool_version() {
  local tool="$1"
  local version_args="${2:---version}"
  
  if command -v "$tool" &> /dev/null; then
    "$tool" $version_args 2>&1 | head -n1
    return 0
  else
    echo "Not installed"
    return 1
  fi
}

# =============================================
# SYSTEM MONITORING FUNCTIONS
# =============================================

# Get CPU usage
arsenal_get_cpu_usage() {
  top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | tr -d '\n'
}

# Get memory usage
arsenal_get_mem_usage() {
  free | grep Mem | awk '{print $3/$2 * 100.0}' | tr -d '\n'
}

# Get disk usage
arsenal_get_disk_usage() {
  local mount_point=${1:-"/"}
  df -h "$mount_point" | tail -1 | awk '{print $5}' | tr -d '%\n'
}

# Get load average
arsenal_get_load_avg() {
  local period=${1:-"1"}
  case $period in
    1)  uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $1}' | tr -d ', \n';;
    5)  uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $2}' | tr -d ', \n';;
    15) uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $3}' | tr -d ', \n';;
    *)  uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $1}' | tr -d ', \n';;
  esac
}

# Check if service is running
arsenal_service_running() {
  local service="$1"
  systemctl is-active --quiet "$service"
  return $?
}

# Restart a service
arsenal_restart_service() {
  local service="$1"
  systemctl restart "$service"
  return $?
}

# =============================================
# FILE MANAGEMENT FUNCTIONS
# =============================================

# Create a timestamped backup of a file
arsenal_backup_file() {
  local file="$1"
  local backup_dir="${2:-$(dirname "$file")}"
  local timestamp="$(date +%Y%m%d%H%M%S)"
  local basename="$(basename "$file")"
  local backup_file="${backup_dir}/${basename}.${timestamp}.bak"
  
  if [[ -f "$file" ]]; then
    mkdir -p "$backup_dir"
    cp -p "$file" "$backup_file"
    return $?
  else
    return 1
  fi
}

# Safely write to file (create backup first)
arsenal_safe_write() {
  local file="$1"
  local content="$2"
  
  if [[ -f "$file" ]]; then
    arsenal_backup_file "$file"
  fi
  
  echo "$content" > "$file"
  return $?
}

# Rotate logs
arsenal_rotate_logs() {
  local log_file="$1"
  local max_size_kb="${2:-1024}"  # 1MB default
  local max_files="${3:-5}"       # Keep 5 files by default
  
  if [[ ! -f "$log_file" ]]; then
    return 0
  fi
  
  # Check file size
  local size_kb=$(du -k "$log_file" | cut -f1)
  
  if [[ $size_kb -gt $max_size_kb ]]; then
    # Rotate files
    for (( i=max_files-1; i>=0; i-- )); do
      if [[ $i -eq 0 ]]; then
        mv "$log_file" "${log_file}.1"
      elif [[ -f "${log_file}.$i" ]]; then
        mv "${log_file}.$i" "${log_file}.$((i+1))"
      fi
    done
    
    # Create new empty log file
    touch "$log_file"
    chmod --reference="${log_file}.1" "$log_file" 2>/dev/null
  fi
  
  return 0
}

# Function to check internet connectivity
arsenal_check_internet() {
  local test_host="${1:-8.8.8.8}"
  ping -c 1 -W 2 "$test_host" &>/dev/null
  return $?
}
