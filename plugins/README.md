# IT Arsenal Plugin System

The plugin system allows you to extend IT Arsenal with custom functionality without modifying core files.

## Plugin Directory Structure

Plugins are organized by category:

- `system/` - Plugins for system administration tools
- `development/` - Plugins for development tools
- `devops/` - Plugins for DevOps and deployment tools
- `database/` - Plugins for database management tools

## Creating a Plugin

A plugin consists of two main parts:

1. **Plugin Script** - The actual implementation file
2. **Plugin Metadata** - A JSON file with information about the plugin

### Basic Plugin Structure

For example, to create a "Network Monitor" plugin:

1. Create a script file in the appropriate category:
   ```bash
   plugins/system/network_monitor.sh
   ```

2. Create a corresponding metadata file:
   ```json
   plugins/system/network_monitor.json
   ```

### Plugin Script

A basic plugin script should:

- Include standard header information
- Import the common library
- Define required functions
- Implement the functionality

Example:

```bash
#!/bin/bash
# IT Arsenal Plugin: Network Monitor
# Description: Monitor network traffic and bandwidth usage
# Version: 1.0
# Author: Your Name

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ARSENAL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ARSENAL_ROOT/lib/common.sh" || exit 1

# Plugin implementation goes here
# ...

# Main function that will be called by the arsenal
network_monitor_main() {
    # Your plugin code here
    echo "Network Monitor Plugin"
}
```

### Plugin Metadata

The metadata file provides information about your plugin to IT Arsenal:

```json
{
    "name": "Network Monitor",
    "version": "1.0",
    "description": "Monitor network traffic and bandwidth usage",
    "author": "Your Name",
    "category": "system",
    "main_function": "network_monitor_main",
    "menu_title": "Network Monitor",
    "dependencies": ["iftop", "nethogs", "iptraf"],
    "compatibility": {
        "min_arsenal_version": "1.0",
        "os": ["linux"]
    }
}
```

## Registering a Plugin

Plugins are automatically detected and loaded when IT Arsenal starts.

## Plugin API

Plugins can use all functions from the `lib/common.sh` library, plus these plugin-specific functions:

- `arsenal_plugin_register_menu_item`: Add an item to a menu
- `arsenal_plugin_get_config`: Get plugin-specific configuration
- `arsenal_plugin_set_config`: Set plugin-specific configuration
- `arsenal_plugin_log`: Log plugin-specific messages

## Plugin Configuration

Plugin settings can be stored in:

```
config/plugins/[plugin_name].conf
```

## Plugin Examples

See `plugins/examples/` for sample plugins demonstrating:

- Adding new menu items
- Extending existing functionality
- Creating custom views
- Integrating with external tools
