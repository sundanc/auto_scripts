#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Monitor system health with adaptive thresholds based on historical data

HISTORY_DIR="/var/log/system-metrics"
ALERT_RECIPIENT="admin@example.com"
THRESHOLD_MULTIPLIER=1.5

mkdir -p "$HISTORY_DIR"

# Check if required tools are installed
if ! command -v top &> /dev/null || ! command -v free &> /dev/null || ! command -v df &> /dev/null; then
    echo -e "${RED}Error: Required tools (top, free, df) are not installed.${NC}"
    exit 1
fi

# Get current metrics
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
LOAD_AVG=$(uptime | awk -F'[a-z]:' '{ print $2}' | awk '{print $2}' | tr -d ',')

# Calculate dynamic thresholds based on historical averages
if [[ -f "${HISTORY_DIR}/cpu.log" ]]; then
    CPU_AVG=$(awk '{ total += $1; count++ } END { print total/count }' "${HISTORY_DIR}/cpu.log")
    CPU_THRESHOLD=$(echo "$CPU_AVG * $THRESHOLD_MULTIPLIER" | bc)
else
    CPU_THRESHOLD=80
fi

# Save current metrics for future threshold calculations
echo "$CPU_USAGE" >> "${HISTORY_DIR}/cpu.log"
echo "$MEM_USAGE" >> "${HISTORY_DIR}/mem.log"
echo "$DISK_USAGE" >> "${HISTORY_DIR}/disk.log"
echo "$LOAD_AVG" >> "${HISTORY_DIR}/load.log"

# Limit history file size
tail -1000 "${HISTORY_DIR}/cpu.log" > "${HISTORY_DIR}/cpu.log.tmp" && mv "${HISTORY_DIR}/cpu.log.tmp" "${HISTORY_DIR}/cpu.log"

# Alert if thresholds exceeded
if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
    echo "ALERT: CPU usage ($CPU_USAGE%) exceeds dynamic threshold of $CPU_THRESHOLD%" | 
    mail -s "System Alert: High CPU Usage" "$ALERT_RECIPIENT"
fi

# Display system health report with trend analysis
echo "=== System Health Report ==="
echo "CPU Usage: $CPU_USAGE% (Threshold: $CPU_THRESHOLD%)"
echo "Memory Usage: $MEM_USAGE%"
echo "Disk Usage: $DISK_USAGE%"
echo "Load Average: $LOAD_AVG"
echo "=========================="