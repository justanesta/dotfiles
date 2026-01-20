# Application & Tools Setup Scripts

Automated installation of applications and tools for fresh Mac or Linux machines.

## Quick Start

After running `chezmoi init --apply`, the setup scripts will be in `~/.local/share/chezmoi/setup/`.

Run from anywhere (scripts use absolute paths):

```bash
~/.local/share/chezmoi/setup/install.sh
```

Or navigate to the setup directory:

```bash
cd ~/.local/share/chezmoi/setup
./install.sh
```

The script will:
1. Detect your operating system
2. Check for already-installed tools (skips them)
3. Install missing applications based on your preferences
4. Report success/failures at the end

**Note:** The script can be run from any directory - it uses absolute paths and saves temporary files to `/tmp/`.

## Customization

### Adding a New Tool

**Mac:** Add to `mac-apps.yml` under appropriate section
```yaml
cli_tools:
  - newtool
```

**Linux:** Add to `linux-apps.yml` with installation method
```yaml
cli_tools:
  newtool:
    method: apt
```

***Check the `YAML_GUIDE.md` and `INTEGRATION_GUIDE.md` files for specifics of how to add, edit, or remove items from `linux-apps.yml` or `mac-apps.yml`.*** 

### Changing Installation Method (Linux)

Edit `linux-apps.yml`:
```yaml
vscode:
  method: snap  # Changed from 'apt'
```

Then run `./install.sh` again. Already-installed tools will be skipped.

## Installation Methods (Linux Only)

Linux offers multiple ways to install applications. Edit `linux-apps.yml` to set your preferences.

### Quick Comparison Table

| Method | Description | Security Model | Updates | Best For |
|--------|-------------|----------------|---------|----------|
| **apt** | System package manager | GPG-signed packages | Manual (`apt upgrade`) | System tools, CLI apps, official repos |
| **snap** | Canonical's sandboxed apps | Centralized store verification | Automatic | GUI apps, Ubuntu-native apps |
| **flatpak** | Cross-distro sandboxed apps | OSTree signing | Automatic | Cross-platform apps, latest versions |
| **deb** | Direct .deb download | Varies (some provide GPG) | Manual (update version in YAML) | Apps without repos (RStudio, Positron) |
| **official** | Tool's install script | Varies by tool | Usually manual | Dev tools (pyenv, nvm, uv) |
| **manual** | Download yourself | You verify | You track | Niche tools, beta software |

---

### apt (Advanced Package Tool)

**How it works:**
- Ubuntu's core package manager
- Packages come from repositories (repos) - either Ubuntu's official repos or third-party repos
- Each package is **GPG-signed** to verify authenticity

**Security: The GPG Workflow**

When you install from a third-party apt repository, you need to establish trust:

1. **Get the GPG public key** - The package maintainer's "signature"
   ```bash
   curl -fsSL https://example.com/key.gpg
   ```

2. **Convert to binary format** - apt prefers binary keys
   ```bash
   | gpg --dearmor
   ```

3. **Save to system keyrings** - Store in apt's trusted keys location
   ```bash
   | sudo tee /etc/apt/keyrings/appname.gpg
   ```

4. **Add repository with signed-by** - Tell apt to use this specific key
   ```bash
   deb [signed-by=/etc/apt/keyrings/appname.gpg] https://example.com/repo stable main
   ```

5. **Install package** - apt verifies signature on every download
   ```bash
   sudo apt update && sudo apt install appname
   ```

**Why GPG matters:** Without signature verification, a hacker could intercept your download and replace legitimate packages with malware. GPG signatures prove packages are authentic and unmodified.

**Pros:**
- ✅ Best system integration (uses system libraries)
- ✅ Automatic security updates (for packages in official repos)
- ✅ Small disk footprint
- ✅ Fast installation
- ✅ Standard Debian/Ubuntu way

**Cons:**
- ❌ Often older versions (especially in official repos)
- ❌ Requires adding custom repos for many apps
- ❌ Manual GPG key management for third-party repos

**When to use:** System tools, CLI utilities, apps with official apt repos

---

### snap (Snapcraft)

