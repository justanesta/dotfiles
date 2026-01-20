#!/bin/bash
# Mac setup script - installs applications via Homebrew

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/common.sh"

# Config file
CONFIG_FILE="$SCRIPT_DIR/mac-apps.yml"

log_section "Mac Application Setup"

# Check if Homebrew is installed
if ! command_exists brew; then
    log_info "Homebrew not found, installing..."
    if [ -z "$DRY_RUN" ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log_success "Homebrew installed"
    else
        log_info "[DRY RUN] Would install Homebrew"
    fi
else
    log_success "Homebrew already installed"
fi

echo ""

# Update Homebrew
if [ -z "$DRY_RUN" ]; then
    log_info "Updating Homebrew..."
    brew update >/dev/null 2>&1
    log_success "Homebrew updated"
fi

echo ""

# Install CLI tools
log_section "Installing CLI Tools"

cli_tools=(
    "gh"
    "pyenv"
    "uv"
    "pass-cli"
    "snowflake-cli"
    "1password-cli"
    "postgresql"
    "sqlite"
)

for tool in "${cli_tools[@]}"; do
    if brew_installed "$tool"; then
        log_warning "$tool is already installed, skipping"
        track_result "skipped" "$tool"
    else
        if [ -n "$DRY_RUN" ]; then
            log_info "[DRY RUN] Would install: $tool"
            track_result "installed" "$tool"
        else
            log_info "Installing $tool..."
            if brew install "$tool" >/dev/null 2>&1; then
                log_success "$tool installed successfully"
                track_result "installed" "$tool"
            else
                log_error "Failed to install $tool"
                track_result "failed" "$tool"
            fi
        fi
    fi
done

echo ""

# Install GUI applications
log_section "Installing GUI Applications"

gui_apps=(
    "1password"
    "bruno"
    "claude"
    "dbeaver-community"
    "positron"
    "rstudio"
    "r"
    "visual-studio-code"
    "slack"
    "zoom"
    "firefox"
    "google-chrome"
    "signal"
    "discord"
    "pgadmin4"
    "db-browser-for-sqlite"
)

for app in "${gui_apps[@]}"; do
    if brew_installed "$app"; then
        log_warning "$app is already installed, skipping"
        track_result "skipped" "$app"
    else
        if [ -n "$DRY_RUN" ]; then
            log_info "[DRY RUN] Would install: $app"
            track_result "installed" "$app"
        else
            log_info "Installing $app..."
            if brew install --cask "$app" >/dev/null 2>&1; then
                log_success "$app installed successfully"
                track_result "installed" "$app"
            else
                log_error "Failed to install $app"
                track_result "failed" "$app"
            fi
        fi
    fi
done

echo ""

# NVM and Node setup
log_section "Setting up Node.js via NVM"

if command_exists nvm; then
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
            
            # Load NVM
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            log_info "Installing Node.js LTS..."
            if nvm install --lts >/dev/null 2>&1; then
                log_success "Node.js LTS installed"
                track_result "installed" "node-lts"
            else
                log_error "Failed to install Node.js"
                track_result "failed" "node-lts"
            fi
        else
            log_error "Failed to install NVM"
            track_result "failed" "nvm"
        fi
    fi
fi

# Install global npm packages
if command_exists npm; then
    echo ""
    log_info "Installing global npm packages..."
    
    if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
        log_warning "@anthropic-ai/claude-code already installed, skipping"
        track_result "skipped" "claude-code"
    else
        if [ -n "$DRY_RUN" ]; then
            log_info "[DRY RUN] Would install: @anthropic-ai/claude-code"
            track_result "installed" "claude-code"
        else
            log_info "Installing @anthropic-ai/claude-code..."
            if npm install -g @anthropic-ai/claude-code >/dev/null 2>&1; then
                log_success "@anthropic-ai/claude-code installed successfully"
                track_result "installed" "claude-code"
            else
                log_error "Failed to install @anthropic-ai/claude-code"
                track_result "failed" "claude-code"
            fi
        fi
    fi
else
    log_warning "npm not found, skipping global package installation"
    log_info "After Node is installed, run: npm install -g @anthropic-ai/claude-code"
fi

echo ""

# Print summary
print_summary
