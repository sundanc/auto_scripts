#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Script Syntax Checker - Checks all scripts for syntax errors

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default paths
SCRIPTS_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"
REPORT_FILE="$SCRIPTS_ROOT/logs/syntax_report.txt"

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to print header
print_header() {
    local title="$1"
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BOLD}${title}${NC}"
    echo -e "${BLUE}=====================================${NC}"
}

# Function to check a single file
check_file() {
    local file="$1"
    local output
    local issues_found=false
    local lineno
    local issues=""
    
    # Skip checking non-bash files
    if ! grep -q "^#\!/bin/bash" "$file" && [[ ! "$file" =~ \.sh$ ]]; then
        return 0
    fi
    
    # Check for syntax errors
    output=$(bash -n "$file" 2>&1)
    if [[ $? -ne 0 ]]; then
        issues_found=true
        issues+="✖ Syntax error: $output\n"
    fi
    
    # Check for common issues
    
    # 1. Check for unquoted variables
    grep -n "if \[\[ [^$][a-zA-Z_][a-zA-Z0-9_]*[^]]" "$file" | while read -r line; do
        lineno=$(echo "$line" | cut -d':' -f1)
        issues_found=true
        issues+="⚠ Line $lineno: Potentially unquoted variable in conditional\n"
    done
    
    # 2. Check for = vs == in conditionals
    grep -n "\[\[ [^=]*=[^=][^]]*\]\]" "$file" | while read -r line; do
        lineno=$(echo "$line" | cut -d':' -f1)
        issues_found=true
        issues+="⚠ Line $lineno: Using = instead of == in conditional\n"
    done
    
    # 3. Check for missing fi, done, etc.
    grep -o "if\|then\|else\|elif\|fi\|for\|do\|done\|while\|case\|esac" "$file" | 
        sort | uniq -c | while read -r count keyword; do
        case "$keyword" in
            "if") if_count=$count ;;
            "fi") fi_count=$count ;;
            "for"|"while") loop_start_count=$((loop_start_count + count)) ;;
            "done") done_count=$count ;;
            "case") case_count=$count ;;
            "esac") esac_count=$count ;;
        esac
    done
    
    # 4. Check for duplicate function definitions
    grep -n "^[[:space:]]*[a-zA-Z0-9_]\+()[[:space:]]*{" "$file" | 
        awk '{print $1}' | cut -d':' -f2 | sort | uniq -d | while read -r func; do
        issues_found=true
        issues+="✖ Duplicate function definition: $func\n"
    done
    
    # Report issues if any
    if [[ "$issues_found" == "true" ]]; then
        echo -e "${RED}Issues found in ${BOLD}$file${NC}"
        echo -e "$issues"
        echo "FILE: $file" >> "$REPORT_FILE"
        echo -e "$issues" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        return 1
    else
        echo -e "${GREEN}✓ ${file}${NC} - No issues found"
        return 0
    fi
}

# Function to check all scripts in a directory recursively
check_directory() {
    local dir="$1"
    local issues_count=0
    local files_checked=0
    
    # Find all shell scripts
    while IFS= read -r -d '' file; do
        check_file "$file"
        if [[ $? -ne 0 ]]; then
            ((issues_count++))
        fi
        ((files_checked++))
    done < <(find "$dir" -type f -name "*.sh" -print0)
    
    echo ""
    echo -e "${BLUE}Results: ${files_checked} files checked, ${issues_count} files with issues${NC}"
    echo -e "Detailed report saved to: ${YELLOW}$REPORT_FILE${NC}"
    
    if [[ $issues_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Main function
main() {
    print_header "IT Arsenal Script Syntax Checker"
    
    # Reset report file
    echo "IT Arsenal Script Syntax Check Report" > "$REPORT_FILE"
    echo "Generated on: $(date)" >> "$REPORT_FILE"
    echo "=======================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Check all scripts
    check_directory "$SCRIPTS_ROOT"
    exit $?
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
