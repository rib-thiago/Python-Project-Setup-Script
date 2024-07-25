#!/bin/bash

# Define ANSI escape codes for colors
GREEN='\033[92m'
RED='\033[91m'
YELLOW='\033[93m'
RESET='\033[0m'





# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required commands are available
for cmd in "poetry" "pyenv" "git" "ignr" "gh"; do
    if ! command_exists "$cmd"; then
        echo -e "${RED}Error: Required command '$cmd' is not installed. Please install it to continue.${RESET}"
        exit 1
    fi
done

# Function to create a new project
create_project() {
    local project_name=$1
    local python_version=$2
    shift 2
    local dependencies=("$@")

    # Check if project directory already exists
    if [ -d "$project_name" ]; then
        echo -e "${RED}Error: Directory '$project_name' already exists. Please choose another name.${RESET}"
        exit 1
    fi

    # Check if the specified Python version is installed
    if ! pyenv versions --bare | grep -q "^$python_version\$"; then
        echo -e "${RED}Error: Python version $python_version is not installed. Please install it using pyenv.${RESET}"
        echo -e "Installed versions:"
        pyenv versions
        exit 1
    fi

    # Create a new Poetry project
    poetry new "$project_name" || { echo -e "${RED}Failed to create project with Poetry.${RESET}"; exit 1; }
    cd "$project_name" || exit

    # Set local Python version
    pyenv local "$python_version" || { echo -e "${RED}Failed to set Python version with pyenv.${RESET}"; exit 1; }
    sed -i "s/python = \".*\"/python = \"$python_version\"/" pyproject.toml

    # Use the specified Python version for Poetry
    poetry env use "$python_version" || { echo -e "${RED}Failed to set Poetry environment to use Python $python_version.${RESET}"; exit 1; }

    # Add dependencies if any are provided
    if [ ${#dependencies[@]} -gt 0 ]; then
        for dep in "${dependencies[@]}"; do
            poetry add "$dep" || { echo -e "${RED}Failed to add dependency: $dep${RESET}"; exit 1; }
        done
    fi

    echo -e "${GREEN}Project '$project_name' created successfully with Python $python_version.${RESET}\n"

    # Initialize git repository
    git init || { echo -e "${RED}Failed to initialize git repository.${RESET}"; exit 1; }

    # Create .gitignore file
    ignr -p python > .gitignore || { echo -e "${RED}Failed to create .gitignore file.${RESET}"; exit 1; }
    echo -e "${GREEN}.gitignore created successfully.${RESET}\n"


    # Add files to git and commit
    git add . || { echo -e "${RED}Failed to add files to git.${RESET}"; exit 1; }
    git commit -m "Commit Inicial" || { echo -e "${RED}Failed to commit files.${RESET}"; exit 1; }

    # Create GitHub repository
    
    
    if gh repo create "$project_name" --source=. --remote=origin --public --push; then
        echo -e "${GREEN}GitHub repository created and pushed successfully.${RESET}\n"
    else
        echo -e "${RED}Failed to create GitHub repository.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}Git repository initialized and pushed to GitHub successfully.${RESET}\n"

    # Activate the virtual environment
    poetry shell || { echo -e "${RED}Failed to activate the virtual environment with Poetry.${RESET}"; exit 1; }

    # Exit the script to prevent re-running after exiting the shell
    exit 0
}

# Interactive mode
interactive_mode() {
    read -p "Enter project name: " project_name
    echo "Installed Python versions:"
    pyenv versions
    read -p "Enter Python version (e.g., 3.10.13): " python_version
    read -p "Enter dependencies (space-separated): " -a dependencies

    create_project "$project_name" "$python_version" "${dependencies[@]}"
}

# Command line options
while getopts ":n:v:d:i" opt; do
    case $opt in
        n) project_name=$OPTARG ;;
        v) python_version=$OPTARG ;;
        d) IFS=' ' read -r -a dependencies <<< "$OPTARG" ;;
        i) interactive_mode ;;
        \?) echo -e "${RED}Invalid option -$OPTARG${RESET}" >&2; exit 1 ;;
        :) echo -e "${RED}Option -$OPTARG requires an argument.${RESET}" >&2; exit 1 ;;
    esac
done

# If not in interactive mode, ensure project name and Python version are provided
if [[ -z "$interactive_mode" && (-z "$project_name" || -z "$python_version") ]]; then
    echo -e "${YELLOW}Usage: $0 -n <project_name> -v <python_version> [-d <dependencies>]${RESET}"
    echo -e "${YELLOW}Or: $0 -i for interactive mode${RESET}"
    exit 1
fi

# Run the project creation function if not in interactive mode
if [ -z "$interactive_mode" ]; then
    create_project "$project_name" "$python_version" "${dependencies[@]}"
fi
