# Development Environment Migration Tool

A comprehensive set of bash scripts to automate the backup and restoration of your development environment when moving to a new computer.

## Overview

This tool helps developers easily migrate their development setup between computers by:

- Backing up configurations, SSH keys, and essential application settings
- Identifying installed applications and Git repositories
- Creating a portable archive for simple transfer
- Restoring your entire environment on the new machine

Perfect for developers who frequently switch machines, set up new work environments, or simply want a reliable backup of their configuration.

## Features

- 🔒 **SSH Key Backup** - Securely backup and restore your SSH keys with proper permissions
- ⚙️ **Application Configs** - Save settings from VS Code, PhpStorm, Terminal emulators, and more
- 🌐 **Git Repository Management** - Track all your repositories for easy re-cloning
- 📋 **Application Inventory** - Generate a list of your essential applications
- 🔍 **Environment Files** - Backup important `.env` files and SSL certificates
- 📦 **Project Structure** - Preserve your project organization structure

## Getting Started

### Prerequisites

- Bash shell environment (Git Bash on Windows, Terminal on macOS/Linux)
- Git installed
- Basic command line knowledge

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/dev-migration-tool.git
   cd dev-migration-tool
   ```

2. Make scripts executable:
   ```bash
   chmod +x prepare-migration.sh post_installation.sh
   chmod +x scripts/*.sh
   ```

## Usage

### On Your Current Computer (Backup)

Run the main backup script:

```bash
./prepare-migration.sh
```

This script will:
- Backup your configurations, SSH keys, and other essential data
- Create a comprehensive list of your applications and Git repositories
- Generate a `migration-backup-YYYYMMDD.tar.gz` archive in your home directory

### On Your New Computer (Restoration)

1. Copy the generated archive to your new computer
2. Extract the archive:
   ```bash
   tar -xzf migration-backup-YYYYMMDD.tar.gz
   ```
3. Run the post-installation script:
   ```bash
   ./post_installation.sh
   ```
4. Install essential applications listed in `app_essentials.txt`
5. Clone your Git repositories using the information in `git-projects-info/git-repos.txt`

## Customization

### Adding Additional Applications
Edit the `app_essentials.txt` file to add or remove applications based on your needs.

### Custom Backup Locations
Each backup script can be modified to include additional directories or files:
- `scripts/backup_configs.sh` — Add more application configurations
- `scripts/additional_backup.sh` — Add more data types to backup

## Supported Applications

Out of the box, this tool backs up configurations for:

| Category | Applications |
|----------|-------------|
| Shell Environments | Bash, Zsh, etc. |
| Development | Git, VS Code, PhpStorm |
| Terminal | Windows Terminal |
| Browsers | Arc Browser, Chrome (bookmarks) |
| Communication | Discord |
| Containerization | Docker |
| Packages | NPM (global packages) |
| API | Postman collections |

## Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add some amazing feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- Inspired by the need to streamline development environment migration
- Built for developers by developers

## Future Improvements

- Add support for more applications and development tools
- Create a configuration file for customizing backup behavior
- Add automatic installation of applications
- Implement a GUI interface
- Add selective restore capability

---

*Built by [Winston Smith]*
