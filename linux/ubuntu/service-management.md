# 🔄 Service Management Commands (systemd)

Comprehensive guide for managing services with systemd.

## Basic Service Control

```bash
# Start service
sudo systemctl start service_name

# Stop service
sudo systemctl stop service_name

# Restart service
sudo systemctl restart service_name

# Reload service configuration
sudo systemctl reload service_name

# Enable service at boot
sudo systemctl enable service_name

# Disable service at boot
sudo systemctl disable service_name

# Check if service is running
systemctl status service_name
```

## Service Status and Information

```bash
# Show all running services
systemctl list-units --type=service

# Show all services (including inactive)
systemctl list-units --type=service --all

# Show failed services
systemctl --failed

# Check if service is enabled
systemctl is-enabled service_name

# Show service dependencies
systemctl list-dependencies service_name

# Show service properties
systemctl show service_name
```

## Service Logs

```bash
# View service logs
journalctl -u service_name

# Follow service logs
journalctl -u service_name -f

# Show logs since last boot
journalctl -u service_name -b

# Show logs with timestamps
journalctl -u service_name --output=short-precise

# Filter logs by time
journalctl -u service_name --since "2024-01-01" --until "2024-01-02"
```

## Creating Custom Services

```bash
# Create new service file
sudo nano /etc/systemd/system/myapp.service

# Basic service template
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=myapp
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/python3 /opt/myapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target

# Reload systemd after creating/modifying services
sudo systemctl daemon-reload
```

## Service Management Tips

```bash
# Mask service (prevent starting)
sudo systemctl mask service_name

# Unmask service
sudo systemctl unmask service_name

# Reset failed service status
sudo systemctl reset-failed service_name

# Check service configuration
systemctl cat service_name

# Edit service configuration
sudo systemctl edit service_name
sudo systemctl edit --full service_name
```

## Resource Control

```bash
# Set service resource limits
sudo systemctl set-property service_name CPUQuota=200%
sudo systemctl set-property service_name MemoryLimit=1G

# Show service resource usage
systemctl status service_name
systemd-cgtop
```
