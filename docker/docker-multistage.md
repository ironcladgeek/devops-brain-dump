# 🏗️ Docker Multi-Stage Builds

## 📌 Table of Contents
- [What are Multi-Stage Builds?](#what-are-multi-stage-builds)
- [Benefits](#benefits)
- [Basic Syntax](#basic-syntax)
- [Best Practices](#best-practices)
- [Real-World Examples](#real-world-examples)
- [Advanced Techniques](#advanced-techniques)
- [Troubleshooting](#troubleshooting)

## What are Multi-Stage Builds?

Multi-stage builds are a feature in Docker that allows you to use multiple temporary build stages to create an optimized final image. This approach helps create smaller, more secure production images by:
- Separating build-time dependencies from runtime dependencies
- Copying only necessary artifacts from build stages
- Reducing the final image size significantly
- Improving security by excluding build tools and dependencies

## Benefits

1. **Smaller Image Size**
   - Only includes runtime dependencies
   - Excludes build tools and intermediate files
   - Reduces attack surface

2. **Better Security**
   - Fewer installed packages means fewer vulnerabilities
   - Build secrets don't persist in final image
   - Separation of build and runtime environments

3. **Simplified Build Process**
   - Single Dockerfile for both build and runtime
   - No need for separate build scripts
   - Cleaner CI/CD pipelines

## Basic Syntax

```dockerfile
# Build stage
FROM python:3.11 AS builder
WORKDIR /build
COPY . .
RUN pip install --user package1 package2

# Final stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local/lib/python3.11/site-packages /root/.local/lib/python3.11/site-packages
COPY app.py .
CMD ["python", "app.py"]
```

## Best Practices

1. **Name Your Stages**
```dockerfile
# Use meaningful names for stages
FROM node:18 AS dependencies
FROM node:18-slim AS builder
FROM nginx:alpine AS production
```

2. **Optimize Layer Caching**
```dockerfile
# Copy dependency files first
COPY package.json package-lock.json ./
RUN npm install
# Then copy source code
COPY . .
```

3. **Use Specific Base Images**
```dockerfile
# Avoid :latest tag
FROM python:3.11-slim-bookworm AS production
```

4. **Minimize Number of Layers**
```dockerfile
# Combine related commands
RUN apt-get update && \
    apt-get install -y --no-install-recommends package1 package2 && \
    rm -rf /var/lib/apt/lists/*
```

5. **Keep Build Stages Focused**
```dockerfile
# Separate concerns between stages
FROM maven AS build
FROM sonar AS test
FROM openjdk:11-jre-slim AS production
```

## Real-World Examples

### Python Web Application

```dockerfile
# Stage 1: Build dependencies
FROM python:3.11 AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Production image
FROM python:3.11-slim

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Create non-root user
RUN useradd --create-home appuser
WORKDIR /home/appuser
USER appuser

# Copy application code
COPY --chown=appuser:appuser ./app .

# Run the application
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:8000"]
```

### Development vs Production Builds

```dockerfile
# Base stage for shared configurations
FROM python:3.11-slim AS base
WORKDIR /app
COPY requirements.txt .

# Development stage
FROM base AS development
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000", "--debug"]

# Production stage
FROM base AS production
RUN pip install --no-cache-dir --production -r requirements.txt
COPY . .
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:8000"]
```

## Advanced Techniques

### 1. Using Build Arguments
```dockerfile
# Allow customization of base images
ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION} AS builder

# Pass build arguments between stages
ARG BUILD_VERSION
RUN echo ${BUILD_VERSION} > version.txt
```

### 2. Conditional Stages
```dockerfile
# Build stage selection
FROM base AS final
ARG ENVIRONMENT=production
RUN if [ "$ENVIRONMENT" = "development" ] ; then \
        echo "Installing development packages..." ; \
        pip install pytest debugpy ; \
    fi
```

### 3. Multi-Architecture Builds
```dockerfile
# Build for multiple platforms
FROM --platform=$BUILDPLATFORM python:3.11 AS builder
ARG TARGETPLATFORM
RUN echo "Building for $TARGETPLATFORM"
```

## Troubleshooting

Common issues and solutions:

1. **Large Final Image**
```bash
# Check image size and layers
docker image history --no-trunc <image>
docker image ls

# Use specific base images instead of full ones
FROM python:3.11-slim instead of FROM python:3.11
```

2. **Build Context Issues**
```dockerfile
# Use .dockerignore to exclude unnecessary files
# Example .dockerignore
__pycache__
*.pyc
.git
.env
venv/
```

3. **Layer Caching Problems**
```dockerfile
# Order commands from least to most frequently changing
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .  # Source code changes frequently, put it last
```

## Running Multi-Stage Builds

```bash
# Build final stage
docker build -t myapp:latest .

# Build specific stage
docker build --target builder -t myapp:builder .

# Build with build arguments
docker build --build-arg ENVIRONMENT=development -t myapp:dev .
```
