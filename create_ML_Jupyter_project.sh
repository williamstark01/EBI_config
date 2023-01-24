#!/usr/bin/env bash


# Create a virtual environment for a new Python project and initialize the project with Poetry.


# exit on any error
set -e


SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"


create_project() {
    if ! command -v pyenv &> /dev/null ; then
        echo "Couldn't run pyenv, check it is installed and properly configured."
    fi
    if [[ -z "$PYENV_ROOT" ]]; then
        echo "The PYENV_ROOT environment variable is not set, check that pyenv is installed and properly configured."
    fi

    read -p "How should the project be called? " project_name
    echo

    mkdir $project_name
    cd $project_name

    echo "Creating a git repository for the project..."
    git init
    git checkout -b main

    cp "$SCRIPT_DIRECTORY/.gitignore" .
    git add .gitignore
    git commit -m "add .gitignore"
    echo

    echo "Creating a dedicated Python virtual environment for the project $project_name..."
    pyenv virtualenv "$project_name"
    pyenv local "$project_name"
    echo "Upgrading the pip module..."
    pip install --upgrade pip
    echo

    git add .python-version
    git commit -m "specify virtual environment"

    echo "Initializing the project with Poetry..."
    poetry init --no-interaction --quiet --name $project_name
    echo

    git add pyproject.toml
    git commit -m "create Python project"
    echo

    echo "The project has been created, using Python version $(pyenv global)"
    echo "cd to the $project_name directory and start hacking!"
}


create_project
