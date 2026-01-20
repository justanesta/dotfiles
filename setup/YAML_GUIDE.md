# linux-apps.yml Quick Reference Guide

## YAML Structure Patterns

This guide explains each pattern used in `linux-apps.yml` with examples.

---

## Pattern 1: Simple apt (Ubuntu Default Repos)

Use when the app is in Ubuntu's default repositories and the package name matches.

```yaml
firefox:
  method: apt
  notes: "Description of the tool"
```

**When to use:** The tool is in Ubuntu's repos and `apt install firefox` works.

**What the script does:**
1. Checks if `firefox` is installed
2. If not: `sudo apt install firefox`

---

## Pattern 2: apt with Different Package Name

Use when the apt package name differs from how you reference it.

```yaml
pass-cli:
  method: apt
  package: pass
  notes: "The actual apt package is called 'pass'"
```

**When to use:** You want to call it `pass-cli` in your list, but apt knows it as `pass`.

**What the script does:**
1. Checks if `pass` is installed
2. If not: `sudo apt install pass`

---

## Pattern 3: apt with Custom Repository

Use when you need to add a third-party apt repository first.

```yaml
vscode:
  method: apt
  package: code
  repo:
    key_url: https://packages.microsoft.com/keys/microsoft.asc
    repo_line: "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-keyring.gpg] https://packages.microsoft.com/repos/code stable main"
    repo_file: vscode.list
  notes: "VS Code from Microsoft's official repository"
```

**Components explained:**

