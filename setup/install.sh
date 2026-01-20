#!/bin/bash
# Main installation orchestrator
# Detects OS and runs appropriate setup script
#
# This script can be run from any directory - it automatically detects
# its location and uses absolute paths. All temporary files go to /tmp/.
#
# Usage: ~/.local/share/chezmoi/setup/install.sh

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/common.sh"

# Print header
clear
log_section "Dotfiles Setup - Application Installer"

# Check if running in dry run mode
if [ -n "$DRY_RUN" ]; then
    log_warning "Running in DRY RUN mode - no actual installations will occur"
    echo ""
fi

# Detect operating system
log_info "Detecting operating system..."

OS="$(uname -s)"
case "$OS" in
    Darwin*)
        OS_TYPE="mac"
        log_success "Detected macOS"
        ;;
    Linux*)
        OS_TYPE="linux"
        log_success "Detected Linux"
        ;;
    *)
        log_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo ""

# Confirmation prompt (unless in dry run mode)
if [ -z "$DRY_RUN" ]; then
    echo "This script will install applications and tools based on your configuration."
    echo "Existing installations will be skipped."
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    echo ""
fi

# Run appropriate setup script
if [ "$OS_TYPE" = "mac" ]; then
    log_info "Running Mac setup script..."
    bash "$SCRIPT_DIR/mac-setup.sh"
    exit_code=$?
elif [ "$OS_TYPE" = "linux" ]; then
    log_info "Running Linux setup script..."
    bash "$SCRIPT_DIR/linux-setup.sh"
    exit_code=$?
fi

# Final message
echo ""
if [ $exit_code -eq 0 ]; then
    log_section "Setup Complete!"
    log_success "All applications installed successfully"
    echo ""
    log_info "Next steps:"
    echo "  1. Close and reopen your terminal (or run: source ~/.bashrc)"
    echo "  2. For NVM/Node: Install Node with: nvm install --lts"
    echo "  3. Test your installations"
    echo ""
else
    log_section "Setup Complete with Errors"
    log_warning "Some installations failed - check output above"
    echo ""
    log_info "To retry failed installations:"
    echo "  ./install.sh"
    echo ""
fi

exit $exit_code