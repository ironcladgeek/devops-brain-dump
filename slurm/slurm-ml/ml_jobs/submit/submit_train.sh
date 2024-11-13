#!/bin/bash

#SBATCH --job-name=ml_train

# Activate virtual environment
source /opt/venv/bin/activate

# Run training script using absolute path
python /ml_jobs/scripts/train_classifier.py
