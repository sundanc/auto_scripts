#!/bin/bash
# GitHub: https://github.com/sundanc/auto_scripts
# filepath: /home/ary/Documents/daily_tracker/cicd_automation.sh

# CI/CD Automation Script - Automates integration, testing, and deployment

# Text colors and formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration variables - customize these
MAIN_BRANCH="main"
DEVELOP_BRANCH="develop"
TEST_COMMAND="./run_tests.sh" # Change this to your test command
DEPLOY_SCRIPT="./deploy.sh" # Change this to your deploy script
LOG_DIR="./logs"
CONFIG_FILE="./.cicd_config"

# Ensure log directory exists
mkdir -p $LOG_DIR

# Check if required tools are installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed.${NC}"
    exit 1
fi

# Load configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# Validate git repository
validate_git_repo() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
  fi
}

# Ask for confirmation
confirm() {
  local message=$1
  local default=${2:-"n"} # Default to "no" for safety
  
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

# Display header
show_header() {
  local title="$1"
  clear
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}        $title${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
}

# Log message to file
log_message() {
  local level="$1"
  local message="$2"
  local log_file="$LOG_DIR/cicd_$(date +%Y%m%d).log"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
}

# Display main menu
show_main_menu() {
  show_header "CI/CD AUTOMATION SYSTEM"
  
  echo -e "${BOLD}INTEGRATION:${NC}"
  echo -e "  ${GREEN}1${NC}. Update branches (fetch & pull)"
  echo -e "  ${GREEN}2${NC}. Integrate feature branch into $DEVELOP_BRANCH"
  echo -e "  ${GREEN}3${NC}. Promote $DEVELOP_BRANCH to $MAIN_BRANCH"
  echo -e ""
  echo -e "${BOLD}TESTING:${NC}"
  echo -e "  ${GREEN}4${NC}. Run test suite"
  echo -e "  ${GREEN}5${NC}. Run code quality checks"
  echo -e ""
  echo -e "${BOLD}DEPLOYMENT:${NC}"
  echo -e "  ${GREEN}6${NC}. Deploy to staging environment"
  echo -e "  ${GREEN}7${NC}. Deploy to production environment"
  echo -e "  ${GREEN}8${NC}. Rollback deployment"
  echo -e ""
  echo -e "${BOLD}CONFIGURATION:${NC}"
  echo -e "  ${GREEN}9${NC}. Configure CI/CD settings"
  echo -e "  ${GREEN}0${NC}. Exit"
  echo -e ""
  echo -e "${BLUE}----------------------------------------${NC}"
  echo -ne "Please select an option [0-9]: "
}

# Update branches
update_branches() {
  show_header "UPDATE BRANCHES"
  
  echo -e "${YELLOW}Current branch: $(git rev-parse --abbrev-ref HEAD)${NC}"
  echo ""
  
  if confirm "Fetch latest changes from remote repository?"; then
    echo -e "${BLUE}Fetching latest changes...${NC}"
    git fetch --all --prune
    echo -e "${GREEN}✓ Fetch completed${NC}"
    log_message "INFO" "Fetched latest changes from remote"
  fi
  
  echo ""
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  if confirm "Pull latest changes into current branch ($current_branch)?"; then
    echo -e "${BLUE}Pulling latest changes...${NC}"
    if git pull origin $current_branch; then
      echo -e "${GREEN}✓ Pull completed successfully${NC}"
      log_message "INFO" "Pulled latest changes into $current_branch"
    else
      echo -e "${RED}✗ Pull failed. You may have conflicts to resolve.${NC}"
      log_message "ERROR" "Pull failed for $current_branch"
    fi
  fi
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Detect project type
detect_project_type() {
  if [[ -f "package.json" ]]; then
    echo "nodejs"
  elif [[ -f "requirements.txt" ]]; then
    echo "python"
  elif [[ -f "pom.xml" ]]; then
    echo "java-maven"
  elif [[ -f "build.gradle" ]]; then
    echo "java-gradle"
  else
    echo "unknown"
  fi
}

# Run appropriate tests based on project type
run_tests() {
  local project_type=$(detect_project_type)
  
  case "$project_type" in
    nodejs)
      echo -e "${BLUE}Detected Node.js project${NC}"
      
      if [[ -f "package.json" ]]; then
        if grep -q '"test"' package.json; then
          echo -e "${BLUE}Running npm tests...${NC}"
          npm test
          return $?
        fi
      fi
      ;;
    python)
      echo -e "${BLUE}Detected Python project${NC}"
      if [[ -f "pytest.ini" ]]; then
        echo -e "${BLUE}Running pytest...${NC}"
        python -m pytest
        return $?
      elif [[ -f "manage.py" ]]; then
        echo -e "${BLUE}Running Django tests...${NC}"
        python manage.py test
        return $?
      fi
      ;;
    java-maven)
      echo -e "${BLUE}Detected Maven project${NC}"
      echo -e "${BLUE}Running Maven tests...${NC}"
      mvn test
      return $?
      ;;
    java-gradle)
      echo -e "${BLUE}Detected Gradle project${NC}"
      echo -e "${BLUE}Running Gradle tests...${NC}"
      gradle test
      return $?
      ;;
    *)
      # Use generic test command
      if [[ -f $TEST_COMMAND ]]; then
        echo -e "${BLUE}Running tests with $TEST_COMMAND...${NC}"
        $TEST_COMMAND
        return $?
      fi
      ;;
  esac
  
  echo -e "${YELLOW}No test configuration detected. Please set up tests or update TEST_COMMAND.${NC}"
  return 1
}

