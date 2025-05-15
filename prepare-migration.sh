#!/bin/bash

# Define the current directory as base
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "==================================================="
echo "PREPARING MIGRATION TO NEW COMPUTER"
echo "==================================================="

# Define absolute paths for backup directories
MIGRATION_DIR="$SCRIPT_DIR/migration-backup"
CONFIG_BACKUP_DIR="$MIGRATION_DIR/config-backups"
SSH_BACKUP_DIR="$MIGRATION_DIR/ssh-backup"
EXTRA_BACKUP_DIR="$MIGRATION_DIR/extra-backups"
GIT_INFO_DIR="$SCRIPT_DIR/git-projects-info"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Create directories if they don't exist
mkdir -p "$MIGRATION_DIR"
mkdir -p "$CONFIG_BACKUP_DIR"
mkdir -p "$SSH_BACKUP_DIR"
mkdir -p "$EXTRA_BACKUP_DIR"
mkdir -p "$GIT_INFO_DIR"

# Run backup scripts
echo -e "\n1. Backing up configurations..."

# Run the configuration backup script
if [ -f "$SCRIPTS_DIR/backup_configs.sh" ]; then
    # Temporarily modify the script to use the correct output path
    TMP_SCRIPT=$(mktemp)
    cat "$SCRIPTS_DIR/backup_configs.sh" | sed "s|BACKUP_DIR=\"\$SCRIPT_DIR/config-backups\"|BACKUP_DIR=\"$CONFIG_BACKUP_DIR\"|g" > "$TMP_SCRIPT"
    chmod +x "$TMP_SCRIPT"
    bash "$TMP_SCRIPT"
    rm "$TMP_SCRIPT"
else
    echo "⚠️ Configuration backup script not found!"
fi

# Verify that the config-backups directory has been created and is not empty
if [ ! -d "$CONFIG_BACKUP_DIR" ] || [ -z "$(ls -A "$CONFIG_BACKUP_DIR")" ]; then
    echo "⚠️ Warning: The directory $CONFIG_BACKUP_DIR does not exist or is empty."
    echo "   Creating an empty directory to avoid errors..."
    mkdir -p "$CONFIG_BACKUP_DIR"
    touch "$CONFIG_BACKUP_DIR/.placeholder"
fi

echo -e "\n2. Backing up SSH keys..."

# Run the SSH backup script
if [ -f "$SCRIPTS_DIR/backup-ssh.sh" ]; then
    # Temporarily modify the script to use the correct output path
    TMP_SCRIPT=$(mktemp)
    cat "$SCRIPTS_DIR/backup-ssh.sh" | sed "s|SSH_BACKUP_DIR=\"\$SCRIPT_DIR/ssh-backup\"|SSH_BACKUP_DIR=\"$SSH_BACKUP_DIR\"|g" > "$TMP_SCRIPT"
    chmod +x "$TMP_SCRIPT"
    bash "$TMP_SCRIPT"
    rm "$TMP_SCRIPT"
else
    echo "⚠️ SSH backup script not found!"
fi

# Verify that the ssh-backup directory has been created
if [ ! -d "$SSH_BACKUP_DIR" ]; then
    echo "⚠️ Warning: The directory $SSH_BACKUP_DIR does not exist."
    echo "   Creating an empty directory to avoid errors..."
    mkdir -p "$SSH_BACKUP_DIR"
    touch "$SSH_BACKUP_DIR/.placeholder"
fi

echo -e "\n3. Backing up additional data..."

# Run the additional backup script
if [ -f "$SCRIPTS_DIR/additional_backup.sh" ]; then
    # Temporarily modify the script to use the correct output path
    TMP_SCRIPT=$(mktemp)
    cat "$SCRIPTS_DIR/additional_backup.sh" | sed "s|EXTRA_BACKUP_DIR=\"\$SCRIPT_DIR/extra-backups\"|EXTRA_BACKUP_DIR=\"$EXTRA_BACKUP_DIR\"|g" > "$TMP_SCRIPT"
    chmod +x "$TMP_SCRIPT"
    bash "$TMP_SCRIPT"
    rm "$TMP_SCRIPT"
else
    echo "ℹ️ Additional backup script not found, skipped."
fi

echo -e "\n4. Backing up recent git projects..."

# Initialize git-repos.txt file
echo "LIST OF GIT REPOSITORIES" > "$GIT_INFO_DIR/git-repos.txt"
echo "======================" >> "$GIT_INFO_DIR/git-repos.txt"
echo "" >> "$GIT_INFO_DIR/git-repos.txt"

