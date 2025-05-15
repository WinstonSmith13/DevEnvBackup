#!/bin/bash

# Define the current directory as base
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Go up to parent directory if we're in 'scripts'
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    PARENT_DIR="$(dirname "$SCRIPT_DIR")"
else
    PARENT_DIR="$SCRIPT_DIR"
fi

# Create a directory for SSH backups in migration-backup
SSH_BACKUP_DIR="$PARENT_DIR/migration-backup/ssh-backup"
mkdir -p "$SSH_BACKUP_DIR"

echo "Backing up SSH keys..."

# Check if SSH directory exists
if [ -d ~/.ssh ]; then
    # Remove old backups if they exist
    rm -rf "$SSH_BACKUP_DIR"/*
    
    # Copy only normal files (no sockets, fifos, or devices)
    find ~/.ssh -type f -name "id_*" -o -name "*.pub" -o -name "config" -o -name "known_hosts" | while read file; do
        cp "$file" "$SSH_BACKUP_DIR/"
    done
    
    # Secure permissions
    chmod 700 "$SSH_BACKUP_DIR"
    chmod 600 "$SSH_BACKUP_DIR"/* 2>/dev/null || true
    chmod 644 "$SSH_BACKUP_DIR"/*.pub 2>/dev/null || true
    chmod 644 "$SSH_BACKUP_DIR"/known_hosts 2>/dev/null || true
    chmod 644 "$SSH_BACKUP_DIR"/config 2>/dev/null || true
    
    # Count the number of saved files
    FILE_COUNT=$(find "$SSH_BACKUP_DIR" -type f | wc -l)
    echo "✓ $FILE_COUNT SSH files saved in $SSH_BACKUP_DIR"
    
    # List SSH keys found
    if [ -n "$(find "$SSH_BACKUP_DIR" -name "id_*" ! -name "*.pub")" ]; then
        echo "  Private keys found:"
        find "$SSH_BACKUP_DIR" -name "id_*" ! -name "*.pub" | while read key; do
            KEY_NAME=$(basename "$key")
            echo "    - $KEY_NAME"
        done
    else
        echo "  No private keys found."
    fi
else
    echo "⚠️ No ~/.ssh directory found"
fi

# Create a README file with instructions
cat > "$SSH_BACKUP_DIR/README.txt" << 'ENDREADME'
Restoring SSH keys on the new computer:

1. First, create the ~/.ssh directory if it doesn't exist:
   mkdir -p ~/.ssh

2. Copy all files from this directory to ~/.ssh:
   cp -r /path/to/ssh-backup/* ~/.ssh/

3. Configure proper permissions:
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/*
   chmod 644 ~/.ssh/*.pub
   chmod 644 ~/.ssh/known_hosts
   chmod 644 ~/.ssh/config

4. Test the configuration:
   ssh -T git@github.com

5. If you're using an SSH agent (recommended), add your keys:
   ssh-add ~/.ssh/id_rsa
   # Or for other key types:
   ssh-add ~/.ssh/id_ed25519

6. On Windows, make sure the SSH Agent service is enabled:
   - Search for "Services" in the Start menu
   - Find "OpenSSH Authentication Agent"
   - Set startup to "Automatic"
   - Start the service
ENDREADME

echo "Restoration instructions created in $SSH_BACKUP_DIR/README.txt"
