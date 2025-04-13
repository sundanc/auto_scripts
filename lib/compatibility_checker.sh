#!/bin/bash
# Script Compatibility Checker for IT Arsenal
# Verifies if the user's system meets requirements for running scripts

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}

# Database of script dependencies and requirements
declare -A SCRIPT_DEPENDENCIES
declare -A SCRIPT_OS_REQUIREMENTS
declare -A SCRIPT_USER_REQUIREMENTS

# Initialize dependency database
init_dependency_database() {
    # System Administration Tools
    SCRIPT_DEPENDENCIES["vm.sh"]="dmidecode ip lsmod lsblk systemd-detect-virt"
    SCRIPT_OS_REQUIREMENTS["vm.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["vm.sh"]="any"
    
    SCRIPT_DEPENDENCIES["security_audit.sh"]="grep find stat awk ss"
    SCRIPT_OS_REQUIREMENTS["security_audit.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["security_audit.sh"]="root"
    
    SCRIPT_DEPENDENCIES["connectivity_check.sh"]="ping"
    SCRIPT_OS_REQUIREMENTS["connectivity_check.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["connectivity_check.sh"]="any"
    
    SCRIPT_DEPENDENCIES["system_benchmark.sh"]="dd time bc awk grep find"
    SCRIPT_OS_REQUIREMENTS["system_benchmark.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["system_benchmark.sh"]="any"
    
    # Development Tools
    SCRIPT_DEPENDENCIES["git_branch_management.sh"]="git"
    SCRIPT_OS_REQUIREMENTS["git_branch_management.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["git_branch_management.sh"]="any"
    
    SCRIPT_DEPENDENCIES["autogit.sh"]="git"
    SCRIPT_OS_REQUIREMENTS["autogit.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["autogit.sh"]="any"
    
    SCRIPT_DEPENDENCIES["create_env.sh"]="python3 venv"
    SCRIPT_OS_REQUIREMENTS["create_env.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["create_env.sh"]="any"
    
    # DevOps & Deployment Tools
    SCRIPT_DEPENDENCIES["deploy.sh"]="git rsync systemctl"
    SCRIPT_OS_REQUIREMENTS["deploy.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["deploy.sh"]="root"
    
    SCRIPT_DEPENDENCIES["ci_cd_auto.sh"]="git bash"
    SCRIPT_OS_REQUIREMENTS["ci_cd_auto.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["ci_cd_auto.sh"]="any"
    
    SCRIPT_DEPENDENCIES["backup.sh"]="mkdir cp"
    SCRIPT_OS_REQUIREMENTS["backup.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["backup.sh"]="any"
    
    # Database Tools
    SCRIPT_DEPENDENCIES["database_backup.sh"]="mysqldump mkdir md5sum"
    SCRIPT_OS_REQUIREMENTS["database_backup.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["database_backup.sh"]="any"
    
    SCRIPT_DEPENDENCIES["autodb.sh"]="mysql mysqldump bc find md5sum"
    SCRIPT_OS_REQUIREMENTS["autodb.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["autodb.sh"]="any"
    
    # Additional System Tools
    SCRIPT_DEPENDENCIES["updateupgrade.sh"]="apt-get"
    SCRIPT_OS_REQUIREMENTS["updateupgrade.sh"]="debian ubuntu"
    SCRIPT_USER_REQUIREMENTS["updateupgrade.sh"]="root"
    
    SCRIPT_DEPENDENCIES["uptime.sh"]="uptime"
    SCRIPT_OS_REQUIREMENTS["uptime.sh"]="any"
    SCRIPT_USER_REQUIREMENTS["uptime.sh"]="any"
    
    SCRIPT_DEPENDENCIES["syshealth.sh"]="top free df uptime"
    SCRIPT_OS_REQUIREMENTS["syshealth.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["syshealth.sh"]="any"
    
    SCRIPT_DEPENDENCIES["sys_monitor.sh"]="ps top free"
    SCRIPT_OS_REQUIREMENTS["sys_monitor.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["sys_monitor.sh"]="any"
    
    SCRIPT_DEPENDENCIES["health_check.sh"]="systemctl"
    SCRIPT_OS_REQUIREMENTS["health_check.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["health_check.sh"]="root"
    
    SCRIPT_DEPENDENCIES["disk_usage.sh"]="df awk"
    SCRIPT_OS_REQUIREMENTS["disk_usage.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["disk_usage.sh"]="any"
    
    SCRIPT_DEPENDENCIES["network_diagnostics.sh"]="ip ping traceroute dig nslookup netstat ss"
    SCRIPT_OS_REQUIREMENTS["network_diagnostics.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["network_diagnostics.sh"]="any"
    
    SCRIPT_DEPENDENCIES["log_analyzer.sh"]="grep sed awk find"
    SCRIPT_OS_REQUIREMENTS["log_analyzer.sh"]="linux"
    SCRIPT_USER_REQUIREMENTS["log_analyzer.sh"]="any"
}

# Check OS compatibility
check_os_compatibility() {
    local script_name="$1"
    local required_os="${SCRIPT_OS_REQUIREMENTS[$script_name]}"
    
    # If no specific OS requirement or "any", return compatible
    if [[ -z "$required_os" || "$required_os" == "any" ]]; then
        return 0
    fi
    
    local current_os=$(arsenal_get_os)
    
    # Check if current OS is in the required OS list
    if [[ "$required_os" == *"$current_os"* ]]; then
        return 0
    elif [[ "$required_os" == "linux" && ("$current_os" == "ubuntu" || "$current_os" == "debian" || "$current_os" == "centos" || "$current_os" == "fedora" || "$current_os" == "arch") ]]; then
        return 0
    else
        return 1
    fi
}

# Check user privileges
check_user_privileges() {
    local script_name="$1"
    local required_user="${SCRIPT_USER_REQUIREMENTS[$script_name]}"
    
    # If no specific user requirement or "any", return compatible
    if [[ -z "$required_user" || "$required_user" == "any" ]]; then
        return 0
    fi
    
    # Check if root is required and user is not root
    if [[ "$required_user" == "root" && $EUID -ne 0 ]]; then
        return 1
    fi
    
    return 0
}

# Check for missing dependencies
check_dependencies() {
    local script_name="$1"
    local dependencies="${SCRIPT_DEPENDENCIES[$script_name]}"
    local missing_deps=()
    
    # If no dependencies defined, return success
    if [[ -z "$dependencies" ]]; then
        return 0
    fi
    
    # Check each dependency
    for dep in $dependencies; do
        if ! command -v "$dep" &> /dev/null; then
            if [[ "$dep" == "venv" ]]; then
                # Special case for Python venv
                if ! python3 -c "import venv" &> /dev/null; then
                    missing_deps+=("$dep")
                fi
            elif [[ "$dep" == "systemd-detect-virt" && -f "/usr/sbin/systemd-detect-virt" ]]; then
                # Special case for systemd-detect-virt which might be in /usr/sbin
                continue
            else
                missing_deps+=("$dep")
            fi
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Check if a script is compatible with the current system
check_script_compatibility() {
    local script_name="$1"
    local verbose="$2"
    local script_base=$(basename "$script_name")
    local issues=()
    local install_cmd=""
    
    # Initialize dependency database if not already done
    if [[ "${#SCRIPT_DEPENDENCIES[@]}" -eq 0 ]]; then
        init_dependency_database
    fi
    
    # Check OS compatibility
    if ! check_os_compatibility "$script_base"; then
        issues+=("Operating system not compatible. Script requires: ${SCRIPT_OS_REQUIREMENTS[$script_base]}")
    fi
    
    # Check user privileges
    if ! check_user_privileges "$script_base"; then
        issues+=("Required privileges not met. Script requires: ${SCRIPT_USER_REQUIREMENTS[$script_base]} privileges")
    fi
    
    # Check dependencies
    missing_deps=$(check_dependencies "$script_base")
    if [[ $? -ne 0 ]]; then
        issues+=("Missing dependencies: $missing_deps")
        
        # Generate installation command based on system
        if [[ -f /etc/debian_version ]]; then
            install_cmd="sudo apt-get install $missing_deps"
        elif [[ -f /etc/redhat-release ]]; then
            install_cmd="sudo yum install $missing_deps"
        elif [[ -f /etc/arch-release ]]; then
            install_cmd="sudo pacman -S $missing_deps"
        fi
    fi
    
    # Return results
    if [[ ${#issues[@]} -gt 0 ]]; then
        if [[ "$verbose" == "true" ]]; then
            echo -e "${YELLOW}⚠️ Compatibility issues for $script_base:${NC}"
            for issue in "${issues[@]}"; do
                echo -e "${YELLOW}   - $issue${NC}"
            done
            if [[ -n "$install_cmd" ]]; then
                echo -e "${YELLOW}   To install missing dependencies: ${GREEN}$install_cmd${NC}"
            fi
        fi
        return 1
    fi
    
    if [[ "$verbose" == "true" ]]; then
        echo -e "${GREEN}✓ $script_base is compatible with your system${NC}"
    fi
    return 0
}

# Check multiple scripts and report a summary
bulk_compatibility_check() {
    local scripts=("$@")
    local compatible=()
    local incompatible=()
    
    echo -e "${BLUE}${BOLD}Checking script compatibility...${NC}"
    
    for script in "${scripts[@]}"; do
        if check_script_compatibility "$script" "false"; then
            compatible+=("$script")
        else
            incompatible+=("$script")
        fi
    done
    
    echo -e "${GREEN}${BOLD}Compatible scripts (${#compatible[@]}):${NC}"
    for script in "${compatible[@]}"; do
        echo -e "${GREEN}✓ $(basename "$script")${NC}"
    done
    
    if [[ ${#incompatible[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}${BOLD}Scripts with compatibility issues (${#incompatible[@]}):${NC}"
        for script in "${incompatible[@]}"; do
            echo -e "${YELLOW}⚠️ $(basename "$script")${NC}"
            check_script_compatibility "$script" "true"
            echo ""
        done
    fi
}

# Enhanced version with detailed dependency verification
verify_specific_dependencies() {
    local script_name="$1"
    local verbose="$2"
    local missing_deps=()
    local version_issues=()
    local dependencies="${SCRIPT_DEPENDENCIES[$script_name]}"
    
    # If no dependencies defined, return success
    if [[ -z "$dependencies" ]]; then
        return 0
    fi
    
    # Check each dependency with detailed information
    for dep in $dependencies; do
        if ! command -v "$dep" &> /dev/null; then
            # Handle special cases
            if [[ "$dep" == "venv" ]]; then
                if ! python3 -c "import venv" &> /dev/null; then
                    missing_deps+=("$dep (Python module)")
                fi
            elif [[ "$dep" == "systemd-detect-virt" && -f "/usr/sbin/systemd-detect-virt" ]]; then
                # Special case for systemd-detect-virt
                continue
            else
                missing_deps+=("$dep")
            fi
        else
            # Check version requirements for specific tools
            case "$dep" in
                git)
                    local git_version=$(git --version | awk '{print $3}')
                    if ! [[ "$git_version" =~ ^[2-9]\. ]]; then
                        version_issues+=("git (found $git_version, recommended 2.0+)")
                    fi
                    ;;
                python3)
                    local py_version=$(python3 --version 2>&1 | awk '{print $2}')
                    if ! [[ "$py_version" =~ ^3\.[6-9]\. ]] && ! [[ "$py_version" =~ ^3\.[1-9][0-9]\. ]]; then
                        version_issues+=("python3 (found $py_version, recommended 3.6+)")
                    fi
                    ;;
                # Add more version checks as needed
            esac
        fi
    done
    
    # Return results
    if [[ ${#missing_deps[@]} -gt 0 || ${#version_issues[@]} -gt 0 ]]; then
        if [[ "$verbose" == "true" ]]; then
            if [[ ${#missing_deps[@]} -gt 0 ]]; then
                echo "Missing dependencies: ${missing_deps[*]}"
            fi
            if [[ ${#version_issues[@]} -gt 0 ]]; then
                echo "Version issues: ${version_issues[*]}"
            fi
        fi
        
        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo "${missing_deps[*]}"
            return 1
        fi
    fi
    
    return 0
}

# Add enhanced OS compatibility check with more details
check_enhanced_os_compatibility() {
    local script_name="$1"
    local verbose="$2"
    local required_os="${SCRIPT_OS_REQUIREMENTS[$script_name]}"
    local current_os=$(arsenal_get_os)
    local kernel_version=$(uname -r)
    
    # If no specific OS requirement or "any", return compatible
    if [[ -z "$required_os" || "$required_os" == "any" ]]; then
        [[ "$verbose" == "true" ]] && echo "OS Compatibility: Any OS supported"
        return 0
    fi
    
    # Check if current OS is in the required OS list
    if [[ "$required_os" == *"$current_os"* ]]; then
        [[ "$verbose" == "true" ]] && echo "OS Compatibility: $current_os is supported (required: $required_os)"
        return 0
    elif [[ "$required_os" == "linux" && ("$current_os" == "ubuntu" || "$current_os" == "debian" || 
            "$current_os" == "centos" || "$current_os" == "fedora" || "$current_os" == "arch") ]]; then
        [[ "$verbose" == "true" ]] && echo "OS Compatibility: $current_os is a compatible Linux distribution"
        return 0
    else
        [[ "$verbose" == "true" ]] && echo "OS Compatibility: $current_os is not compatible (required: $required_os)"
        return 1
    fi
}

# Debug script requirements and provide detailed recommendations
debug_script_requirements() {
    local script_name="$1"
    local script_base=$(basename "$script_name")
    
    echo -e "${BLUE}${BOLD}Debugging Script Requirements for: $script_base${NC}"
    
    # Initialize dependency database if not already done
    if [[ "${#SCRIPT_DEPENDENCIES[@]}" -eq 0 ]]; then
        init_dependency_database
    fi
    
    # Print script requirements
    echo -e "${YELLOW}Required dependencies:${NC} ${SCRIPT_DEPENDENCIES[$script_base]:-"None specified"}"
    echo -e "${YELLOW}OS requirements:${NC} ${SCRIPT_OS_REQUIREMENTS[$script_base]:-"Any"}"
    echo -e "${YELLOW}User privileges:${NC} ${SCRIPT_USER_REQUIREMENTS[$script_base]:-"Any"}"
    
    # Check OS compatibility with detailed output
    echo -e "\n${BLUE}Checking OS compatibility:${NC}"
    check_enhanced_os_compatibility "$script_base" "true"
    
    # Check user privileges
    echo -e "\n${BLUE}Checking user privileges:${NC}"
    if ! check_user_privileges "$script_base"; then
        echo -e "${RED}✗ Required privileges not met${NC}"
        echo -e "   Script requires: ${SCRIPT_USER_REQUIREMENTS[$script_base]} privileges"
        echo -e "   Current user: $(whoami) (EUID: $EUID)"
        if [[ "${SCRIPT_USER_REQUIREMENTS[$script_base]}" == "root" ]]; then
            echo -e "   ${YELLOW}Recommendation: Run with sudo or as root${NC}"
        fi
    else
        echo -e "${GREEN}✓ User privileges OK${NC}"
    fi
    
    # Check dependencies with detailed output
    echo -e "\n${BLUE}Checking dependencies:${NC}"
    local dep_output=$(verify_specific_dependencies "$script_base" "true")
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Missing dependencies${NC}"
        echo -e "   $dep_output"
        
        # Generate installation command based on system
        if [[ -f /etc/debian_version ]]; then
            echo -e "   ${YELLOW}Recommendation: sudo apt-get install $dep_output${NC}"
        elif [[ -f /etc/redhat-release ]]; then
            echo -e "   ${YELLOW}Recommendation: sudo yum install $dep_output${NC}"
        elif [[ -f /etc/arch-release ]]; then
            echo -e "   ${YELLOW}Recommendation: sudo pacman -S $dep_output${NC}"
        fi
    else
        echo -e "${GREEN}✓ All dependencies found${NC}"
        if [[ -n "$dep_output" ]]; then
            echo -e "   ${YELLOW}Note: $dep_output${NC}"
        fi
    fi
    
    # Overall recommendation
    echo -e "\n${BLUE}Overall status:${NC}"
    if check_script_compatibility "$script_base" "false"; then
        echo -e "${GREEN}✓ Script should run correctly on this system${NC}"
    else
        echo -e "${RED}✗ Script may not work correctly on this system${NC}"
        echo -e "   Please address the issues above before running."
    fi
}

# System-wide compatibility check
check_system_compatibility() {
    local script_dir="$1"
    local detailed="${2:-false}"
    
    # Initialize dependency database if not already done
    if [[ "${#SCRIPT_DEPENDENCIES[@]}" -eq 0 ]]; then
        init_dependency_database
    fi
    
    # Get OS and user information
    local os_name=$(arsenal_get_os)
    local kernel_version=$(uname -r)
    local is_root=$([[ $EUID -eq 0 ]] && echo "Yes" || echo "No")
    
    echo -e "${BLUE}${BOLD}System Compatibility Check${NC}"
    echo -e "${YELLOW}Operating System:${NC} $os_name"
    echo -e "${YELLOW}Kernel Version:${NC} $kernel_version"
    echo -e "${YELLOW}Running as root:${NC} $is_root"
    
    # Check for commonly used tools
    echo -e "\n${BLUE}Checking for commonly used tools:${NC}"
    local common_tools=("bash" "grep" "sed" "awk" "find" "git" "python3" "pip3" 
                      "mysql" "mysqldump" "rsync" "systemctl" "ssh" "curl" "wget")
    local missing_tools=()
    
    for tool in "${common_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            if [[ "$detailed" == "true" ]]; then
                local version=$(command -v "$tool" | xargs --version 2>&1 | head -n1 || echo "Version unknown")
                echo -e "${GREEN}✓ $tool${NC} - $version"
            fi
        else
            missing_tools+=("$tool")
            if [[ "$detailed" == "true" ]]; then
                echo -e "${RED}✗ $tool${NC} - Not installed"
            fi
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 && "$detailed" != "true" ]]; then
        echo -e "${RED}Missing tools:${NC} ${missing_tools[*]}"
    fi
    
    # Scan directory for scripts and check compatibility
    echo -e "\n${BLUE}Script Compatibility Summary:${NC}"
    
    if [[ -d "$script_dir" ]]; then
        local all_scripts=()
        while IFS= read -r -d '' script; do
            all_scripts+=("$script")
        done < <(find "$script_dir" -name "*.sh" -type f -print0)
        
        bulk_compatibility_check "${all_scripts[@]}"
    else
        echo -e "${RED}Directory not found: $script_dir${NC}"
    fi
}

# Main function if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 script_name [script_name2 ...]"
        echo "Checks if the specified script(s) are compatible with the current system"
        exit 1
    fi
    
    bulk_compatibility_check "$@"
fi
