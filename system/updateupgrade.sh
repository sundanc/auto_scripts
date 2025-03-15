#!/bin/bash

# Define some color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Updating package lists...${NC}"
sudo apt update

echo -e "${YELLOW}Upgrading installed packages...${NC}"
sudo apt upgrade -y

echo -e "${GREEN}Update and upgrade complete.${NC}"