# Function to save information about a git repository
save_git_repo_info() {
    local repo_dir="$1"
    local source_dir="$2"
    
    # Check if it's a git repository (contains .git)
    if [ -d "$repo_dir/.git" ]; then
        local repo_name=$(basename "$repo_dir")
        
        # Get the remote URL (origin)
        cd "$repo_dir"
        local remote_url=$(git config --get remote.origin.url)
        local current_branch=$(git branch --show-current)
        
        # Save the information
        echo "Repository: $repo_name" >> "$GIT_INFO_DIR/git-repos.txt"
        echo "Path: $repo_dir" >> "$GIT_INFO_DIR/git-repos.txt"
        echo "Source: $source_dir" >> "$GIT_INFO_DIR/git-repos.txt"
        echo "URL: $remote_url" >> "$GIT_INFO_DIR/git-repos.txt"
        echo "Current branch: $current_branch" >> "$GIT_INFO_DIR/git-repos.txt"
        echo "-------------------" >> "$GIT_INFO_DIR/git-repos.txt"
    fi
}

# Find git repositories in ~/sites/
echo "Searching for git repositories in ~/sites/..."
find ~/sites -name ".git" -type d 2>/dev/null | while read gitdir; do
    # Extract the parent repository path
    repo_dir=$(dirname "$gitdir")
    save_git_repo_info "$repo_dir" "~/sites"
done

# Find git repositories in /c/git/
echo "Searching for git repositories in /c/git/..."
find /c/git -name ".git" -type d 2>/dev/null | while read gitdir; do
    # Extract the parent repository path
    repo_dir=$(dirname "$gitdir")
    save_git_repo_info "$repo_dir" "/c/git"
done

echo "✓ Git repository information saved in $GIT_INFO_DIR/git-repos.txt"

# Archive history if the script exists
if [ -f "$SCRIPTS_DIR/archive_history.sh" ]; then
    echo -e "\n5. Archiving backup history..."
    bash "$SCRIPTS_DIR/archive_history.sh"
fi

# Create an archive of all backup files
echo -e "\n6. Creating final archive..."
BACKUP_DATE=$(date +"%Y%m%d")
BACKUP_ARCHIVE="$HOME/migration-backup-$BACKUP_DATE.tar.gz"

# Prepare files and directories for the archive
echo "Preparing files for the archive..."

# Copy the post-installation script
if [ -f "$SCRIPT_DIR/post_installation.sh" ]; then
    cp "$SCRIPT_DIR/post_installation.sh" "$MIGRATION_DIR/"
    echo "✓ Post-installation script copied"
fi

# Copy the app_essentials.txt file
if [ -f "$SCRIPT_DIR/app_essentials.txt" ]; then
    cp "$SCRIPT_DIR/app_essentials.txt" "$MIGRATION_DIR/"
    echo "✓ Essential applications list copied"
fi

# Copy documentation
if [ -d "$SCRIPT_DIR/docs" ]; then
    mkdir -p "$MIGRATION_DIR/docs"
    cp -r "$SCRIPT_DIR/docs/"* "$MIGRATION_DIR/docs/" 2>/dev/null
    echo "✓ Documentation copied"
fi

# Copy git information
if [ -d "$GIT_INFO_DIR" ]; then
    mkdir -p "$MIGRATION_DIR/git-projects-info"
    cp -r "$GIT_INFO_DIR/"* "$MIGRATION_DIR/git-projects-info/" 2>/dev/null
    echo "✓ Git information copied"
fi

# List all elements to include in the archive
echo "Elements to include in the archive:"
find "$MIGRATION_DIR" -maxdepth 1 -type d | while read dir; do
    if [ "$dir" != "$MIGRATION_DIR" ]; then
        dir_name=$(basename "$dir")
        file_count=$(find "$dir" -type f | wc -l)
        echo "- $dir_name/ ($file_count files)"
    fi
done

# List files at the root
find "$MIGRATION_DIR" -maxdepth 1 -type f | while read file; do
    echo "- $(basename "$file")"
done

# Create the archive
echo "Creating archive..."
tar -czf "$BACKUP_ARCHIVE" -C "$MIGRATION_DIR" .

echo -e "\nPreparation complete!"
if [ -f "$BACKUP_ARCHIVE" ]; then
    echo "Final archive created: $BACKUP_ARCHIVE"
    echo -e "\nArchive contents:"
    tar -tvf "$BACKUP_ARCHIVE" | head -10
    
    if [ $(tar -tvf "$BACKUP_ARCHIVE" | wc -l) -gt 10 ]; then
        echo "... and $(($(tar -tvf "$BACKUP_ARCHIVE" | wc -l) - 10)) more files"
    fi
    
    echo -e "\nTransfer this archive to your new computer or an external device."
    echo -e "\nOn your new computer:"
    echo "1. Extract the archive: tar -xzf $(basename "$BACKUP_ARCHIVE")"
    echo "2. Check app_essentials.txt to install software"
    echo "3. Run post_installation.sh to automatically restore configurations"
    echo "4. Clone your git repositories using the information in git-projects-info/git-repos.txt"
else
    echo "⚠️ Error: The archive was not created correctly."
fi
