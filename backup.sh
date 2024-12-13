#!/bin/bash

# Load configuration
source config

# Create backup directory if it does not exist
mkdir -p "$BACKUP_DIR"

# Get current date and time for backup file names
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Copy files with error handling
cp "$CONFIG_FILE" "$BACKUP_DIR/mumble-server_$TIMESTAMP.ini" || { echo "Failed to backup config"; exit 1; }
cp "$DB_FILE" "$BACKUP_DIR/mumble-server_$TIMESTAMP.sqlite" || { echo "Failed to backup database"; exit 1; }

echo "Backup completed successfully."

# Test for configuration file backup
BACKUP_CONFIG_FILE="$BACKUP_DIR/mumble-server_$TIMESTAMP.ini"
if cmp -s "$CONFIG_FILE" "$BACKUP_CONFIG_FILE"; then
    echo "Configuration file backup is successful and matches the original."
else
    echo "Configuration file backup failed: files do not match."
    exit 1
fi

# Test for database file backup
BACKUP_DB_FILE="$BACKUP_DIR/mumble-server_$TIMESTAMP.sqlite"
if [ -s "$BACKUP_DB_FILE" ]; then
    echo "Database file backup is successful and has a non-zero size."
else
    echo "Database file backup failed: file is empty."
    exit 1
fi
