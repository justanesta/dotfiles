#!/bin/bash
# Common utilities for setup scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a package is installed (apt)
apt_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Check if a snap is installed
snap_installed() {
    snap list "$1" >/dev/null 2>&1
}

# Check if a flatpak is installed
flatpak_installed() {
    flatpak list | grep -q "$1"
}

# Check if homebrew package/cask is installed
brew_installed() {
    brew list "$1" >/dev/null 2>&1 || brew list --cask "$1" >/dev/null 2>&1
}

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Check if running on Ubuntu/Debian-based system
is_debian_based() {
    local distro=$(detect_linux_distro)
    [[ "$distro" == "ubuntu" || "$distro" == "debian" || "$distro" == "pop" ]]
}

# Install package with apt (with error handling)
apt_install() {
    local package="$1"
    if apt_package_installed "$package"; then
        log_warning "$package is already installed (apt), skipping"
        return 0
    fi
    
    if [ -n "$DRY_RUN" ]; then
        log_info "[DRY RUN] Would install: $package (apt)"
        return 0
    fi
    
    log_info "Installing $package via apt..."
    if sudo apt-get install -y "$package" >/dev/null 2>&1; then
        log_success "$package installed successfully"
        return 0
    else
        log_error "Failed to install $package via apt"
        return 1
    fi
}

# Install package with snap
snap_install() {
    local package="$1"
    local classic="${2:-}" # Optional: --classic flag
    
    if snap_installed "$package"; then
        log_warning "$package is already installed (snap), skipping"
        return 0
    fi
    
    if [ -n "$DRY_RUN" ]; then
        log_info "[DRY RUN] Would install: $package (snap)"
        return 0
    fi
    
    log_info "Installing $package via snap..."
    if sudo snap install "$package" $classic >/dev/null 2>&1; then
        log_success "$package installed successfully"
        return 0
    else
        log_error "Failed to install $package via snap"
        return 1
    fi
}

# Install package with flatpak
flatpak_install() {
    local package="$1"
    
    if flatpak_installed "$package"; then
        log_warning "$package is already installed (flatpak), skipping"
        return 0
    fi
    
    if [ -n "$DRY_RUN" ]; then
        log_info "[DRY RUN] Would install: $package (flatpak)"
        return 0
    fi
    
    log_info "Installing $package via flatpak..."
    if flatpak install -y flathub "$package" >/dev/null 2>&1; then
        log_success "$package installed successfully"
        return 0
    else
        log_error "Failed to install $package via flatpak"
        return 1
    fi
}

# Run official install script
run_official_script() {
    local name="$1"
    local script="$2"
    
    if [ -n "$DRY_RUN" ]; then
        log_info "[DRY RUN] Would run official script for: $name"
        return 0
    fi
    
    log_info "Running official install script for $name..."
    if eval "$script" >/dev/null 2>&1; then
        log_success "$name installed successfully"
        return 0
    else
        log_error "Failed to install $name via official script"
        return 1
    fi
}

# Show manual installation instructions
show_manual_install() {
    local name="$1"
    local url="$2"
    local notes="$3"
    
    log_warning "$name requires manual installation"
    echo "  URL: $url"
    if [ -n "$notes" ]; then
        echo "  Notes: $notes"
    fi
}

# Add apt repository
add_apt_repo() {
    local name="$1"
    local key_url="$2"
    local repo_line="$3"
    local repo_file="$4"
    
    if [ -f "/etc/apt/sources.list.d/$repo_file" ]; then
        log_warning "Repository for $name already added, skipping"
        return 0
    fi
    
    if [ -n "$DRY_RUN" ]; then
        log_info "[DRY RUN] Would add apt repository for: $name"
        return 0
    fi
    
    log_info "Adding apt repository for $name..."
    
    # Download and add GPG key
    if ! curl -fsSL "$key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/$name-keyring.gpg" 2>/dev/null; then
        log_error "Failed to add GPG key for $name"
        return 1
    fi
    
    # Add repository
    echo "$repo_line" | sudo tee "/etc/apt/sources.list.d/$repo_file" >/dev/null
    
    # Update package list
    sudo apt-get update >/dev/null 2>&1
    
    log_success "Repository for $name added successfully"
    return 0
}