# Integrate feature branch to develop
integrate_feature() {
  show_header "INTEGRATE FEATURE BRANCH"
  
  # List all branches
  echo -e "${YELLOW}Available branches:${NC}"
  git branch | grep -v "$DEVELOP_BRANCH" | sed 's/^../  /'
  echo ""
  
  echo -ne "Enter feature branch name to integrate: "
  read feature_branch
  
  if [[ -z "$feature_branch" ]]; then
    echo -e "${RED}Error: Branch name cannot be empty${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Check if branch exists
  if ! git show-ref --verify --quiet refs/heads/$feature_branch; then
    echo -e "${RED}Error: Branch '$feature_branch' does not exist${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Update branches
  echo -e "${BLUE}Updating branches...${NC}"
  git fetch origin $DEVELOP_BRANCH
  git checkout $feature_branch
  git pull origin $feature_branch
  
  # Run tests on feature branch
  echo ""
  if confirm "Run tests on $feature_branch before integration?"; then
    echo -e "${BLUE}Running tests on $feature_branch...${NC}"
    
    if run_tests; then
      echo -e "${GREEN}✓ Tests passed!${NC}"
      log_message "INFO" "Tests passed on $feature_branch"
    else
      echo -e "${RED}✗ Tests failed!${NC}"
      log_message "ERROR" "Tests failed on $feature_branch"
      
      if ! confirm "Tests failed! Continue with integration anyway?" "n"; then
        echo -e "${YELLOW}Integration aborted.${NC}"
        read -p "Press Enter to return to main menu..."
        return
      fi
    fi
  fi
  
  # Confirm integration
  echo ""
  if confirm "Integrate $feature_branch into $DEVELOP_BRANCH?"; then
    git checkout $DEVELOP_BRANCH
    git pull origin $DEVELOP_BRANCH
    
    echo -e "${BLUE}Merging $feature_branch into $DEVELOP_BRANCH...${NC}"
    
    if git merge --no-ff $feature_branch -m "Merge feature '$feature_branch' into $DEVELOP_BRANCH"; then
      echo -e "${GREEN}✓ Merge successful!${NC}"
      log_message "INFO" "Merged $feature_branch into $DEVELOP_BRANCH"
      
      if confirm "Push changes to remote $DEVELOP_BRANCH?"; then
        git push origin $DEVELOP_BRANCH
        echo -e "${GREEN}✓ Changes pushed to remote!${NC}"
        log_message "INFO" "Pushed changes to remote $DEVELOP_BRANCH"
      fi
    else
      echo -e "${RED}✗ Merge failed! You need to resolve conflicts.${NC}"
      log_message "WARNING" "Merge conflict when integrating $feature_branch into $DEVELOP_BRANCH"
      
      if confirm "Would you like to abort the merge?"; then
        git merge --abort
        echo -e "${YELLOW}Merge aborted.${NC}"
        log_message "INFO" "Merge aborted"
      else
        echo -e "${YELLOW}Please resolve conflicts, then commit and push.${NC}"
      fi
    fi
  else
    echo -e "${YELLOW}Integration cancelled.${NC}"
  fi
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Promote develop to main
promote_to_main() {
  show_header "PROMOTE TO $MAIN_BRANCH"
  
  if ! confirm "This will merge $DEVELOP_BRANCH into $MAIN_BRANCH. Continue?" "n"; then
    echo -e "${YELLOW}Promotion cancelled.${NC}"
    read -p "Press Enter to return to main menu..."
    return
  fi
  
  # Update branches
  echo -e "${BLUE}Updating branches...${NC}"
  git fetch origin
  git checkout $DEVELOP_BRANCH
  git pull origin $DEVELOP_BRANCH
  git checkout $MAIN_BRANCH
  git pull origin $MAIN_BRANCH
  
  # Run tests on develop branch before promotion
  git checkout $DEVELOP_BRANCH
  echo ""
  if confirm "Run tests on $DEVELOP_BRANCH before promotion?"; then
    echo -e "${BLUE}Running tests on $DEVELOP_BRANCH...${NC}"
    
    if run_tests; then
      echo -e "${GREEN}✓ Tests passed!${NC}"
      log_message "INFO" "Tests passed on $DEVELOP_BRANCH before promotion"
    else
      echo -e "${RED}✗ Tests failed!${NC}"
      log_message "ERROR" "Tests failed on $DEVELOP_BRANCH before promotion"
      
      if ! confirm "Tests failed! Continue with promotion anyway?" "n"; then
        echo -e "${YELLOW}Promotion aborted.${NC}"
        read -p "Press Enter to return to main menu..."
        return
      fi
    fi
  fi
  
  # Create release tag
  echo ""
  echo -ne "Enter version tag for this release (e.g. v1.0.0): "
  read version_tag
  
  if [[ -z "$version_tag" ]]; then
    echo -e "${YELLOW}Warning: No version tag specified. Using date-based tag.${NC}"
    version_tag="release-$(date +%Y%m%d-%H%M%S)"
  fi
  
  # Merge develop into main
  git checkout $MAIN_BRANCH
  
  echo -e "${BLUE}Merging $DEVELOP_BRANCH into $MAIN_BRANCH...${NC}"
  
  if git merge --no-ff $DEVELOP_BRANCH -m "Promote $DEVELOP_BRANCH to $MAIN_BRANCH ($version_tag)"; then
    echo -e "${GREEN}✓ Promotion successful!${NC}"
    log_message "INFO" "Promoted $DEVELOP_BRANCH to $MAIN_BRANCH with tag $version_tag"
    
    # Create tag
    git tag -a "$version_tag" -m "Release $version_tag"
    
    if confirm "Push changes and tags to remote $MAIN_BRANCH?"; then
      git push origin $MAIN_BRANCH
      git push origin --tags
      echo -e "${GREEN}✓ Changes and tags pushed to remote!${NC}"
      log_message "INFO" "Pushed $MAIN_BRANCH and tags to remote"
    fi
  else
    echo -e "${RED}✗ Merge failed! You need to resolve conflicts.${NC}"
    log_message "WARNING" "Merge conflict when promoting $DEVELOP_BRANCH to $MAIN_BRANCH"
    
    if confirm "Would you like to abort the merge?"; then
      git merge --abort
      echo -e "${YELLOW}Merge aborted.${NC}"
      log_message "INFO" "Promotion aborted"
    else
      echo -e "${YELLOW}Please resolve conflicts, then commit and push.${NC}"
    fi
  fi
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Run test suite
run_test_suite() {
  show_header "RUN TEST SUITE"
  
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  echo -e "${YELLOW}Current branch: $current_branch${NC}"
  echo ""
  
  if confirm "Run tests on current branch?"; then
    echo -e "${BLUE}Running tests...${NC}"
    
    if run_tests; then
      echo -e "${GREEN}✓ All tests passed!${NC}"
      log_message "INFO" "Tests passed on branch $current_branch"
    else
      echo -e "${RED}✗ Tests failed!${NC}"
      log_message "ERROR" "Tests failed on branch $current_branch"
    fi
  fi
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Run code quality checks
run_code_quality() {
  show_header "CODE QUALITY CHECKS"
  
  local project_type=$(detect_project_type)
  echo -e "${YELLOW}Project type: $project_type${NC}"
  echo ""
  
  if confirm "Run code quality checks?"; then
    case "$project_type" in
      nodejs)
        echo -e "${BLUE}Running ESLint...${NC}"
        if [[ -f "node_modules/.bin/eslint" ]]; then
          node_modules/.bin/eslint . --quiet && echo -e "${GREEN}✓ ESLint passed!${NC}" || echo -e "${RED}✗ ESLint found issues!${NC}"
        else
          echo -e "${YELLOW}ESLint not found. Install with: npm install eslint --save-dev${NC}"
        fi
        ;;
      python)
        echo -e "${BLUE}Running flake8...${NC}"
        if command -v flake8 &> /dev/null; then
          flake8 && echo -e "${GREEN}✓ flake8 passed!${NC}" || echo -e "${RED}✗ flake8 found issues!${NC}"
        else
          echo -e "${YELLOW}flake8 not found. Install with: pip install flake8${NC}"
        fi
        ;;
      java-maven)
        echo -e "${BLUE}Running Checkstyle...${NC}"
        if [[ -f "pom.xml" ]] && grep -q "checkstyle" pom.xml; then
          mvn checkstyle:check && echo -e "${GREEN}✓ Checkstyle passed!${NC}" || echo -e "${RED}✗ Checkstyle found issues!${NC}"
        else
          echo -e "${YELLOW}Checkstyle not configured in your Maven project.${NC}"
        fi
        ;;
      *)
        echo -e "${YELLOW}No code quality checks configured for this project type.${NC}"
        ;;
    esac
  fi
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Deploy to staging environment
deploy_to_staging() {
  show_header "DEPLOY TO STAGING"
  
  if ! confirm "Deploy current branch to staging environment?" "n"; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    read -p "Press Enter to return to main menu..."
    return
  fi
  
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  echo -e "${BLUE}Deploying $current_branch to staging...${NC}"
  
  # Run tests before deployment
  if confirm "Run tests before deployment?"; then
    echo -e "${BLUE}Running tests...${NC}"
    
    if ! run_tests; then
      echo -e "${RED}✗ Tests failed!${NC}"
      if ! confirm "Tests failed! Continue with deployment anyway?" "n"; then
        echo -e "${YELLOW}Deployment aborted.${NC}"
        log_message "WARNING" "Deployment to staging aborted due to test failures"
        read -p "Press Enter to return to main menu..."
        return
      fi
    else
      echo -e "${GREEN}✓ Tests passed!${NC}"
    fi
  fi
  
  # Actual deployment logic would go here
  echo -e "${BLUE}Executing deployment script...${NC}"
  log_message "INFO" "Deploying $current_branch to staging environment"
  
  # Example deployment (replace with actual deployment commands)
  echo -e "${GREEN}✓ Deployment to staging completed!${NC}"
  echo -e "${YELLOW}Staging URL: https://staging-environment.example.com${NC}"
  log_message "INFO" "Successfully deployed $current_branch to staging"
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Deploy to production environment
deploy_to_production() {
  show_header "DEPLOY TO PRODUCTION"
  
  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$MAIN_BRANCH" ]]; then
    echo -e "${RED}Error: You must be on the $MAIN_BRANCH branch to deploy to production.${NC}"
    echo -e "${YELLOW}Current branch: $(git rev-parse --abbrev-ref HEAD)${NC}"
    
    if confirm "Checkout $MAIN_BRANCH branch?"; then
      git checkout $MAIN_BRANCH
    else
      read -p "Press Enter to return to main menu..."
      return
    fi
  fi
  
  git pull origin $MAIN_BRANCH
  
  # Check if we're on the latest tagged version
  local latest_tag=$(git describe --tags --abbrev=0)
  local current_commit=$(git rev-parse HEAD)
  local tag_commit=$(git rev-list -n 1 $latest_tag)
  
  echo -e "${YELLOW}Latest tag: $latest_tag${NC}"
  
  if [[ "$current_commit" != "$tag_commit" ]]; then
    echo -e "${RED}Warning: You are not on the latest tagged version!${NC}"
    echo -e "${YELLOW}Use the latest tagged version for production deployments.${NC}"
    
    if ! confirm "Continue anyway?" "n"; then
      echo -e "${YELLOW}Deployment cancelled.${NC}"
      read -p "Press Enter to return to main menu..."
      return
    fi
  fi
  
  if ! confirm "⚠️  CRITICAL ACTION: Deploy to PRODUCTION environment?" "n"; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    read -p "Press Enter to return to main menu..."
    return
  fi
  
  echo -e "${PURPLE}⚠️  PRODUCTION DEPLOYMENT INITIATED ⚠️${NC}"
  echo -e "${BLUE}Deploying $MAIN_BRANCH ($latest_tag) to production...${NC}"
  log_message "CRITICAL" "Deploying $MAIN_BRANCH ($latest_tag) to production"
  
  # Actual deployment logic would go here
  echo -e "${GREEN}✓ Deployment to production completed!${NC}"
  echo -e "${YELLOW}Production URL: https://www.example.com${NC}"
  log_message "INFO" "Successfully deployed $MAIN_BRANCH ($latest_tag) to production"
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Rollback deployment
rollback_deployment() {
  show_header "ROLLBACK DEPLOYMENT"
  
  echo -e "${YELLOW}Available tags:${NC}"
  git tag -l --sort=-v:refname | head -10  # Show 10 most recent tags
  echo ""
  
  echo -ne "Enter tag to rollback to: "
  read rollback_tag
  
  if [[ -z "$rollback_tag" ]]; then
    echo -e "${RED}Error: Tag name cannot be empty${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Check if tag exists
  if ! git show-ref --verify --quiet refs/tags/$rollback_tag; then
    echo -e "${RED}Error: Tag '$rollback_tag' does not exist${NC}"
    read -p "Press Enter to continue..."
    return
  fi
  
  if ! confirm "⚠️  CRITICAL ACTION: Rollback to $rollback_tag?" "n"; then
    echo -e "${YELLOW}Rollback cancelled.${NC}"
    read -p "Press Enter to return to main menu..."
    return
  fi
  
  echo -e "${PURPLE}⚠️  ROLLBACK INITIATED ⚠️${NC}"
  echo -e "${BLUE}Rolling back to $rollback_tag...${NC}"
  log_message "CRITICAL" "Rolling back to $rollback_tag"
  
  git checkout $rollback_tag
  
  # Actual rollback deployment logic would go here
  echo -e "${GREEN}✓ Rollback completed!${NC}"
  log_message "INFO" "Successfully rolled back to $rollback_tag"
  
  echo ""
  read -p "Press Enter to return to main menu..."
}

# Configure CI/CD settings
configure_settings() {
  show_header "CONFIGURE CI/CD SETTINGS"
  
  echo -e "Current settings:"
  echo -e "${YELLOW}Main branch:${NC} $MAIN_BRANCH"
  echo -e "${YELLOW}Develop branch:${NC} $DEVELOP_BRANCH"
  echo -e "${YELLOW}Test command:${NC} $TEST_COMMAND"
  echo -e "${YELLOW}Deploy script:${NC} $DEPLOY_SCRIPT"
  echo -e "${YELLOW}Log directory:${NC} $LOG_DIR"
  echo -e ""
  
  if confirm "Update settings?"; then
    echo -ne "Main branch name [$MAIN_BRANCH]: "
    read input
    MAIN_BRANCH=${input:-$MAIN_BRANCH}
    
    echo -ne "Develop branch name [$DEVELOP_BRANCH]: "
    read input
    DEVELOP_BRANCH=${input:-$DEVELOP_BRANCH}
    
    echo -ne "Test command [$TEST_COMMAND]: "
    read input
    TEST_COMMAND=${input:-$TEST_COMMAND}
    
    echo -ne "Deploy script [$DEPLOY_SCRIPT]: "
    read input
    DEPLOY_SCRIPT=${input:-$DEPLOY_SCRIPT}
    
    echo -ne "Log directory [$LOG_DIR]: "
    read input
    LOG_DIR=${input:-$LOG_DIR}
    
    # Save settings to config file
    echo "# CI/CD Configuration" > $CONFIG_FILE
    echo "MAIN_BRANCH=\"$MAIN_BRANCH\"" >> $CONFIG_FILE
    echo "DEVELOP_BRANCH=\"$DEVELOP_BRANCH\"" >> $CONFIG_FILE
    echo "TEST_COMMAND=\"$TEST_COMMAND\"" >> $CONFIG_FILE
    echo "DEPLOY_SCRIPT=\"$DEPLOY_SCRIPT\"" >> $CONFIG_FILE
    echo "LOG_DIR=\"$LOG_DIR\"" >> $CONFIG_FILE
    
    echo -e "${GREEN}✓ Settings updated and saved!${NC}"
  fi
  
  echo ""
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
        update_branches
        ;;
      2)
        integrate_feature
        ;;
      3)
        promote_to_main
        ;;
      4)
        run_test_suite
        ;;
      5)
        run_code_quality
        ;;
      6)
        deploy_to_staging
        ;;
      7)
        deploy_to_production
        ;;
      8)
        rollback_deployment
        ;;
      9)
        configure_settings
        ;;
      0)
        echo -e "${GREEN}Exiting CI/CD Automation. Goodbye!${NC}"
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