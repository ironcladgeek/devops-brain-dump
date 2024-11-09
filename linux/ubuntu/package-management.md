# 📦 Package Management Commands

Essential Ubuntu package management commands.

## APT Commands

```bash
# Update package list
sudo apt update

# Upgrade installed packages
sudo apt upgrade
sudo apt full-upgrade

# Install package
sudo apt install package_name

# Remove package
sudo apt remove package_name
sudo apt purge package_name  # Remove with config files

# Search for package
apt search package_name

# Show package information
apt show package_name

# List installed packages
apt list --installed
dpkg -l
```

## Package Maintenance

```bash
# Clean up unused packages
sudo apt autoremove

# Clear package cache
sudo apt clean
sudo apt autoclean

# Fix broken installations
sudo apt --fix-broken install

# Hold package version (prevent updates)
sudo apt-mark hold package_name
sudo apt-mark unhold package_name

# Add PPA repository
sudo add-apt-repository ppa:repository_name
```

## DEB Package Operations

```bash
# Install .deb package
sudo dpkg -i package.deb

# Remove .deb package
sudo dpkg -r package_name

# List files in package
dpkg -L package_name

# Find which package owns a file
dpkg -S /path/to/file
```

## Repository Management

```bash
# List repositories
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/

# Backup repositories
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Remove repository
sudo add-apt-repository --remove ppa:repository_name
```
