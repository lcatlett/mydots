#!/bin/bash

# Source directory
SOURCE_DIR=/Users/lindseycatlett/notes

# Destination directory on the removable hard drive
DEST_DIR=/Volumes/dock/notes

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Move the directory to the removable hard drive with rclone
rclone move "$SOURCE_DIR" "$DEST_DIR" --progress --transfers=12 --checkers=12 --delete-empty-src-dirs --copy-links

# Verify the move was successful
if [ $? -eq 0 ]; then
  echo "Move completed successfully and source directory deleted."
else
  echo "Move failed. Source directory not deleted."
fi