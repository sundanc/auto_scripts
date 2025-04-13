# IT Arsenal Installation Guide

This guide walks you through the process of installing IT Arsenal on your system.

## Prerequisites

Before installing IT Arsenal, ensure your system meets the following requirements:

- Linux-based operating system (Debian/Ubuntu, RHEL/CentOS, or Arch Linux recommended)
- Bash shell (version 4.0 or later)
- Root/sudo access (for some features)
- Git (for installation and updates)

## Installation Methods

### Method 1: Automatic Installation (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/sundanc/auto_scripts.git
   cd auto_scripts
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

3. Follow the prompts to complete the installation.

### Method 2: Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sundanc/auto_scripts.git
   cd auto_scripts
   ```

2. Ensure the main script is executable:
   ```bash
   chmod +x arsenal.sh
   ```

3. Create required directories (if they don't exist):
   ```bash
   mkdir -p config logs plugins templates
   ```

4. Create a configuration file:
   ```bash
   cp config/arsenal.conf.example config/arsenal.conf
   ```

5. Edit the configuration file to match your environment:
   ```bash
   nano config/arsenal.conf
   ```

## Post-Installation Configuration

After installing IT Arsenal, you should:

1. Review and customize the configuration in `config/arsenal.conf`
2. Set up email notifications (if desired)
3. Configure backup directories
4. Test the installation by running `./arsenal.sh`

## Directory Structure

After installation, your IT Arsenal directory should have the following structure:

```
auto_scripts/
├── arsenal.sh           # Main command center script
├── config/              # Configuration files
│   ├── arsenal.conf     # Main configuration
│   └── credentials/     # Secure credential storage
├── database/            # Database management scripts
├── development/         # Development scripts
├── devops/              # DevOps scripts
├── docs/                # Documentation
├── lib/                 # Common libraries
├── logs/                # Log files
├── plugins/             # Plugin directory
├── system/              # System administration scripts
├── templates/           # Script templates
└── tests/               # Test scripts
```

## Troubleshooting

### Common Installation Issues

1. **Permission denied errors**
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

2. **Missing dependencies**
   ```bash
   # Debian/Ubuntu
   sudo apt-get install bash grep sed awk curl git bc jq

   # RHEL/CentOS
   sudo yum install bash grep sed gawk curl git bc jq
   ```

3. **Configuration issues**
   - Ensure the configuration file exists
   - Check file permissions on the config directory
   - Verify the paths in the configuration file are correct

### Getting Help

If you encounter issues during installation, refer to:
- The full documentation in the `docs/` directory
- GitHub issues at [https://github.com/sundanc/auto_scripts/issues](https://github.com/sundanc/auto_scripts/issues)

## Next Steps

Once IT Arsenal is installed, check out the [Quick Start Guide](quick-start.md) to begin using the toolkit.
