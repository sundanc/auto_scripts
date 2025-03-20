#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# System Benchmark Tool - Measure CPU, memory, disk and network performance

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPORT_FILE="$HOME/benchmark_results_$(date +%Y%m%d_%H%M%S).txt"
TEMP_DIR="/tmp/benchmark_$$"
DURATION_SHORT=5  # seconds
DURATION_LONG=10  # seconds
DISK_TEST_SIZE=512  # MB
DISK_TEST_FILE="$TEMP_DIR/test_file"
TEST_LOOPS=3

# Check for required tools
check_required_tools() {
    local missing_tools=()
    
    for tool in dd time bc awk grep find; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        exit 1
    fi
}

# Header function
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
    echo -e "\n=== $1 ===\n" >> "$REPORT_FILE"
}

# Result reporting function
report_result() {
    local test_name="$1"
    local result="$2"
    local unit="$3"
    
    echo -e "${CYAN}$test_name:${NC} $result $unit"
    echo "$test_name: $result $unit" >> "$REPORT_FILE"
}

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Initialize report file
echo "System Benchmark Report" > "$REPORT_FILE"
echo "Generated on: $(date)" >> "$REPORT_FILE"
echo "System: $(hostname)" >> "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"

# Output system information
print_header "SYSTEM INFORMATION"
echo -e "${YELLOW}Gathering system information...${NC}"

# CPU info
cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
cpu_cores=$(grep -c processor /proc/cpuinfo)
echo "CPU: $cpu_model ($cpu_cores cores)" >> "$REPORT_FILE"
echo -e "${CYAN}CPU:${NC} $cpu_model ($cpu_cores cores)"

# Memory info
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2/1024/1024}')
mem_total=$(printf "%.2f" $mem_total)
echo "Memory: ${mem_total}GB" >> "$REPORT_FILE"
echo -e "${CYAN}Memory:${NC} ${mem_total}GB"

# Disk info
disk_info=$(df -h / | tail -1)
disk_size=$(echo "$disk_info" | awk '{print $2}')
disk_used=$(echo "$disk_info" | awk '{print $3}')
disk_avail=$(echo "$disk_info" | awk '{print $4}')
echo "Disk (root): ${disk_size} total, ${disk_used} used, ${disk_avail} available" >> "$REPORT_FILE"
echo -e "${CYAN}Disk (root):${NC} ${disk_size} total, ${disk_used} used, ${disk_avail} available"

# OS info
if [ -f /etc/os-release ]; then
    . /etc/os-release
    os_name="${NAME} ${VERSION}"
else
    os_name=$(uname -a)
fi
echo "OS: $os_name" >> "$REPORT_FILE"
echo -e "${CYAN}OS:${NC} $os_name"

# Check Linux kernel
kernel=$(uname -r)
echo "Kernel: $kernel" >> "$REPORT_FILE"
echo -e "${CYAN}Kernel:${NC} $kernel"

# CPU Benchmark
print_header "CPU BENCHMARK"
echo -e "${YELLOW}Running CPU benchmark...${NC}"

# Function to calculate prime numbers (CPU intensive)
cpu_test() {
    local max=$1
    local count=0
    
    for ((i=2; i<=max; i++)); do
        is_prime=1
        for ((j=2; j*j<=i; j++)); do
            if (( i % j == 0 )); then
                is_prime=0
                break
            fi
        done
        (( is_prime == 1 )) && ((count++))
    done
    
    echo $count
}

# Run CPU test multiple times and average
cpu_times=()
for ((i=1; i<=TEST_LOOPS; i++)); do
    echo -e "${YELLOW}CPU Test $i/$TEST_LOOPS...${NC}"
    start_time=$(date +%s.%N)
    cpu_test 15000 > /dev/null
    end_time=$(date +%s.%N)
    execution_time=$(echo "$end_time - $start_time" | bc)
    cpu_times+=("$execution_time")
    echo -e "${GREEN}Completed in ${execution_time} seconds${NC}"
done

# Calculate average
total_time=0
for time in "${cpu_times[@]}"; do
    total_time=$(echo "$total_time + $time" | bc)
done
avg_time=$(echo "scale=3; $total_time / ${#cpu_times[@]}" | bc)

report_result "Prime calculation time" "$avg_time" "seconds"

# Parallel CPU test using multiple cores
echo -e "${YELLOW}Running parallel CPU test...${NC}"
start_time=$(date +%s.%N)

# Run multiple instances based on core count
for ((i=1; i<=cpu_cores; i++)); do
    cpu_test 10000 > /dev/null &
done
wait

end_time=$(date +%s.%N)
parallel_time=$(echo "$end_time - $start_time" | bc)

report_result "Parallel processing time" "$parallel_time" "seconds"
report_result "Parallel efficiency" "$(echo "scale=2; $avg_time / ($parallel_time / $cpu_cores)" | bc)" "ratio"

# Memory Benchmark
print_header "MEMORY BENCHMARK"
echo -e "${YELLOW}Running memory benchmark...${NC}"

# Memory write test
echo -e "${YELLOW}Testing memory write speed...${NC}"
memory_write_speed=$(dd if=/dev/zero of="$TEMP_DIR/memory_test" bs=1M count=1024 2>&1 | grep copied | awk '{print $(NF-1)}')
report_result "Memory write speed" "$memory_write_speed" "MB/s"

