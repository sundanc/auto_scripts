#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Script Debugging Tool - Helps identify and resolve script issues

# Import common library functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../lib/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}

# Import compatibility checker
source "$SCRIPT_DIR/../lib/compatibility_checker.sh" || {
    echo "Error: Could not source compatibility checker"
    exit 1
}

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Usage information
usage() {
    echo "Usage: $0 [options] [script_path]"
    echo ""
    echo "Options:"
    echo "  -a, --all           Check all scripts in repository"
    echo "  -s, --script PATH   Debug a specific script"
    echo "  -c, --category CAT  Check all scripts in category (system, development, devops, database)"
    echo "  -v, --verbose       Display detailed information"
    echo "  -h, --help          Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s ../system/vm.sh         # Debug vm.sh script"
    echo "  $0 -c system                  # Debug all system scripts"
    echo "  $0 -a                         # Check all scripts in repository"
}

# Parse command line arguments
SCRIPT_PATH=""
CHECK_ALL=false
CATEGORY=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            CHECK_ALL=true
            shift
            ;;
        -s|--script)
            SCRIPT_PATH="$2"
            shift 2
            ;;
        -c|--category)
            CATEGORY="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -f "$1" ]]; then
                SCRIPT_PATH="$1"
                shift
            else
                echo -e "${RED}Error: Unknown option or invalid script path: $1${NC}"
                usage
                exit 1
            fi
            ;;
    esac
done

# Initialize dependency database
init_dependency_database

# Function to check a script
check_script() {
    local script="$1"
    local basename=$(basename "$script")
    
    echo -e "${BLUE}${BOLD}=== Debugging $basename ===${NC}"
    
    # Check if script exists
    if [[ ! -f "$script" ]]; then
        echo -e "${RED}Error: Script not found: $script${NC}"
        return 1
    fi
    
    # Check if script is executable
    if [[ ! -x "$script" ]]; then
        echo -e "${YELLOW}Warning: Script is not executable${NC}"
        if confirm "Make script executable?" "y"; then
            chmod +x "$script"
            echo -e "${GREEN}Script is now executable${NC}"
        fi
    fi
    
    # Check script content
    echo -e "\n${BLUE}Checking script content:${NC}"
    local shebang=$(head -n1 "$script")
    if [[ "$shebang" != "#!/bin/bash"* && "$shebang" != "#!/usr/bin/env bash"* ]]; then
        echo -e "${YELLOW}Warning: Missing or incorrect shebang (found: $shebang)${NC}"
    else
        echo -e "${GREEN}✓ Shebang line OK${NC}"
    fi
    
    # Check for common functions import
    if grep -q "source.*common.sh" "$script"; then
        echo -e "${GREEN}✓ Common functions imported${NC}"
    else
        echo -e "${YELLOW}Warning: Script does not import common functions${NC}"
    fi
    
    # Check for potential syntax errors
    echo -e "\n${BLUE}Checking for syntax errors:${NC}"
    bash -n "$script"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ No syntax errors detected${NC}"
    else
        echo -e "${RED}✗ Syntax errors found${NC}"
    fi
    
    # Run compatibility check
    echo -e "\n${BLUE}Checking compatibility:${NC}"
    debug_script_requirements "$basename"
    
    # Static analysis for potential issues
    echo -e "\n${BLUE}Static analysis for potential issues:${NC}"
    
    # Check for hardcoded paths
    if grep -q "\/home\/\w\+" "$script"; then
        echo -e "${YELLOW}Warning: Script appears to contain hardcoded paths${NC}"
    fi
    
    # Check for error handling
    if ! grep -q "exit \+[1-9][0-9]*" "$script"; then
        echo -e "${YELLOW}Warning: Script may lack proper error handling (no non-zero exit codes)${NC}"
    fi
    
    # Check for logging
    if grep -q "arsenal_log\|log " "$script"; then
        echo -e "${GREEN}✓ Script uses logging functions${NC}"
    else
        echo -e "${YELLOW}Warning: Script may not use logging functions${NC}"
    fi
    
    # Check for root requirement without check
    if grep -qE "sudo |/etc/|/var/|/usr/" "$script" && ! grep -q "EUID\|arsenal_check_root" "$script"; then
        echo -e "${YELLOW}Warning: Script may require root privileges but doesn't check for them${NC}"
    fi
    
    echo -e "\n${GREEN}Debugging completed for $basename${NC}"
}

# Function to check all scripts in a category
check_category() {
    local category="$1"
    local category_dir="$ARSENAL_ROOT/$category"
    
    echo -e "${BLUE}${BOLD}=== Checking all scripts in $category category ===${NC}"
    
    if [[ ! -d "$category_dir" ]]; then
        echo -e "${RED}Error: Category directory not found: $category_dir${NC}"
        return 1
    fi
    
    local scripts=()
    while IFS= read -r -d '' script; do
        scripts+=("$script")
    done < <(find "$category_dir" -name "*.sh" -type f -print0)
    
    if [[ ${#scripts[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No scripts found in $category category${NC}"
        return 0
    fi
    
    echo -e "${GREEN}Found ${#scripts[@]} scripts in $category category${NC}"
    
    # Initialize dependency database
    init_dependency_database
    
    # Check compatibility for all scripts
    bulk_compatibility_check "${scripts[@]}"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "\n${BLUE}Detailed analysis of each script:${NC}"
        for script in "${scripts[@]}"; do
            check_script "$script"
            echo ""
        done
    fi
}

# Main execution
if [[ "$CHECK_ALL" == "true" ]]; then
    echo -e "${BLUE}${BOLD}=== Checking all scripts in repository ===${NC}"
    check_system_compatibility "$ARSENAL_ROOT" "$VERBOSE"
elif [[ -n "$CATEGORY" ]]; then
    check_category "$CATEGORY"
elif [[ -n "$SCRIPT_PATH" ]]; then
    check_script "$SCRIPT_PATH"
else
    echo -e "${YELLOW}No option specified${NC}"
    usage
    exit 1
fi

echo -e "\n${GREEN}Script debugging completed${NC}"
exit 0
