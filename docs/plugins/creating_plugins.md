# Creating IT Arsenal Plugins

This guide walks you through the process of creating plugins to extend IT Arsenal functionality.

## Plugin System Overview

The IT Arsenal plugin system allows you to add new features without modifying core code. Plugins:

- Are loaded dynamically at startup
- Can add new menu items to specific categories
- Can access all core library functions
- Can store and retrieve their own configuration

## Plugin Structure

A plugin consists of two mandatory files:

1. **Plugin Script** (`your_plugin_name.sh`): Contains the actual implementation
2. **Plugin Metadata** (`your_plugin_name.json`): Contains information about the plugin

Both files must have the same name (with different extensions) and must be placed in the appropriate category directory under `plugins/`.

### Plugin Categories

- `plugins/system/` - System administration plugins
- `plugins/development/` - Development workflow plugins  
- `plugins/devops/` - DevOps and deployment plugins
- `plugins/database/` - Database management plugins

## Creating a Plugin Script

The plugin script contains your implementation. Here's a template:

```bash
#!/bin/bash
# IT Arsenal Plugin: [Plugin Name]
# Description: [Brief description]
# Version: [Version]
# Author: [Your Name]

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ARSENAL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ARSENAL_ROOT/lib/common.sh" || exit 1

# Plugin specific variables
# ...

# Your functions go here
# ...

# Main function that will be called by the arsenal
# This function MUST exist and match the main_function in your JSON metadata
your_plugin_main() {
    # Implement your main plugin functionality here
    # This is what runs when the user selects your plugin from the menu
    echo "Hello from your plugin!"
}
```

## Creating Plugin Metadata

The JSON metadata file provides information about your plugin:

```json
{
    "name": "Your Plugin Name",
    "version": "1.0",
    "description": "Brief description of what your plugin does",
    "author": "Your Name",
    "category": "system",
    "main_function": "your_plugin_main",
    "menu_title": "Your Plugin Menu Entry",
    "dependencies": ["command1", "command2"],
    "compatibility": {
        "min_arsenal_version": "1.0",
        "os": ["linux", "debian", "ubuntu"]
    }
}
```

### Metadata Fields

- `name`: Display name of your plugin
- `version`: Plugin version
- `description`: Brief explanation of plugin functionality
- `author`: Your name or organization
- `category`: One of: system, development, devops, database
- `main_function`: Name of the function to call when user selects your plugin
- `menu_title`: Text to display in the arsenal menu
- `dependencies`: Array of commands required by your plugin
- `compatibility`: Compatibility requirements
  - `min_arsenal_version`: Minimum IT Arsenal version
  - `os`: Array of compatible operating systems

## Plugin API

Your plugin can use these special functions:

### Configuration Management

```bash
# Store plugin-specific configuration
arsenal_plugin_set_config "plugin_name" "key" "value"

# Retrieve plugin-specific configuration with default fallback
value=$(arsenal_plugin_get_config "plugin_name" "key" "default_value")
```

### Logging

```bash
# Log plugin-specific messages
arsenal_plugin_log "plugin_name" "INFO" "Your message here"
arsenal_plugin_log "plugin_name" "ERROR" "Error message"
```

### Menu Registration

```bash
# Register menu item (normally handled automatically during loading)
arsenal_plugin_register_menu_item "plugin_name" "category" "Menu Title" "function_name"
```

## Accessing Common Library

Your plugin has access to all functions from the common library:

```bash
# Print styled header
arsenal_print_header "Your Header"

# Get system information
os_info=$(arsenal_get_os_info)

# Check dependencies
arsenal_check_dependencies command1 command2

# Format file sizes
human_size=$(arsenal_format_bytes 1048576)
```

## Example: Hello World Plugin

### `plugins/system/hello_world.sh`

```bash
#!/bin/bash
# IT Arsenal Plugin: Hello World
# Description: Simple example plugin
# Version: 1.0
# Author: Arsenal Team

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ARSENAL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ARSENAL_ROOT/lib/common.sh" || exit 1

# Show greeting
show_greeting() {
    local name=$(arsenal_plugin_get_config "hello_world" "user_name" "User")
    arsenal_print_header "Hello World Plugin"
    echo -e "${GREEN}Hello, $name!${NC}"
    echo ""
    echo -e "This is a simple example plugin."
    echo -e "Current time: $(date)"
    echo -e "Your operating system: $(arsenal_get_os)"
    echo ""
    read -p "Press Enter to return to menu..."
}

# Configure plugin
configure_plugin() {
    arsenal_print_header "Hello World Configuration"
    echo -ne "Enter your name: "
    read user_name
    
    if [[ -n "$user_name" ]]; then
        arsenal_plugin_set_config "hello_world" "user_name" "$user_name"
        echo -e "${GREEN}Configuration saved!${NC}"
    else
        echo -e "${YELLOW}No name entered, using default.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Main plugin menu
hello_world_menu() {
    while true; do
        arsenal_print_header "Hello World Plugin"
        echo -e "${GREEN}1${NC}. Show Greeting"
        echo -e "${GREEN}2${NC}. Configure Plugin"
        echo -e "${GREEN}0${NC}. Back to Main Menu"
        echo ""
        echo -ne "Select an option [0-2]: "
        
        read choice
        case $choice in
            1) show_greeting ;;
            2) configure_plugin ;;
            0) return 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; read -p "Press Enter to continue..." ;;
        esac
    done
}

# Main function that will be called by arsenal
hello_world_main() {
    hello_world_menu
}
```

### `plugins/system/hello_world.json`

```json
{
    "name": "Hello World",
    "version": "1.0",
    "description": "A simple example plugin that demonstrates plugin functionality",
    "author": "Arsenal Team",
    "category": "system",
    "main_function": "hello_world_main",
    "menu_title": "Hello World Example",
    "dependencies": [],
    "compatibility": {
        "min_arsenal_version": "1.0",
        "os": ["linux"]
    }
}
```

## Best Practices

1. **Always check dependencies** - Use `arsenal_check_dependencies` to verify required tools
2. **Handle errors gracefully** - Use proper error messages and exit codes
3. **Clean up temporary files** - Don't leave behind temporary files
4. **Store user settings** - Use the configuration API to persist settings
5. **Provide feedback** - Keep the user informed of what's happening
6. **Follow the UI style** - Use the color constants and formatting from common.sh
7. **Include help text** - Always provide help or usage information

## Testing Your Plugin

1. Place both files in the appropriate plugin category directory
2. Restart IT Arsenal or select "Reload Plugins" from the Arsenal menu
3. Your plugin should appear in the appropriate category menu

## Troubleshooting

If your plugin doesn't load:

1. Check console for error messages
2. Verify JSON syntax is correct
3. Make sure your script is executable (`chmod +x your_plugin.sh`)
4. Confirm the main function exists and matches the name in the JSON file
5. Check the logs for detailed error information
