#!/usr/bin/env bash


# Create a virtual environment for a new Machine Learning Python project, initialize
# the project with Poetry, and install useful ML packages.


# exit on any error
set -e


SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"


#create_Python_project() {
#    # function identical to the homonymous one in the create_Python_project.sh script
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


    PYTHON_VERSION="3.10.9"


    # best to install locally but not necessary
    # # install Python 3.10.9 if it doesn't exist
    # ############################################################################
    # PYTHON_VERSION="3.10.9"

    # # load cluster Homebrew (ex Linuxbrew)
    # # /hps/software/users/ensembl/ensw/C8-MAR21-sandybridge/envs/linuxbrew.sh
    # ################################################################################
    # export HOMEBREW_ENSEMBL_MOONSHINE_ARCHIVE=/hps/software/users/ensembl/ensw/ENSEMBL_MOONSHINE_ARCHIVE
    # export ENSEMBL_MOONSHINE_ARCHIVE=/hps/software/users/ensembl/ensw/ENSEMBL_MOONSHINE_ARCHIVE

    # export LINUXBREW_HOME=/hps/software/users/ensembl/ensw/C8-MAR21-sandybridge/linuxbrew
    # export PATH="$LINUXBREW_HOME/bin:$LINUXBREW_HOME/sbin:$PATH"
    # export MANPATH="$LINUXBREW_HOME/share/man:$MANPATH"
    # export INFOPATH="$LINUXBREW_HOME/share/info:$INFOPATH"
    # ################################################################################

    # if ! pyenv versions | grep --quiet "$PYTHON_VERSION"; then
    #     CC=gcc-10 CPPFLAGS="-I$LINUXBREW_HOME/include -I/usr/include" LDFLAGS="-L$LINUXBREW_HOME/lib -L/usr/lib64" pyenv install "$PYTHON_VERSION"
    # fi
    # ############################################################################


    # clone ML project template virtual environment
    ############################################################################
    echo "Cloning ML project template virtual environment... (Takes a few minutes.)"

    PYENV_VERSIONS_DIRECTORY="$(pyenv root)/versions"

    # use if $PYTHON_VERSION is installed locally
    #VENV_PARENT_DIRECTORY="$PYENV_VERSIONS_DIRECTORY/$PYTHON_VERSION/envs"

    #VENV_DIRECTORY="$VENV_PARENT_DIRECTORY/$PROJECT_NAME"
    VENV_DIRECTORY="$PYENV_VERSIONS_DIRECTORY/$PROJECT_NAME"

    GB_ML_PROJECT_TEMPLATE_VENV_DIRECTORY="/nfs/production/flicek/ensembl/genebuild/william/.pyenv/versions/3.10.9/envs/gb_ml_project_template"
    cp --interactive --recursive "$GB_ML_PROJECT_TEMPLATE_VENV_DIRECTORY" "$VENV_DIRECTORY"
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

    cp --interactive "$PYPROJECT_TOML_TEMPLATE" .

    git add pyproject.toml
    git commit -m "import pyproject.toml project configuration file"
    echo
    ############################################################################


    # copy Fergal's experiments notebooks
    ############################################################################
    cp --interactive --recursive /nfs/production/flicek/ensembl/genebuild/shared/ML_notebooks/Fergal_experiments .
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

    # connect to the tmux session
    tmux attach-session -t $TMUX_SESSION_NAME
    ############################################################################
}


create_ML_Jupyter_project
