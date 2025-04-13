#!/bin/bash
# Unit tests for file management functions in common library

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
test_start "File Management Functions Test"

# Test arsenal_backup_file function
test_case "arsenal_backup_file should create a backup of a file"
test_source="/tmp/arsenal_test_backup_source_$$.txt"
test_backup_dir="/tmp/arsenal_test_backup_dir_$$"

# Create test directory and file
mkdir -p "$test_backup_dir"
echo "test content" > "$test_source"

arsenal_backup_file "$test_source" "$test_backup_dir"
# Check if a backup file was created
backup_count=$(find "$test_backup_dir" -name "arsenal_test_backup_source_$$.txt.*" | wc -l)
assert_equals "$backup_count" "1" "Expected 1 backup file but found $backup_count"

# Test arsenal_safe_write function
test_case "arsenal_safe_write should create backup and write new content"
test_file="/tmp/arsenal_test_safe_write_$$.txt"
echo "original content" > "$test_file"
arsenal_safe_write "$test_file" "new content"

# Check if content was updated
new_content=$(cat "$test_file")
assert_equals "$new_content" "new content" "File content was not updated correctly"

# Check if backup was created
backup_count=$(find "$(dirname "$test_file")" -name "arsenal_test_safe_write_$$.txt.*" | wc -l)
assert_equals "$backup_count" "1" "Expected 1 backup file but found $backup_count"

# Test arsenal_rotate_logs function
test_case "arsenal_rotate_logs should rotate logs when size exceeds limit"
test_log="/tmp/arsenal_test_rotate_$$.log"

# Create a log file larger than 2KB
dd if=/dev/zero bs=1K count=3 | tr '\0' 'X' > "$test_log"
initial_size=$(stat -c %s "$test_log")

# Rotate with 2KB limit
arsenal_rotate_logs "$test_log" 2 3

# Check if rotation happened
rotated_exists=$(test -f "${test_log}.1" && echo "yes" || echo "no")
assert_equals "$rotated_exists" "yes" "Rotated log file not created"

# Check if original was emptied
new_size=$(stat -c %s "$test_log")
assert_equals "$new_size" "0" "Original log was not emptied after rotation"

# Test arsenal_check_file function
test_case "arsenal_check_file should validate file existence and return correct status"
# Create a test file
touch "/tmp/arsenal_test_check_file_$$.txt"

# Test with existing file
arsenal_check_file "/tmp/arsenal_test_check_file_$$.txt"
assert_equals "$?" "0" "Failed to detect existing file"

# Test with non-existent file
arsenal_check_file "/tmp/nonexistent_file_$$" && test_fail "Should fail with non-existent file" || test_pass

# Test with non-existent file but not required
arsenal_check_file "/tmp/nonexistent_file_$$" false
assert_equals "$?" "1" "Should return 1 for non-existent optional file"

# Clean up test files
rm -f "$test_source" "$test_file" "$test_log" "${test_log}.1" "/tmp/arsenal_test_check_file_$$.txt"
rm -rf "$test_backup_dir"

# End test and report results
test_end
exit $?
