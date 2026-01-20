#!/bin/bash
# Linux setup script - installs applications based on YAML configuration

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/common.sh"

# Config file
CONFIG_FILE="$SCRIPT_DIR/linux-apps.yml"

log_section "Linux Application Setup"

# Check if we're on a Debian-based system
if ! is_debian_based; then
    log_warning "This script is optimized for Debian/Ubuntu-based systems"
    log_warning "Some installations may not work on your distribution"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
fi

echo ""

# Check for required tools
log_info "Checking for required tools..."

if ! command_exists python3; then
    log_error "python3 is required but not installed"
    log_info "Install with: sudo apt-get install python3"
    exit 1
fi

if ! python3 -c "import yaml" 2>/dev/null; then
    log_warning "PyYAML not found, installing..."
    if [ -z "$DRY_RUN" ]; then
        sudo apt-get install -y python3-yaml >/dev/null 2>&1
        log_success "PyYAML installed"
    else
        log_info "[DRY RUN] Would install python3-yaml"
    fi
fi

echo ""

# Update package lists
if [ -z "$DRY_RUN" ]; then
    log_info "Updating package lists..."
    sudo apt-get update >/dev/null 2>&1
    log_success "Package lists updated"
    echo ""
fi

# Install CLI tools
log_section "Installing CLI Tools"

# Parse YAML and install CLI tools
python3 << 'EOF' | while IFS='|' read -r name method package repo_info script notes; do
    if [ -z "$name" ]; then
        continue
    fi
    
    case "$method" in
        apt)
            # Check if we need to add a repository first
            if [ -n "$repo_info" ]; then
                # Parse repo info: key_url,repo_line,repo_file
                IFS=',' read -r key_url repo_line repo_file <<< "$repo_info"
                
                repo_name="$(echo "$name" | tr '-' '_')"
                
                if [ ! -f "/etc/apt/sources.list.d/$repo_file" ]; then
                    log_info "Adding repository for $name..."
                    
                    if [ -z "$DRY_RUN" ]; then
                        # Download and add GPG key
                        curl -fsSL "$key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/${repo_name}-keyring.gpg" 2>/dev/null
                        
                        # Add repository
                        echo "$repo_line" | sudo tee "/etc/apt/sources.list.d/$repo_file" >/dev/null
                        
                        # Update package list
                        sudo apt-get update >/dev/null 2>&1
                        
                        log_success "Repository for $name added"
                    else
                        log_info "[DRY RUN] Would add repository for $name"
                    fi
                fi
            fi
            
            # Install package
            pkg="${package:-$name}"
            apt_install "$pkg"
            if [ $? -eq 0 ]; then
                [ -z "$DRY_RUN" ] && track_result "installed" "$name" || track_result "skipped" "$name"
            else
                track_result "failed" "$name"
            fi
            ;;
            
        official)
            if command_exists "$name"; then
                log_warning "$name is already installed, skipping"
                track_result "skipped" "$name"
            else
                run_official_script "$name" "$script"
                if [ $? -eq 0 ]; then
                    track_result "installed" "$name"
                    if [ -n "$notes" ]; then
                        log_info "Note: $notes"
                    fi
                else
                    track_result "failed" "$name"
                fi
            fi
            ;;
            
        manual)
            show_manual_install "$name" "${script:-$package}" "$notes"
            track_result "manual" "$name"
            ;;
    esac
done
import yaml
import sys

config_file = sys.argv[1] if len(sys.argv) > 1 else 'SCRIPT_DIR/linux-apps.yml'

with open(config_file.replace('SCRIPT_DIR', '$SCRIPT_DIR'), 'r') as f:
    config = yaml.safe_load(f)

cli_tools = config.get('cli_tools', {})

for name, details in cli_tools.items():
    method = details.get('method', '')
    package = details.get('package', '')
    script = details.get('script', '')
    notes = details.get('notes', '')
    
    repo_info = ''
    if 'repo' in details:
        repo = details['repo']
        key_url = repo.get('key_url', '')
        repo_line = repo.get('repo_line', '')
        repo_file = repo.get('repo_file', '')
        repo_info = f"{key_url},{repo_line},{repo_file}"
    
    url = details.get('url', '')
    
    print(f"{name}|{method}|{package}|{repo_info}|{script}|{notes}|{url}")
EOF

echo ""

# Install GUI apps
log_section "Installing GUI Applications"

