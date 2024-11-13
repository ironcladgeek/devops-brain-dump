# 🐳 Docker Compose Guide

## What is Docker Compose?
Docker Compose is a tool for defining and running multi-container Docker applications. It uses YAML files to configure application services and makes it easy to manage complex applications with multiple interconnected containers.

## Installation

```bash
# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install -y docker-compose-plugin

# Verify installation
docker compose version
```

## Basic Usage

### Example docker-compose.yml
```yaml
version: '3.8'
services:
  web:
    build: ./web
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/myapp
    depends_on:
      - db

  db:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=postgres

volumes:
  postgres_data:
```

### Common Commands
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# List services
docker compose ps

# Execute command in service
docker compose exec <service> <command>

# Build services
docker compose build

# Pull service images
docker compose pull
```

## Key Concepts

### Services
Services are the containers that make up your application. Each service is defined in the `docker-compose.yml` file and can be built from a Dockerfile or based on an existing image.

### Networks
Docker Compose automatically creates a network for your application. Services can communicate using their service names as hostnames.

```yaml
services:
  web:
    networks:
      - frontend
      - backend
  db:
    networks:
      - backend

networks:
  frontend:
  backend:
```

### Volumes
Volumes persist data and share files between host and containers:

```yaml
services:
  db:
    volumes:
      - db-data:/var/lib/postgresql/data  # Named volume
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql  # Bind mount

volumes:
  db-data:  # Volume definition
```

## Environment Variables
You can use environment variables in your compose file:

```yaml
services:
  web:
    image: nginx
    ports:
      - "${PORT}:80"  # Use .env file or shell environment
```

Create a `.env` file:
```bash
PORT=8080
DB_PASSWORD=secret
```

## Dependencies
Use `depends_on` to control startup order:

```yaml
services:
  web:
    depends_on:
      - db
      - redis
  db:
    image: postgres
  redis:
    image: redis
```
