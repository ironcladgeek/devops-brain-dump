#!/bin/bash

#SBATCH --job-name=param_search
#SBATCH --array=0-3

source /opt/venv/bin/activate
python /ml_jobs/scripts/param_search.py
