# Base Dockerfile for Slurm nodes
FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install only the essential packages
RUN apt-get update && apt-get install -y \
    munge \
    slurm-wlm \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories and setup munge
RUN mkdir -p /var/run/munge \
    && mkdir -p /var/lib/slurm/slurmd \
    && mkdir -p /var/log/slurm \
    && mkdir -p /var/spool/slurmd \
    && mkdir -p /etc/slurm \
    && chown munge:munge /var/run/munge \
    && dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key \
    && chown munge:munge /etc/munge/munge.key \
    && chmod 400 /etc/munge/munge.key

# Entry script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
