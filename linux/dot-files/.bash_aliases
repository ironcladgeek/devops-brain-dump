#!/bin/bash

# Git
alias g="git"
alias gst="git status"
alias git-changed-files="git diff-tree --no-commit-id --name-only -r"
alias gl1="git log --oneline"
alias gla="git log --oneline --decorate --all --graph"
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gwip="git add . && git commit -m 'wip'"
alias gnah="git reset --hard && git clean -df"

# Navigation
alias ..="cd .." # Go up one directory
alias ...="cd ../.." # Go up two directories
alias ....="cd ../../.." # Go up three directories
alias cg='cd `git rev-parse --show-toplevel`' # cd to git root directory

# Python
alias py="python3"
alias ve='python3 -m venv ./venv' # Create virtual environment named venv
alias va='source ./venv/bin/activate' # Activate virtual environment

# Misc
alias c="clear"
alias v="vim"
alias k="kubectl"
alias tf="terraform"
