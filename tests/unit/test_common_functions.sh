#!/bin/bash
# Unit tests for common library functions

# Import test utilities
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../test_utils.sh"

# Source common library
ARSENAL_DIR="$(cd "$TEST_DIR/../.." && pwd)"
source "$ARSENAL_DIR/lib/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}

# Initialize test
test_start "Common Library Functions Test"

# Test arsenal_command_exists function
test_case "arsenal_command_exists should detect existing command"
arsenal_command_exists "bash" && test_pass || test_fail "Failed to detect 'bash' command"

test_case "arsenal_command_exists should detect non-existing command"
arsenal_command_exists "this_command_does_not_exist" && test_fail "Should not detect non-existent command" || test_pass

# Test arsenal_get_config function
test_case "arsenal_get_config should return default value when key doesn't exist"
result=$(arsenal_get_config "NONEXISTENT_KEY" "default_value")
assert_equals "$result" "default_value"

# Create temporary config file for testing
TMP_CONFIG="/tmp/arsenal_test_config.$$"
echo "TEST_KEY=test_value" > "$TMP_CONFIG"
echo "EMPTY_KEY=" >> "$TMP_CONFIG"

# Temporarily override CONFIG_FILE
CONFIG_FILE_BAK="$CONFIG_FILE"
CONFIG_FILE="$TMP_CONFIG"

test_case "arsenal_get_config should read value from config file"
result=$(arsenal_get_config "TEST_KEY" "default")
assert_equals "$result" "test_value"

test_case "arsenal_get_config should return default for empty values"
result=$(arsenal_get_config "EMPTY_KEY" "default_for_empty")
assert_equals "$result" "default_for_empty"

# Restore original CONFIG_FILE and clean up
CONFIG_FILE="$CONFIG_FILE_BAK"
rm -f "$TMP_CONFIG"

# Test arsenal_format_bytes function
test_case "arsenal_format_bytes should format bytes correctly"
result=$(arsenal_format_bytes 1024)
assert_equals "$result" "1.00KB"

test_case "arsenal_format_bytes should format megabytes correctly"
result=$(arsenal_format_bytes 2097152)
assert_equals "$result" "2.00MB"

test_case "arsenal_format_bytes should handle precision parameter"
result=$(arsenal_format_bytes 1048576 0)
assert_equals "$result" "1MB"

# Test arsenal_confirm function (mock user input)
test_case "arsenal_confirm should accept default y"
# Mock read command by redefining it
read() { return 0; }
arsenal_confirm "Test message" "y" && test_pass || test_fail "Failed with default y"

# Test filesystem functions
test_case "arsenal_check_file should detect existing file"
touch "/tmp/arsenal_test_file.$$"
arsenal_check_file "/tmp/arsenal_test_file.$$" && test_pass || test_fail "Failed to detect existing file"
rm -f "/tmp/arsenal_test_file.$$"

test_case "arsenal_check_file should detect missing file"
arsenal_check_file "/tmp/this_file_should_not_exist.$$" && test_fail "Should not detect non-existent file" || test_pass

# Test arsenal_backup_file function
test_case "arsenal_backup_file should create a backup of a file"
echo "test content" > "/tmp/arsenal_test_backup_source.$$"
arsenal_backup_file "/tmp/arsenal_test_backup_source.$$" "/tmp"
# Check if a backup file was created (should match pattern with timestamp)
ls /tmp/arsenal_test_backup_source.$$.*.bak &>/dev/null && test_pass || test_fail "Backup file not created"
rm -f /tmp/arsenal_test_backup_source.$$.*.bak
rm -f "/tmp/arsenal_test_backup_source.$$"

# Test arsenal_get_os function
test_case "arsenal_get_os should return a valid OS identifier"
os_id=$(arsenal_get_os)
[[ -n "$os_id" ]] && test_pass || test_fail "Did not return a valid OS identifier"

# End test and report results
test_end
exit $?
