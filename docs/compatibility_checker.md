# IT Arsenal Compatibility Checker

## Overview

The Compatibility Checker is a powerful tool that validates whether your system meets the requirements to run IT Arsenal scripts. It helps prevent errors before they occur by proactively checking dependencies, OS compatibility, and permissions.

## Features

The Compatibility Checker provides:

- **Dependency Verification**: Ensures all required tools and utilities are installed
- **OS Compatibility**: Verifies the script works with your operating system
- **User Privileges**: Checks if you have the necessary permissions (root/non-root)
- **Version Validation**: Verifies minimum version requirements for critical tools
- **Installation Guidance**: Provides OS-specific installation commands

## Using the Compatibility Checker

### From the Arsenal Menu

1. Launch the arsenal: `./arsenal.sh`
2. Select option `9` for "Check System Compatibility"
3. Review the compatibility report

### Direct Usage

Check a specific script:
```bash
./lib/compatibility_checker.sh system/security_audit.sh
```

Check multiple scripts:
```bash
./lib/compatibility_checker.sh system/vm.sh devops/deploy.sh
```

Check all scripts in a directory:
```bash
./lib/compatibility_checker.sh $(find system -name "*.sh")
```

### During Script Execution

The arsenal automatically runs a compatibility check before executing any script. If issues are found:

1. You'll see a warning about potential compatibility issues
2. The specific issues will be displayed
3. You'll be given the option to:
   - Continue anyway (at your own risk)
   - Cancel execution to address the issues

### Debug Mode

For in-depth analysis, use the dedicated debugging script:

```bash
./system/script_debug.sh -s path/to/script.sh
```

## Understanding Results

The compatibility report uses color-coded indicators:

- **Green** ✓: Compatible with your system
- **Yellow** ⚠️: Compatibility issues that might affect functionality
- **Red** ✗: Critical issues that will prevent the script from functioning

For each incompatible script, you'll see:
- The specific issues found
- Installation commands for missing dependencies (tailored to your OS)
- User privilege requirements
- OS compatibility information

## Extending Compatibility Data

The compatibility database is located in `lib/compatibility_checker.sh`. To add compatibility information for a new or custom script, update the `init_dependency_database()` function:

```bash
SCRIPT_DEPENDENCIES["your_script.sh"]="tool1 tool2 tool3"
SCRIPT_OS_REQUIREMENTS["your_script.sh"]="linux"
SCRIPT_USER_REQUIREMENTS["your_script.sh"]="root"
```

## Benefits

- **Prevents Frustration**: Identifies issues before they cause script failures
- **Saves Time**: Provides exact commands to resolve dependencies
- **Improves Security**: Alerts you when scripts require elevated privileges
- **Enhances Learning**: Helps understand what each script requires to function
- **Promotes Compatibility**: Guides users on making scripts work across different environments
