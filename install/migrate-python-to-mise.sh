#!/usr/bin/env bash

#===============================================================================
# Python Migration: Homebrew → mise
#===============================================================================
# Migrates Python version management from Homebrew to mise.
#
# What this does:
# 1. Checks for Homebrew Python dependencies
# 2. Installs missing Python versions in mise (3.10, 3.14)
# 3. Verifies all versions are available in mise
# 4. Uninstalls Homebrew Python versions
# 5. Cleans up Homebrew
# 6. Verifies the migration
#
# Usage: ./migrate-python-to-mise.sh
#===============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Confirmation prompt
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

#===============================================================================
# Step 1: Check Homebrew Dependencies
#===============================================================================

log_section "Step 1: Checking Homebrew Python Dependencies"

PYTHON_VERSIONS=("python@3.10" "python@3.11" "python@3.12" "python@3.13" "python@3.14")
BLOCKING_DEPS=()

for version in "${PYTHON_VERSIONS[@]}"; do
    if brew list "$version" &>/dev/null; then
        log_info "Checking dependencies for $version..."
        DEPS=$(brew uses --installed "$version" 2>/dev/null | grep -v "^$" || true)

        if [ -n "$DEPS" ]; then
            log_warning "Found dependencies for $version:"
            echo "$DEPS" | sed 's/^/  - /'
            BLOCKING_DEPS+=("$version")
        else
            log_success "No dependencies for $version"
        fi
    fi
done

if [ ${#BLOCKING_DEPS[@]} -gt 0 ]; then
    log_warning "The following Python versions have dependencies:"
    printf '  - %s\n' "${BLOCKING_DEPS[@]}"
    echo
    log_info "These packages depend on Homebrew Python. They may need reinstallation after migration."

    if ! confirm "Continue anyway?"; then
        log_error "Migration aborted by user"
        exit 1
    fi
fi

#===============================================================================
# Step 2: Install Missing Python Versions in mise
#===============================================================================

log_section "Step 2: Installing Missing Python Versions in mise"

MISSING_VERSIONS=("3.10" "3.14")

for version in "${MISSING_VERSIONS[@]}"; do
    log_info "Installing Python $version in mise..."

    if mise list python | grep -q "^$version"; then
        log_success "Python $version already installed in mise"
    else
        mise install python@$version
        log_success "Python $version installed successfully"
    fi
done

#===============================================================================
# Step 3: Verify mise Installations
#===============================================================================

log_section "Step 3: Verifying mise Python Installations"

REQUIRED_VERSIONS=("3.10" "3.11" "3.12" "3.13" "3.14")
ALL_PRESENT=true

for version in "${REQUIRED_VERSIONS[@]}"; do
    if mise list python | grep -q "^$version"; then
        log_success "Python $version present in mise"
    else
        log_error "Python $version NOT found in mise"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    log_error "Not all required Python versions are present in mise"
    exit 1
fi

log_success "All required Python versions are available in mise"

#===============================================================================
# Step 4: Save Global pip Packages (Optional)
#===============================================================================

log_section "Step 4: Saving Global pip Packages"

log_info "Saving currently installed global pip packages..."
pip3 list --format=freeze > /tmp/global-pip-packages-backup.txt 2>/dev/null || true
log_success "Global pip packages saved to /tmp/global-pip-packages-backup.txt"
echo "You can reinstall them later with:"
echo "  pip3 install -r /tmp/global-pip-packages-backup.txt"

#===============================================================================
# Step 5: Uninstall Homebrew Python Versions
#===============================================================================

log_section "Step 5: Uninstalling Homebrew Python Versions"

log_warning "This will uninstall all Homebrew Python versions (3.10-3.14)"

if ! confirm "Proceed with uninstallation?"; then
    log_error "Migration aborted by user"
    exit 1
fi

for version in "${PYTHON_VERSIONS[@]}"; do
    if brew list "$version" &>/dev/null; then
        log_info "Uninstalling $version..."
        brew uninstall --ignore-dependencies "$version" || {
            log_warning "Failed to uninstall $version (may have dependencies)"
        }
    else
        log_info "$version not installed via Homebrew"
    fi
done

log_success "Homebrew Python versions uninstalled"

#===============================================================================
# Step 6: Clean up Homebrew
#===============================================================================

log_section "Step 6: Cleaning up Homebrew"

log_info "Running brew cleanup..."
brew cleanup

log_success "Homebrew cleanup complete"

#===============================================================================
# Step 7: Verify Migration
#===============================================================================

log_section "Step 7: Verifying Migration"

log_info "Checking Python binary locations..."

# Check python3 command
PYTHON3_PATH=$(command -v python3)
log_info "python3 location: $PYTHON3_PATH"

if [[ "$PYTHON3_PATH" == *".local/share/mise"* ]]; then
    log_success "python3 is now managed by mise"
else
    log_warning "python3 may not be managed by mise. Current location: $PYTHON3_PATH"
fi

# Check mise versions
log_info "Available Python versions in mise:"
mise list python | sed 's/^/  /'

# Check for stray Homebrew Python binaries
log_info "Checking for remaining Homebrew Python installations..."
BREW_PYTHONS=$(brew list | grep "^python@" || true)

if [ -z "$BREW_PYTHONS" ]; then
    log_success "No Homebrew Python versions remaining"
else
    log_warning "Found remaining Homebrew Python versions:"
    echo "$BREW_PYTHONS" | sed 's/^/  - /'
fi

#===============================================================================
# Summary
#===============================================================================

log_section "Migration Complete!"

echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Verify Python version: python3 --version"
echo "  3. Check mise status: mise doctor"
echo "  4. Optionally reinstall global pip packages:"
echo "     pip3 install -r /tmp/global-pip-packages-backup.txt"
echo
echo "If you have virtual environments, you may need to recreate them:"
echo "  rm -rf venv/"
echo "  python3 -m venv venv"
echo

log_success "Python version management is now handled by mise"
