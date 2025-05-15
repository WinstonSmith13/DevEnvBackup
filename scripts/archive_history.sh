#!/bin/bash


ARCHIVE_DIR="$HOME/migration-archives"
mkdir -p "$ARCHIVE_DIR"


if ls $HOME/migration-backup-*.tar.gz 1> /dev/null 2>&1; then
    echo "Archivage des sauvegardes précédentes..."
    mv $HOME/migration-backup-*.tar.gz "$ARCHIVE_DIR/" 2>/dev/null
    echo "✓ Sauvegardes précédentes déplacées vers $ARCHIVE_DIR"
fi


HISTORY_FILE="$ARCHIVE_DIR/backup-history.txt"
touch "$HISTORY_FILE"

BACKUP_DATE=$(date +"%Y-%m-%d %H:%M:%S")
BACKUP_FILE="migration-backup-$(date +"%Y%m%d").tar.gz"
echo "$BACKUP_DATE : $BACKUP_FILE créé" >> "$HISTORY_FILE"

echo "✓ Historique des sauvegardes mis à jour dans $HISTORY_FILE"
