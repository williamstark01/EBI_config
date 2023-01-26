#!/usr/bin/env bash


# Create a virtual environment for a new Python project and initialize the project with Poetry.


# exit on any error
set -e


# create_Python_project() {
# <...>
# }


install_ml_packages() {
    echo "Installing Machine Learning packages..."

    poetry add biopython jupyterlab matplotlib numpy pandas pytorch-lightning scikit-learn tensorflow torch

    echo
}


# NOTE
# There is an issue with automating the `poetry add <...>` command, see
# https://github.com/python-poetry/poetry/issues/651
# https://python-poetry.org/docs/configuration/#virtualenvsprefer-active-python-experimental
#install_ml_packages