**How it works:**
- Centralized app store run by Canonical (Ubuntu's parent company)
- Apps are **sandboxed** (isolated from your system)
- Canonical verifies publisher identity
- No GPG keys to manage - trust is centralized through Snapcraft.io

**Security Model:**
```
Developer → Uploads to Snapcraft.io → Canonical verifies identity
                                    ↓
You → snap install appname → Snapcraft.io → Cryptographically verified download
```

**Sandboxing:**
- Each snap runs in a container with limited access to your system
- Apps request specific permissions (like mobile apps)
- More secure but can cause integration issues

**Pros:**
- ✅ Ubuntu's official method for third-party GUI apps
- ✅ Automatic background updates
- ✅ Easy installation (no repos/keys to manage)
- ✅ Sandboxed security
- ✅ Always latest versions

**Cons:**
- ❌ Slower startup times (containerization overhead)
- ❌ Higher disk usage (each snap includes its dependencies)
- ❌ Some filesystem/integration quirks due to sandboxing
- ❌ Requires snapd daemon running

**When to use:** GUI applications, apps not in apt, modern desktop apps

**Setup:** Snapd comes pre-installed on Ubuntu. If not:
```bash
sudo apt install snapd
sudo systemctl enable --now snapd
```

---

### flatpak (Flathub)

**How it works:**
- Decentralized but usually uses Flathub as the main repository
- Apps are **sandboxed** similar to snap
- Uses OSTree for versioning and signing (different from GPG)
- More cross-distribution than snap

**Security Model:**
```
Developer → Uploads to Flathub → Community review → OSTree signing
                                                   ↓
You → flatpak install → Flathub → Cryptographically verified download
```

**Pros:**
- ✅ Works identically across all Linux distributions
- ✅ Large app selection (Flathub)
- ✅ Automatic updates
- ✅ Sandboxed security
- ✅ Community-driven (not controlled by one company)

**Cons:**
- ❌ Higher disk usage (like snap)
- ❌ Less Ubuntu-native than snap
- ❌ Requires initial flatpak setup
- ❌ Some integration quirks

**When to use:** Apps not available in apt/snap, cross-platform consistency, prefer community-driven ecosystem

**Setup:**
```bash
# Install flatpak
sudo apt install flatpak

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Restart (required for first-time setup)
```

---

### deb (Direct .deb Download)

**How it works:**
- Downloads a `.deb` package file directly from the application's website
- Installs using `apt install` (which handles dependencies)
- No repository needed - just a direct download URL

**Two variants:**

1. **Static URL** (like Zoom's "latest"):
   ```yaml
   zoom:
     method: deb
     deb_url: "https://zoom.us/client/latest/zoom_amd64.deb"
   ```

2. **Versioned** (like RStudio):
   ```yaml
   rstudio:
     method: deb
     version: "2026.01.0-392"
     deb_url: "https://download1.rstudio.org/electron/jammy/amd64/rstudio-{version}-amd64.deb"
   ```
   The `{version}` placeholder gets replaced with the `version` value.

**Security:**
- Varies by application
- Some provide GPG signatures (e.g., RStudio)
- Download over HTTPS provides transport security
- You're trusting the application vendor's download server

**Pros:**
- ✅ Clean integration with setup scripts
- ✅ Version tracking in YAML file
- ✅ Easy to update (just change `version:` field)
- ✅ Works for apps without repositories

**Cons:**
- ❌ Manual version updates required
- ❌ No automatic updates
- ❌ Trust depends on vendor

**When to use:** Applications that provide .deb downloads but no apt repository (RStudio, Positron, some proprietary apps)

---

### official (Tool's Install Script)

**How it works:**
- Run a shell script provided by the tool's developers
- Script downloads and installs the tool
- Usually installs to user directory (like `~/.pyenv`) or system-wide

**Security:** Varies by tool. You're trusting the tool's developers and their server.

**Pros:**
- ✅ Always latest version
- ✅ Direct from source
- ✅ Often better maintained than distribution packages
- ✅ Works across distributions

**Cons:**
- ❌ Less system integration
- ❌ Usually requires manual updates
- ❌ Security depends on the specific tool

**When to use:** Development tools (pyenv, nvm, uv), tools that change frequently

---

### manual (Download and Install Yourself)

**How it works:**
- Download a `.deb` file from the app's website
- Install with `sudo dpkg -i filename.deb`

**When to use:**
- App only provides manual downloads
- Beta/preview versions
- You want full control over the source

**Pros:**
- ✅ Full control
- ✅ Can inspect before installing

**Cons:**
- ❌ No automation in scripts
- ❌ Must manually track updates
- ❌ Most work

---

### Default Strategy (How the YAML Was Created)

When creating `linux-apps.yml`, I followed this decision-making priority:
1. **Official apt repos** (when available) - Best integration
2. **Direct .deb downloads** - For apps like RStudio without repos
3. **Snap** - For GUI apps, easy management
4. **Official install scripts** - For dev tools like pyenv, nvm
5. **Manual** - Fallback with instructions

**Important:** The script uses *only* what's specified in `linux-apps.yml` for each tool. There's no runtime fallback or priority checking. If you want to change how an app is installed, edit its entry in the YAML file.

## Configuration Files

### `mac-apps.yml`
Simple list of applications. All installed via Homebrew (formulae or casks).

### `linux-apps.yml`
Applications with installation methods specified. Edit to change how each app is installed.

#### Understanding the YAML Structure

The `linux-apps.yml` file uses different structures depending on the installation method:

**Simple apt install (from Ubuntu's default repos):**
```yaml
firefox:
  method: apt
  notes: "Web browser from Ubuntu repos"
```
- Package name matches the tool name
- No custom repo needed

**apt with different package name:**
```yaml
pass-cli:
  method: apt
  package: pass
  notes: "Package is called 'pass' but we reference it as 'pass-cli'"
```
- `package:` specifies the actual apt package name when it differs from our reference name

**apt with custom repository:**
```yaml
vscode:
  method: apt
  package: code
  repo:
    key_url: https://packages.microsoft.com/keys/microsoft.asc
    repo_line: "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-keyring.gpg] https://packages.microsoft.com/repos/code stable main"
    repo_file: vscode.list
  notes: "VS Code from official Microsoft repository"
```
- `key_url`: URL to download the GPG public key (verify this on the tool's official site)
- `repo_line`: The repository configuration line (verify format on tool's site)
- `repo_file`: Filename for the repo config in `/etc/apt/sources.list.d/` (you choose this name, usually `appname.list`)
- The GPG key will be saved to `/usr/share/keyrings/{appname}-keyring.gpg`

**snap install:**
```yaml
slack:
  method: snap
  classic: true
  notes: "Team communication - requires classic confinement"
```
- `classic: true` means the snap needs classic confinement (less sandboxing, more system access)
- `classic: false` or omitted means strict confinement (more sandboxed)

**flatpak install:**
```yaml
some-app:
  method: flatpak
  package: com.example.AppName
  notes: "The flatpak package identifier from Flathub"
```
- `package:` is the flatpak application ID (find on flathub.org)

**official install script:**
```yaml
pyenv:
  method: official
  script: "curl https://pyenv.run | bash"
  notes: "Python version manager - adds to shell config automatically"
```
- `script:` the exact command to run for installation

**manual install:**
```yaml
zoom:
  method: manual
  url: https://zoom.us/download?os=linux
  notes: "Download .deb file and install with: sudo dpkg -i zoom_amd64.deb"
```
- `url:` where to download from
- `notes:` instructions for manual installation

#### Verifying Repository Information

**IMPORTANT:** Always verify repository details from the official source:

1. **key_url**: Go to the app's official Linux installation page
   - Look for "GPG key" or "signing key"
   - Copy the exact URL they provide
   - Example: VS Code docs at https://code.visualstudio.com/docs/setup/linux

2. **repo_line**: Copy from official docs
   - Pay attention to `signed-by=` path - should match where the script saves the key
   - Architecture (`arch=amd64`) and distribution (`stable`, `jammy`, etc.)

3. **repo_file**: You choose this filename
   - Convention: `{appname}.list`
   - Must end in `.list`
   - Gets saved to `/etc/apt/sources.list.d/`

**Example - Finding Bruno's GPG info:**
1. Go to https://www.usebruno.com/downloads
2. Click "Linux" → "View installation instructions"
3. Find the `curl` command for the GPG key - that's your `key_url`
4. Find the `echo "deb..."` command - that's your `repo_line`
5. The filename in `tee /etc/apt/sources.list.d/filename.list` - that's your `repo_file`


## Testing

Test individual scripts:
```bash
# Dry run (shows what would be installed)
DRY_RUN=1 ./install.sh

# Test specific OS script
./mac-setup.sh
./linux-setup.sh
```

## Troubleshooting

**"Command not found" after installation:**
- Close and reopen your terminal
- Source your shell config: `source ~/.bashrc` or `source ~/.zshrc`

**Permission errors:**
- Some tools may require sudo. The script will prompt when needed.

**Failed installations:**
- Check the error message
- For manual installations, follow the URL/notes in the YAML config
- Re-run `./install.sh` after fixing issues

**Snap daemon not running:**
```bash
sudo systemctl start snapd
sudo systemctl enable snapd
```

**Flatpak not set up:**
```bash
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# Restart required after first install
```

## Security: Verifying Repository Information

**CRITICAL:** Always verify GPG keys and repository URLs from official sources before adding them to your system.

### How to Verify

For each tool using `method: apt` with a custom `repo:`, you should:

1. **Visit the official website/docs** for the tool
   - Look for "Linux installation" or "Ubuntu installation" instructions
   - Find the section about adding repositories

2. **Verify the GPG key URL** (`key_url`)
   - Official docs will show a command like: `curl -fsSL <URL> | sudo gpg...`
   - Copy that exact URL to `key_url`
   - **Never use a GPG key URL from an unofficial source**

3. **Verify the repository line** (`repo_line`)
   - Official docs will show: `echo "deb [arch=...] <URL> ..." | sudo tee...`
   - Copy that exact repository line
   - Make sure `signed-by=` path matches where the script saves the key

4. **Choose the repo filename** (`repo_file`)
   - This is the filename that will be created in `/etc/apt/sources.list.d/`
   - Convention: `{tool-name}.list` (must end in `.list`)
   - You control this - it's just for organization

### Example: Verifying VS Code Repository

1. Go to official docs: https://code.visualstudio.com/docs/setup/linux
2. Under "Debian and Ubuntu based distributions", find:
   ```bash
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
   ```
   → `key_url: https://packages.microsoft.com/keys/microsoft.asc` ✓

3. Find:
   ```bash
   echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
   ```
   → Adjust to: `repo_line: "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-keyring.gpg] https://packages.microsoft.com/repos/code stable main"` ✓

4. Choose filename: `repo_file: vscode.list` ✓

### Red Flags

⚠️ **DO NOT PROCEED** if:
- The GPG key URL is not on the official domain
- You can't find official installation instructions
- The repository URL looks suspicious
- Instructions come from a third-party blog/forum

When in doubt, use `method: manual` or `method: snap` instead.

---

### Manual GPG Verification for .deb Packages

Some applications (like RStudio) provide GPG signatures for their .deb files. Here's how to manually verify:

#### What is GPG Verification?

GPG (GNU Privacy Guard) uses **public-key cryptography** to verify file authenticity:

1. **Developer signs** the file with their private key (only they have this)
2. **You verify** using their public key (everyone can have this)
3. **Math proves** the file hasn't been tampered with since signing

**Analogy:** Like a wax seal on a letter - you can verify it's from the claimed sender and hasn't been opened.

#### Steps to Verify

**1. Get the developer's public key:**
```bash
# Import from keyserver (RStudio example)
gpg --keyserver keys.openpgp.org --recv-keys 51C0B5B19F92D60
```

You can also search interactively:
```bash
gpg --keyserver keys.openpgp.org --search-keys 51C0B5B19F92D60
```

**2. Download both the .deb and its signature:**
```bash
# Download the package
wget https://download1.rstudio.org/.../rstudio-2026.01.0-392-amd64.deb

# Download the signature (usually same URL + .asc)
wget https://download1.rstudio.org/.../rstudio-2026.01.0-392-amd64.deb.asc
```

**3. Verify the signature:**
```bash
gpg --verify rstudio-2026.01.0-392-amd64.deb.asc rstudio-2026.01.0-392-amd64.deb
```

**Good output looks like:**
```
gpg: Signature made Thu 09 Jan 2025 02:15:23 PM EST
gpg:                using RSA key 51C0B5B19F92D60
gpg: Good signature from "Posit Software, PBC <...>"
```

**Bad output (DO NOT INSTALL):**
```
gpg: BAD signature from "..."
```

**4. Install if verification passes:**
```bash
sudo apt install ./rstudio-2026.01.0-392-amd64.deb
```

#### Automatic Verification in Scripts

If you add `gpg_key_id` and `gpg_keyserver` to your YAML for `deb` method apps, the script will automatically attempt verification:

```yaml
rstudio:
  method: deb
  version: "2026.01.0-392"
  deb_url: "https://download1.../rstudio-{version}-amd64.deb"
  gpg_key_id: "51C0B5B19F92D60"
  gpg_keyserver: "keys.openpgp.org"
```

The script will:
- Import the key
- Download the .asc signature file
- Verify before installing
- Prompt you if verification fails

#### Finding GPG Information

Look for "code signing" or "verification" pages on the software's website:
- **RStudio:** https://posit.co/code-signing/
- **Zoom:** Provides SHA256 checksums but not GPG signatures
- **Signal:** Uses apt repository with GPG (already handled)

Not all software provides GPG signatures - HTTPS download is still reasonably secure.

## Philosophy

These scripts follow the principle: **install only what you explicitly need**. If you don't recognize a tool, it's intentionally excluded. Discover needs organically through your workflow, then add them to the config files.

## Scripts Overview

- `install.sh` - Detects OS and calls appropriate setup script
- `mac-setup.sh` - Handles all Mac installations via Homebrew
- `linux-setup.sh` - Handles Linux installations based on YAML config
- `common.sh` - Shared logging and utility functions