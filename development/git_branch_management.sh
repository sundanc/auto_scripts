#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts

# Git Branch Manager - Automates creation, deletion, and merging of branches

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate if we're in a git repository
validate_git_repo() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
  fi
}

# Ask for confirmation
confirm() {
  local message=$1
  local default=${2:-"y"}
  
  if [[ "$default" == "y" ]]; then
    prompt="[Y/n]"
  else
    prompt="[y/N]"
  fi
  
  echo -ne "${YELLOW}$message $prompt ${NC}"
  read response
  
  if [[ -z "$response" ]]; then
    response=$default
  fi
  
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 0
  else
    return 1
  fi
}

# Display main menu
show_main_menu() {
  clear
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}        GIT BRANCH MANAGER${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo -e "${GREEN}1${NC}. Create a new branch"
  echo -e "${GREEN}2${NC}. Delete a branch"
  echo -e "${GREEN}3${NC}. Merge branches"
  echo -e "${GREEN}4${NC}. List all branches"
  echo -e "${GREEN}0${NC}. Exit"
  echo ""
  echo -e "${BLUE}----------------------------------------${NC}"
  echo -ne "Please select an option [0-4]: "
}

# Create a new branch
create_branch_menu() {
  clear
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}        CREATE A NEW BRANCH${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  echo -ne "Enter new branch name (e.g., feature/new-login): "
  read new_branch
  
  if [[ -z "$new_branch" ]]; then
    echo -e "${RED}Error: Branch name cannot be empty${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  echo -ne "Enter base branch (leave empty for current branch): "
  read base_branch
  
  if [[ -z "$base_branch" ]]; then
    base_branch=$(git rev-parse --abbrev-ref HEAD)
  fi
  
  if confirm "Create branch '$new_branch' from '$base_branch'?"; then
    # Check if branch already exists
    if git show-ref --verify --quiet refs/heads/$new_branch; then
      echo -e "${RED}Error: Branch '$new_branch' already exists${NC}"
      read -p "Press Enter to continue..."
      return
    fi
    
    echo -e "${YELLOW}Creating branch ${GREEN}$new_branch${YELLOW} from ${GREEN}$base_branch${NC}..."
    
    # Make sure we have latest from base branch
    git fetch origin $base_branch 2>/dev/null || true
    
    # Create and checkout the new branch
    git checkout $base_branch
    git pull origin $base_branch 2>/dev/null || true
    git checkout -b $new_branch
    
    echo -e "${GREEN}Successfully created branch '$new_branch' from '$base_branch'${NC}"
  else
    echo -e "${YELLOW}Branch creation cancelled${NC}"
  fi
  
  read -p "Press Enter to return to main menu..."
}

# Delete a branch
delete_branch_menu() {
  clear
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}        DELETE A BRANCH${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # List available branches
  echo -e "${YELLOW}Available local branches:${NC}"
  git branch | sed 's/^../  /'
  echo ""
  
  echo -ne "Enter branch name to delete: "
  read branch_name
  
  if [[ -z "$branch_name" ]]; then
    echo -e "${RED}Error: Branch name cannot be empty${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  # Safety check - don't delete current branch
  if [ "$branch_name" == "$current_branch" ]; then
    echo -e "${RED}Error: Cannot delete the currently checked out branch${NC}"
    echo -e "Please checkout another branch first"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Check if branch exists
  if ! git show-ref --verify --quiet refs/heads/$branch_name; then
    echo -e "${RED}Error: Branch '$branch_name' does not exist${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  echo -ne "Force delete (ignores unmerged changes)? [y/N]: "
  read force_option
  
  if confirm "Are you sure you want to delete branch '$branch_name'?" "n"; then
    # Delete the branch
    if [[ "$force_option" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo -e "${YELLOW}Force deleting branch ${RED}$branch_name${NC}..."
      git branch -D $branch_name
    else
      echo -e "${YELLOW}Deleting branch ${RED}$branch_name${NC}..."
      if ! git branch -d $branch_name; then
        echo -e "${YELLOW}Branch has unmerged changes. Use force delete option to proceed.${NC}"
        read -p "Press Enter to continue..."
        return
      fi
    fi
    
    echo -e "${GREEN}Successfully deleted branch '$branch_name'${NC}"
    
    # Delete remote branch if exists and user confirms
    if git ls-remote --heads origin $branch_name | grep -q $branch_name; then
      if confirm "Remote branch '$branch_name' exists. Delete it too?" "n"; then
        git push origin --delete $branch_name
        echo -e "${GREEN}Successfully deleted remote branch '$branch_name'${NC}"
      fi
    fi
  else
    echo -e "${YELLOW}Branch deletion cancelled${NC}"
  fi
  
  read -p "Press Enter to return to main menu..."
}

# Merge branches
merge_branch_menu() {
  clear
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}        MERGE BRANCHES${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # List available branches
  echo -e "${YELLOW}Available local branches:${NC}"
  git branch | sed 's/^../  /'
  echo ""
  
  echo -ne "Enter source branch to merge from: "
  read source_branch
  
  if [[ -z "$source_branch" ]]; then
    echo -e "${RED}Error: Source branch name cannot be empty${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  echo -ne "Enter target branch to merge into (leave empty for current branch): "
  read target_branch
  
  if [[ -z "$target_branch" ]]; then
    target_branch=$(git rev-parse --abbrev-ref HEAD)
  fi
  
  # Check if source branch exists
  if ! git show-ref --verify --quiet refs/heads/$source_branch; then
    echo -e "${RED}Error: Source branch '$source_branch' does not exist${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Check if target branch exists
  if ! git show-ref --verify --quiet refs/heads/$target_branch; then
    echo -e "${RED}Error: Target branch '$target_branch' does not exist${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  if confirm "Merge branch '$source_branch' into '$target_branch'?"; then
    echo -e "${YELLOW}Merging ${GREEN}$source_branch${YELLOW} into ${GREEN}$target_branch${NC}..."
    
    # Make sure branches are up-to-date
    echo -e "${YELLOW}Updating branches...${NC}"
    git fetch origin
    
    # Switch to target branch
    git checkout $target_branch
    git pull origin $target_branch 2>/dev/null || true
    
    # Try to merge
    echo -e "${YELLOW}Attempting to merge...${NC}"
    if git merge $source_branch; then
      echo -e "${GREEN}Successfully merged '$source_branch' into '$target_branch'${NC}"
    else
      echo -e "${RED}Merge conflict detected.${NC}"
      echo -e "${YELLOW}Options:${NC}"
      echo -e "1. Resolve conflicts manually and then commit"
      echo -e "2. Abort merge with 'git merge --abort'"
    fi
  else
    echo -e "${YELLOW}Merge operation cancelled${NC}"
  fi
  
  read -p "Press Enter to return to main menu..."
}

# List all branches
list_branches_menu() {
  clear
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}        LIST ALL BRANCHES${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  echo -e "${YELLOW}Local branches:${NC}"
  git branch
  
  echo -e "\n${YELLOW}Remote branches:${NC}"
  git branch -r
  
  read -p "Press Enter to return to main menu..."
}

# Main script execution
main() {
  validate_git_repo
  
  while true; do
    show_main_menu
    read choice
    
    case $choice in
      1)
        create_branch_menu
        ;;
      2)
        delete_branch_menu
        ;;
      3)
        merge_branch_menu
        ;;
      4)
        list_branches_menu
        ;;
      0)
        echo -e "${GREEN}Exiting Git Branch Manager. Goodbye!${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option. Please try again.${NC}"
        read -p "Press Enter to continue..."
        ;;
    esac
  done
}

# Start the script
main