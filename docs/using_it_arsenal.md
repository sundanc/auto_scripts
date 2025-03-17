# How to Use IT Arsenal: Your One-Stop IT Automation Solution

IT Arsenal is a comprehensive automation toolkit that brings together system administration, development, DevOps, and database management scripts into a unified, easy-to-use interface. This guide will walk you through installing, configuring, and leveraging IT Arsenal to streamline your IT operations.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation and Setup](#installation-and-setup)
3. [Getting Started with Arsenal Command Center](#getting-started-with-arsenal-command-center)
4. [Using System Administration Tools](#using-system-administration-tools)
5. [Using Development Tools](#using-development-tools)
6. [Using DevOps & Deployment Tools](#using-devops--deployment-tools)
7. [Using Database Management Tools](#using-database-management-tools)
8. [Advanced Features](#advanced-features)
9. [Creating Your Own Scripts](#creating-your-own-scripts)
10. [Troubleshooting Common Issues](#troubleshooting-common-issues)
11. [Best Practices](#best-practices)

## Introduction

IT Arsenal is designed to turn scattered automation scripts into a cohesive toolkit, making it easier to perform common IT tasks consistently and efficiently. Whether you're managing servers, developing applications, deploying code, or maintaining databases, IT Arsenal provides the tools you need in one centralized interface.

**Key Benefits:**
- Unified access to dozens of specialized tools
- Consistent logging across all operations
- Centralized configuration management
- Enhanced error handling and notifications
- Easy extensibility for custom requirements

## Installation and Setup

### Prerequisites

- Linux-based operating system (Debian/Ubuntu recommended)
- Bash shell
- Git (for installation and updates)
- Required permissions for the operations you intend to perform

### Installation Steps

1. Clone the IT Arsenal repository:
   ```bash
   git clone https://github.com/sundanc/auto_scripts.git
   cd auto_scripts
   ```

2. Make the main arsenal script executable:
   ```bash
   chmod +x arsenal.sh
   ```

3. Run the setup script (if desired):
   ```bash
   ./arsenal.sh
   ```
   - On first run, IT Arsenal will create a default configuration file.

4. Install additional dependencies (if prompted).

## Getting Started with Arsenal Command Center

The IT Arsenal command center (`arsenal.sh`) is the main interface through which you'll access all tools. To launch it:

```bash
./arsenal.sh
```

### Understanding the Main Menu

The main menu is divided into several categories:

1. **System Administration Tools** - For system monitoring, maintenance, and security
2. **Development Tools** - For streamlining development workflows
3. **DevOps & Deployment Tools** - For integration, testing, and deployment
4. **Database Management Tools** - For database backups and maintenance
5. **Configuration & Settings** - For customizing the Arsenal
6. **View Logs** - For accessing operation logs
7. **Update Arsenal** - For keeping the toolkit up to date
8. **About** - For information about the Arsenal

Navigate through menus by entering the corresponding number and pressing Enter.

## Using System Administration Tools

The System Administration tools are designed to help you monitor, maintain, and secure your systems.

### Security Audit

To run a comprehensive security audit:

1. Select `1` for System Administration Tools
2. Select `1` for Security Audit
3. Review the findings after the scan completes

This tool will check for:
- System updates
- Network security issues
- SSH configuration problems
- Firewall status
- User account security
- Password policies
- File permissions
- Kernel security parameters

### System Health Monitoring

To monitor system health:

1. Select `1` for System Administration Tools
2. Select `3` for System Health Monitor

The system health monitor tracks:
- CPU utilization
- Memory usage
- Disk space
- Load averages
- Adaptive thresholds based on historical data

### Other System Tools

- **VM Detection** - Determine if you're running in a virtualized environment
- **Disk Usage Monitor** - Check for partitions exceeding space thresholds
- **Service Health Check** - Verify critical services are running
- **System Update & Upgrade** - Keep your system up to date

## Using Development Tools

The Development tools streamline common development workflows.

### Git Branch Management

To manage Git branches:

1. Select `2` for Development Tools
2. Select `1` for Git Branch Manager

The Git Branch Manager allows you to:
- Create new branches
- Delete local and remote branches
- Merge branches with conflict handling
- List all branches

### Auto Git

To streamline Git operations:

1. Select `2` for Development Tools
2. Select `2` for Auto Git

Auto Git simplifies add, commit, and push operations into a single workflow with prompts for commit messages and branch selection.

### Python Environment Setup

To create a Python virtual environment:

1. Select `2` for Development Tools
2. Select `3` for Create Python Environment

This tool creates and activates a Python virtual environment for isolated development.

## Using DevOps & Deployment Tools

The DevOps tools help streamline integration, testing, and deployment.

### CI/CD Automation

To access comprehensive CI/CD functions:

1. Select `3` for DevOps & Deployment Tools
2. Select `1` for CI/CD Automation

The CI/CD automation tool provides:
- Branch management (update, integrate, promote)
- Testing suite execution
- Code quality checks
- Deployment to staging and production
- Rollback capabilities

### Deployment Tool

To deploy applications:

1. Select `3` for DevOps & Deployment Tools
2. Select `2` for Deployment Tool

Follow the prompts to specify:
- Git repository URL
- Branch to deploy
- Deployment directory
- Service to restart (optional)

### Backup Tool

To create backups:

1. Select `3` for DevOps & Deployment Tools
2. Select `3` for Backup Tool

The backup tool creates timestamped backups of specified directories.

## Using Database Management Tools

The Database tools help maintain and back up your databases.

### Database Backup

To back up a database:

1. Select `4` for Database Management Tools
2. Select `1` for Database Backup

This tool creates compressed SQL dumps with timestamps.

### Advanced Database Management

To perform comprehensive database maintenance:

1. Select `4` for Database Management Tools
2. Select `2` for Advanced Database Management

The advanced database management tool provides:
- Automated backups with rotation
- Table optimization and analysis
- Connection monitoring
- Database size reporting
- Performance analysis

## Advanced Features

### Configuration Management

To customize your IT Arsenal:

1. Select `5` for Configuration & Settings
2. Select `1` to edit the configuration file

Key settings you can customize:
- Admin email for notifications
- Notification preferences
- Default backup directories
- Monitoring thresholds
- Logging levels

### Logging System

To view operation logs:

1. Select `6` for View Logs
2. Choose a log file to view or other options

The logging system tracks all operations with timestamps and severity levels for easy troubleshooting.

### Integration Between Tools

IT Arsenal's most powerful feature is the ability to combine tools into complex workflows. The `lib/integrations.sh` file provides functions that coordinate multiple scripts for advanced operations:

- `arsenal_secure_and_update` - Run a security audit before updating
- `arsenal_backup_and_maintain_db` - Back up before performing database maintenance
- `arsenal_health_check_and_repair` - Check system health and fix common issues
- `arsenal_setup_dev_environment` - Create a complete development environment
- `arsenal_monitoring_dashboard` - Run a live monitoring dashboard
- `arsenal_deploy_workflow` - Execute a complete deployment workflow

Access these integrations through the IT Arsenal API or by extending the main menu.

## Creating Your Own Scripts

### Structure of an Arsenal-Compatible Script

To create a script that works seamlessly with IT Arsenal:

1. Start with a standard header:
```bash
#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# Description: Brief explanation of what your script does
```

2. Import common library functions:
```bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../lib/common.sh"
```

3. Use Arsenal functions for consistency:
```bash
arsenal_print_header "YOUR SCRIPT TITLE"
arsenal_log "INFO" "Starting script operation" "$(basename "$0")"
```

4. Add your script to the appropriate directory:
   - `/system` for system administration scripts
   - `/development` for development tools
   - `/devops` for CI/CD and deployment scripts
   - `/database` for database management scripts

5. Update the menu in `arsenal.sh` to include your new script.

## Troubleshooting Common Issues

### Script Not Found

**Problem**: Arsenal reports a script is not found.  
**Solution**: Verify the script exists in the expected directory and has execute permissions.
```bash
chmod +x path/to/your/script.sh
```

### Permission Denied

**Problem**: A script fails with permission errors.  
**Solution**: Run the script with appropriate permissions. For scripts requiring root:
```bash
sudo ./arsenal.sh
```

### Configuration Issues

**Problem**: Scripts fail due to configuration errors.  
**Solution**: Check and update `config/arsenal.conf` with correct values.

### Logging Not Working

**Problem**: Logs aren't being created or updated.  
**Solution**: Ensure the `logs` directory exists and is writable.
```bash
mkdir -p logs
chmod 755 logs
```

## Best Practices

1. **Regular Updates**: Keep your IT Arsenal up to date using the built-in update function.

2. **Configuration Management**: Create environment-specific configuration files for different systems.

3. **Script Development**:
   - Add proper error handling to custom scripts
   - Use meaningful success/error exit codes
   - Add comprehensive logging
   - Follow the coding style of existing scripts

4. **Security Awareness**:
   - Review scripts before running them
   - Use the principle of least privilege
   - Be cautious with scripts that require root access

5. **Documentation**:
   - Document any customizations you make
   - Comment your code for future reference
   - Update README files when adding new features

## Conclusion

IT Arsenal transforms scattered automation scripts into a powerful, unified toolkit for IT operations. By bringing together system administration, development, DevOps, and database management tools, it provides a comprehensive solution for common IT challenges. Whether you're maintaining servers, developing applications, or managing deployments, IT Arsenal helps you work more efficiently and consistently.

Start by exploring the various tools available, then gradually integrate them into your daily workflow. As you become more comfortable with the system, you can extend it with custom scripts and advanced integrations to meet your specific needs.

---

For more information, visit the [GitHub repository](https://github.com/sundanc/auto_scripts) or contribute to the project by submitting issues and pull requests.
