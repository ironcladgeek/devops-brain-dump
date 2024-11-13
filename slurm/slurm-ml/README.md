# Machine Learning Jobs on Slurm Cluster

This guide explains how to run various types of machine learning jobs on our Slurm cluster setup. It provides examples of single-node training, hyperparameter search using job arrays, and distributed training across multiple nodes.

## Directory Structure
```
.
├── ml_jobs/
│   ├── scripts/                   # ML training scripts
│   │   ├── train_classifier.py    # Single-node basic classifier
│   │   ├── param_search.py        # Hyperparameter search (array job)
│   │   └── distributed_train.py   # Multi-node distributed training
│   └── submit/                    # Slurm submission scripts
│       ├── submit_train.sh        # Submit single-node job
│       ├── submit_param_search.sh # Submit array job
│       └── submit_distributed.sh  # Submit distributed job
├── requirements.txt               # Python dependencies
└── shared/                        # Shared storage for all nodes
    ├── logs/                      # Job output logs
    ├── models/                    # Saved models
    └── results/                   # Training results
```

## Setup

1. Build the cluster with ML support:
```bash
docker-compose up -d --build
```

2. Verify ML environment:
```bash
docker exec -it slurmctld bash
python3 -c "import torch; print(f'PyTorch version: {torch.__version__}')"
```

## Types of ML Jobs

### 1. Single-Node Training (`train_classifier.py`)
Basic classifier training on a single node.

Features:
- Random Forest classifier on synthetic data
- Model saving and metrics logging
- Progress tracking

Run with:
```bash
sbatch ml_jobs/submit/submit_train.sh
```

### 2. Hyperparameter Search (`param_search.py`)
Uses Slurm job arrays to parallelize hyperparameter search.

Features:
- Multiple parameter combinations
- Parallel evaluation
- Results aggregation

Run with:
```bash
sbatch ml_jobs/submit/submit_param_search.sh
```

Monitor array tasks:
```bash
squeue -r  # Show individual array tasks
```

### 3. Distributed Training (`distributed_train.py`)
Multi-node distributed training using PyTorch DDP.

Features:
- Distributed data parallel training
- Synchronized model updates
- Per-node progress logging

Run with:
```bash
sbatch ml_jobs/submit/submit_distributed.sh
```

Monitor nodes:
```bash
tail -f /shared/logs/nodes/node_*_log.txt  # Monitor all nodes
```

## Job Types Comparison

### Array Jobs
- **Purpose**: Run same code with different parameters
- **Use Case**: Hyperparameter search, cross-validation
- **Data**: Independent data per task
- **Communication**: No inter-task communication
- **Fault Tolerance**: Individual tasks can fail independently
- **Submit Script Example**:
```bash
#SBATCH --array=0-3
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
```

### Distributed Jobs
- **Purpose**: Single training job across multiple nodes
- **Use Case**: Large model training, distributed SGD
- **Data**: Shared/distributed across nodes
- **Communication**: Continuous inter-node communication
- **Fault Tolerance**: Entire job fails if any node fails
- **Submit Script Example**:
```bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
```

## Monitoring and Logs

### Job Output
Each job type has different logging patterns:

1. Single Node Jobs:
```bash
tail -f slurm-*_train.out
```

2. Array Jobs:
```bash
# Monitor specific array task
tail -f slurm-*_[array_task_id].out
```

3. Distributed Jobs:
```bash
# Monitor all nodes
tail -f /shared/logs/nodes/node_*_log.txt
```

### Training Progress
```bash
# View saved models
ls -l /shared/models/

# Check results
cat /shared/results/distributed_training_results_*.txt
```

## Troubleshooting

1. Node Communication Issues:
```bash
# Check network connectivity
srun --nodes=2 hostname

# Verify distributed setup
python -c "import torch.distributed as dist; print(dist.is_available())"
```

2. Memory Issues:
```bash
# Monitor memory usage
sstat -j <jobid> --format=JobID,MaxRSS,MaxVMSize

# Adjust batch size in code if needed
```

3. Failed Tasks in Array Jobs:
```bash
# Rerun failed array tasks
sacct -j <jobid> --format=JobID,State
sbatch --array=<failed_indices> submit_script.sh
```

## Resource Management

1. Check available resources:
```bash
sinfo -o "%n %c %m"  # Show nodes, CPUs, and memory
```

2. Monitor job resource usage:
```bash
sstat -j <jobid> --format=JobID,AveCPU,AveRSS,AveVMSize
```

3. Cancel jobs:
```bash
scancel <jobid>  # Cancel specific job
scancel -u $USER  # Cancel all your jobs
```

This setup provides a comprehensive environment for running various types of ML workloads on a Slurm cluster, from simple single-node training to complex distributed training scenarios.
