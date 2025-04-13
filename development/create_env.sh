#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python3 is not installed.${NC}"
    exit 1
fi

# Create a virtual environment if it doesn't exist
ENV_DIR="env"
if [ ! -d "$ENV_DIR" ]; then
    python3 -m venv $ENV_DIR
    echo "Virtual environment created."
else
    echo "Virtual environment already exists."
fi

# Activate the virtual environment
source $ENV_DIR/bin/activate

# Install the required packages
# pip install -r requirements.txt

echo "Virtual environment activated."