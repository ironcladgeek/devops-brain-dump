# 🔐 SSH Configuration Guide

Complete guide for SSH setup, management, and configuration for various Git platforms.

## Basic SSH Commands

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"
# For legacy systems:
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add SSH key to agent
ssh-add ~/.ssh/id_ed25519

# List added keys
ssh-add -l

# Test SSH connection
ssh -T git@github.com
ssh -T git@gitlab.com
ssh -T git@bitbucket.org
```

## SSH Config File Setup

```bash
# Create/edit SSH config file
nano ~/.ssh/config

# Basic SSH config template
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60

# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_ed25519
    IdentitiesOnly yes

# GitLab configuration
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/gitlab_ed25519
    IdentitiesOnly yes

# BitBucket configuration
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/bitbucket_ed25519
    IdentitiesOnly yes
```

## Platform-Specific Setup

### GitHub Setup

```bash
# Generate GitHub-specific key
ssh-keygen -t ed25519 -C "your.email@github.com" -f ~/.ssh/github_ed25519

# Copy public key
cat ~/.ssh/github_ed25519.pub

# Add to GitHub:
# 1. Go to GitHub → Settings → SSH and GPG keys
# 2. Click "New SSH key"
# 3. Paste your public key
# 4. Give it a meaningful title

# Test connection
ssh -T git@github.com
```

### GitLab Setup

```bash
# Generate GitLab-specific key
ssh-keygen -t ed25519 -C "your.email@gitlab.com" -f ~/.ssh/gitlab_ed25519

# Copy public key
cat ~/.ssh/gitlab_ed25519.pub

# Add to GitLab:
# 1. Go to GitLab → Preferences → SSH Keys
# 2. Paste your public key
# 3. Add title and expiration date (optional)

# Test connection
ssh -T git@gitlab.com
```

### BitBucket Setup

```bash
# Generate BitBucket-specific key
ssh-keygen -t ed25519 -C "your.email@bitbucket.org" -f ~/.ssh/bitbucket_ed25519

# Copy public key
cat ~/.ssh/bitbucket_ed25519.pub

# Add to BitBucket:
# 1. Go to BitBucket → Personal Settings → SSH Keys
# 2. Click "Add key"
# 3. Paste your public key
# 4. Add label

# Test connection
ssh -T git@bitbucket.org
```

## SSH Key Management

```bash
# List all SSH keys
ls -la ~/.ssh/

# Check key fingerprint
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Convert OpenSSH to PEM format (if needed)
ssh-keygen -e -m PEM -f ~/.ssh/id_ed25519 > id_ed25519.pem

# Remove key from SSH agent
ssh-add -d ~/.ssh/id_ed25519

# Clear all keys from SSH agent
ssh-add -D
```

## Security Best Practices

```bash
# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Create backup of SSH keys
tar -czf ssh_backup.tar.gz ~/.ssh/
```

## Troubleshooting

```bash
# Debug SSH connection
ssh -vv git@github.com

# Check SSH agent
ssh-add -l

# Verify key permissions
ls -la ~/.ssh/

# Reset SSH connection
ssh-keygen -R github.com
ssh-keygen -R gitlab.com
ssh-keygen -R bitbucket.org

# Common fixes
# Fix "permissions too open" error:
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519

# Fix "Could not open a connection to your authentication agent"
eval "$(ssh-agent -s)"
```

## Multiple Accounts Setup

```bash
# SSH config for multiple accounts
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_personal
    IdentitiesOnly yes

Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_work
    IdentitiesOnly yes

# Usage with multiple accounts
git clone git@github-personal:username/repo.git
git clone git@github-work:company/repo.git

# Set local git config for different emails
git config user.email "personal@example.com"
git config user.email "work@company.com"
```