python3 << 'EOF' | while IFS='|' read -r name method package repo_info script notes url classic deb_url gpg_key_id gpg_keyserver; do
    if [ -z "$name" ]; then
        continue
    fi
    
    case "$method" in
        apt)
            # Check if we need to add a repository first
            if [ -n "$repo_info" ]; then
                IFS=',' read -r key_url repo_line repo_file <<< "$repo_info"
                
                repo_name="$(echo "$name" | tr '-' '_')"
                
                if [ ! -f "/etc/apt/sources.list.d/$repo_file" ]; then
                    log_info "Adding repository for $name..."
                    
                    if [ -z "$DRY_RUN" ]; then
                        curl -fsSL "$key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/${repo_name}-keyring.gpg" 2>/dev/null
                        echo "$repo_line" | sudo tee "/etc/apt/sources.list.d/$repo_file" >/dev/null
                        sudo apt-get update >/dev/null 2>&1
                        log_success "Repository for $name added"
                    else
                        log_info "[DRY RUN] Would add repository for $name"
                    fi
                fi
            fi
            
            pkg="${package:-$name}"
            apt_install "$pkg"
            if [ $? -eq 0 ]; then
                [ -z "$DRY_RUN" ] && track_result "installed" "$name" || track_result "skipped" "$name"
            else
                track_result "failed" "$name"
            fi
            ;;
            
        snap)
            classic_flag=""
            [ "$classic" = "true" ] && classic_flag="--classic"
            
            snap_install "$name" "$classic_flag"
            if [ $? -eq 0 ]; then
                [ -z "$DRY_RUN" ] && track_result "installed" "$name" || track_result "skipped" "$name"
            else
                track_result "failed" "$name"
            fi
            ;;
            
        flatpak)
            flatpak_install "$name"
            if [ $? -eq 0 ]; then
                [ -z "$DRY_RUN" ] && track_result "installed" "$name" || track_result "skipped" "$name"
            else
                track_result "failed" "$name"
            fi
            ;;
            
        deb)
            # Handle direct .deb downloads
            if command_exists "$name"; then
                log_warning "$name is already installed, skipping"
                track_result "skipped" "$name"
            else
                if [ -n "$DRY_RUN" ]; then
                    log_info "[DRY RUN] Would download and install: $name from $deb_url"
                    [ -n "$gpg_key_id" ] && log_info "[DRY RUN] Would verify GPG signature"
                    track_result "installed" "$name"
                else
                    log_info "Downloading $name..."
                    temp_deb="/tmp/${name}.deb"
                    temp_sig="/tmp/${name}.deb.asc"
                    
                    # Download main file
                    if wget -q --show-progress "$deb_url" -O "$temp_deb" 2>&1; then
                        log_success "Download complete"
                        
                        # Download signature if GPG info provided
                        if [ -n "$gpg_key_id" ]; then
                            log_info "Downloading GPG signature..."
                            if wget -q "${deb_url}.asc" -O "$temp_sig" 2>/dev/null; then
                                log_success "Signature downloaded"
                                
                                # Verify signature
                                if verify_deb_signature "$temp_deb" "$gpg_key_id" "$gpg_keyserver" "$name"; then
                                    log_success "GPG verification passed ✓"
                                else
                                    log_warning "GPG verification failed or unavailable"
                                    read -p "Continue with installation anyway? (y/N): " -n 1 -r
                                    echo ""
                                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                                        log_info "Installation cancelled"
                                        rm -f "$temp_deb" "$temp_sig"
                                        track_result "skipped" "$name"
                                        continue
                                    fi
                                fi
                                rm -f "$temp_sig"
                            else
                                log_warning "Signature file not available - continuing with HTTPS trust"
                            fi
                        fi
                        
                        log_info "Installing $name..."
                        if sudo apt install -y "$temp_deb" >/dev/null 2>&1; then
                            log_success "$name installed successfully"
                            rm "$temp_deb"
                            track_result "installed" "$name"
                            if [ -n "$notes" ]; then
                                log_info "Note: $notes"
                            fi
                        else
                            log_error "Failed to install $name"
                            rm "$temp_deb"
                            track_result "failed" "$name"
                        fi
                    else
                        log_error "Failed to download $name from: $deb_url"
                        track_result "failed" "$name"
                    fi
                fi
            fi
            ;;
            
        manual)
            show_manual_install "$name" "$url" "$notes"
            track_result "manual" "$name"
            ;;
    esac
done
import yaml
import sys

config_file = sys.argv[1] if len(sys.argv) > 1 else 'SCRIPT_DIR/linux-apps.yml'

with open(config_file.replace('SCRIPT_DIR', '$SCRIPT_DIR'), 'r') as f:
    config = yaml.safe_load(f)

gui_apps = config.get('gui_apps', {})

for name, details in gui_apps.items():
    method = details.get('method', '')
    package = details.get('package', '')
    script = details.get('script', '')
    notes = details.get('notes', '')
    url = details.get('url', '')
    classic = str(details.get('classic', False)).lower()
    
    # Handle deb method fields
    deb_url = details.get('deb_url', '')
    version = details.get('version', '')
    gpg_key_id = details.get('gpg_key_id', '')
    gpg_keyserver = details.get('gpg_keyserver', '')
    
    # Replace {version} placeholder in deb_url
    if version and '{version}' in deb_url:
        deb_url = deb_url.replace('{version}', version)
    
    repo_info = ''
    if 'repo' in details:
        repo = details['repo']
        key_url = repo.get('key_url', '')
        repo_line = repo.get('repo_line', '')
        repo_file = repo.get('repo_file', '')
        repo_info = f"{key_url},{repo_line},{repo_file}"
    
    print(f"{name}|{method}|{package}|{repo_info}|{script}|{notes}|{url}|{classic}|{deb_url}|{gpg_key_id}|{gpg_keyserver}")
EOF

echo ""

# NVM and Node setup
log_section "Setting up Node.js via NVM"

if [ -d "$HOME/.nvm" ]; then
    log_warning "NVM already installed, skipping"
    track_result "skipped" "nvm"
else
    if [ -n "$DRY_RUN" ]; then
        log_info "[DRY RUN] Would install NVM"
        track_result "installed" "nvm"
    else
        log_info "Installing NVM..."
        if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash >/dev/null 2>&1; then
            log_success "NVM installed successfully"
            track_result "installed" "nvm"
            log_info "Note: Restart your terminal or run: source ~/.bashrc"
        else
            log_error "Failed to install NVM"
            track_result "failed" "nvm"
        fi
    fi
fi

echo ""
log_info "After NVM is loaded, install Node with: nvm install --lts"
log_info "Then install Claude Code with: npm install -g @anthropic-ai/claude-code"

echo ""

# Print summary
print_summary
