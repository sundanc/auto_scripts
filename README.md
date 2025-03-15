# Auto-Scripts Collection

A collection of useful automation scripts for system administration, development, and DevOps tasks.

## Directory Structure

- **system/** - Scripts for system administration tasks
- **development/** - Scripts for development workflows and tools
- **devops/** - Scripts for deployment and CI/CD automation
- **database/** - Scripts for database management and maintenance


## Available Scripts

### System Administration

| Script | Description |
|--------|-------------|
| `vm.sh` | Enhanced VM detection script that checks for hypervisors, virtual hardware signatures, network adapters and container environments. |
| `uptime.sh` | Displays system uptime and boot time in a human-readable format. |
| `updateupgrade.sh` | Simple apt package update and upgrade script with colored output. |
| `syshealth.sh` | Advanced system health monitoring with adaptive thresholds based on historical data. Includes CPU, memory, disk usage and load average tracking. |
| `sys_monitor.sh` | Simple system monitoring script that logs system statistics every 5 seconds. |
| `health_check.sh` | Service health check that verifies if nginx is running and starts it if needed. |
| `disk_usage.sh` | Monitors disk usage and alerts when partitions exceed the defined threshold (85%). |
| `connectivity_check.sh` | Checks network connectivity to a specified host and logs the result. |

### Development Tools

| Script | Description |
|--------|-------------|
| `git_branch_management.sh` | Interactive git branch management tool for creating, deleting, and merging branches. Includes safety checks and confirmation prompts. |
| `autogit.sh` | Streamlines the git workflow by automating add, commit, and push operations with interactive prompts. |
| `create_env.sh` | Creates and activates a Python virtual environment for development projects. |

### DevOps & Deployment

| Script | Description |
|--------|-------------|
| `ci_cd_auto.sh` | Comprehensive CI/CD automation system with branch management, testing, code quality checks, and deployment capabilities. |
| `deploy.sh` | Deploys an application from a git repository to a target server with options for branch selection and service restart. |
| `backup.sh` | Simple file backup script that creates timestamped backup directories. |

### Database Management

| Script | Description |
|--------|-------------|
| `database_backup.sh` | MySQL database backup utility that creates timestamped SQL dumps. |
| `autodb.sh` | Advanced database maintenance script with backup, optimization, connection monitoring, and performance reporting features. |

## Usage

Most scripts can be executed directly after making them executable:

```bash
chmod +x script_name.sh
./script_name.sh
```

Some scripts may require root privileges or specific configurations. Check the script comments for details.

## Contributing

Feel free to contribute to this collection by adding new scripts or improving existing ones. Please follow these guidelines:
- Add clear comments to your script
- Include error handling where appropriate
- Use consistent formatting
- Document any dependencies or prerequisites

## License

These scripts are provided as-is under the MIT license. Use at your own risk.