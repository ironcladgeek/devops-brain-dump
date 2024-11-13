# 🐳 Docker Guide

This guide covers essential Docker concepts and common operations for DevOps workflows.

- [🐳 Docker Guide](#-docker-guide)
  - [Installation](#installation)
    - [Installing Docker Engine (Ubuntu)](#installing-docker-engine-ubuntu)
    - [User Management](#user-management)
  - [Basic Concepts](#basic-concepts)
  - [Common Operations](#common-operations)
    - [Container Management](#container-management)
    - [Interactive Container Operations](#interactive-container-operations)
    - [Image Management](#image-management)
  - [System Maintenance](#system-maintenance)
    - [Cache and Storage Cleanup](#cache-and-storage-cleanup)
    - [Uninstall docker completely](#uninstall-docker-completely)
    - [Storage Management](#storage-management)
      - [Changing Docker Root Directory](#changing-docker-root-directory)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
    - [Performance Monitoring](#performance-monitoring)


## Installation

### Installing Docker Engine (Ubuntu)
See the official document [here](https://docs.docker.com/engine/install/ubuntu/).

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages (latest version)
sudo apt-get install docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Verify installation
sudo docker run hello-world
```

### User Management
```bash
# Add user to docker group
sudo usermod -aG docker ${USER}

# Apply group changes without logout
newgrp docker

# Verify group membership
groups ${USER}
```

## Basic Concepts

Docker provides container virtualization through several key components:

- **Docker Engine**: The core container runtime
- **Docker Images**: Read-only templates for containers
- **Docker Containers**: Running instances of images
- **Docker Registry**: Repository for storing and sharing images
- **Docker Compose**: Tool for defining multi-container applications

## Common Operations

### Container Management
```bash
# List containers
docker ps                  # Running containers
docker ps -a               # All containers

# Container lifecycle
docker start <container>   # Start a container
docker stop <container>    # Stop a container
docker restart <container> # Restart a container
docker rm <container>      # Remove a container

# Container logs
docker logs <container>    # View logs
docker logs -f <container> # Follow logs
```
### Interactive Container Operations
```bash
# Run container interactively
docker run -it <image> bash    # New container with bash shell
docker run -it --rm <image> sh # New container with sh (auto-remove after exit)

# Execute commands in running container
docker exec <container> <command>     # Run single command
docker exec -it <container> bash      # Interactive shell
docker exec -u root <container> bash  # Interactive shell as root

# Copy files between host and container
docker cp /path/to/file <container>:/path  # Host to container
docker cp <container>:/path /path/to/file  # Container to host
```

### Image Management
```bash
# List images
docker images

# Pull images
docker pull <image>:<tag>

# Remove images
docker rmi <image>
docker image prune -a      # Remove unused images

# Build image
docker build -t <name>:<tag> .
```
## System Maintenance

### Cache and Storage Cleanup
```bash
# Remove all unused containers, networks, images, and cache
docker system prune -a

# Remove specific components
docker container prune  # Remove stopped containers
docker image prune      # Remove dangling images
docker network prune    # Remove unused networks
docker volume prune     # Remove unused volumes

# Clean Docker overlay2 (use with caution!)
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```

### Uninstall docker completely

```bash
sudo apt-get purge docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### Storage Management

#### Changing Docker Root Directory
If you need to store Docker data on a different disk:

1. Stop Docker service:
```bash
sudo systemctl stop docker
```

2. Configure new storage location:
```bash
sudo vim /etc/docker/daemon.json
```
Add:
```json
{
  "data-root": "/mnt/docker"
}
```

3. Create new directory:
```bash
sudo mkdir -p /mnt/docker
```

4. Migrate existing data:
```bash
# Copy existing data
sudo rsync -avzP /var/lib/docker/ /mnt/docker

# Backup old directory
sudo mv /var/lib/docker /var/lib/docker.old
```

5. Restart Docker:
```bash
sudo systemctl start docker
```

6. Verify new location:
```bash
docker info | grep "Docker Root Dir"
```

## Troubleshooting

### Common Issues
```bash
# Check Docker service status
sudo systemctl status docker

# Check Docker disk usage
docker system df

# Display detailed system information
docker info
```

### Performance Monitoring
```bash
# Container resource usage
docker stats

# Container processes
docker top <container>

# View container configuration
docker inspect <container>
```
