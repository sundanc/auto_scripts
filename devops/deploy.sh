#!/bin/bash
# deploy-app.sh - Deploy an application from git to a target server

# Usage information
usage() {
  echo "Usage: $0 -r REPO_URL -b BRANCH -d DEPLOY_DIR [-s SERVICE_NAME]"
  echo "  -r  Git repository URL"
  echo "  -b  Git branch to deploy"
  echo "  -d  Deployment directory"
  echo "  -s  Service name to restart (optional)"
  exit 1
}

# Process command line arguments
while getopts "r:b:d:s:" opt; do
  case $opt in
    r) REPO_URL="$OPTARG" ;;
    b) BRANCH="$OPTARG" ;;
    d) DEPLOY_DIR="$OPTARG" ;;
    s) SERVICE_NAME="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check required parameters
if [ -z "$REPO_URL" ] || [ -z "$BRANCH" ] || [ -z "$DEPLOY_DIR" ]; then
  usage
fi

echo "Deploying $REPO_URL branch $BRANCH to $DEPLOY_DIR"

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Created temp directory: $TEMP_DIR"

# Clone repository
echo "Cloning repository..."
git clone -b "$BRANCH" "$REPO_URL" "$TEMP_DIR" || { echo "Failed to clone repository"; exit 1; }

# Ensure target directory exists
mkdir -p "$DEPLOY_DIR"

# Deploy files
echo "Copying files to deployment directory..."
rsync -av --delete "$TEMP_DIR/" "$DEPLOY_DIR/" --exclude .git || { echo "Failed to deploy files"; exit 1; }

# Restart service if specified
if [ -n "$SERVICE_NAME" ]; then
  echo "Restarting service: $SERVICE_NAME"
  systemctl restart "$SERVICE_NAME" || { echo "Failed to restart service"; exit 1; }
fi

# Cleanup temp directory
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Deployment completed successfully!"