# Parse YAML (simple key-value extraction)
# Usage: yaml_get_value "filename.yml" "section.key"
yaml_get_value() {
    local file="$1"
    local path="$2"
    
    # This is a simplified YAML parser - works for our flat structure
    # For production, consider yq or python
    python3 -c "
import yaml
import sys

with open('$file', 'r') as f:
    data = yaml.safe_load(f)

path = '$path'.split('.')
value = data
for key in path:
    value = value.get(key, {})

if isinstance(value, dict):
    print(yaml.dump(value))
else:
    print(value)
"
}

# Track installation results
declare -a INSTALLED
declare -a FAILED
declare -a SKIPPED

# Verify GPG signature of a .deb file
verify_deb_signature() {
    local deb_file="$1"
    local key_id="$2"
    local keyserver="$3"
    local name="$4"
    
    if [ -z "$key_id" ] || [ -z "$keyserver" ]; then
        log_warning "GPG verification skipped (no key_id or keyserver provided)"
        return 0
    fi
    
    log_info "Verifying GPG signature for $name..."
    
    # Check if key is already in keyring
    if ! gpg --list-keys "$key_id" >/dev/null 2>&1; then
        log_info "Importing GPG key $key_id from $keyserver..."
        if gpg --keyserver "$keyserver" --recv-keys "$key_id" >/dev/null 2>&1; then
            log_success "GPG key imported successfully"
        else
            log_error "Failed to import GPG key"
            log_warning "Continuing without verification (download is still over HTTPS)"
            return 1
        fi
    else
        log_info "GPG key already in keyring"
    fi
    
    # Check if signature file exists
    local sig_file="${deb_file}.asc"
    if [ ! -f "$sig_file" ]; then
        log_warning "Signature file not found at ${sig_file}"
        log_warning "GPG verification skipped (continuing with HTTPS trust)"
        return 1
    fi
    
    # Verify signature
    log_info "Verifying signature..."
    if gpg --verify "$sig_file" "$deb_file" >/dev/null 2>&1; then
        log_success "GPG signature verified ✓"
        return 0
    else
        log_error "GPG signature verification failed!"
        log_error "This could indicate a tampered package"
        return 1
    fi
}

# Track installation results
declare -a INSTALLED
declare -a FAILED
declare -a SKIPPED

track_result() {
    local status="$1"
    local name="$2"
    
    case "$status" in
        "installed")
            INSTALLED+=("$name")
            ;;
        "failed")
            FAILED+=("$name")
            ;;
        "skipped")
            SKIPPED+=("$name")
            ;;
    esac
}

# Print summary at the end
print_summary() {
    log_section "Installation Summary"
    
    if [ ${#INSTALLED[@]} -gt 0 ]; then
        echo -e "${GREEN}Successfully installed (${#INSTALLED[@]}):${NC}"
        for item in "${INSTALLED[@]}"; do
            echo "  ✓ $item"
        done
        echo ""
    fi
    
    if [ ${#SKIPPED[@]} -gt 0 ]; then
        echo -e "${YELLOW}Skipped (already installed) (${#SKIPPED[@]}):${NC}"
        for item in "${SKIPPED[@]}"; do
            echo "  - $item"
        done
        echo ""
    fi
    
    if [ ${#FAILED[@]} -gt 0 ]; then
        echo -e "${RED}Failed installations (${#FAILED[@]}):${NC}"
        for item in "${FAILED[@]}"; do
            echo "  ✗ $item"
        done
        echo ""
        log_error "Some installations failed. Check errors above for details."
        return 1
    else
        log_success "All installations completed successfully!"
        return 0
    fi
}
