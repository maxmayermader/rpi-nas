#!/bin/bash
#
# Backup script: Encrypted incremental sync to OneDrive using rclone crypt
# Dependencies: rclone (with crypt remote configured)
#
# Setup rclone (one-time):
#   1. rclone config -> Create "onedrive" remote (Microsoft OneDrive)
#   2. rclone config -> Create "onedrive-crypt" remote (Encrypt/Decrypt, pointing to onedrive:Backups)
#
# Cronjob example (daily at 2 AM):
#   0 2 * * * /path/to/backup-to-onedrive.sh >> /var/log/backup-onedrive.log 2>&1
#

set -e

# ============== CONFIGURATION ==============
SOURCE_DIR="/path/to/folder/to/backup"       # Folder to backup
RCLONE_CRYPT_REMOTE="onedrive-crypt"         # Name of your rclone crypt remote
# ===========================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting encrypted backup of: $SOURCE_DIR"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log "ERROR: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Check dependencies
if ! command -v rclone &> /dev/null; then
    log "ERROR: rclone is not installed"
    exit 1
fi

# Sync to encrypted OneDrive remote
log "Syncing to encrypted OneDrive remote: ${RCLONE_CRYPT_REMOTE}:/"
rclone sync "$SOURCE_DIR" "${RCLONE_CRYPT_REMOTE}:/" \
    --progress \
    --log-level INFO \
    --stats 30s

log "Backup finished successfully!"
