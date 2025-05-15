#!/bin/bash

# Define the current directory as base
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Go up to parent directory if we're in 'scripts'
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    PARENT_DIR="$(dirname "$SCRIPT_DIR")"
else
    PARENT_DIR="$SCRIPT_DIR"
fi

# Create a directory for backups in migration-backup
BACKUP_DIR="$PARENT_DIR/migration-backup/config-backups"
mkdir -p "$BACKUP_DIR"

echo "Backing up configuration files..."

# Clean the existing backup directory
rm -rf "$BACKUP_DIR"/*
mkdir -p "$BACKUP_DIR"

# Function to backup a file
backup_file() {
    local src="$1"
    local dest="$2"
    
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        echo "✓ $(basename "$src") backed up"
        return 0
    else
        return 1
    fi
}

# Function to backup a directory
backup_dir() {
    local src="$1"
    local dest="$2"
    
    if [ -d "$src" ]; then
        mkdir -p "$dest"
        cp -r "$src"/* "$dest"/ 2>/dev/null
        echo "✓ $(basename "$src") backed up"
        return 0
    else
        return 1
    fi
}

# Bash configuration files
backup_file "$HOME/.bashrc" "$BACKUP_DIR/"
backup_file "$HOME/.bash_profile" "$BACKUP_DIR/"
backup_file "$HOME/.bash_aliases" "$BACKUP_DIR/"

# Git configuration
backup_file "$HOME/.gitconfig" "$BACKUP_DIR/"

# NPM configuration
backup_file "$HOME/.npmrc" "$BACKUP_DIR/"

# List global npm packages
if command -v npm &> /dev/null; then
    npm list -g --depth=0 > "$BACKUP_DIR/npm-global-packages.txt"
    echo "✓ List of global npm packages saved"
fi

# PhpStorm (Windows)
PHPSTORM_CONFIG="$HOME/AppData/Roaming/JetBrains"
if [ -d "$PHPSTORM_CONFIG" ]; then
    # Backup only essential configuration files, not caches
    mkdir -p "$BACKUP_DIR/phpstorm"
    find "$PHPSTORM_CONFIG" -name "*.xml" -not -path "*system*" -not -path "*plugins*" | while read file; do
        rel_path="${file#$PHPSTORM_CONFIG/}"
        mkdir -p "$BACKUP_DIR/phpstorm/$(dirname "$rel_path")"
        cp "$file" "$BACKUP_DIR/phpstorm/$rel_path"
    done
    echo "✓ PhpStorm configuration backed up"
fi

# VS Code configuration
VSCODE_DIR="$HOME/AppData/Roaming/Code/User"
if [ -d "$VSCODE_DIR" ]; then
    mkdir -p "$BACKUP_DIR/vscode"
    backup_file "$VSCODE_DIR/settings.json" "$BACKUP_DIR/vscode/"
    backup_file "$VSCODE_DIR/keybindings.json" "$BACKUP_DIR/vscode/"
    
    # Backup VS Code extensions
    if command -v code &> /dev/null; then
        code --list-extensions > "$BACKUP_DIR/vscode/extensions.txt" 2>/dev/null
        echo "✓ VS Code extensions backed up"
    else
        echo "⚠️ 'code' command not found, unable to list VS Code extensions"
    fi
fi

# Discord (Windows)
DISCORD_CONFIG="$HOME/AppData/Roaming/discord"
if [ -d "$DISCORD_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR/discord"
    backup_file "$DISCORD_CONFIG/settings.json" "$BACKUP_DIR/discord/"
fi

# Arc Browser (Windows)
ARC_CONFIG="$HOME/AppData/Roaming/Arc"
if [ -d "$ARC_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR/arc"
    find "$ARC_CONFIG" -name "*.json" -not -path "*Cache*" | while read file; do
        rel_path="${file#$ARC_CONFIG/}"
        mkdir -p "$BACKUP_DIR/arc/$(dirname "$rel_path")"
        cp "$file" "$BACKUP_DIR/arc/$rel_path"
    done
    echo "✓ Arc Browser configuration backed up"
fi

CHROME_BOOKMARKS="$HOME/AppData/Local/Google/Chrome/User Data/Default/Bookmarks"
if [ -f "$CHROME_BOOKMARKS" ]; then
    mkdir -p "$BACKUP_DIR/chrome"  # Ensure directory exists
    backup_file "$CHROME_BOOKMARKS" "$BACKUP_DIR/chrome/"
fi

# Warp Terminal (Mac)
WARP_CONFIG="$HOME/.warp"
if [ -d "$WARP_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR/warp"
    backup_dir "$WARP_CONFIG/themes" "$BACKUP_DIR/warp/themes"
    backup_dir "$WARP_CONFIG/launch_configurations" "$BACKUP_DIR/warp/launch_configurations"
    backup_file "$WARP_CONFIG/keybindings.yaml" "$BACKUP_DIR/warp/"
fi

# Terminal configuration (Windows)
TERMINAL_CONFIG="$HOME/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json"
for terminal_settings in $TERMINAL_CONFIG; do
    if [ -f "$terminal_settings" ]; then
        mkdir -p "$BACKUP_DIR/windows-terminal"
        cp "$terminal_settings" "$BACKUP_DIR/windows-terminal/settings.json"
        echo "✓ Windows Terminal configuration backed up"
        break
    fi
done

# Create a README file with restoration instructions
cat > "$BACKUP_DIR/README.txt" << 'ENDREADME'
Instructions for restoring configurations on your new computer:

1. General configuration files (.bashrc, .gitconfig, etc.):
   cp config-backups/.bashrc ~/
   cp config-backups/.gitconfig ~/
   ... etc for each similar file

2. VS Code:
   a) First install VS Code
   b) Copy the configuration files:
      mkdir -p ~/.config/Code/User/ # For Linux/Mac
      cp config-backups/vscode/settings.json ~/.config/Code/User/
      cp config-backups/vscode/keybindings.json ~/.config/Code/User/
      # Or for Windows:
      cp config-backups/vscode/settings.json ~/AppData/Roaming/Code/User/
      cp config-backups/vscode/keybindings.json ~/AppData/Roaming/Code/User/
   c) Install extensions:
      cat config-backups/vscode/extensions.txt | xargs -L 1 code --install-extension

3. PhpStorm:
   Copy the configuration files after installing PhpStorm.
   XML files should be restored to their original location.

4. Arc/Chrome:
   Restore bookmarks and settings after installing the browser.

5. NPM Packages:
   Check config-backups/npm-global-packages.txt to reinstall global npm packages.
   npm install -g [package-name]

Feel free to adapt these commands according to your operating system.
ENDREADME

echo "✓ Restoration instructions created in $BACKUP_DIR/README.txt"

# Backup summary
echo -e "\nBackup summary:"
find "$BACKUP_DIR" -type f | sort | while read file; do
    rel_path="${file#$BACKUP_DIR/}"
    echo "  - $rel_path"
done | head -n 20

# Display total number of backed up files
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
if [ $FILE_COUNT -gt 20 ]; then
    echo "  ... and $(($FILE_COUNT - 20)) additional files"
fi

echo -e "\nBackup completed. $(find "$BACKUP_DIR" -type f | wc -l) files backed up in $BACKUP_DIR"
