#!/bin/bash

echo "==================================================="
echo "POST-MIGRATION RESTORATION ASSISTANT"
echo "==================================================="

# Check execution context
CURRENT_DIR="$(pwd)"

# Check if we are in the directory extracted from the archive
if [ -f "$CURRENT_DIR/app_essentials.txt" ] && [ -d "$CURRENT_DIR/config-backups" ]; then
    # We are in the root directory extracted from the archive
    CONFIG_DIR="$CURRENT_DIR/config-backups"
    SSH_DIR="$CURRENT_DIR/ssh-backup"
    GIT_INFO_DIR="$CURRENT_DIR/git-projects-info"
    APP_LIST="$CURRENT_DIR/app_essentials.txt"
elif [ -f "$CURRENT_DIR/migration-backup/app_essentials.txt" ] && [ -d "$CURRENT_DIR/migration-backup/config-backups" ]; then
    # We are in the parent directory, with the archive extracted in migration-backup
    CONFIG_DIR="$CURRENT_DIR/migration-backup/config-backups"
    SSH_DIR="$CURRENT_DIR/migration-backup/ssh-backup"
    GIT_INFO_DIR="$CURRENT_DIR/migration-backup/git-projects-info"
    APP_LIST="$CURRENT_DIR/migration-backup/app_essentials.txt"
else
    echo "⚠️ This script must be run from the extracted migration archive directory"
    echo "   or from the parent directory containing 'migration-backup'."
    exit 1
fi

# Restore basic configuration files
echo -e "\n1. Restoring basic configuration files..."
if [ -f "$CONFIG_DIR/.bashrc" ]; then
    cp "$CONFIG_DIR/.bashrc" ~/
    echo "✓ .bashrc restored"
fi

if [ -f "$CONFIG_DIR/.bash_profile" ]; then
    cp "$CONFIG_DIR/.bash_profile" ~/
    echo "✓ .bash_profile restored"
fi

if [ -f "$CONFIG_DIR/.gitconfig" ]; then
    cp "$CONFIG_DIR/.gitconfig" ~/
    echo "✓ .gitconfig restored"
fi

# Restore SSH keys
echo -e "\n2. Restoring SSH keys..."
if [ -d "$SSH_DIR" ] && [ "$(ls -A "$SSH_DIR")" ]; then
    mkdir -p ~/.ssh
    cp "$SSH_DIR"/* ~/.ssh/
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/*
    chmod 644 ~/.ssh/*.pub 2>/dev/null
    chmod 644 ~/.ssh/known_hosts 2>/dev/null
    chmod 644 ~/.ssh/config 2>/dev/null
    echo "✓ SSH keys restored"
fi

# Create directory for Git projects
echo -e "\n3. Creating directory for Git projects..."
if [ -d "$GIT_INFO_DIR" ]; then
    mkdir -p ~/sites
    mkdir -p /c/git 2>/dev/null || true
    echo "✓ Git project directories created"
    
    echo -e "\nTo clone your Git repositories, consult the file $GIT_INFO_DIR/git-repos.txt"
fi

# Instructions for VS Code
echo -e "\n4. Installing VS Code extensions..."
if [ -f "$CONFIG_DIR/vscode/extensions.txt" ]; then
    echo "To install VS Code extensions, run:"
    echo "  cat $CONFIG_DIR/vscode/extensions.txt | xargs -L 1 code --install-extension"
    
    # Option for direct installation
    read -p "Do you want to install VS Code extensions now? (y/n) " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        if command -v code &> /dev/null; then
            cat "$CONFIG_DIR/vscode/extensions.txt" | xargs -L 1 code --install-extension
            echo "✓ VS Code extensions installed"
        else
            echo "⚠️ 'code' command not found. Install VS Code and add it to PATH."
        fi
    fi
fi

# Additional application configurations
echo -e "\n5. Restoring application configurations..."

# VS Code
if [ -d "$CONFIG_DIR/vscode" ]; then
    VSCODE_CONFIG_DIR=""
    if [ -d "$HOME/AppData/Roaming/Code/User" ]; then
        # Windows
        VSCODE_CONFIG_DIR="$HOME/AppData/Roaming/Code/User"
    elif [ -d "$HOME/.config/Code/User" ]; then
        # Linux
        VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
    elif [ -d "$HOME/Library/Application Support/Code/User" ]; then
        # macOS
        VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
    fi
    
    if [ -n "$VSCODE_CONFIG_DIR" ]; then
        # Make sure the directory exists
        mkdir -p "$VSCODE_CONFIG_DIR"
        
        # Copy configuration files
        if [ -f "$CONFIG_DIR/vscode/settings.json" ]; then
            cp "$CONFIG_DIR/vscode/settings.json" "$VSCODE_CONFIG_DIR/"
            echo "✓ VS Code configuration restored"
        fi
        
        if [ -f "$CONFIG_DIR/vscode/keybindings.json" ]; then
            cp "$CONFIG_DIR/vscode/keybindings.json" "$VSCODE_CONFIG_DIR/"
            echo "✓ VS Code keyboard shortcuts restored"
        fi
    else
        echo "⚠️ VS Code configuration directory not found"
    fi
fi

# Restore Windows Terminal files if applicable
if [ -d "$CONFIG_DIR/windows-terminal" ] && [ -f "$CONFIG_DIR/windows-terminal/settings.json" ]; then
    # Path for Windows Terminal
    TERMINAL_CONFIG_DIR="$HOME/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState"
    
    # Find the actual directory (expansion of *)
    for terminal_dir in $TERMINAL_CONFIG_DIR; do
        if [ -d "$terminal_dir" ]; then
            cp "$CONFIG_DIR/windows-terminal/settings.json" "$terminal_dir/"
            echo "✓ Windows Terminal configuration restored"
            break
        fi
    done
fi

echo -e "\nBasic configuration restoration completed."
echo "Check $APP_LIST to install missing applications."
