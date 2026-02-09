#!/bin/bash

# SSD Copy Script
# This script copies directories from SSD to local while preserving exact structure
# Only copies directories that have the "move" tag on the SSD
# Never deletes anything from the SSD - only copies

# Removed set -e to prevent hanging on command substitutions

# Configuration
SSD_BASE_DIR="${TEST_SSD_DIR:-/Volumes/dock}"  # Allow override for testing
LOCAL_BASE_DIR="$HOME"
MOVE_TAG_FILE=".move"  # Tag file that indicates directory should be copied
SCRIPT_NAME="$(basename "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME}:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME}:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME}:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME}:${NC} $1"
}

# Check if SSD is mounted and accessible
is_ssd_available() {
    if [ -d "$SSD_BASE_DIR" ] && [ -r "$SSD_BASE_DIR" ]; then
        return 0  # SSD is available
    else
        return 1  # SSD is not available
    fi
}

# Debug function
debug() {
    if [ "${DEBUG:-}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        log "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Convert SSD path to local path
ssd_to_local_path() {
    local ssd_path="$1"
    # Remove the SSD base directory and prepend local base directory
    local relative_path="${ssd_path#$SSD_BASE_DIR/}"
    echo "$LOCAL_BASE_DIR/$relative_path"
}

# Check if directory has move tag
has_move_tag() {
    local dir="$1"
    if [ -f "$dir/$MOVE_TAG_FILE" ]; then
        return 0  # Has move tag
    else
        return 1  # No move tag
    fi
}

# Find all directories with move tags on SSD
find_tagged_directories() {
    if ! is_ssd_available; then
        log_error "SSD not available at $SSD_BASE_DIR"
        return 1
    fi

    log "Scanning SSD for directories with move tags in sites, notes, and scripts..."

    # Search only in specific top-level directories, 1 level deep
    # Look for .move tags in: /Volumes/dock/notes/*, /Volumes/dock/sites/*, /Volumes/dock/scripts/*
    for base_dir in "notes" "sites" "scripts"; do
        local search_path="$SSD_BASE_DIR/$base_dir"
        if [ -d "$search_path" ]; then
            debug "Searching in $search_path"
            # Find .move files exactly 1 level deep in the base directory
            find "$search_path" -maxdepth 2 -mindepth 2 -name "$MOVE_TAG_FILE" -type f 2>/dev/null | while read -r tag_file; do
                # Get the directory containing the tag file
                local tagged_dir
                tagged_dir="$(dirname "$tag_file")"
                echo "$tagged_dir"
            done
        else
            debug "Directory $search_path does not exist, skipping"
        fi
    done
}

# Copy a single directory from SSD to local
copy_directory() {
    local ssd_dir="$1"
    local local_dir
    local_dir="$(ssd_to_local_path "$ssd_dir")"

    if [ ! -d "$ssd_dir" ]; then
        log_error "SSD directory does not exist: $ssd_dir"
        return 1
    fi

    log "Copying directory:"
    log "  From: $ssd_dir"
    log "  To:   $local_dir"

    # Ensure parent directory exists
    ensure_dir "$(dirname "$local_dir")"

    # Use rclone to copy the directory while preserving structure
    if command -v rclone >/dev/null 2>&1; then
        log "Using rclone for copy..."
        rclone copy "$ssd_dir/" "$local_dir/" \
            --progress \
            --transfers=8 \
            --checkers=8 \
            --copy-links \
            --update \
            --verbose

        if [ $? -eq 0 ]; then
            log_success "Rclone copy completed successfully"
            return 0
        else
            log_error "Rclone copy failed"
            return 1
        fi
    else
        # Fallback to rsync if rclone is not available
        log "Rclone not found, using rsync for copy..."
        rsync -av --update "$ssd_dir/" "$local_dir/"

        if [ $? -eq 0 ]; then
            log_success "Rsync completed successfully"
            return 0
        else
            log_error "Rsync failed"
            return 1
        fi
    fi
}

# Copy all tagged directories from SSD to local
copy_all_tagged() {
    if ! is_ssd_available; then
        log_error "SSD not available. Cannot copy directories."
        return 1
    fi

    log "Starting copy of all tagged directories from SSD to local..."

    # Find tagged directories in specific locations
    local tagged_dirs_file
    tagged_dirs_file=$(mktemp)

    # Search only in sites, notes, and scripts directories, 1 level deep
    for base_dir in "notes" "sites" "scripts"; do
        local search_path="$SSD_BASE_DIR/$base_dir"
        if [ -d "$search_path" ]; then
            debug "Searching in $search_path"
            # Find .move files exactly 1 level deep in the base directory
            find "$search_path" -maxdepth 2 -mindepth 2 -name "$MOVE_TAG_FILE" -type f 2>/dev/null >> "$tagged_dirs_file"
        else
            debug "Directory $search_path does not exist, skipping"
        fi
    done

    if [ ! -s "$tagged_dirs_file" ]; then
        log "No directories with move tags found in sites, notes, or scripts."
        rm -f "$tagged_dirs_file"
        return 0
    fi

    local success_count=0
    local total_count=0

    while IFS= read -r tag_file; do
        if [ -n "$tag_file" ]; then
            local ssd_dir
            ssd_dir="$(dirname "$tag_file")"
            total_count=$((total_count + 1))
            log "Processing tagged directory ($total_count): $ssd_dir"

            if copy_directory "$ssd_dir"; then
                success_count=$((success_count + 1))
                log_success "Successfully copied: $ssd_dir"
            else
                log_error "Failed to copy: $ssd_dir"
            fi
        fi
    done < "$tagged_dirs_file"

    rm -f "$tagged_dirs_file"
    log_success "Copy operation completed. Successfully copied $success_count of $total_count directories."
}

# List all directories with move tags
list_tagged_directories() {
    if ! is_ssd_available; then
        log_error "SSD not available at $SSD_BASE_DIR"
        return 1
    fi

    log "Directories with move tags in sites, notes, and scripts:"

    # Find tagged directories in specific locations
    local tagged_dirs_file
    tagged_dirs_file=$(mktemp)

    # Search only in sites, notes, and scripts directories, 1 level deep
    for base_dir in "notes" "sites" "scripts"; do
        local search_path="$SSD_BASE_DIR/$base_dir"
        if [ -d "$search_path" ]; then
            debug "Searching in $search_path"
            # Find .move files exactly 1 level deep in the base directory
            find "$search_path" -maxdepth 2 -mindepth 2 -name "$MOVE_TAG_FILE" -type f 2>/dev/null >> "$tagged_dirs_file"
        else
            debug "Directory $search_path does not exist, skipping"
        fi
    done

    if [ ! -s "$tagged_dirs_file" ]; then
        log "No directories with move tags found in sites, notes, or scripts."
        rm -f "$tagged_dirs_file"
        return 0
    fi

    while IFS= read -r tag_file; do
        if [ -n "$tag_file" ]; then
            local ssd_dir
            ssd_dir="$(dirname "$tag_file")"
            local local_dir
            local_dir="$(ssd_to_local_path "$ssd_dir")"
            echo "  SSD:   $ssd_dir"
            echo "  Local: $local_dir"
            echo ""
        fi
    done < "$tagged_dirs_file"

    rm -f "$tagged_dirs_file"
}

# Tag a directory for moving
tag_directory() {
    local target_dir="$1"

    if [ -z "$target_dir" ]; then
        log_error "Directory path required"
        echo "Usage: $0 tag <directory_path>"
        return 1
    fi

    if [ ! -d "$target_dir" ]; then
        log_error "Directory does not exist: $target_dir"
        return 1
    fi

    local tag_file="$target_dir/$MOVE_TAG_FILE"

    if [ -f "$tag_file" ]; then
        log_warning "Directory already tagged: $target_dir"
        return 0
    fi

    # Create the tag file
    touch "$tag_file"
    log_success "Tagged directory for moving: $target_dir"
}

# Remove tag from a directory
untag_directory() {
    local target_dir="$1"

    if [ -z "$target_dir" ]; then
        log_error "Directory path required"
        echo "Usage: $0 untag <directory_path>"
        return 1
    fi

    local tag_file="$target_dir/$MOVE_TAG_FILE"

    if [ ! -f "$tag_file" ]; then
        log_warning "Directory is not tagged: $target_dir"
        return 0
    fi

    # Remove the tag file
    rm "$tag_file"
    log_success "Removed tag from directory: $target_dir"
}

# Show status
show_status() {
    log "=== SSD Copy Status ==="

    if is_ssd_available; then
        log_success "SSD is available at: $SSD_BASE_DIR"

        # Count tagged directories in specific locations
        local tagged_count=0
        for base_dir in "notes" "sites" "scripts"; do
            local search_path="$SSD_BASE_DIR/$base_dir"
            if [ -d "$search_path" ]; then
                local count
                count=$(find "$search_path" -maxdepth 2 -mindepth 2 -name "$MOVE_TAG_FILE" -type f 2>/dev/null | wc -l)
                tagged_count=$((tagged_count + count))
                debug "Found $count tagged directories in $base_dir"
            fi
        done

        log "Found $tagged_count directories with move tags in sites, notes, and scripts"
        log "Search locations: sites/, notes/, scripts/ (1 level deep)"
    else
        log_warning "SSD is not available"
    fi

    log "Local base directory: $LOCAL_BASE_DIR"
    log "Move tag file: $MOVE_TAG_FILE"
}

# Main function
main() {
    case "${1:-}" in
        "copy")
            copy_all_tagged
            ;;
        "list")
            list_tagged_directories
            ;;
        "tag")
            tag_directory "$2"
            ;;
        "untag")
            untag_directory "$2"
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 {copy|list|tag|untag|status}"
            echo ""
            echo "Commands:"
            echo "  copy              - Copy all tagged directories from SSD to local"
            echo "  list              - List all directories with move tags"
            echo "  tag <dir>         - Tag a directory for moving"
            echo "  untag <dir>       - Remove tag from a directory"
            echo "  status            - Show status of SSD and tagged directories"
            echo ""
            echo "Examples:"
            echo "  $0 copy"
            echo "  $0 list"
            echo "  $0 tag /Volumes/dock/notes/upenn"
            echo "  $0 untag /Volumes/dock/notes/upenn"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
