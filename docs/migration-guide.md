# Guide de Migration

Ce document décrit le processus de migration de vos environnements de développement.

## Étape 1 : Avant la migration

- Exécutez `./prepare-migration.sh` sur l'ancien ordinateur
- Vérifiez que l'archive `migration-backup-*.tar.gz` a été créée

## Étape 2 : Sur le nouvel ordinateur

1. Installez Git Bash (sur Windows) ou Terminal (sur Mac)
2. Copiez et extrayez l'archive de migration
   ```bash
   tar -xzf migration-backup-*.tar.gz
