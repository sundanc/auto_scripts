#!/bin/bash
# IT Arsenal - Installation Script
# GitHub: https://github.com/sundanc/auto_scripts

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Print header
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "[ ${GREEN}OK${NC} ] $2"
    else
        echo -e "[${RED}FAIL${NC}] $2"
        if [ -n "$3" ]; then
            echo -e "       ${RED}$3${NC}"
        fi
    fi
}

# Check system type
check_system_type() {
    print_header "Checking System Type"
    
    if [ -f /etc/debian_version ]; then
        PACKAGE_MANAGER="apt-get"
        PACKAGE_INSTALL="apt-get install -y"
        echo -e "Detected ${CYAN}Debian/Ubuntu${NC} system"
    elif [ -f /etc/redhat-release ]; then
        PACKAGE_MANAGER="yum"
        PACKAGE_INSTALL="yum install -y"
        echo -e "Detected ${CYAN}RHEL/CentOS${NC} system"
    elif [ -f /etc/arch-release ]; then
        PACKAGE_MANAGER="pacman"
        PACKAGE_INSTALL="pacman -S --noconfirm"
        echo -e "Detected ${CYAN}Arch Linux${NC} system"
    else
        echo -e "${YELLOW}Warning: Unable to detect system type, using basic installation mode${NC}"
        PACKAGE_MANAGER=""
        PACKAGE_INSTALL=""
    fi
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    local optional_missing=()
    
    # Essential dependencies
    for dep in bash grep sed awk curl git; do
        echo -ne "Checking for ${CYAN}$dep${NC}... "
        if command -v "$dep" >/dev/null 2>&1; then
            echo -e "${GREEN}Found${NC}"
        else
            echo -e "${RED}Missing${NC}"
            missing_deps+=("$dep")
        fi
    done
    
    # Optional dependencies - helpful but not required
    for dep in bc jq python3 nano dmidecode htop; do
        echo -ne "Checking for optional ${CYAN}$dep${NC}... "
        if command -v "$dep" >/dev/null 2>&1; then
            echo -e "${GREEN}Found${NC}"
        else
            echo -e "${YELLOW}Missing${NC}"
            optional_missing+=("$dep")
        fi
    done
    
    # Install missing dependencies if possible
    if [ ${#missing_deps[@]} -ne 0 ] && [ -n "$PACKAGE_MANAGER" ]; then
        echo -e "\n${YELLOW}Installing missing essential dependencies...${NC}"
        sudo $PACKAGE_INSTALL "${missing_deps[@]}"
        print_status $? "Installing essential dependencies"
    elif [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "\n${RED}Missing essential dependencies: ${missing_deps[*]}${NC}"
        echo -e "${RED}Please install them manually and run this script again${NC}"
        exit 1
    fi
    
    # Install optional dependencies if possible
    if [ ${#optional_missing[@]} -ne 0 ] && [ -n "$PACKAGE_MANAGER" ]; then
        echo -e "\n${YELLOW}Would you like to install optional dependencies? (y/n)${NC}"
        read -r install_optional
        if [[ "$install_optional" =~ ^[Yy] ]]; then
            sudo $PACKAGE_INSTALL "${optional_missing[@]}"
            print_status $? "Installing optional dependencies"
        fi
    fi
}

# Create directory structure
create_directories() {
    print_header "Creating Directory Structure"
    
    # Core directories
    for dir in system development devops database lib config logs docs templates plugins tests; do
        echo -ne "Creating ${CYAN}$dir${NC} directory... "
        mkdir -p "$dir"
        print_status $? "$dir directory"
    done
    
    # Plugin subdirectories
    mkdir -p plugins/{system,development,devops,database}
    print_status $? "Plugin subdirectories"
    
    # Templates subdirectories
    mkdir -p templates/{system,development,devops,database}
    print_status $? "Template subdirectories"
    
    # Create docs subdirectories
    mkdir -p docs/{system,development,devops,database,tutorials}
    print_status $? "Documentation subdirectories"
    
    # Create test subdirectories
    mkdir -p tests/{unit,integration,system}
    print_status $? "Test subdirectories"
}

# Set file permissions
set_permissions() {
    print_header "Setting File Permissions"
    
    # Make all scripts executable
    echo -ne "Making scripts executable... "
    find . -name "*.sh" -exec chmod +x {} \;
    print_status $? "Scripts are now executable"
    
    # Set restrictive permissions on config directory
    echo -ne "Setting secure permissions for config directory... "
    chmod 750 config
    print_status $? "Config directory permissions"
    
    # Ensure the arsenal.sh is executable
    echo -ne "Setting executable permission for arsenal.sh... "
    chmod +x arsenal.sh
    print_status $? "Main script is executable"
}

# Initialize configuration
initialize_config() {
    print_header "Initializing Configuration"
    
    # Check if configuration exists
    if [ -f "config/arsenal.conf" ]; then
        echo -e "${YELLOW}Configuration file already exists. Keeping existing configuration.${NC}"
        return 0
    fi
    
    # Create basic configuration
    echo -ne "Creating configuration file... "
    cat > "config/arsenal.conf" << EOF
# IT Arsenal Configuration
ADMIN_EMAIL="admin@example.com"
NOTIFICATION_ENABLED="yes"
LOG_LEVEL="INFO"
DEFAULT_BACKUP_DIR="${HOME}/backups"
DEFAULT_ENVIRONMENT="production"
MONITOR_INTERVAL="5"
HEALTH_CHECK_THRESHOLD="85"
EOF
    print_status $? "Configuration file created"
    
    # Copy example configuration
    echo -ne "Creating example configuration file... "
    cp "config/arsenal.conf" "config/arsenal.conf.example"
    print_status $? "Example configuration file created"
    
    # Create credentials directory with secure permissions
    echo -ne "Creating credentials directory... "
    mkdir -p "config/credentials"
    chmod 700 "config/credentials"
    print_status $? "Credentials directory with secure permissions"
}

# Create symbolic links
create_links() {
    print_header "Creating Symbolic Links"
    
    # Ask if user wants to create a symlink in /usr/local/bin
    echo -e "${YELLOW}Would you like to create a symbolic link to arsenal.sh in /usr/local/bin? (y/n)${NC}"
    read -r create_link
    
    if [[ "$create_link" =~ ^[Yy] ]]; then
        echo -ne "Creating symbolic link... "
        sudo ln -sf "$SCRIPT_DIR/arsenal.sh" /usr/local/bin/arsenal
        print_status $? "Symbolic link created at /usr/local/bin/arsenal"
        echo -e "You can now run the IT Arsenal from anywhere by typing ${GREEN}arsenal${NC}"
    else
        echo -e "No symbolic link created. You can run IT Arsenal with ${GREEN}./arsenal.sh${NC} from its directory."
    fi
}

# Finalize installation
finalize_installation() {
    print_header "Installation Completed"
    
    echo -e "${GREEN}${BOLD}IT Arsenal has been successfully installed!${NC}"
    echo -e "\nYou can start using IT Arsenal by running:"
    echo -e "  ${CYAN}cd ${SCRIPT_DIR}${NC}"
    echo -e "  ${CYAN}./arsenal.sh${NC}"
    
    if [[ "$create_link" =~ ^[Yy] ]]; then
        echo -e "\nOr from anywhere by running:"
        echo -e "  ${CYAN}arsenal${NC}"
    fi
    
    echo -e "\nFor more information, see the documentation in the ${CYAN}docs/${NC} directory."
}

# Main installation process
main() {
    print_header "IT Arsenal Installation"
    echo -e "This script will install IT Arsenal and set up the required components.\n"
    
    check_system_type
    check_dependencies
    create_directories
    set_permissions
    initialize_config
    create_links
    finalize_installation
}

# Run the installation
main
