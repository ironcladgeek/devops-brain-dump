# Base Dockerfile for Slurm nodes with ML support
FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages and Python
RUN apt-get update && apt-get install -y \
    munge \
    slurm-wlm \
    python3.10 \
    python3.10-venv \
    python3-pip \
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

# Create virtual environment and install ML packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install common ML packages
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Entry script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]