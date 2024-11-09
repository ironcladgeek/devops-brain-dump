# 🔍 System Monitoring Commands

Quick reference guide for monitoring system resources and performance on Ubuntu.

## Process Management

```bash
# View real-time process information with CPU/memory usage
top

# More user-friendly alternative to top
htop

# List all running processes
ps aux

# Find specific process
pgrep <process_name>
ps aux | grep <process_name>

# Kill process
kill <pid>
killall <process_name>
```

## Resource Usage

```bash
# Show free and used memory
free -h

# Show disk usage
df -h

# Show directory size
du -sh /path/to/directory

# IO statistics
iostat -x 1

# CPU information
lscpu

# Show system load average
uptime
```

## Network Monitoring

```bash
# Show active network connections
netstat -tupln

# Monitor network traffic in real-time
iftop
nethogs

# Test network connectivity
ping <host>
traceroute <host>

# Show routing table
route -n
```

## System Information

```bash
# Show system information
uname -a

# Show Ubuntu version
lsb_release -a

# Show uptime
uptime

# Show hardware information
lshw
```

## Real-time Monitoring

```bash
# Monitor system calls
strace <command>

# Monitor file system access
inotifywait -m /path/to/watch

# Watch command output in real-time
watch -n 1 '<command>'
```
