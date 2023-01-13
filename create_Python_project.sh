#!/usr/bin/env bash


# Create a virtual environment for a new Python project and initialize the project with Poetry.


# exit on any error
set -e


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

    echo "Creating a dedicated Python virtual environment for the project $project_name..."
    pyenv virtualenv "$project_name"
    pyenv local "$project_name"
    echo "Upgrading the pip module..."
    pip install --upgrade pip
    echo

    echo "Initializing the project with Poetry..."
    poetry init --no-interaction --quiet --name $project_name
    echo

    echo "Creating a git repository and importing the project files..."
    git init
    git checkout -b main
    git add .python-version pyproject.toml
    git commit -m "import project files"
    echo

    echo "The project has been created, using Python version $(pyenv global)"
    echo "cd to the $project_name directory and start hacking!"
}


create_project
