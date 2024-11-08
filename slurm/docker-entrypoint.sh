#!/bin/bash

# Start munge
service munge start

# Start the appropriate Slurm daemon based on node type
case "$SLURM_NODE_TYPE" in
    "controller")
        echo "Starting slurmctld..."
        service slurmctld start
        ;;
    "worker")
        echo "Starting slurmd..."
        service slurmd start
        ;;
    *)
        echo "Unknown node type: $SLURM_NODE_TYPE"
        exit 1
        ;;
esac

# Keep container running
tail -f /dev/null
