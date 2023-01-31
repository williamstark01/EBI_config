#!/usr/bin/env bash


# Create a virtual environment for a new Python project and initialize the project with Poetry.


# exit on any error
set -e


SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"


#create_Python_project() {
#    # function identical to the hononumous one in the create_Python_project.sh script
#<...>
#}
#create_Python_project


install_ml_packages() {
    # NOTE
    # There is an issue with automating the `poetry add <...>` command, see
    # https://github.com/python-poetry/poetry/issues/651
    # https://python-poetry.org/docs/configuration/#virtualenvsprefer-active-python-experimental

    echo "Installing Machine Learning packages..."

    poetry add biopython jupyterlab matplotlib numpy pandas pytorch-lightning scikit-learn tensorflow torch

    echo
}
#install_ml_packages


create_ML_Jupyter_project() {
    read -p "How should the project be called? " PROJECT_NAME
    echo


    # create project directory and git repository
    ############################################################################
    mkdir $PROJECT_NAME
    cd $PROJECT_NAME

    echo "Creating a git repository for the project..."
    git init
    git checkout -b main

    cp "$SCRIPT_DIRECTORY/.gitignore" .
    git add .gitignore
    git commit -m "add .gitignore"
    echo
    ############################################################################


    # clone ML project template virtual environment
    ############################################################################
    echo "Cloning ML project template virtual environment... (Takes a few minutes.)"

    PYENV_VERSIONS_DIRECTORY="$(pyenv root)/versions"

    # # create directory structure for the new virtual environment
    # VENV_PARENT_DIRECTORY="$PYENV_VERSIONS_DIRECTORY/3.10.9/envs"
    # mkdir --parents --verbose "$VENV_PARENT_DIRECTORY"

    #VENV_DIRECTORY="$VENV_PARENT_DIRECTORY/$PROJECT_NAME"
    VENV_DIRECTORY="$PYENV_VERSIONS_DIRECTORY/$PROJECT_NAME"

    GB_ML_PROJECT_TEMPLATE_VENV_DIRECTORY="/nfs/production/flicek/ensembl/genebuild/william/.pyenv/versions/3.10.9/envs/gb_ml_project_template"
    cp --interactive --preserve --recursive "$GB_ML_PROJECT_TEMPLATE_VENV_DIRECTORY" "$VENV_DIRECTORY"
    #ln --symbolic "$VENV_DIRECTORY" "$PYENV_VERSIONS_DIRECTORY"

    pyenv local "$PROJECT_NAME"
    echo

    git add .python-version
    git commit -m "specify virtual environment"
    echo
    ############################################################################


    # clone Poetry pyproject.toml template configuration
    ############################################################################
    echo "Cloning Poetry pyproject.toml template configuration..."

    PYPROJECT_TOML_TEMPLATE="/nfs/production/flicek/ensembl/genebuild/william/ML_Jupyter/gb_ml_project_template/pyproject.toml"

    cp --interactive --preserve "$PYPROJECT_TOML_TEMPLATE" .

    git add pyproject.toml
    git commit -m "import pyproject.toml project configuration file"
    echo
    ############################################################################


    # copy Fergal's experiments notebooks
    ############################################################################
    cp --interactive --preserve --recursive /nfs/production/flicek/ensembl/genebuild/shared/ML_notebooks/Fergal_experiments .
    ############################################################################


    # create a tmux session and start the JupyterLab server
    ############################################################################
    TMUX_SESSION_NAME=$PROJECT_NAME

    # create a detached tmux session
    tmux new-session -d -s "$TMUX_SESSION_NAME" -n "jupyterlab"

    # run a JupyterLab server bsub job in the tmux session
    MEM_LIMIT=16384
    PORT=54321
    JUPYTERLAB_BSUB_JOB="bsub -q production -M $MEM_LIMIT -Is -tty jupyter-lab --port=$PORT --no-browser --ip 0.0.0.0"
    tmux send-keys -t "${TMUX_SESSION_NAME}:jupyterlab" "$JUPYTERLAB_BSUB_JOB" ENTER
    ############################################################################
}


create_ML_Jupyter_project
