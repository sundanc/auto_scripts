#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Check if python3 is installed
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found, please install it first."
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