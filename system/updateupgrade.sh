#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Define some color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if the system is Debian-based
if [[ -f /etc/debian_version ]]; then
    echo -e "${GREEN}Debian-based system detected. Proceeding with updates...${NC}"
else
    echo -e "${RED}Error: This script is designed for Debian-based systems only.${NC}"
    exit 1
fi

echo -e "${YELLOW}Updating package lists...${NC}"
sudo apt update

echo -e "${YELLOW}Upgrading installed packages...${NC}"
sudo apt upgrade -y

echo -e "${GREEN}Update and upgrade complete.${NC}"
