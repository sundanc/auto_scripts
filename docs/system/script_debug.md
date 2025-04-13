# Script Debug Tool

## Summary
Advanced diagnostic tool that analyzes script issues, including dependency verification, syntax checking, best practices, and compatibility validation.

## Location
`/system/script_debug.sh`

## Purpose
The Script Debug Tool helps users identify and resolve issues with scripts by performing comprehensive analysis and diagnostics. It's particularly useful for:

1. Troubleshooting scripts that aren't working correctly
2. Verifying compatibility before running scripts
3. Checking if scripts follow best practices
4. Identifying potential security issues
5. Detecting and resolving common coding mistakes

## Usage

```bash
./system/script_debug.sh [options] [script_path]
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-a, --all` | Check all scripts in repository |
| `-s, --script PATH` | Debug a specific script |
| `-c, --category CAT` | Check all scripts in category (system, development, devops, database) |
| `-v, --verbose` | Display detailed information |
| `-h, --help` | Display help message |

## Examples

Debug a specific script:

```bash
./system/script_debug.sh -s system/vm.sh
```

Check all scripts in the system category:

```bash
./system/script_debug.sh -c system
```

Perform comprehensive analysis of all scripts:

```bash
./system/script_debug.sh -a
```

## Output

The script debug tool performs several types of checks:

### Script Content Verification
- Checks for proper shebang line
- Verifies common function imports
- Detects hardcoded paths
- Validates error handling

### Syntax Check
- Verifies script syntax without execution
- Identifies potential coding errors

### Compatibility Analysis
- Checks OS compatibility
- Verifies required permissions
- Identifies missing dependencies
- Validates tool versions

### Static Analysis
- Identifies security concerns
- Detects potential performance issues
- Checks for common coding mistakes

## Example Output

```
=== Debugging vm.sh ===

Checking script content:
✓ Shebang line OK
✓ Common functions imported
✓ No syntax errors detected

Checking compatibility:
OS Compatibility: Linux is supported (required: linux)
User privileges OK

Checking dependencies:
✗ Missing dependencies: dmidecode
   Recommendation: sudo apt-get install dmidecode

Static analysis for potential issues:
✓ No hardcoded paths detected
✓ Error handling found
✓ Script uses logging functions

Overall status:
✗ Script may not work correctly on this system
   Please address the issues above before running.
```

## Related
- [Compatibility Checker](compatibility_checker.md)
- [Troubleshooting Guide](../tutorials/troubleshooting.md)
- [Creating Scripts](../tutorials/creating-scripts.md)
