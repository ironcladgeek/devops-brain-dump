# Setting Up a Slurm Learning Environment with Docker

This guide will help you create a local Slurm cluster using Docker containers. This setup provides a perfect environment for learning Slurm without the overhead of managing multiple physical or virtual machines.

## Prerequisites

- Docker Engine installed
- Docker Compose installed
- At least 4GB RAM available
- About 10GB free disk space

## Setup Instructions

1. Required files:
```bash
.
├── Dockerfile
├── config
│   └── slurm.conf
├── docker-compose.yaml
└── docker-entrypoint.sh
```

2. Build and start the cluster:
```bash
docker-compose up -d --build
```

1. Verify the cluster is running:
```bash
# Check running containers
docker ps

# Should show three containers:
# - slurmctld (controller)
# - slurmd1 (worker)
# - slurmd2 (worker)
```

## Basic Usage

1. Connect to the controller node:
```bash
docker exec -it slurmctld bash
```

2. Check cluster status:
```bash
sinfo
```
This should show your nodes and their states.

3. Submit your first job:
```bash
# Create a test job
echo '#!/bin/bash
hostname
date
sleep 10' > /shared/test.sh
chmod +x /shared/test.sh

# Submit the job
sbatch /shared/test.sh
```

4. Monitor jobs:
```bash
# View job queue
squeue

# View job history
sacct
```

## Common Slurm Commands

1. Resource allocation:
```bash
# Interactive shell on a compute node
srun --pty bash

# Run command on all nodes
srun -N2 hostname

# Allocate specific resources
srun --cpus-per-task=2 --mem=512 hostname
```

2. Job arrays:
```bash
# Create an array job script
echo '#!/bin/bash
echo "Task ID: $SLURM_ARRAY_TASK_ID"
sleep 5' > /shared/array.sh
chmod +x /shared/array.sh

# Submit array job
sbatch --array=1-4 /shared/array.sh
```

3. Job management:
```bash
# Cancel a job
scancel <job_id>

# Hold a job
scontrol hold <job_id>

# Release a held job
scontrol release <job_id>
```

## Using the Shared Directory

The `shared` directory is mounted in all containers at `/shared`. Use this to:
- Store job scripts
- Share input/output files between nodes
- Store results

Example workflow:
```bash
# On your host machine, create a job script
echo '#!/bin/bash
echo "Running on node: $(hostname)"
date
sleep 30
echo "Job completed"' > shared/long_job.sh

# In the container
chmod +x /shared/long_job.sh
sbatch /shared/long_job.sh
```

## Maintenance Tasks

1. Restart the cluster:
```bash
docker-compose restart
```

2. Stop the cluster:
```bash
docker-compose down
```

3. View logs:
```bash
# Controller logs
docker logs slurmctld

# Worker logs
docker logs slurmd1
docker logs slurmd2
```

4. Reset everything:
```bash
docker-compose down -v
docker-compose up -d --build
```

## Best Practices

1. Always use the `/shared` directory for job scripts and data files
2. Monitor resource usage with `sinfo -o "%n %c %m"` to see CPU and memory per node
3. Use job arrays for multiple similar tasks
4. Write job scripts with proper error handling and output logging
5. Use appropriate Slurm directives in job scripts:
```bash
#SBATCH --job-name=my_job
#SBATCH --output=/shared/logs/%j.out
#SBATCH --error=/shared/logs/%j.err
#SBATCH --time=01:00:00
```

## Troubleshooting

1. If nodes show as DOWN:
```bash
scontrol update nodename=slurmd1 state=resume
```

2. If jobs are stuck in pending state:
```bash
# Check reason
squeue -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"
```

3. Check node health:
```bash
scontrol show node slurmd1
```

This setup provides a realistic Slurm environment for learning cluster computing concepts, job scheduling, and resource management without the complexity of managing multiple machines.
