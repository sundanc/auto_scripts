#!/bin/bash
# Unit tests for plugin system functions

# Import test utilities
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../test_utils.sh"

# Source common library and plugin manager
ARSENAL_DIR="$(cd "$TEST_DIR/../.." && pwd)"
source "$ARSENAL_DIR/lib/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}
source "$ARSENAL_DIR/lib/plugin_manager.sh" || {
    echo "Error: Could not source plugin manager"
    exit 1
}

# Initialize test
test_start "Plugin System Functions Test"

# Setup a temporary directory for test plugins
TEST_PLUGINS_DIR="/tmp/arsenal_test_plugins_$$"
TEST_PLUGIN_CONFIG_DIR="/tmp/arsenal_test_plugin_config_$$"
mkdir -p "$TEST_PLUGINS_DIR/system"
mkdir -p "$TEST_PLUGIN_CONFIG_DIR"

# Temporarily override plugin roots
PLUGINS_ROOT_BAK="$PLUGINS_ROOT"
PLUGINS_ROOT="$TEST_PLUGINS_DIR"
PLUGIN_CONFIG_DIR_BAK="$PLUGIN_CONFIG_DIR"
PLUGIN_CONFIG_DIR="$TEST_PLUGIN_CONFIG_DIR"

# Create a test plugin
create_test_plugin() {
    # Create plugin script
    cat > "$TEST_PLUGINS_DIR/system/test_plugin.sh" << EOF
#!/bin/bash
# Test plugin
test_plugin_function() {
    echo "Test plugin function called"
    return 0
}
EOF
    chmod +x "$TEST_PLUGINS_DIR/system/test_plugin.sh"
    
    # Create plugin metadata
    cat > "$TEST_PLUGINS_DIR/system/test_plugin.json" << EOF
{
    "name": "Test Plugin",
    "version": "1.0",
    "description": "Plugin for testing",
    "author": "Test Author",
    "category": "system",
    "main_function": "test_plugin_function",
    "menu_title": "Test Plugin Menu Entry",
    "dependencies": [],
    "compatibility": {
        "min_arsenal_version": "1.0",
        "os": ["linux"]
    }
}
EOF
}

# Test plugin config functions
test_case "arsenal_plugin_set_config should store config values"
arsenal_plugin_set_config "test_plugin" "test_key" "test_value"

# Check if config file was created
config_file="$TEST_PLUGIN_CONFIG_DIR/test_plugin.conf"
test -f "$config_file" && test_pass || test_fail "Config file was not created"

# Test plugin config retrieval
test_case "arsenal_plugin_get_config should retrieve stored config values"
value=$(arsenal_plugin_get_config "test_plugin" "test_key" "default")
assert_equals "$value" "test_value" "Config value doesn't match expected value"

# Test plugin config default value
test_case "arsenal_plugin_get_config should return default for missing keys"
value=$(arsenal_plugin_get_config "test_plugin" "nonexistent_key" "default_value")
assert_equals "$value" "default_value" "Default value wasn't returned for missing key"

# Create a test plugin for loading tests
create_test_plugin

# Test plugin loading
test_case "arsenal_plugin_load should load a valid plugin"
arsenal_plugin_load "$TEST_PLUGINS_DIR/system/test_plugin.sh"
load_result=$?
assert_equals "$load_result" "0" "Plugin loading failed"

# Test main function registration
test_case "Plugin loading should register main function"
[[ -n "${PLUGIN_MAIN_FUNCTIONS[system_test_plugin]}" ]] && test_pass || test_fail "Main function not registered"

# Test menu item registration
test_case "Plugin loading should register menu item"
[[ -n "${PLUGIN_MENU_ITEMS[system_test_plugin]}" ]] && test_pass || test_fail "Menu item not registered"

# Test menu item text
test_case "Plugin menu item should have correct text"
menu_text="${PLUGIN_MENU_ITEMS[system_test_plugin]}"
assert_equals "$menu_text" "Test Plugin Menu Entry" "Menu text is incorrect"

# Test plugin discovery
test_case "arsenal_plugin_discover_all should find plugins"
# Reset plugin tracking arrays to ensure clean state
LOADED_PLUGINS=()
PLUGIN_MENU_ITEMS=()
PLUGIN_MAIN_FUNCTIONS=()

arsenal_plugin_discover_all
# Check if our test plugin was discovered
[[ -n "${LOADED_PLUGINS[test_plugin]}" ]] && test_pass || test_fail "Plugin discovery failed to find test plugin"

# Test plugin compatibility check
test_case "check_plugin_compatibility should validate version requirements"
# Create metadata file with future version requirement
cat > "$TEST_PLUGINS_DIR/system/incompatible_plugin.json" << EOF
{
    "name": "Incompatible Plugin",
    "version": "1.0",
    "description": "Plugin with incompatible version",
    "author": "Test Author",
    "category": "system",
    "main_function": "test_plugin_function",
    "menu_title": "Incompatible Plugin",
    "dependencies": [],
    "compatibility": {
        "min_arsenal_version": "999.0",
        "os": ["linux"]
    }
}
EOF

check_plugin_compatibility "incompatible_plugin" "$TEST_PLUGINS_DIR/system/incompatible_plugin.json" && 
    test_fail "Incompatible plugin should be rejected" || 
    test_pass "Correctly rejected incompatible plugin"

# Test plugin execution
test_case "arsenal_plugin_execute should run plugin main function"
# Mock the test plugin function to verify it gets called
test_plugin_function() {
    return 42  # Unique return code to verify execution
}
PLUGIN_MAIN_FUNCTIONS["system_test_plugin"]="test_plugin_function"

arsenal_plugin_execute "system_test_plugin"
exec_result=$?
assert_equals "$exec_result" "42" "Plugin execution didn't return correct value"

# Cleanup test environment
rm -rf "$TEST_PLUGINS_DIR"
rm -rf "$TEST_PLUGIN_CONFIG_DIR"

# Restore original values
PLUGINS_ROOT="$PLUGINS_ROOT_BAK"
PLUGIN_CONFIG_DIR="$PLUGIN_CONFIG_DIR_BAK"

# End test and report results
test_end
exit $?
