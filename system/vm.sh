#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Enhanced VM detection

# Define colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for required tools
check_dependencies() {
  local missing_tools=()
  
  for tool in dmidecode ip lsmod systemd-detect-virt lsblk; do
    if ! command -v $tool &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Warning: Some tools are missing: ${missing_tools[*]}${NC}"
    echo -e "${YELLOW}Some VM detection methods will be skipped${NC}"
    echo -e "${YELLOW}On Debian/Ubuntu, install with: sudo apt install ${missing_tools[*]}${NC}"
  fi
}

# Initialize variables
VM_INDICATORS=0
TOTAL_CHECKS=0
OUTPUT_FILE=""

# Process command line arguments
while getopts "ho:" opt; do
  case $opt in
    o) OUTPUT_FILE="$OPTARG" ;;
    h) 
      echo "Usage: $0 [-o output_file]"
      echo "  -o: Output file (optional)"
      echo "  -h: Show this help"
      exit 0
      ;;
    *) 
      echo "Usage: $0 [-o output_file]"
      exit 1
      ;;
  esac
done

# Function to log findings
log_finding() {
  local message="$1"
  ((TOTAL_CHECKS++))
  
  echo -e "${BLUE}[CHECK]${NC} $message"
  [[ -n "$OUTPUT_FILE" ]] && echo "[CHECK] $message" >> "$OUTPUT_FILE"
  
  if [[ "$2" == "found" ]]; then
    ((VM_INDICATORS++))
    echo -e "${RED}[FOUND]${NC} $message"
    [[ -n "$OUTPUT_FILE" ]] && echo "[FOUND] $message" >> "$OUTPUT_FILE"
  fi
}

# Run dependency check
check_dependencies

echo -e "${BLUE}Running VM detection checks...${NC}"
[[ -n "$OUTPUT_FILE" ]] && echo "VM Detection Results - $(date)" > "$OUTPUT_FILE"

# 1. Check for hypervisor specific files/directories
if [ -d "/proc/vz" ] || [ -f "/proc/xen" ] || [ -f "/proc/lxc" ] || [ -f "/proc/self/cgroup" ]; then
  log_finding "Hypervisor related files/directories found. Likely a VM/container." "found"
else
  log_finding "No hypervisor files/directories detected."
fi

# 2. Check for common virtualized hardware signatures
if command -v dmidecode &> /dev/null; then
  if dmidecode -s system-product-name | grep -qi "virtualbox\|vmware\|qemu\|hyper-v"; then
    log_finding "DMI system product name suggests a VM." "found"
  else
    log_finding "DMI system product name shows no virtualization indicators."
  fi

  if dmidecode -s system-manufacturer | grep -qi "virtualbox\|vmware\|qemu\|microsoft"; then
    log_finding "DMI system manufacturer suggests a VM." "found"
  else
    log_finding "DMI system manufacturer shows no virtualization indicators."
  fi
else
  log_finding "dmidecode not available, skipping hardware signature checks."
fi

# 3. Enhanced network adapter checks (including less common types)
if ip link show | grep -Eq "virbr|vnet|eth.*host|enp.*virtio|tun[0-9]+|tap[0-9]+|docker[0-9]+|lxcbr[0-9]+|wlp.*vm.*"; then
  log_finding "Virtual network adapters found." "found"
else
  log_finding "No virtual network adapters detected."
fi

# 4. Check for virtio driver presence (more robust than just interface names)
if lsmod | grep -q virtio; then
  log_finding "Virtio drivers loaded. Likely a VM." "found"
else
  log_finding "No virtio drivers detected."
fi

# 5. Check for container specific cgroup settings (more robust than /proc/lxc alone)
if [[ $(cat /proc/1/cgroup) =~ "docker" || $(cat /proc/1/cgroup) =~ "lxc" ]]; then
  log_finding "Container cgroup settings detected." "found"
else
  log_finding "No container cgroup settings detected."
fi

# 6. Check for specific files that virtual machines and containers often create.
if [ -f "/.dockerenv" ] || [ -f "/.containerenv" ]; then
  log_finding "Docker/container environment files found." "found"
else
  log_finding "No Docker/container environment files detected."
fi

# 7. Check for specific kernel parameters that are common in virtualized environments
if [[ $(cat /proc/cmdline) =~ "hypervisor" ]]; then
  log_finding "Hypervisor kernel parameter found." "found"
else
  log_finding "No hypervisor kernel parameters detected."
fi

# 8. Check for specific block devices that are common in virtual environments.
if lsblk | grep -Eq "vd[a-z][0-9]*|xvda[0-9]*|sda[0-9]*.*(VMware|VirtualBox)"; then
  log_finding "Virtual block devices found." "found"
else
  log_finding "No virtual block devices detected."
fi

# 9. Check for specific files in /dev/ that VMs often use.
if [ -c "/dev/vga" ] || [ -c "/dev/kvm" ]; then
  log_finding "Virtualized device files found." "found"
else
  log_finding "No virtualized device files detected."
fi

# 10. Check for systemd-detect-virt output
if systemd-detect-virt -q; then
  log_finding "systemd-detect-virt indicates virtualization" "found"
else
  log_finding "systemd-detect-virt shows no virtualization."
fi

# Summary
echo -e "\n${BLUE}===== VM Detection Summary =====${NC}"
echo -e "Total checks performed: $TOTAL_CHECKS"
echo -e "VM indicators found: $VM_INDICATORS"

if [ $VM_INDICATORS -gt 0 ]; then
  echo -e "${RED}Conclusion: This system is likely a virtual machine or container.${NC}"
  [[ -n "$OUTPUT_FILE" ]] && echo "Conclusion: This system is likely a virtual machine or container." >> "$OUTPUT_FILE"
else
  echo -e "${GREEN}Conclusion: No virtualization indicators found. System appears to be physical hardware.${NC}"
  [[ -n "$OUTPUT_FILE" ]] && echo "Conclusion: No virtualization indicators found. System appears to be physical hardware." >> "$OUTPUT_FILE"
fi

[[ -n "$OUTPUT_FILE" ]] && echo -e "${GREEN}Results saved to: $OUTPUT_FILE${NC}"
