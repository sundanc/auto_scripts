# IT Arsenal Script Templates

This directory contains templates for creating new scripts that are compatible with the IT Arsenal framework.

## Available Templates

- **system_script.sh** - Template for system administration scripts
- **development_script.sh** - Template for development workflow scripts
- **devops_script.sh** - Template for DevOps and deployment scripts
- **database_script.sh** - Template for database management scripts
- **plugin_script.sh** - Template for creating plugins

## Usage

1. Copy the appropriate template to your working directory:
   ```bash
   cp templates/system_script.sh system/my_new_script.sh
   ```

2. Edit the script to implement your functionality:
   ```bash
   nano system/my_new_script.sh
   ```

3. Make the script executable:
   ```bash
   chmod +x system/my_new_script.sh
   ```

4. Create documentation for your script:
   ```bash
   cp templates/script_doc_template.md docs/system/my_new_script.md
   nano docs/system/my_new_script.md
   ```

## Template Structure

Each template includes:

- Standard header with metadata
- License and attribution
- Common library imports
- Argument parsing
- Help function
- Logging setup
- Main function structure
- Error handling
- Exit handling

## Guidelines for Script Creation

1. **Follow the template structure** to maintain consistency
2. **Use the common library functions** from `lib/common.sh`
3. **Implement proper error handling** with meaningful exit codes
4. **Include clear help text** that explains usage and parameters
5. **Log important operations** using the logging functions
6. **Add appropriate documentation** in the docs directory
7. **Consider dependencies carefully** and check for their existence
