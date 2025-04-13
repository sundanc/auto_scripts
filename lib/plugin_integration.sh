#!/bin/bash
# Plugin integration for IT Arsenal
# This file integrates plugins with the main arsenal command center
# GitHub: https://github.com/sundanc/auto_scripts

# Import common functions and plugin manager
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}
source "$SCRIPT_DIR/plugin_manager.sh" || {
    echo "Error: Could not source plugin manager"
    exit 1
}

# Function to initialize plugins
arsenal_init_plugins() {
    # Create plugin directories
    arsenal_plugin_init
    return $?
}

# Function to incorporate plugin menu items into arsenal menus
arsenal_display_plugin_menu() {
    local category="$1"
    local menu_items=$(arsenal_plugin_get_menu_items "$category")
    
    if [[ -n "$menu_items" ]]; then
        echo -e ""
        echo -e "${BOLD}PLUGINS:${NC}"
        
        local idx=20  # Start plugin indexes at 20 to avoid conflict with core functions
        IFS=' ' read -ra ITEMS <<< "$menu_items"
        for item in "${ITEMS[@]}"; do
            IFS=':' read -r plugin_id menu_title <<< "$item"
            echo -e "  ${GREEN}${idx}.${NC} ${menu_title} (Plugin)"
            PLUGIN_MENU_MAP[$idx]="$plugin_id"
            ((idx++))
        done
    fi
}

# Function to handle plugin menu selections
arsenal_handle_plugin_selection() {
    local category="$1"
    local choice="$2"
    
    # Check if this is a plugin menu item (we use 20+ for plugins)
    if [[ $choice -ge 20 && -n "${PLUGIN_MENU_MAP[$choice]}" ]]; then
        local plugin_id="${PLUGIN_MENU_MAP[$choice]}"
        
        # Execute the plugin
        arsenal_plugin_execute "$plugin_id"
        
        read -p "Press Enter to continue..."
        return 0
    fi
    
    return 1  # Not a plugin selection
}

# Function to display plugin management menu
arsenal_manage_plugins() {
    while true; do
        # Clear plugin menu mapping
        declare -A PLUGIN_MENU_MAP
        
        display_header
        echo -e "${BOLD}PLUGIN MANAGEMENT:${NC}"
        echo -e "  ${GREEN}1.${NC} List Installed Plugins"
        echo -e "  ${GREEN}2.${NC} Install Plugin"
        echo -e "  ${GREEN}3.${NC} Remove Plugin"
        echo -e "  ${GREEN}4.${NC} Update Plugins"
        echo -e "  ${GREEN}5.${NC} Configure Plugin"
        echo -e "  ${GREEN}6.${NC} Reload Plugins"
        echo -e "  ${GREEN}0.${NC} Back to Main Menu"
        echo -e ""
        echo -e "${BLUE}------------------------------------------------------------${NC}"
        echo -ne "Enter your choice [0-6]: "
        
        read choice
        case $choice in
            1) 
                arsenal_list_plugins
                ;;
            2)
                arsenal_install_plugin
                ;;
            3)
                arsenal_remove_plugin
                ;;
            4)
                arsenal_update_plugins
                ;;
            5)
                arsenal_configure_plugin
                ;;
            6)
                arsenal_plugin_init
                echo -e "${GREEN}Plugins reloaded.${NC}"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to list installed plugins
arsenal_list_plugins() {
    display_header
    echo -e "${BOLD}INSTALLED PLUGINS:${NC}"
    
    local found_plugins=false
    
    for category in "${PLUGIN_CATEGORIES[@]}"; do
        local category_plugins=0
        
        echo -e "\n${YELLOW}${category^} Plugins:${NC}"
        
        for plugin_name in "${!LOADED_PLUGINS[@]}"; do
            if [[ "$plugin_name" == ${category}_* ]]; then
                local plugin_id=${plugin_name#${category}_}
                local plugin_file="${LOADED_PLUGINS[$plugin_name]}"
                local plugin_dir=$(dirname "$plugin_file")
                local metadata_file="${plugin_dir}/${plugin_id}.json"
                
                # Get plugin information
                local plugin_title=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
                local plugin_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
                local plugin_author=$(grep -o '"author"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
                
                echo -e "  ${CYAN}$plugin_title v$plugin_version${NC} by $plugin_author"
                found_plugins=true
                ((category_plugins++))
            fi
        done
        
        if [[ $category_plugins -eq 0 ]]; then
            echo -e "  ${YELLOW}No plugins installed${NC}"
        fi
    done
    
    if [[ "$found_plugins" == "false" ]]; then
        echo -e "\n${YELLOW}No plugins are currently installed.${NC}"
        echo -e "You can install plugins by placing them in the appropriate subdirectory under:"
        echo -e "${CYAN}$PLUGINS_ROOT${NC}\n"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to install a plugin
arsenal_install_plugin() {
    display_header
    echo -e "${BOLD}INSTALL PLUGIN:${NC}"
    
    echo -e "${YELLOW}Plugin installation options:${NC}"
    echo -e "  1. Install from local file"
    echo -e "  2. Install from URL"
    echo -e "  0. Cancel"
    echo -e ""
    echo -ne "Select an option [0-2]: "
    
    read install_option
    case $install_option in
        1)
            echo -ne "\nEnter path to plugin file: "
            read plugin_path
            
            if [[ ! -f "$plugin_path" ]]; then
                echo -e "${RED}Error: File not found: $plugin_path${NC}"
                read -p "Press Enter to continue..."
                return
            fi
            
            echo -ne "\nSelect plugin category:\n"
            echo -e "  1. System"
            echo -e "  2. Development"
            echo -e "  3. DevOps"
            echo -e "  4. Database"
            echo -ne "\nCategory [1-4]: "
            
            read category_option
            case $category_option in
                1) category="system" ;;
                2) category="development" ;;
                3) category="devops" ;;
                4) category="database" ;;
                *) 
                    echo -e "${RED}Invalid category.${NC}"
                    read -p "Press Enter to continue..."
                    return
                    ;;
            esac
            
            # Copy plugin to appropriate directory
            plugin_filename=$(basename "$plugin_path")
            target_dir="$PLUGINS_ROOT/$category"
            
            mkdir -p "$target_dir"
            cp "$plugin_path" "$target_dir/"
            chmod +x "$target_dir/$plugin_filename"
            
            echo -e "${GREEN}Plugin installed to: $target_dir/$plugin_filename${NC}"
            echo -e "${YELLOW}Note: You may need to create a JSON metadata file.${NC}"
            ;;
        2)
            echo -e "${YELLOW}Feature not yet implemented.${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to remove a plugin
