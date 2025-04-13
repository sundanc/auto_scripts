#!/bin/bash
# Plugin Manager for IT Arsenal
# GitHub: https://github.com/sundanc/auto_scripts

# Plugin categories
PLUGIN_CATEGORIES=("system" "development" "devops" "database")

# Plugin directories
PLUGINS_ROOT="$ARSENAL_ROOT/plugins"
PLUGIN_CONFIG_DIR="$CONFIG_DIR/plugins"

# Loaded plugins
declare -A LOADED_PLUGINS

# Log plugin messages
arsenal_plugin_log() {
    local plugin_name="$1"
    local level="$2"
    local message="$3"
    arsenal_log "$level" "$message" "plugin:$plugin_name"
}

# Register plugin menu item
arsenal_plugin_register_menu_item() {
    local plugin_name="$1"
    local category="$2"
    local menu_title="$3"
    local main_function="$4"
    
    # Register menu item based on category
    case "$category" in
        system)
            SYSTEM_MENU_ITEMS+=("$menu_title:$main_function")
            ;;
        development)
            DEV_MENU_ITEMS+=("$menu_title:$main_function")
            ;;
        devops)
            DEVOPS_MENU_ITEMS+=("$menu_title:$main_function")
            ;;
        database)
            DB_MENU_ITEMS+=("$menu_title:$main_function")
            ;;
        *)
            arsenal_plugin_log "$plugin_name" "WARNING" "Unknown category: $category"
            ;;
    esac
}

# Check plugin compatibility
check_plugin_compatibility() {
    local plugin_name="$1"
    local metadata_file="$2"
    local os_name=$(arsenal_get_os)
    
    # Parse JSON file (simple grep-based approach)
    local min_version=$(grep -o '"min_arsenal_version"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local compatible_os=$(grep -o '"os"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$metadata_file")
    
    # Check arsenal version compatibility
    if [[ -n "$min_version" ]] && [[ "$ARSENAL_VERSION" < "$min_version" ]]; then
        echo "Plugin '$plugin_name' requires Arsenal version $min_version or higher"
        return 1
    fi
    
    # Check OS compatibility if specified
    if [[ -n "$compatible_os" ]] && ! echo "$compatible_os" | grep -qi "\"$os_name\""; then
        echo "Plugin '$plugin_name' is not compatible with your OS ($os_name)"
        return 1
    fi
    
    return 0
}

# Load a plugin
arsenal_plugin_load() {
    local plugin_file="$1"
    local plugin_name=$(basename "${plugin_file%.*}")
    local plugin_dir=$(dirname "$plugin_file")
    local metadata_file="${plugin_dir}/${plugin_name}.json"
    
    # Skip if not a valid plugin file
    if [[ ! -f "$plugin_file" ]] || [[ ! "$plugin_file" =~ \.sh$ ]]; then
        return 1
    fi
    
    # Skip if already loaded
    if [[ -n "${LOADED_PLUGINS[$plugin_name]}" ]]; then
        arsenal_plugin_log "$plugin_name" "INFO" "Plugin already loaded"
        return 0
    fi
    
    # Check if metadata exists
    if [[ ! -f "$metadata_file" ]]; then
        arsenal_plugin_log "$plugin_name" "WARNING" "No metadata file found: $metadata_file"
        return 1
    fi
    
    # Check compatibility
    if ! check_plugin_compatibility "$plugin_name" "$metadata_file"; then
        arsenal_plugin_log "$plugin_name" "WARNING" "Plugin compatibility check failed"
        return 1
    fi
    
    # Extract plugin information
    local category=$(grep -o '"category"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local main_function=$(grep -o '"main_function"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local menu_title=$(grep -o '"menu_title"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local dependencies=$(grep -o '"dependencies"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$metadata_file" | sed 's/.*\[\([^]]*\)\].*/\1/g' | tr -d '"' | tr ',' ' ')
    
    # Check dependencies
    for dep in $dependencies; do
        if ! command -v "$dep" &>/dev/null; then
            arsenal_plugin_log "$plugin_name" "WARNING" "Missing dependency: $dep"
        fi
    done
    
    # Source the plugin file
    source "$plugin_file" || {
        arsenal_plugin_log "$plugin_name" "ERROR" "Failed to load plugin: $plugin_name"
        return 1
    }
    
    # Verify main function exists
    if ! command -v "$main_function" &>/dev/null; then
        arsenal_plugin_log "$plugin_name" "ERROR" "Main function '$main_function' not defined in plugin"
        return 1
    fi
    
    # Register the plugin
    LOADED_PLUGINS["$plugin_name"]="$plugin_file"
    arsenal_plugin_register_menu_item "$plugin_name" "$category" "$menu_title" "$main_function"
    
    arsenal_plugin_log "$plugin_name" "INFO" "Plugin loaded successfully"
    return 0
}

# Discover and load all plugins
arsenal_plugin_discover_all() {
    local load_count=0
    local skip_count=0
    
    echo "Discovering plugins..."
    
    # Process each plugin category
    for category in "${PLUGIN_CATEGORIES[@]}"; do
        local category_dir="$PLUGINS_ROOT/$category"
        
        if [[ ! -d "$category_dir" ]]; then
            continue
        fi
        
        # Find and load plugins in this category
        while IFS= read -r -d '' plugin_file; do
            if arsenal_plugin_load "$plugin_file"; then
                ((load_count++))
            else
                ((skip_count++))
            fi
        done < <(find "$category_dir" -name "*.sh" -type f -print0)
    done
    
    echo "Plugin discovery complete: $load_count plugins loaded, $skip_count plugins skipped"
    return 0
}

# Initialize the plugin system
arsenal_plugin_init() {
    # Create plugin directories if they don't exist
    for category in "${PLUGIN_CATEGORIES[@]}"; do
        mkdir -p "$PLUGINS_ROOT/$category"
    done
    
    # Check plugin configuration directory
    mkdir -p "$PLUGIN_CONFIG_DIR"
    
    # Discover and load all plugins
    arsenal_plugin_discover_all
    
    return 0
}