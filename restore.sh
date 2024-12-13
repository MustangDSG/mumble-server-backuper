#!/bin/bash

# Load configuration
source config

# Check if the service is running and stop it if it is
if systemctl is-active --quiet mumble-server; then
    service mumble-server stop
    echo "Mumble server stopped."
    SERVER_WAS_RUNNING=true
else
    SERVER_WAS_RUNNING=false
fi

# Get the latest backups
LATEST_CONFIG_FILE=$(ls -t $BACKUP_DIR/mumble-server_*.ini | head -n 1)
LATEST_DB_FILE=$(ls -t $BACKUP_DIR/mumble-server_*.sqlite | head -n 1)

# Check for the existence of backups
if [[ -z "$LATEST_CONFIG_FILE" || -z "$LATEST_DB_FILE" ]]; then
    echo "No backup files found."
    exit 1
fi

# Restore configuration file with error handling
cp "$LATEST_CONFIG_FILE" "$CONFIG_FILE" || { echo "Failed to restore config"; exit 1; }
echo "Restored configuration from $LATEST_CONFIG_FILE."

# Restore database file with error handling
cp "$LATEST_DB_FILE" "$DB_FILE" || { echo "Failed to restore database"; exit 1; }
echo "Restored database from $LATEST_DB_FILE."

# Set permissions on files
chown "$SERVER_USER":"$SERVER_USER" "$CONFIG_FILE"
chmod 644 "$CONFIG_FILE"  # Permissions: read and write for owner, read for others

chown "$SERVER_USER":"$SERVER_USER" "$DB_FILE"
chmod 600 "$DB_FILE"  # Permissions: read and write only for owner

# Test restored configuration file against the latest backup
if cmp -s "$LATEST_CONFIG_FILE" "$CONFIG_FILE"; then
    echo "Restored configuration file matches the latest backup."
else
    echo "Restoration of configuration failed: files do not match."
    exit 1
fi

# Test restored database file size
if [ -s "$DB_FILE" ]; then
    echo "Restored database file has a non-zero size."
else
    echo "Restoration of database failed: file is empty."
    exit 1
fi

# Start the Mumble server if it was running before restoration
if [ "$SERVER_WAS_RUNNING" = true ]; then
    service mumble-server start
    echo "Mumble server started."
fi
