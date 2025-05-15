#!/bin/bash

# Define the current directory as base
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Go up to parent directory if we're in 'scripts'
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    PARENT_DIR="$(dirname "$SCRIPT_DIR")"
else
    PARENT_DIR="$SCRIPT_DIR"
fi

# Create a directory for additional backups
EXTRA_BACKUP_DIR="$PARENT_DIR/migration-backup/extra-backups"
mkdir -p "$EXTRA_BACKUP_DIR"

echo "Backing up additional elements..."

# Backup hosts file
if [ -f "/c/Windows/System32/drivers/etc/hosts" ]; then
    mkdir -p "$EXTRA_BACKUP_DIR/system"
    cp "/c/Windows/System32/drivers/etc/hosts" "$EXTRA_BACKUP_DIR/system/"
    echo "✓ Hosts file backed up"
fi

# Backup Docker configurations
DOCKER_CONFIG="$HOME/.docker"
if [ -d "$DOCKER_CONFIG" ]; then
    mkdir -p "$EXTRA_BACKUP_DIR/docker"
    cp -r "$DOCKER_CONFIG" "$EXTRA_BACKUP_DIR/docker/"
    echo "✓ Docker configuration backed up"
fi

# Backup Postman exports
POSTMAN_DIR="$HOME/Postman/Exported"
if [ -d "$POSTMAN_DIR" ]; then
    mkdir -p "$EXTRA_BACKUP_DIR/postman"
    cp -r "$POSTMAN_DIR"/* "$EXTRA_BACKUP_DIR/postman/"
    echo "✓ Postman collections backed up"
fi

# Find and backup .env files (security caution)
echo "Searching for .env files in projects..."
find ~/sites -name ".env" -type f 2>/dev/null | while read env_file; do
    rel_path=$(realpath --relative-to="$HOME" "$env_file")
    target_dir="$EXTRA_BACKUP_DIR/env-files/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    cp "$env_file" "$target_dir/"
    echo "✓ .env file found and backed up: $rel_path"
done

# Backup personal SSL certificates
SSL_DIR="$HOME/ssl" # Adapt this path to your configuration
if [ -d "$SSL_DIR" ]; then
    mkdir -p "$EXTRA_BACKUP_DIR/ssl"
    cp -r "$SSL_DIR"/* "$EXTRA_BACKUP_DIR/ssl/"
    echo "✓ SSL certificates backed up"
fi

# List of installed software (Windows)
if command -v powershell.exe &> /dev/null; then
    powershell.exe "Get-ItemProperty HKLM:\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* | Select-Object DisplayName, DisplayVersion | Sort-Object DisplayName | Format-Table -AutoSize" > "$EXTRA_BACKUP_DIR/installed-software.txt"
    echo "✓ List of installed software saved"
fi

# Backup non-versioned projects
echo "Searching for non-versioned projects in ~/sites..."
find ~/sites -type d -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.git/*" -not -path "*/dist/*" 2>/dev/null | while read dir; do
    # Check if it's not a git repository
    if [ ! -d "$dir/.git" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
        # If it's a non-empty directory without git
        rel_path=$(realpath --relative-to="$HOME/sites" "$dir")
        if [ ${#rel_path} -gt 0 ] && [ ! "$rel_path" = "." ]; then
            echo "✓ Non-versioned project found: $rel_path"
            # Add to a list for future reference
            echo "$rel_path" >> "$EXTRA_BACKUP_DIR/non-git-projects.txt"
        fi
    fi
done

echo "Additional elements backup completed in $EXTRA_BACKUP_DIR"