- `package: code` - The actual package name (VS Code's apt package is called `code`)
- `key_url` - URL to download the GPG public key
  - **Where to find:** Official installation docs (e.g., https://code.visualstudio.com/docs/setup/linux)
  - **Verify:** Must be from the official domain
- `repo_line` - The repository source line
  - **Format:** `deb [arch=... signed-by=...] <URL> <distribution> <component>`
  - **signed-by:** Must match `/usr/share/keyrings/{appname}-keyring.gpg`
  - **Where to find:** Copy from official docs
- `repo_file` - Filename for the repo config
  - **Saved to:** `/etc/apt/sources.list.d/{repo_file}`
  - **You choose this:** Convention is `{appname}.list`
  - **Must end in:** `.list`

**What the script does:**
1. Downloads GPG key from `key_url`
2. Converts to binary: `gpg --dearmor`
3. Saves to: `/usr/share/keyrings/vscode-keyring.gpg`
4. Creates repo config: `/etc/apt/sources.list.d/vscode.list` with content from `repo_line`
5. Runs: `sudo apt update`
6. Installs: `sudo apt install code`

**Security check:** Always verify `key_url` and `repo_line` are from official docs!

---

## Pattern 4: snap

Use for Snapcraft packages.

```yaml
slack:
  method: snap
  classic: true
  notes: "Requires classic confinement for system integration"
```

**Components explained:**

- `classic: true` - Use classic confinement (less sandboxed, more access)
  - Required for apps needing full filesystem/system access
  - Examples: IDEs, some communication apps
- `classic: false` or omit - Use strict confinement (more sandboxed)
  - Safer but may have limitations
  - Examples: Games, simple utilities

**What the script does:**
1. Checks if snap is installed: `snap list slack`
2. If not: `sudo snap install slack --classic`

**Find the app:** Search on https://snapcraft.io/

---

## Pattern 5: flatpak

Use for Flathub packages.

```yaml
gimp:
  method: flatpak
  package: org.gimp.GIMP
  notes: "Image editor from Flathub"
```

**Components explained:**

- `package` - The flatpak application ID
  - **Format:** Reverse domain notation (org.domain.AppName)
  - **Where to find:** https://flathub.org/ (search for the app)

**What the script does:**
1. Checks if flatpak is installed: `flatpak list | grep org.gimp.GIMP`
2. If not: `flatpak install flathub org.gimp.GIMP`

**Prerequisite:** Flatpak must be set up (see README troubleshooting section)

---

## Pattern 6: official (Install Script)

Use when the tool provides its own installation script.

```yaml
pyenv:
  method: official
  script: "curl https://pyenv.run | bash"
  notes: "Python version manager. Adds to shell config automatically."
```

**Components explained:**

- `script` - The exact command to run
  - **Must be:** The full command as shown in official docs
  - **Piped installs:** `curl ... | bash` is common pattern
  - **Where to find:** Official GitHub repo or project website

**What the script does:**
1. Checks if command exists: `command -v pyenv`
2. If not: Runs the script exactly as specified

**Security:** Only use scripts from official sources!

---

## Pattern 7: manual

Use when you need to download and install manually.

```yaml
zoom:
  method: manual
  url: https://zoom.us/download?os=linux
  notes: "Download .deb file and install with: sudo apt install ./zoom_amd64.deb"
```

**Components explained:**

- `url` - Where to download the installer
- `notes` - Step-by-step installation instructions
  - **Tip:** Use `sudo apt install ./file.deb` instead of `dpkg -i` (handles dependencies better)

**What the script does:**
1. Displays the URL
2. Shows the installation instructions
3. YOU download and install manually

---

## Pattern 8: deb (Direct .deb Download)

Use for applications that provide direct .deb downloads but no apt repository.

### Simple (static URL):
```yaml
zoom:
  method: deb
  deb_url: "https://zoom.us/client/latest/zoom_amd64.deb"
  notes: "Uses 'latest' URL - always gets current version"
```

### Versioned (with placeholder):
```yaml
rstudio:
  method: deb
  version: "2026.01.0-392"
  deb_url: "https://download1.rstudio.org/electron/jammy/amd64/rstudio-{version}-amd64.deb"
  gpg_key_id: "51C0B5B19F92D60"
  gpg_keyserver: "keys.openpgp.org"
  notes: "Update 'version' field for new releases"
```

**Components explained:**

- `deb_url` - Direct URL to the .deb file
  - Can include `{version}` placeholder which gets replaced with `version` field
  - For static URLs (like Zoom's "latest"), just use the URL directly
- `version` - Optional version number
  - Only needed if using `{version}` placeholder in `deb_url`
  - **This is what you update** when new versions release
- `gpg_key_id` / `gpg_keyserver` - Optional GPG verification info
  - Currently documented but not auto-verified by script
  - Use for reference/manual verification

**What the script does:**
1. Replaces `{version}` in `deb_url` with the `version` value
2. Downloads the .deb file to `/tmp/`
3. Installs: `sudo apt install /tmp/{name}.deb` (handles dependencies)
4. Cleans up the temporary file

**Benefits over manual:**
- ✅ All version info in one place (YAML file)
- ✅ Easy to update: just change the `version:` field
- ✅ Automatic download and install
- ✅ Works in your setup flow alongside other apps
- ✅ Dependency handling via `apt install`

**When to use:**
- App provides direct .deb downloads (not a repository)
- You want to track which version you're using
- Examples: RStudio, Positron, Zoom, GitHub Desktop

#### GPG Verification for deb Method

Some applications provide GPG signatures. Add these fields for automatic verification:

```yaml
rstudio:
  method: deb
  version: "2026.01.0-392"
  deb_url: "https://download1.../rstudio-{version}-amd64.deb"
  gpg_key_id: "51C0B5B19F92D60"         # ← Find on code-signing page
  gpg_keyserver: "keys.openpgp.org"      # ← Usually this keyserver
  notes: "..."
```

**What the script does with GPG info:**
1. Imports the key: `gpg --keyserver keys.openpgp.org --recv-keys 51C0B5B19F92D60`
2. Downloads signature: `wget {deb_url}.asc`
3. Verifies: `gpg --verify file.deb.asc file.deb`
4. Prompts if verification fails

**Finding GPG information:**
- Check the software's "code signing" or "verification" documentation
- RStudio: https://posit.co/code-signing/
- If not available, omit `gpg_key_id` and `gpg_keyserver` (HTTPS is still secure)

**Manual verification:**
```bash
# 1. Import key
gpg --keyserver keys.openpgp.org --recv-keys 51C0B5B19F92D60

# 2. Download package and signature
wget https://url/to/package.deb
wget https://url/to/package.deb.asc

# 3. Verify (should say "Good signature")
gpg --verify package.deb.asc package.deb

# 4. Install if good
sudo apt install ./package.deb
```

---

## Special: Node Packages

```yaml
node:
  nvm:
    method: official
    script: "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
    notes: "Node Version Manager"
  
  packages:
    - "@anthropic-ai/claude-code"
```

**What the script does:**
1. Installs NVM using the official script
2. After NVM is installed, you run: `nvm install --lts`
3. Then install global packages: `npm install -g @anthropic-ai/claude-code`

---

## Decision Tree: Which Pattern to Use?

```
Is the app in Ubuntu's default repos?
├─ YES → Pattern 1 (simple apt)
│
└─ NO → Does it need a custom apt repo?
    ├─ YES → Pattern 3 (apt with repo)
    │
    └─ NO → Does it provide direct .deb downloads?
        ├─ YES → Pattern 8 (deb)
        │
        └─ NO → Is it available as a snap?
            ├─ YES → Pattern 4 (snap)
            │
            └─ NO → Is it available as a flatpak?
                ├─ YES → Pattern 5 (flatpak)
                │
                └─ NO → Does it have an install script?
                    ├─ YES → Pattern 6 (official)
                    │
                    └─ NO → Pattern 7 (manual)
```

---

## Common Mistakes

❌ **Wrong:** Package name in key name doesn't match actual package
```yaml
vscode:
  method: apt
  # Missing package: code
```

✅ **Right:**
```yaml
vscode:
  method: apt
  package: code
```

---

❌ **Wrong:** GPG key path doesn't match between repo_line and script
```yaml
repo:
  repo_line: "deb [signed-by=/some/random/path.gpg] ..."
```

✅ **Right:** Use standard path that script expects
```yaml
repo:
  repo_line: "deb [signed-by=/usr/share/keyrings/appname-keyring.gpg] ..."
```

---

❌ **Wrong:** Snap without classic specification
```yaml
slack:
  method: snap
  # Will fail - Slack needs classic confinement
```

✅ **Right:**
```yaml
slack:
  method: snap
  classic: true
```

---

## Need Help?

1. Check the app's official Linux installation docs
2. Look at existing examples in `linux-apps.yml`
3. Search for the app on:
   - https://snapcraft.io/ (for snap)
   - https://flathub.org/ (for flatpak)
4. When in doubt, use `method: manual` to avoid errors