arsenal_remove_plugin() {
    display_header
    echo -e "${BOLD}REMOVE PLUGIN:${NC}"
    
    # Display numbered list of installed plugins
    local plugin_list=()
    local i=1
    
    echo -e "Installed plugins:\n"
    for plugin_name in "${!LOADED_PLUGINS[@]}"; do
        local plugin_file="${LOADED_PLUGINS[$plugin_name]}"
        local plugin_dir=$(dirname "$plugin_file")
        local plugin_id=${plugin_name#*_}
        local metadata_file="${plugin_dir}/${plugin_id}.json"
        
        # Get plugin information
        local plugin_title=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
        local plugin_category=${plugin_name%%_*}
        
        echo -e "  ${GREEN}$i.${NC} $plugin_title (${plugin_category^})"
        plugin_list[$i]=$plugin_name
        ((i++))
    done
    
    if [[ $i -eq 1 ]]; then
        echo -e "${YELLOW}No plugins are currently installed.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "  ${GREEN}0.${NC} Cancel"
    echo -e ""
    echo -ne "Select plugin to remove [0-$((i-1))]: "
    
    read plugin_choice
    if [[ "$plugin_choice" == "0" ]]; then
        return
    fi
    
    if [[ "$plugin_choice" =~ ^[0-9]+$ && $plugin_choice -ge 1 && $plugin_choice -lt $i ]]; then
        local selected_plugin=${plugin_list[$plugin_choice]}
        local plugin_file="${LOADED_PLUGINS[$selected_plugin]}"
        local plugin_dir=$(dirname "$plugin_file")
        local plugin_id=${selected_plugin#*_}
        local script_file="${plugin_dir}/${plugin_id}.sh"
        local metadata_file="${plugin_dir}/${plugin_id}.json"
        
        echo -e "\n${YELLOW}Removing plugin: ${plugin_id}${NC}"
        
        if confirm "Are you sure you want to remove this plugin?" "n"; then
            rm -f "$script_file" "$metadata_file"
            echo -e "${GREEN}Plugin removed.${NC}"
            
            # Remove from loaded plugins
            unset LOADED_PLUGINS[$selected_plugin]
            unset PLUGIN_MENU_ITEMS[$selected_plugin]
            unset PLUGIN_MAIN_FUNCTIONS[$selected_plugin]
        else
            echo -e "${YELLOW}Plugin removal cancelled.${NC}"
        fi
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to update plugins
arsenal_update_plugins() {
    display_header
    echo -e "${BOLD}UPDATE PLUGINS:${NC}"
    
    echo -e "${YELLOW}This feature is not yet implemented.${NC}"
    read -p "Press Enter to continue..."
}

# Function to configure plugins
arsenal_configure_plugin() {
    display_header
    echo -e "${BOLD}CONFIGURE PLUGIN:${NC}"
    
    # Display numbered list of installed plugins
    local plugin_list=()
    local i=1
    
    echo -e "Installed plugins:\n"
    for plugin_name in "${!LOADED_PLUGINS[@]}"; do
        local plugin_file="${LOADED_PLUGINS[$plugin_name]}"
        local plugin_dir=$(dirname "$plugin_file")
        local plugin_id=${plugin_name#*_}
        local metadata_file="${plugin_dir}/${plugin_id}.json"
        
        # Get plugin information
        local plugin_title=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
        local plugin_category=${plugin_name%%_*}
        
        echo -e "  ${GREEN}$i.${NC} $plugin_title (${plugin_category^})"
        plugin_list[$i]=$plugin_id
        ((i++))
    done
    
    if [[ $i -eq 1 ]]; then
        echo -e "${YELLOW}No plugins are currently installed.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "  ${GREEN}0.${NC} Cancel"
    echo -e ""
    echo -ne "Select plugin to configure [0-$((i-1))]: "
    
    read plugin_choice
    if [[ "$plugin_choice" == "0" ]]; then
        return
    fi
    
    if [[ "$plugin_choice" =~ ^[0-9]+$ && $plugin_choice -ge 1 && $plugin_choice -lt $i ]]; then
        local selected_plugin=${plugin_list[$plugin_choice]}
        
        # Check if plugin has config
        local config_file="$PLUGIN_CONFIG_DIR/${selected_plugin}.conf"
        
        if [[ ! -f "$config_file" ]]; then
            echo -e "${YELLOW}This plugin has no configuration yet.${NC}"
            echo -e "Creating empty configuration file."
            arsenal_plugin_set_config "$selected_plugin" "enabled" "true"
        fi
        
        # Edit configuration
        if command -v nano &>/dev/null; then
            nano "$config_file"
        elif command -v vi &>/dev/null; then
            vi "$config_file"
        else
            echo -e "${RED}No text editor found (nano or vi).${NC}"
        fi
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}
