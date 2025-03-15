#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Enhanced VM detection

# 1. Check for hypervisor specific files/directories
if [ -d "/proc/vz" ] || [ -f "/proc/xen" ] || [ -f "/proc/lxc" ] || [ -f "/proc/self/cgroup" ]; then
  echo "Hypervisor related files/directories found. Likely a VM/container."
fi

# 2. Check for common virtualized hardware signatures
if dmidecode -s system-product-name | grep -qi "virtualbox\|vmware\|qemu\|hyper-v"; then
  echo "DMI system product name suggests a VM."
fi

if dmidecode -s system-manufacturer | grep -qi "virtualbox\|vmware\|qemu\|microsoft"; then
    echo "DMI system manufacturer suggests a VM."
fi

# 3. Enhanced network adapter checks (including less common types)
if ip link show | grep -Eq "virbr|vnet|eth.*host|enp.*virtio|tun[0-9]+|tap[0-9]+|docker[0-9]+|lxcbr[0-9]+|wlp.*vm.*"; then
  echo "Virtual network adapters found."
fi

# 4. Check for virtio driver presence (more robust than just interface names)
if lsmod | grep -q virtio; then
  echo "Virtio drivers loaded. Likely a VM."
fi

# 5. Check for container specific cgroup settings (more robust than /proc/lxc alone)
if [[ $(cat /proc/1/cgroup) =~ "docker" || $(cat /proc/1/cgroup) =~ "lxc" ]]; then
    echo "Container cgroup settings detected."
fi

# 6. Check for specific files that virtual machines and containers often create.
if [ -f "/.dockerenv" ] || [ -f "/.containerenv" ]; then
    echo "Docker/container environment files found."
fi

# 7. Check for specific kernel parameters that are common in virtualized environments
if [[ $(cat /proc/cmdline) =~ "hypervisor" ]]; then
    echo "Hypervisor kernel parameter found."
fi

#8 Check for specific block devices that are common in virtual environments.
if lsblk | grep -Eq "vd[a-z][0-9]*|xvda[0-9]*|sda[0-9]*.*(VMware|VirtualBox)"; then
    echo "Virtual block devices found."
fi

#9 Check for specific files in /dev/ that VMs often use.
if [ -c "/dev/vga" ] || [ -c "/dev/kvm" ]; then
    echo "Virtualized device files found."
fi

#10 check for systemd-detect-virt output
if systemd-detect-virt -q; then
    echo "systemd-detect-virt indicates virtualization"
fi
