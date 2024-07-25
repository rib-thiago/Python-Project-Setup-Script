#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required commands are available
for cmd in "poetry" "pyenv" "git" "ignr" "gh"; do
    if ! command_exists "$cmd"; then
        echo "Error: Required command '$cmd' is not installed. Please install it to continue."
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
        echo "Error: Directory '$project_name' already exists. Please choose another name."
        exit 1
    fi

    # Check if the specified Python version is installed
    if ! pyenv versions --bare | grep -q "^$python_version\$"; then
        echo "Error: Python version $python_version is not installed. Please install it using pyenv."
        echo "Installed versions:"
        pyenv versions
        exit 1
    fi

    # Create a new Poetry project
    poetry new "$project_name" || { echo "Failed to create project with Poetry."; exit 1; }
    cd "$project_name" || exit

    # Set local Python version
    pyenv local "$python_version" || { echo "Failed to set Python version with pyenv."; exit 1; }
    sed -i "s/python = \".*\"/python = \"$python_version\"/" pyproject.toml

    # Use the specified Python version for Poetry
    poetry env use "$python_version" || { echo "Failed to set Poetry environment to use Python $python_version."; exit 1; }

    # Add dependencies if any are provided
    if [ ${#dependencies[@]} -gt 0 ]; then
        for dep in "${dependencies[@]}"; do
            poetry add "$dep" || { echo "Failed to add dependency: $dep"; exit 1; }
        done
    fi

    echo "Project '$project_name' created successfully with Python $python_version."

    # Initialize git repository
    git init || { echo "Failed to initialize git repository."; exit 1; }

    # Create .gitignore file
    ignr -p python > .gitignore || { echo "Failed to create .gitignore file."; exit 1; }
    echo ".gitignore created successfully."

    # Add files to git and commit
    git add . || { echo "Failed to add files to git."; exit 1; }
    git commit -m "Commit Inicial" || { echo "Failed to commit files."; exit 1; }

    # Create GitHub repository
    if gh repo create "$project_name" --source=. --remote=origin --public --push; then
        echo "GitHub repository created successfully."
        # Push the initial commit to GitHub
        git push -u origin main || { echo "Failed to push to GitHub."; exit 1; }
    else
        echo "Failed to create GitHub repository."; exit 1;
    fi

    echo "Git repository initialized and pushed to GitHub successfully."

    # Activate the virtual environment
    poetry shell || { echo "Failed to activate the virtual environment with Poetry."; exit 1; }

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
        \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done

# If not in interactive mode, ensure project name and Python version are provided
if [[ -z "$interactive_mode" && (-z "$project_name" || -z "$python_version") ]]; then
    echo "Usage: $0 -n <project_name> -v <python_version> [-d <dependencies>]"
    echo "Or: $0 -i for interactive mode"
    exit 1
fi

# Run the project creation function if not in interactive mode
if [ -z "$interactive_mode" ]; then
    create_project "$project_name" "$python_version" "${dependencies[@]}"
fi
