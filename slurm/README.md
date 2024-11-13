# Slurm Learning Environment

This directory contains Docker-based Slurm cluster configurations for learning and testing purposes. It includes both basic Slurm setup and machine learning job configurations.

## Available Configurations

### 1. [Basic Slurm Setup](slurm-basic/README.md)
A minimal Slurm cluster setup to learn the basics of:
- Job submission and management
- Resource allocation
- Job arrays
- Basic monitoring and administration

```bash
cd slurm-basic
docker-compose up -d --build
```

### 2. [ML-Ready Slurm Setup](slurm-ml/README.md)
Extended Slurm configuration with Python ML libraries and example jobs showing:
- Single-node ML training
- Hyperparameter search using job arrays
- Distributed training across multiple nodes
- ML job monitoring and management

```bash
cd slurm-ml
docker-compose up -d --build
```

## Quick Start

1. Choose your configuration:
   - For learning Slurm basics: Use the basic setup
   - For ML workloads: Use the ML-ready setup

2. Navigate to the chosen directory:
```bash
# For basic setup
cd slurm-basic

# OR for ML setup
cd slurm-ml
```

3. Start the cluster:
```bash
docker-compose up -d --build
```

4. Connect to the controller node:
```bash
docker exec -it slurmctld bash
```

5. Verify the cluster:
```bash
sinfo
```

## Prerequisites

- Docker Engine installed
- Docker Compose installed
- At least 4GB RAM available
- About 10GB free disk space

## Need Help?

- Basic Slurm usage: Check the [basic setup guide](slurm-basic/README.md)
- ML jobs: See the [ML setup guide](slurm-ml/README.md)
- Slurm documentation: [Official Slurm docs](https://slurm.schedmd.com/)
