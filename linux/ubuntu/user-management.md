# 👥 User Management Commands

Essential commands for managing users and groups in Ubuntu.

## User Operations

```bash
# Create new user
sudo useradd -m -s /bin/bash username  # -m creates home directory
sudo adduser username  # More user-friendly interactive version
sudo adduser --disabled-password username  # Create new user without a password

# Create user with specific settings
sudo useradd -m -s /bin/bash -u 1500 -G sudo,docker username

# Delete user
sudo userdel username
sudo userdel -r username  # Also removes home directory

# Modify existing user
sudo usermod -aG docker username  # Add to docker group
sudo usermod -s $(which zsh) username  # Change shell
sudo usermod -L username  # Lock user account
sudo usermod -U username  # Unlock user account
```

## Password Management

```bash
# Set/change password
sudo passwd username

# Change password expiry
sudo chage -E 2024-12-31 username  # Set expiry date
sudo chage -M 90 username  # Maximum password age
sudo chage -l username  # List password policy

# Force password change at next login
sudo passwd -e username
```

## Group Management

```bash
# Create new group
sudo groupadd groupname

# Delete group
sudo groupdel groupname

# Add user to group
sudo gpasswd -a username groupname
sudo usermod -aG groupname username

# Remove user from group
sudo gpasswd -d username groupname

# List groups
groups  # Current user's groups
groups username  # Specific user's groups
```

## User Information

```bash
# View user information
id username
finger username  # If finger is installed
getent passwd username

# List all users
cut -d: -f1 /etc/passwd
awk -F: '{ print $1}' /etc/passwd

# List all groups
getent group
cat /etc/group

# Show who is logged in
who
w  # More detailed version
```

## Sudo Management

```bash
# Add user to sudoers
sudo usermod -aG sudo username

# Edit sudoers file
sudo visudo

# Grant specific permissions in sudoers
# Add to /etc/sudoers.d/username:
username ALL=(ALL) NOPASSWD: /usr/bin/docker

# Check sudo privileges
sudo -l
```

## User Limits and Quotas

```bash
# Set user limits (edit /etc/security/limits.conf)
username hard nproc 100  # Max processes
username soft nofile 4096  # Open files

# Enable disk quotas
sudo quotacheck -ugm /home
sudo quotaon -v /home

# Set disk quota
sudo edquota -u username
```
