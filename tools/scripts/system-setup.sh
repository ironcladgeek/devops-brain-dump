#!/bin/bash

# ===========================================
# Server Setup and User Management Script
# ===========================================
#
# This script automates the setup of Docker, ZSH, and user management on Ubuntu servers.
# It handles Docker installation, ZSH configuration, and creation of non-sudo users with
# SSH access and Docker permissions.
#
# Features:
# ---------
# 1. Docker Setup:
#    - Installs Docker Engine and related packages
#    - Configures docker group and permissions
#
# 2. ZSH Setup:
#    - Installs ZSH and Oh My Zsh
#    - Configures useful plugins (autosuggestions, syntax-highlighting)
#    - Sets up environment variables
#
# 3. User Management:
#    - Creates non-sudo users
#    - Generates and configures SSH keys
#    - Sets up ZSH for new users
#    - Adds users to docker group
#    - Packages SSH keys for easy distribution
#
# Requirements:
# ------------
# - Ubuntu Server
# - Root/sudo access
# - Internet connection
#
# Usage Examples:
# --------------
# 1. Install Docker:
#    sudo ./system-setup.sh --docker
#
# 2. Install ZSH for ubuntu user:
#    sudo ./system-setup.sh --zsh
#
# 3. Create new user with all configurations:
#    sudo ./system-setup.sh --create-user john
#
# 4. Download SSH keys for existing user:
#    sudo ./system-setup.sh --download-keys john
#
# 5. Multiple operations:
#    sudo ./system-setup.sh --docker --zsh --create-user john
#
# Output Files:
# ------------
# For each new user, the script generates:
# - OpenSSH private key (id_ed25519.pem)
# - OpenSSH public key (id_ed25519.pub)
# - PuTTY private key (id_ed25519.ppk)
# - SSH configuration instructions
#
# File Locations:
# --------------
# - User SSH directory: /home/<username>/.ssh/
# - Admin copies: /home/ubuntu/user_ssh_keys/<username>/
# - SSH archives: /home/ubuntu/ssh_archives/
#
# Notes:
# ------
# - Users are created without sudo access
# - SSH password authentication is disabled
# - All users get ZSH as their default shell
# - All users are added to the docker group
# - Keys are provided in both OpenSSH and PuTTY formats

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Function to print usage
print_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  --install-docker            Install Docker and related packages"
    echo "  --install-zsh               Install and configure ZSH for ubuntu user"
    echo "  --create-user USERNAME      Create a new user with ZSH and Docker access"
    echo "  --download-keys USERNAME    Create downloadable archive of user's SSH keys"
    exit 1
}

# Function to install Docker
install_docker() {
    echo "Installing Docker..."

    # Remove old versions
    apt-get remove docker docker-engine docker.io containerd runc

    # Install prerequisites
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    echo ""
    echo "✅ Docker installation completed"
    echo "Please log out and log back in for all changes to take effect."
}

# Function to install and configure ZSH
install_zsh() {
    local user=$1
    local home_dir=$(eval echo ~$user)

    echo "Installing ZSH for user $user..."

    # Install ZSH
    apt-get update
    apt-get install -y zsh curl git

    # Install Oh My Zsh
    su - $user -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'

    # Install plugins
    su - $user -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'
    su - $user -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting'

    # Configure .zshrc
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $home_dir/.zshrc

    # Add environment variables
    echo 'export EDITOR="vim"' >>$home_dir/.zshrc
    echo 'export PATH=$HOME/bin:/usr/local/bin:$PATH' >>$home_dir/.zshrc

    # Change default shell to zsh
    chsh -s $(which zsh) $user

    echo "ZSH installation completed for user $user"
}

# Function to install uv package manager
install_uv() {
    local username=$1
    local home_dir=$(eval echo ~$username)

    echo "Installing uv package manager for user $username..."

    # Install curl if not present
    apt-get install -y curl

    # Create .local/bin directory if it doesn't exist
    su - $username -c 'mkdir -p ~/.local/bin'

    # Download and install uv using official installer
    su - $username -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

    # Add uv to PATH in .zshrc if not already present
    su - $username -c 'echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.zshrc'

    # Source .zshrc to make uv available in current session
    su - $username -c 'source ~/.zshrc'

    # Set permissions
    chown -R $username:$username "$home_dir/.local"
    chmod -R 755 "$home_dir/.local/bin"

    echo "uv installation completed for user $username"
}

# Function to ensure required packages are installed
ensure_packages() {
    apt-get update
    apt-get install -y zip putty-tools curl
}

# Function to get public IP
get_public_ip() {
    curl -s ifconfig.me
}

