#!/bin/bash
# IT Arsenal Plugin: System Metrics
# Description: Collects and displays detailed system metrics
# Version: 1.0
# Author: Arsenal Team

# Import common functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ARSENAL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ARSENAL_ROOT/lib/common.sh" || exit 1

# Plugin specific variables
METRICS_LOG_DIR="${LOGS_DIR}/metrics"
DEFAULT_REFRESH_INTERVAL=3  # seconds
DEFAULT_METRICS_TO_SHOW="cpu,memory,disk,network,processes"

# Create metrics log directory
mkdir -p "$METRICS_LOG_DIR"

# Function to show system metrics
show_system_metrics() {
    local refresh_interval=$(arsenal_plugin_get_config "system_metrics" "refresh_interval" "$DEFAULT_REFRESH_INTERVAL")
    local metrics_to_show=$(arsenal_plugin_get_config "system_metrics" "metrics_to_show" "$DEFAULT_METRICS_TO_SHOW")
    
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}${BOLD}        SYSTEM METRICS MONITOR${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Press ${BOLD}Ctrl+C${NC} to exit"
    echo ""
    
    # Main metrics loop
    trap 'echo -e "\n${GREEN}Metrics monitoring stopped.${NC}"; return 0' INT
    
    while true; do
        # Get current timestamp
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        # Display header with timestamp
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${YELLOW}${BOLD}        SYSTEM METRICS MONITOR${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo -e "Timestamp: $timestamp | Refresh: ${refresh_interval}s"
        echo -e "Press ${BOLD}Ctrl+C${NC} to exit"
        echo ""
        
        # CPU metrics
        if [[ "$metrics_to_show" == *"cpu"* ]]; then
            echo -e "${BOLD}CPU USAGE:${NC}"
            cpu_usage=$(arsenal_get_cpu_usage)
            echo -e "  Total CPU: ${cpu_usage}%"
            echo -e "  Load Average: $(arsenal_get_load_avg 1) (1m), $(arsenal_get_load_avg 5) (5m), $(arsenal_get_load_avg 15) (15m)"
            
            # CPU frequency if available
            if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
                cpu_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
                cpu_freq_mhz=$(echo "scale=2; $cpu_freq / 1000" | bc)
                echo -e "  CPU Frequency: ${cpu_freq_mhz} MHz"
            fi
            echo ""
        fi
        
        # Memory metrics
        if [[ "$metrics_to_show" == *"memory"* ]]; then
            echo -e "${BOLD}MEMORY USAGE:${NC}"
            mem_info=$(free -m)
            mem_total=$(echo "$mem_info" | grep "Mem:" | awk '{print $2}')
            mem_used=$(echo "$mem_info" | grep "Mem:" | awk '{print $3}')
            mem_free=$(echo "$mem_info" | grep "Mem:" | awk '{print $4}')
            mem_shared=$(echo "$mem_info" | grep "Mem:" | awk '{print $5}')
            mem_cache=$(echo "$mem_info" | grep "Mem:" | awk '{print $6}')
            mem_avail=$(echo "$mem_info" | grep "Mem:" | awk '{print $7}')
            
            mem_usage_pct=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
            
            echo -e "  Physical Memory: ${mem_used}MB/${mem_total}MB (${mem_usage_pct}%)"
            echo -e "  Free: ${mem_free}MB | Cached: ${mem_cache}MB | Available: ${mem_avail}MB"
            
            # Swap information
            swap_total=$(echo "$mem_info" | grep "Swap:" | awk '{print $2}')
            swap_used=$(echo "$mem_info" | grep "Swap:" | awk '{print $3}')
            
            if [[ $swap_total -gt 0 ]]; then
                swap_pct=$(echo "scale=2; $swap_used * 100 / $swap_total" | bc)
                echo -e "  Swap: ${swap_used}MB/${swap_total}MB (${swap_pct}%)"
            else
                echo -e "  Swap: Not configured"
            fi
            echo ""
        fi
        
        # Disk metrics
        if [[ "$metrics_to_show" == *"disk"* ]]; then
            echo -e "${BOLD}DISK USAGE:${NC}"
            # Get mounted filesystems (exclude special filesystems)
            df -h | grep -v "tmpfs\|devtmpfs\|udev\|cdrom" | head -1
            df -h | grep -v "tmpfs\|devtmpfs\|udev\|cdrom" | grep -v "Filesystem" | sort -rn -k 5 | sed 's/^/  /'
            
            # Disk I/O if iostat is available
            if command -v iostat >/dev/null 2>&1; then
                echo ""
                echo -e "${BOLD}DISK I/O:${NC}"
                iostat -d -x 1 1 | grep -v "Linux" | grep -v "^$" | head -n 10 | sed 's/^/  /'
            fi
            echo ""
        fi
        
        # Network metrics
        if [[ "$metrics_to_show" == *"network"* ]]; then
            echo -e "${BOLD}NETWORK INTERFACES:${NC}"
            for iface in $(ls /sys/class/net/ | grep -v "lo"); do
                if [[ -f "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
                    rx_bytes=$(cat /sys/class/net/$iface/statistics/rx_bytes)
                    tx_bytes=$(cat /sys/class/net/$iface/statistics/tx_bytes)
                    
                    # Convert to human-readable format
                    rx_human=$(arsenal_format_bytes "$rx_bytes")
                    tx_human=$(arsenal_format_bytes "$tx_bytes")
                    
                    # Get IP address
                    ip_addr=$(ip -4 addr show $iface 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
                    if [[ -z "$ip_addr" ]]; then
                        ip_addr="No IP"
                    fi
                    
                    echo -e "  $iface ($ip_addr): RX: $rx_human, TX: $tx_human"
                fi
            done
            echo ""
        fi
        
        # Process information
        if [[ "$metrics_to_show" == *"processes"* ]]; then
            echo -e "${BOLD}TOP PROCESSES (CPU):${NC}"
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6 | sed 's/^/  /'
            echo ""
            
            echo -e "${BOLD}TOP PROCESSES (MEMORY):${NC}"
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6 | sed 's/^/  /'
            echo ""
        fi
        
        # Log metrics to file if enabled
        if [[ "$(arsenal_plugin_get_config "system_metrics" "log_metrics" "no")" == "yes" ]]; then
            local log_file="$METRICS_LOG_DIR/system_metrics_$(date +%Y%m%d).log"
            echo "[$timestamp] CPU=${cpu_usage}% MEM=${mem_usage_pct}% LOAD=$(arsenal_get_load_avg 5)" >> "$log_file"
        fi
        
        # Wait for the specified refresh interval
        sleep "$refresh_interval"
    done
}

# Configure system metrics
configure_system_metrics() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}${BOLD}    SYSTEM METRICS CONFIGURATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Get current configuration
    local current_interval=$(arsenal_plugin_get_config "system_metrics" "refresh_interval" "$DEFAULT_REFRESH_INTERVAL")
    local current_metrics=$(arsenal_plugin_get_config "system_metrics" "metrics_to_show" "$DEFAULT_METRICS_TO_SHOW")
    local current_logging=$(arsenal_plugin_get_config "system_metrics" "log_metrics" "no")
    
    echo -e "Current configuration:"
    echo -e "  Refresh interval: ${CYAN}${current_interval}${NC} seconds"
    echo -e "  Metrics to show: ${CYAN}${current_metrics}${NC}"
    echo -e "  Log metrics: ${CYAN}${current_logging}${NC}"
    echo ""
    
    # Update configuration
    echo -ne "Enter refresh interval [${current_interval}s]: "
    read new_interval
    new_interval=${new_interval:-$current_interval}
    
    echo -ne "Metrics to show (comma-separated: cpu,memory,disk,network,processes) [${current_metrics}]: "
    read new_metrics
    new_metrics=${new_metrics:-$current_metrics}
    
    echo -ne "Log metrics to file? (yes/no) [${current_logging}]: "
    read new_logging
    new_logging=${new_logging:-$current_logging}
    
    # Save configuration
    arsenal_plugin_set_config "system_metrics" "refresh_interval" "$new_interval"
    arsenal_plugin_set_config "system_metrics" "metrics_to_show" "$new_metrics"
    arsenal_plugin_set_config "system_metrics" "log_metrics" "$new_logging"
    
    echo ""
    echo -e "${GREEN}Configuration saved.${NC}"
    read -p "Press Enter to continue..."
}

# Main plugin menu
system_metrics_menu() {
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${YELLOW}${BOLD}        SYSTEM METRICS PLUGIN${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1${NC}. Show System Metrics"
        echo -e "${GREEN}2${NC}. Configure Metrics Display"
        echo -e "${GREEN}3${NC}. View Metrics Logs"
        echo -e "${GREEN}0${NC}. Back to Main Menu"
        echo ""
        echo -ne "Select an option [0-3]: "
        
        read choice
        case $choice in
            1) show_system_metrics ;;
            2) configure_system_metrics ;;
            3) 
                if command -v less >/dev/null 2>&1; then
                    less "$METRICS_LOG_DIR/system_metrics_$(date +%Y%m%d).log" 2>/dev/null || 
                        echo -e "${RED}No metrics logs found for today.${NC}"; read -p "Press Enter to continue..."
                else
                    cat "$METRICS_LOG_DIR/system_metrics_$(date +%Y%m%d).log" 2>/dev/null || 
                        echo -e "${RED}No metrics logs found for today.${NC}"; read -p "Press Enter to continue..."
                fi
                ;;
            0) return 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; read -p "Press Enter to continue..." ;;
        esac
    done
}

# Main function that will be called by the arsenal
system_metrics_main() {
    system_metrics_menu
}
