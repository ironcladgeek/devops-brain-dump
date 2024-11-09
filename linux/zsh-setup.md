# 🔲 ZSH Installation and Configuration Guide

Complete guide for setting up and customizing ZSH with Oh My Zsh.

## Installation

```bash
# Install ZSH
sudo apt update
sudo apt install zsh

# Verify installation
zsh --version

# Make ZSH default shell
chsh -s $(which zsh)

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Setting Up ZSH for Non-Admin User

```bash
# As admin/sudo user, install ZSH system-wide
sudo apt update
sudo apt install zsh

# Switch to the target user
sudo su - target_username

# Check current shell
echo $SHELL

# Change shell for the target user (two methods)
# Method 1: As admin using chsh
sudo chsh -s $(which zsh) target_username

# Method 2: Using usermod
sudo usermod -s $(which zsh) target_username


# Install Oh My Zsh for target user
# Method 1: Direct installation as target user
sudo -u target_username sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Method 2: Manual installation
# Clone Oh My Zsh repository
sudo -u target_username git clone https://github.com/ohmyzsh/ohmyzsh.git /home/target_username/.oh-my-zsh

# Create initial .zshrc if necessary
sudo -u target_username cp /home/target_username/.oh-my-zsh/templates/zshrc.zsh-template /home/target_username/.zshrc
```

## Essential Plugins

```bash
# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Edit ~/.zshrc to enable plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
)
```


## Theme Configuration

```bash
# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Edit ~/.zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"

# Configure Powerlevel10k
p10k configure
```

## Custom Configuration

```bash
# Add to ~/.zshrc

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Environment variables
export EDITOR='vim'
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}
```

## ZSH Key Features

```bash
# Directory shortcuts
cd -  # Go to previous directory
cd ~  # Go to home directory
cd /  # Go to root directory

# Expansion and globbing
ls *(.)     # List regular files
ls *(/)     # List directories
ls *(@)     # List symbolic links
ls *(Lk+100) # List files larger than 100kb

# Command history
!!          # Run last command
!$          # Last argument of previous command
!*          # All arguments of previous command
!string     # Run last command starting with 'string'
```

## Troubleshooting

```bash
# Fix font issues
# Install recommended fonts
sudo apt install fonts-powerline

# Reset ZSH configuration
rm ~/.zshrc
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# Compile ZSH files for faster loading
zcompile ~/.zshrc
```
