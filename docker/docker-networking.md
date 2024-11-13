# 🌐 Docker Networking Guide

## Network Types

### 1. Bridge Networks
Default network type for containers. Containers can communicate with each other on the same bridge network.

```bash
# Create bridge network
docker network create mynetwork

# Run container with network
docker run --network mynetwork nginx

# List networks
docker network ls

# Inspect network
docker network inspect mynetwork
```

### 2. Host Network
Container shares host's network namespace. No network isolation.

```bash
docker run --network host nginx
```

### 3. None Network
No networking. Container is isolated.

```bash
docker run --network none nginx
```

### 4. Overlay Networks
Multi-host networking for Docker Swarm.

```bash
docker network create -d overlay myoverlay
```

## Common Network Operations

```bash
# Connect container to network
docker network connect mynetwork container1

# Disconnect container from network
docker network disconnect mynetwork container1

# Remove network
docker network rm mynetwork

# Prune unused networks
docker network prune
```

## Network Configuration in Docker Compose

```yaml
version: '3.8'
services:
  web:
    networks:
      frontend:
        ipv4_address: 172.16.238.10
      backend:
  
  db:
    networks:
      backend:
        ipv4_address: 172.16.238.20

networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.238.0/24
  backend:
    driver: bridge
    internal: true  # No internet access
```

## Network Troubleshooting

### 1. DNS Resolution
```bash
# Check DNS resolution from container
docker exec container1 ping container2

# Inspect DNS settings
docker exec container1 cat /etc/resolv.conf
```

### 2. Network Connectivity
```bash
# Check network connectivity
docker exec container1 wget -O- http://container2:port

# Network statistics
docker exec container1 netstat -tupln
```

### 3. Port Mapping
```bash
# List port mappings
docker port container1

# Check listening ports
docker exec container1 ss -tunlp
```

## Best Practices

1. **Use Custom Bridge Networks**: Instead of the default bridge
2. **Network Segmentation**: Separate front-end and back-end networks
3. **Internal Networks**: Use internal networks for databases
4. **Service Discovery**: Use Docker's built-in DNS
5. **Security**: Limit exposed ports and use internal networks when possible
