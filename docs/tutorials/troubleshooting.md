# IT Arsenal Troubleshooting Guide

This guide helps you identify and resolve common issues when working with IT Arsenal scripts.

## Table of Contents

1. [Using Diagnostic Tools](#using-diagnostic-tools)
2. [Common Error Messages](#common-error-messages)
3. [Script-Specific Troubleshooting](#script-specific-troubleshooting)
4. [System Compatibility Issues](#system-compatibility-issues)
5. [Advanced Debugging](#advanced-debugging)

## Using Diagnostic Tools

IT Arsenal includes powerful diagnostic and troubleshooting tools to help you resolve issues.

### Compatibility Checker

The compatibility checker verifies if your system meets the requirements to run scripts:

```bash
# From the main menu
./arsenal.sh  # Then select option 9

# Direct compatibility check for a specific script
./lib/compatibility_checker.sh system/security_audit.sh

# Check compatibility of multiple scripts
./lib/compatibility_checker.sh system/vm.sh system/connectivity_check.sh
```

### Script Debug Tool

For in-depth analysis and troubleshooting of scripts:

```bash
# Debug a specific script
./system/script_debug.sh -s system/vm.sh

# Check all scripts in a category
./system/script_debug.sh -c system

# Comprehensive analysis of all scripts
./system/script_debug.sh -a 
```

### Log Analysis

View detailed logs to understand what happened during script execution:

```bash
# From the main menu
./arsenal.sh  # Then select option 6

# Direct log viewing
less logs/arsenal_$(date +%Y%m%d).log
```

## Common Error Messages

### "Command not found"

**Issue**: A required command or tool is missing.

**Solution**:
1. Run the compatibility checker to identify missing dependencies:
   ```bash
   ./lib/compatibility_checker.sh your_script.sh
   ```
2. Install the missing tools using your package manager:
   ```bash
   sudo apt-get install missing-tool  # Debian/Ubuntu
   sudo yum install missing-tool      # CentOS/RHEL
   ```

### "Permission denied"

**Issue**: The script lacks execute permissions or requires elevated privileges.

**Solution**:
1. Make the script executable:
   ```bash
   chmod +x path/to/script.sh
   ```
2. For scripts requiring root:
   ```bash
   sudo ./path/to/script.sh
   ```
3. Check if the script requires root using the compatibility checker:
   ```bash
   ./lib/compatibility_checker.sh your_script.sh
   ```

### "No such file or directory"

**Issue**: A script is trying to access a file or directory that doesn't exist.

**Solution**:
1. Ensure all referenced paths exist
2. Check for typos in file paths
3. Use the script debug tool for detailed analysis:
   ```bash
   ./system/script_debug.sh -s path/to/script.sh
   ```

### "Configuration file not found"

**Issue**: The script cannot find its configuration file.

**Solution**:
1. Ensure the `config` directory exists
2. Create the required configuration file:
   ```bash
   cp config/arsenal.conf.example config/arsenal.conf
   ```
3. Edit the configuration file with appropriate settings

## Script-Specific Troubleshooting

### Security Audit Script

**Issue**: Script shows "Permission denied" errors or skipped checks.

**Solution**: The security audit requires root privileges for complete results:
```bash
sudo ./system/security_audit.sh
```

### Database Backup Script

**Issue**: "Access denied" errors during backup.

**Solution**:
1. Verify database connection parameters
2. Create proper database credentials file:
   ```bash
   cp config/db_credentials.conf.example config/db_credentials.conf
   nano config/db_credentials.conf  # Edit with your credentials
   ```

### VM Detection Script

**Issue**: Missing certain VM indicators.

**Solution**:
1. Install required dependencies:
   ```bash
   sudo apt-get install dmidecode
   ```
2. Run with sudo for more complete detection:
   ```bash
   sudo ./system/vm.sh
   ```

## System Compatibility Issues

### Missing Dependencies

**Issue**: Scripts fail due to missing tools or utilities.

**Solution**:
1. Run the system-wide compatibility check:
   ```bash
   ./arsenal.sh  # Then select option 9
   ```
2. Install missing dependencies using displayed recommendations
3. For bulk installation on Debian/Ubuntu:
   ```bash
   sudo apt-get install $(./lib/compatibility_checker.sh script.sh | grep "Missing dependencies" | cut -d':' -f2)
   ```

### OS Compatibility

**Issue**: Script isn't compatible with your operating system.

**Solution**:
1. Check OS-specific requirements:
   ```bash
   ./lib/compatibility_checker.sh script.sh
   ```
2. Look for alternative scripts for your OS in the repository
3. Modify the script to work with your OS (advanced)

### Version Compatibility

**Issue**: Installed tools don't meet version requirements.

**Solution**:
1. Check detailed version requirements:
   ```bash
   ./system/script_debug.sh -s script.sh
   ```
2. Update tools to required versions
3. Modify version checks in scripts if needed (advanced)

## Advanced Debugging

For the most challenging issues, try these advanced debugging techniques:

### Enable Verbose Output

Many scripts support verbose output with `-v` or `--verbose` flags:
```bash
./script.sh -v
```

### Trace Script Execution

Use bash's built-in tracing:
```bash
bash -x ./script.sh
```

### Check Script Syntax

Validate script syntax without running it:
```bash
bash -n ./script.sh
```

### Analyze Static Code Issues

Use the script debug tool's static analysis:
```bash
./system/script_debug.sh -s script.sh
```

### Manual Dependency Verification

For scripts with complex dependencies:
```bash
for dep in tool1 tool2 tool3; do
  command -v $dep &>/dev/null && echo "$dep: Found" || echo "$dep: Missing"
done
```

### Examine Recent Logs

Look for patterns across multiple script executions:
```bash
grep ERROR logs/arsenal_*.log | sort
```

If you encounter issues not covered in this guide, please report them on our GitHub repository for assistance.
