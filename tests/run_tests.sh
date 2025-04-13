#!/bin/bash
# IT Arsenal Test Runner
# Run all tests or specific test categories

# Set strict mode
set -eo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test directories
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_DIR="$TEST_DIR/unit"
INTEGRATION_DIR="$TEST_DIR/integration"
SYSTEM_DIR="$TEST_DIR/system"
ARSENAL_DIR="$(dirname "$TEST_DIR")"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Print header
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Run all tests in a directory
run_tests_in_dir() {
    local dir="$1"
    local category="$2"
    local test_files=()
    
    # Find all executable test files
    while IFS= read -r -d '' file; do
        test_files+=("$file")
    done < <(find "$dir" -type f -name "test_*.sh" -executable -print0)
    
    # Skip if no tests found
    if [ ${#test_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No $category tests found.${NC}"
        return 0
    fi
    
    print_header "$category Tests (${#test_files[@]} test files)"
    
    local passed_category=0
    local failed_category=0
    
    # Run each test file
    for test_file in "${test_files[@]}"; do
        local test_name=$(basename "$test_file")
        echo -ne "Running ${BOLD}$test_name${NC}... "
        
        # Run the test and capture output
        output=$(bash "$test_file" 2>&1)
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}PASSED${NC}"
            ((passed_category++))
            ((PASSED_TESTS++))
        else
            echo -e "${RED}FAILED${NC}"
            echo -e "${RED}$output${NC}"
            ((failed_category++))
            ((FAILED_TESTS++))
        fi
        
        ((TOTAL_TESTS++))
    done
    
    echo -e "\n${category} Results: ${GREEN}$passed_category passed${NC}, ${RED}$failed_category failed${NC}"
    return $failed_category
}

# Run specified test categories
run_test_categories() {
    local categories=("$@")
    
    if [ ${#categories[@]} -eq 0 ]; then
        categories=("unit" "integration" "system")
    fi
    
    local exit_code=0
    
    for category in "${categories[@]}"; do
        case "$category" in
            unit)
                run_tests_in_dir "$UNIT_DIR" "Unit"
                [ $? -ne 0 ] && exit_code=1
                ;;
            integration)
                run_tests_in_dir "$INTEGRATION_DIR" "Integration"
                [ $? -ne 0 ] && exit_code=1
                ;;
            system)
                run_tests_in_dir "$SYSTEM_DIR" "System"
                [ $? -ne 0 ] && exit_code=1
                ;;
            *)
                echo -e "${RED}Unknown test category: $category${NC}"
                echo "Valid categories are: unit, integration, system"
                exit 1
                ;;
        esac
    done
    
    return $exit_code
}

# Print test summary
print_summary() {
    echo -e "\n${BLUE}${BOLD}=== Test Summary ===${NC}"
    echo -e "Total tests:  $TOTAL_TESTS"
    echo -e "Passed:     ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:     ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}${BOLD}All tests passed!${NC}"
    else
        echo -e "\n${RED}${BOLD}Some tests failed.${NC}"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [category...]"
    echo ""
    echo "Categories:"
    echo "  unit       Run unit tests"
    echo "  integration Run integration tests"
    echo "  system     Run system tests"
    echo ""
    echo "If no category is specified, all tests will be run."
}

# Main function
main() {
    # Check for help flag
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        show_usage
        exit 0
    fi
    
    print_header "IT Arsenal Test Suite"
    
    # Run specified test categories
    run_test_categories "$@"
    local exit_code=$?
    
    # Print summary
    print_summary
    
    return $exit_code
}

# Run main function with all arguments
main "$@"
exit $?
