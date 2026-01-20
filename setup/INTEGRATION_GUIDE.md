# Integration Guide: Adding Setup Scripts to Your Dotfiles

## Overview
You now have a complete `setup/` directory ready to add to your existing dotfiles repository managed by chezmoi.

## Files Created

```
setup/
├── README.md              # User documentation
├── YAML_GUIDE.md          # Detailed YAML structure reference
├── install.sh             # Main orchestrator (detects OS)
├── mac-setup.sh           # Mac installations via Homebrew
├── linux-setup.sh         # Linux installations from YAML config
├── common.sh              # Shared utilities
├── mac-apps.yml           # Mac application list
└── linux-apps.yml         # Linux applications with methods
```

## Integration Steps

### 1. Add to Your Dotfiles Repository

```bash
# Navigate to your chezmoi source directory
cd ~/.local/share/chezmoi

# Add to git
git add setup/
git commit -m "Add automated setup scripts for Mac and Linux"
git push
```

### 2. Test Before Pushing (Recommended)

```bash
# From ~/.local/share/chezmoi
cd setup

# Dry run to see what would be installed
DRY_RUN=1 ./install.sh

# Review the output - make sure it looks correct
```

### 3. Customize for Your Needs

**Edit application lists:**
```bash
# Mac apps
vim setup/mac-apps.yml

# Linux apps and installation methods
vim setup/linux-apps.yml
```

**For detailed YAML structure explanation:**
```bash
# Read the comprehensive YAML guide
cat setup/YAML_GUIDE.md
```

**Modify installation methods (Linux only):**
Change how specific apps are installed by editing `linux-apps.yml`:
```yaml
vscode:
  method: snap  # Change from 'apt' to 'snap'
  notes: "Using snap instead of apt for auto-updates"
```

See `YAML_GUIDE.md` for all available patterns and examples.

### 4. On a Fresh Machine

After you've pushed to your repo:

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Initialize with your dotfiles
chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git

# 3. Run the setup script (from anywhere - uses absolute paths)
~/.local/share/chezmoi/setup/install.sh

# 4. Follow post-installation instructions
source ~/.bashrc  # or ~/.zshrc
nvm install --lts
npm install -g @anthropic-ai/claude-code
```

## Customization Tips

### Adding a New Application

**Mac:**
1. Add to `mac-apps.yml` under appropriate section
2. Find the correct Homebrew package name: `brew search <app>`

**Linux:**
1. Add to `linux-apps.yml` under appropriate section
2. Specify the installation method
3. If using apt with a custom repo, include repo details

Example:
```yaml
new-app:
  method: apt
  repo:
    key_url: https://example.com/key.gpg
    repo_line: "deb [signed-by=/usr/share/keyrings/new-app-keyring.gpg] https://example.com/repo stable main"
    repo_file: new-app.list
```

### Removing an Application

Simply delete or comment out the entry in the respective YAML file.

### Testing Individual Scripts

```bash
# Test just Mac setup (on macOS)
./setup/mac-setup.sh

# Test just Linux setup (on Linux)
./setup/linux-setup.sh

# Dry run mode (no actual installations)
DRY_RUN=1 ./setup/install.sh
```

## Maintenance

### Keeping Scripts Updated

**Update NVM version:**
Edit the NVM install line in `mac-setup.sh` and `linux-apps.yml`:
```bash
# Change version number in the URL
https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh
```

**Update repository URLs:**
If a tool's repository changes, update in `linux-apps.yml`:
```yaml
tool-name:
  repo:
    key_url: NEW_URL
    repo_line: NEW_REPO_LINE
```

**Add new tools as you discover them:**
Keep your YAML files up to date as you adopt new tools.

## Troubleshooting

**Scripts don't execute:**
```bash
chmod +x setup/*.sh
```

**Python YAML errors on Linux:**
```bash
sudo apt-get install python3-yaml
```

**Snap not working:**
```bash
sudo systemctl start snapd
sudo systemctl enable snapd
```

**Homebrew not in PATH (Mac):**
Add to your shell config:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Philosophy & Design Decisions

1. **Architecture**: Clean separation between dotfiles (chezmoi) and installations (setup scripts)
2. **Idempotent**: Scripts check for existing installations and skip them
3. **Declarative**: YAML configs make intentions clear and versionable
4. **No Prompts During Installation**: All preferences set upfront in config files
5. **Lean by Default**: Only install what you explicitly list

## Next Steps

1. Review and customize the YAML files for your exact needs
2. Test with `DRY_RUN=1 ./install.sh`
3. Commit to your dotfiles repo
4. Document any personal notes or gotchas in the README

## Questions?

- Check `setup/README.md` for detailed usage instructions
- Review individual scripts for implementation details
- Test in a VM or container before running on your main system