# Function to package SSH keys for easy download
package_ssh_keys() {
    local username=$1
    local key_dir="/home/ubuntu/user_ssh_keys/$username"
    local archives_dir="/home/ubuntu/ssh_archives"
    local archive_name="${username}_ssh_keys.zip"
    local archive_path="$archives_dir/$archive_name"
    local server_ip=$(get_public_ip)

    # Ensure archives directory exists
    mkdir -p "$archives_dir"
    chown ubuntu:ubuntu "$archives_dir"
    chmod 700 "$archives_dir"

    # Create PPK format for PuTTY
    puttygen "/home/$username/.ssh/id_ed25519.pem" -o "$key_dir/id_ed25519.ppk"
    chmod 600 "$key_dir/id_ed25519.ppk"
    chown ubuntu:ubuntu "$key_dir/id_ed25519.ppk"

    # Create SSH config instructions file
    cat >"$key_dir/ssh_config_instructions.txt" <<EOF
=== For Linux/Mac Users ===
# Add this to your ~/.ssh/config file:

Host ${username}-server
    HostName $server_ip
    User $username
    IdentityFile ~/.ssh/id_ed25519.pem

# Then you can connect using:
ssh ${username}-server


=== For Windows Users (PuTTY) ===
1. Open PuTTY
2. In the 'Session' category:
   - Host Name: $server_ip
   - Port: 22
   - Connection type: SSH

3. In the 'Connection > Data' category:
   - Auto-login username: $username

4. In the 'Connection > SSH > Auth > Credentials' category:
   - Private key file: Browse and select id_ed25519.ppk

5. Back in 'Session':
   - Enter '${username}-server' in 'Saved Sessions'
   - Click 'Save' to store these settings

6. Click 'Open' to connect

Note: To avoid entering these settings again, you can save them and simply double-click the saved session next time.
EOF

    # Create zip archive
    cd "/home/ubuntu/user_ssh_keys"
    zip -j "$archive_path" \
        "$username/id_ed25519.pem" \
        "$username/id_ed25519.pub" \
        "$username/id_ed25519.ppk" \
        "$username/ssh_config_instructions.txt"
    chown ubuntu:ubuntu "$archive_path"
    chmod 600 "$archive_path"

    echo "SSH keys packaged for download!"
    echo "Download using one of these commands from your local machine:"
    echo "  scp ubuntu@$server_ip:~/ssh_archives/$archive_name ."
    echo "  sftp ubuntu@$server_ip:~/ssh_archives/$archive_name"
    echo ""
    echo "Archive location on server: $archive_path"
    echo "⚠️  IMPORTANT: Delete the archive after downloading using:"
    echo "  rm $archive_path"
    echo ""
    echo "📝 Add this to your ~/.ssh/config file on your local machine:"
    echo "Host ${username}-server"
    echo "    HostName $server_ip"
    echo "    User $username"
    echo "    IdentityFile ~/.ssh/id_ed25519.pem"
    echo ""
    echo "Then you can connect using:"
    echo "  ssh ${username}-server"
}

# Function to create new user
create_user() {
    local username=$1

    if [ -z "$username" ]; then
        echo "Error: Username is required"
        print_usage
    fi

    # Check for required packages first
    ensure_packages

    echo "Creating user $username..."

    # Create user with adduser (non-interactive)
    adduser --disabled-password --gecos "" $username

    # Disable password login
    passwd -d $username

    # Create and set up .ssh directory with correct permissions
    local ssh_dir="/home/$username/.ssh"
    mkdir -p $ssh_dir
    chown $username:$username $ssh_dir
    chmod 700 $ssh_dir

    # Generate SSH key as the user
    su - $username -c "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''"

    # Rename private key to .pem
    su - $username -c "mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pem"

    # Set up authorized_keys with correct permissions
    su - $username -c "cp ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys"
    su - $username -c "chmod 600 ~/.ssh/authorized_keys"

    # Add to docker group
    usermod -aG docker $username

    # Install and configure ZSH
    install_zsh $username

    # Install uv package manager
    install_uv $username

    # Create and set up key storage directory for ubuntu user
    local ubuntu_keys_dir="/home/ubuntu/user_ssh_keys"
    mkdir -p "$ubuntu_keys_dir"
    chown ubuntu:ubuntu "$ubuntu_keys_dir"
    chmod 700 "$ubuntu_keys_dir"

    # Create user-specific key directory
    local key_dir="$ubuntu_keys_dir/$username"
    mkdir -p "$key_dir"
    chown ubuntu:ubuntu "$key_dir"
    chmod 700 "$key_dir"

    # Copy SSH keys to ubuntu user's directory (using the full paths)
    cp "/home/$username/.ssh/id_ed25519.pem" "$key_dir/"
    cp "/home/$username/.ssh/id_ed25519.pub" "$key_dir/"

    # Set proper ownership and permissions for the copied keys
    chown ubuntu:ubuntu "$key_dir/id_ed25519.pem" "$key_dir/id_ed25519.pub"
    chmod 600 "$key_dir/id_ed25519.pem"
    chmod 644 "$key_dir/id_ed25519.pub"

    echo ""
    echo "✅ User creation completed"
    echo "SSH private key locations:"
    echo "  - User's copy: $ssh_dir/id_ed25519.pem"
    echo "  - Admin's copy: $key_dir/id_ed25519.pem"
    echo "SSH public key locations:"
    echo "  - User's copy: $ssh_dir/id_ed25519.pub"
    echo "  - Admin's copy: $key_dir/id_ed25519.pub"
}

# Main script logic
if [ $# -eq 0 ]; then
    print_usage
fi

# Process command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
    --install-docker)
        install_docker
        ;;
    --install-zsh)
        install_zsh "ubuntu"
        ;;
    --create-user)
        shift
        create_user "$1"
        ;;
    --download-keys)
        shift
        package_ssh_keys "$1"
        ;;
    *)
        print_usage
        ;;
    esac
    shift
done

