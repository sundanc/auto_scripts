# Compatibility Checker

## Summary
Verifies if your system meets the requirements to run IT Arsenal scripts, including dependency checking, OS compatibility, and user privilege validation.

## Location
`/lib/compatibility_checker.sh`

## Purpose
The Compatibility Checker is designed to prevent issues before they occur by proactively checking if your system environment meets the requirements for running specific scripts. This helps users identify and resolve potential problems before attempting to execute scripts, resulting in fewer errors and a smoother user experience.

The tool checks for:
- Required command-line tools and dependencies
- Operating system compatibility
- User privileges (root vs non-root requirements)
- Version compatibility for critical dependencies
- Provides tailored installation recommendations

## Usage

### From Arsenal Menu
```bash
# Select option 9 from the main menu
./arsenal.sh
# Choose "Check System Compatibility"
```

### Direct Command Line
```bash
# Check compatibility of a specific script
./lib/compatibility_checker.sh system/security_audit.sh

# Check compatibility of multiple scripts
./lib/compatibility_checker.sh system/vm.sh system/connectivity_check.sh

# Check compatibility of all scripts in a directory
./lib/compatibility_checker.sh $(find system -name "*.sh")
```

### Script Debugging Tool
```bash
# Detailed debugging of a specific script
./system/script_debug.sh -s system/security_audit.sh

# Check all scripts in a category
./system/script_debug.sh -c system
```

## Parameters

| Function | Description |
|----------|-------------|
| `check_script_compatibility script_name [verbose]` | Checks if a script is compatible with the current system |
| `bulk_compatibility_check script1 script2...` | Performs compatibility checks on multiple scripts |
| `debug_script_requirements script_name` | Provides detailed compatibility information for a script |
| `check_system_compatibility directory [detailed]` | Analyzes system compatibility for all scripts in a directory |

## Examples

Check if the security audit script is compatible with your system:
```bash
./lib/compatibility_checker.sh system/security_audit.sh
```

Debug why a script isn't working:
```bash
./system/script_debug.sh -s system/vm.sh
```

Check system-wide compatibility:
```bash
./lib/compatibility_checker.sh $(find . -name "*.sh" | grep -v "/lib/" | grep -v "/tests/")
```

## Output

The compatibility checker provides color-coded output:
- **Green** ✓ - Compatible features/dependencies
- **Yellow** ⚠️ - Missing optional dependencies or minor issues
- **Red** ✗ - Critical missing dependencies or compatibility issues

### Example Output

```
Checking script compatibility...

Compatible scripts (3):
✓ connectivity_check.sh
✓ disk_usage.sh
✓ uptime.sh

Scripts with compatibility issues (2):
⚠️ security_audit.sh
   - Required privileges not met. Script requires: root privileges
   - To resolve: Run script with sudo or as root

⚠️ vm.sh
   - Missing dependencies: dmidecode
   - To install missing dependencies: sudo apt-get install dmidecode
```

## Notes

- The compatibility checker initializes its database on first run
- Custom compatibility checks can be added by updating the `init_dependency_database` function
- Some checks (like root privileges) can be overridden with user confirmation if needed
- The compatibility checker is automatically run before any script execution within the arsenal

## Related
- [Script Debug Tool](script_debug.md)
- [Troubleshooting Common Issues](../tutorials/troubleshooting.md)