# Memory read test
echo -e "${YELLOW}Testing memory read speed...${NC}"
# Clear caches to ensure accurate read test
sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
memory_read_speed=$(dd if="$TEMP_DIR/memory_test" of=/dev/null bs=1M 2>&1 | grep copied | awk '{print $(NF-1)}')
report_result "Memory read speed" "$memory_read_speed" "MB/s"

# Disk Benchmark
print_header "DISK BENCHMARK"
echo -e "${YELLOW}Running disk benchmark...${NC}"

# Sequential write test
echo -e "${YELLOW}Testing sequential write speed...${NC}"
dd_write=$(dd if=/dev/zero of="$DISK_TEST_FILE" bs=1M count=$DISK_TEST_SIZE 2>&1)
seq_write_speed=$(echo "$dd_write" | grep copied | awk '{print $(NF-1)}')
report_result "Sequential write" "$seq_write_speed" "MB/s"

# Sequential read test
echo -e "${YELLOW}Testing sequential read speed...${NC}"
# Clear caches to ensure accurate read test
sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
dd_read=$(dd if="$DISK_TEST_FILE" of=/dev/null bs=1M 2>&1)
seq_read_speed=$(echo "$dd_read" | grep copied | awk '{print $(NF-1)}')
report_result "Sequential read" "$seq_read_speed" "MB/s"

# Random I/O test using dd
echo -e "${YELLOW}Testing random I/O performance...${NC}"
random_io_start_time=$(date +%s.%N)

for ((i=0; i<100; i++)); do
    # Create a random block size between 512 bytes and 8KB
    bs=$((RANDOM % 16 + 1))
    # Create a random seek position within the file
    seek=$((RANDOM % (DISK_TEST_SIZE * 1024) + 1))
    dd if=/dev/urandom of="$DISK_TEST_FILE" bs=512 count=1 seek=$seek conv=notrunc &>/dev/null
done

random_io_end_time=$(date +%s.%N)
random_io_time=$(echo "$random_io_end_time - $random_io_start_time" | bc)
random_io_iops=$(echo "scale=2; 100 / $random_io_time" | bc)

report_result "Random I/O" "$random_io_iops" "IOPS"

# File system test
echo -e "${YELLOW}Testing file system operations...${NC}"
fs_test_dir="$TEMP_DIR/fs_test"
mkdir -p "$fs_test_dir"

# Create files test
echo -e "${YELLOW}Testing file creation...${NC}"
create_start_time=$(date +%s.%N)

for ((i=0; i<1000; i++)); do
    touch "$fs_test_dir/file_$i"
done

create_end_time=$(date +%s.%N)
create_time=$(echo "$create_end_time - $create_start_time" | bc)
create_rate=$(echo "scale=2; 1000 / $create_time" | bc)

report_result "File creation" "$create_rate" "files/sec"

# Find files test
echo -e "${YELLOW}Testing file operations...${NC}"
find_start_time=$(date +%s.%N)
find "$fs_test_dir" -type f -name "file_*" > /dev/null
find_end_time=$(date +%s.%N)
find_time=$(echo "$find_end_time - $find_start_time" | bc)

report_result "File search" "$find_time" "seconds"

# Delete files test
echo -e "${YELLOW}Testing file deletion...${NC}"
delete_start_time=$(date +%s.%N)
rm -rf "$fs_test_dir"
delete_end_time=$(date +%s.%N)
delete_time=$(echo "$delete_end_time - $delete_start_time" | bc)
delete_rate=$(echo "scale=2; 1000 / $delete_time" | bc)

report_result "File deletion" "$delete_rate" "files/sec"

# Network benchmark (if supported)
print_header "NETWORK BENCHMARK"
echo -e "${YELLOW}Running network benchmark...${NC}"

# Function to check if network benchmarking is possible
check_network_benchmark() {
    if command -v ping &> /dev/null && ping -c 1 google.com &> /dev/null; then
        return 0  # Network available
    else
        return 1  # Network not available
    fi
}

if check_network_benchmark; then
    # Ping test
    echo -e "${YELLOW}Testing network latency...${NC}"
    ping_result=$(ping -c 10 google.com | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
    report_result "Network latency (avg)" "$ping_result" "ms"
    
    # Download speed test
    if command -v curl &> /dev/null; then
        echo -e "${YELLOW}Testing download speed...${NC}"
        # Use a small file from a reliable server
        download_start_time=$(date +%s.%N)
        curl -s -o /dev/null https://speed.hetzner.de/100MB.bin 2>/dev/null &
        curl_pid=$!
        
        # Monitor for a short period then kill
        sleep 5
        kill $curl_pid 2>/dev/null
        
        download_end_time=$(date +%s.%N)
        download_time=$(echo "$download_end_time - $download_start_time" | bc)
        
        # Very approximate but gives some indication
        report_result "Download test" "$download_time" "seconds (lower is better)"
    else
        echo -e "${YELLOW}curl not found, skipping download test${NC}"
        echo "Download test skipped: curl not available" >> "$REPORT_FILE"
    fi
else
    echo -e "${YELLOW}Network not available, skipping network tests${NC}"
    echo "Network tests skipped: No connectivity" >> "$REPORT_FILE"
fi

# Final report
echo -e "\n${GREEN}${BOLD}Benchmarks Complete!${NC}"
echo -e "Detailed report saved to: ${BLUE}$REPORT_FILE${NC}"

# Cleanup
rm -rf $TEMP_DIR
