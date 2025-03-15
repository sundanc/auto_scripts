#!/bin/bash

# Script to automate git add, commit, push

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Add all changes
echo -e "${YELLOW}Adding all changes...${NC}"
git add .

# Prompt for a commit message
echo -e "${YELLOW}Enter commit message:${NC} "
read commit_message

# Validate commit message
if [ -z "$commit_message" ]; then
  echo -e "${RED}Error: Commit message cannot be empty${NC}"
  exit 1
fi

# Commit with the provided message
echo -e "${YELLOW}Committing changes...${NC}"
git commit -m "$commit_message"

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Prompt for branch name to push to
echo -e "${YELLOW}Enter branch name to push to (default: $current_branch):${NC} "
read branch_name

# Use the current branch if no branch is specified
if [ -z "$branch_name" ]; then
  branch_name=$current_branch
  echo -e "${YELLOW}Using current branch: $branch_name${NC}"
fi

# Push to the specified branch
echo -e "${YELLOW}Pushing to branch '$branch_name'...${NC}"
git push origin $branch_name

echo -e "${GREEN}Changes have been pushed to the '$branch_name' branch.${NC}"