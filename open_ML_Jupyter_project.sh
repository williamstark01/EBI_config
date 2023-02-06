#!/usr/bin/env bash


# Start JupyterLab server for an existing Genebuild Machine Learning project.


# exit on any error
set -e


MEM_LIMIT=16384
PORT=54321
bsub -q production -M $MEM_LIMIT -Is -tty jupyter-lab --port=$PORT --no-browser --ip 0.0.0.0
