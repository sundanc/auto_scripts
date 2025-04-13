# VM Detection Script

## Summary
Detects whether the current system is running in a virtual environment by checking multiple virtualization indicators.

## Location
`/system/vm.sh`

## Purpose
This script performs comprehensive checks to determine if a system is running in a virtualized environment. It uses multiple detection methods to provide reliable results, including:

- Hypervisor-specific files and directories
- Virtualized hardware signatures via DMI information
- Network adapter configuration
- Virtualization driver presence
- Container-specific cgroup settings
- Virtual block devices and device files
- System virtualization detection tools

## Usage

```bash
./vm.sh [-o output_file] [-h]
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-o <file>` | Save results to the specified output file |
| `-h` | Display help information |

## Examples

Basic usage:

```bash
./vm.sh
```

Save results to a file:

```bash
./vm.sh -o vm_detection_results.txt
```

## Dependencies

- `dmidecode` - For hardware detection
- `ip` - For network interface checking
- `lsmod` - For kernel module detection
- `lsblk` - For block device information
- `systemd-detect-virt` - For systemd virtualization detection

## Notes

- Some checks require root privileges for complete results
- Certain checks may produce false positives or negatives in unusual configurations
- This script checks for various virtualization technologies including:
  - VMware
  - VirtualBox
  - QEMU/KVM
  - Xen
  - Hyper-V
  - Docker/LXC containers
  - Cloud virtualization (AWS, Azure, GCP)

## Related
- [System Benchmark Script](system_benchmark.md)
- [Hardware Inventory Script](hardware_inventory.md)
