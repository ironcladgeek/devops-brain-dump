#!/bin/bash

#SBATCH --job-name=dist_train
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1


# Activate virtual environment
source /opt/venv/bin/activate

# Set up distributed environment variables
export MASTER_ADDR=$(hostname)
export MASTER_PORT=29500

# Run distributed training using srun
srun python /ml_jobs/scripts/distributed_train.py