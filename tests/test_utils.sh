#!/bin/bash
# IT Arsenal Test Utilities
# Common functions for writing and running tests

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test counters
TEST_NAME=""
TOTAL_CASES=0
PASSED_CASES=0
FAILED_CASES=0
CURRENT_CASE=""

# Initialize test
test_start() {
    TEST_NAME="$1"
    TOTAL_CASES=0
    PASSED_CASES=0
    FAILED_CASES=0
    
    echo "Running test: $TEST_NAME"
}

# Start a new test case
test_case() {
    CURRENT_CASE="$1"
    ((TOTAL_CASES++))
}

# Mark the current test case as failed
test_fail() {
    local message="$1"
    ((FAILED_CASES++))
    
    echo -e "${RED}✖ $CURRENT_CASE: FAILED${NC}"
    if [ -n "$message" ]; then
        echo -e "${RED}  $message${NC}"
    fi
    
    return 1
}

# Mark the current test case as passed
test_pass() {
    local message="$1"
    ((PASSED_CASES++))
    
    echo -e "${GREEN}✓ $CURRENT_CASE: PASSED${NC}"
    if [ -n "$message" ]; then
        echo -e "${GREEN}  $message${NC}"
    fi
    
    return 0
}

# Assert that two values are equal
assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values are not equal: expected \"$expected\", got \"$actual\"}"
    
    if [ "$actual" == "$expected" ]; then
        test_pass
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-String \"$string\" does not contain \"$substring\"}"
    
    if [[ "$string" == *"$substring"* ]]; then
        test_pass
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File \"$file\" does not exist}"
    
    if [ -f "$file" ]; then
        test_pass
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert that a command succeeds
assert_success() {
    local cmd="$1"
    local message="${2:-Command failed: \"$cmd\"}"
    
    if eval "$cmd" &>/dev/null; then
        test_pass
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    local cmd="$1"
    local message="${2:-Command succeeded when it should fail: \"$cmd\"}"
    
    if ! eval "$cmd" &>/dev/null; then
        test_pass
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# End test and report results
test_end() {
    echo -e "\nTest results for: $TEST_NAME"
    echo -e "Total test cases: $TOTAL_CASES"
    echo -e "${GREEN}Passed: $PASSED_CASES${NC}"
    echo -e "${RED}Failed: $FAILED_CASES${NC}"
    
    if [ $FAILED_CASES -eq 0 ]; then
        echo -e "${GREEN}All test cases passed!${NC}"
        return 0
    else
        echo -e "${RED}Some test cases failed!${NC}"
        return 1
    fi
}
