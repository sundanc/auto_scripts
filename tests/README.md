# IT Arsenal Testing Framework

This directory contains test scripts for verifying the functionality of IT Arsenal scripts and components.

## Testing Structure

The test suite is organized into three categories:

1. **Unit Tests** - Test individual functions in isolation
2. **Integration Tests** - Test interactions between components
3. **System Tests** - Test complete workflows and end-to-end scenarios

## Running Tests

### Run All Tests

```bash
./run_tests.sh
```

### Run Specific Test Categories

```bash
./run_tests.sh unit      # Run only unit tests
./run_tests.sh integration  # Run only integration tests
./run_tests.sh system    # Run only system tests
```

### Run Individual Tests

```bash
./tests/unit/test_common_functions.sh
```

## Creating Tests

To create a new test:

1. Add your test script to the appropriate directory
2. Make sure it follows the testing conventions
3. Make it executable (`chmod +x your_test.sh`)

### Test Conventions

Each test script should:

1. Return exit code 0 if all tests pass, non-zero otherwise
2. Output clear success/failure messages
3. Clean up after itself (temporary files, etc.)
4. Be able to run non-interactively

### Example Test Structure

```bash
#!/bin/bash
# Test script for [function or component]

# Import test utilities
source "$(dirname "$0")/../test_utils.sh"

# Initialize test
test_start "[Test name]"

# Test case 1
test_case "Function should return success"
result=$(function_being_tested arg1 arg2)
assert_equals "$result" "expected result"

# Test case 2
test_case "Function should handle errors"
function_being_tested invalid_arg && {
    test_fail "Function did not fail as expected"
}

# Report results
test_end
```

## Testing Utilities

The `test_utils.sh` script provides common testing functions:

- `test_start` - Initialize a test run
- `test_case` - Start a new test case
- `test_fail` - Mark a test as failed
- `test_pass` - Mark a test as passed
- `assert_equals` - Compare values for equality
- `assert_contains` - Check if string contains a substring
- `assert_file_exists` - Check if a file exists
- `test_end` - Finalize a test run and report results
