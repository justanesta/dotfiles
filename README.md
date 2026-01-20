# Dotfiles (managed with chezmoi)

This repository manages my dotfiles using **[chezmoi](https://www.chezmoi.io/)** across multiple machines with different operating systems and password managers.

## Machines

| Machine | OS | Password Manager | Identifier |
|---------|-----|------------------|------------|
| Personal System76 | Pop!_OS 22.04 (Linux) | ProtonPass CLI | `personal-system76` |
| Work Mac | macOS Sequoia | 1Password CLI + ProtonPass CLI | `work-mac` |

---

## Quick start

### Fresh machine setup

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# Initialize from this repository and apply (prompts for machine type)
chezmoi init --apply https://github.com/justanesta/dotfiles.git

# OR if you use GitHub and your dotfiles repo is called `dotfiles` this can be shortened to (prompts for machine type)
chezmoi init --apply justanesta
```

When prompted "Which machine is this", select your machine type.

### Install password manager CLIs

**ProtonPass CLI (both machines):**
```bash
# Linux
curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

# macOS
brew install protonpass/tap/pass-cli

# Login
pass-cli login
```

**1Password CLI (work Mac only):**
```bash
brew install 1password-cli
# Authenticate via 1Password app
```

---

## Core concepts

- **Target files**: The actual dotfiles in `$HOME` (e.g., `~/.bashrc`, `~/.gitconfig`)
- **Source state**: Chezmoi's managed copies (e.g., `dot_bashrc.tmpl`) stored in `~/.local/share/chezmoi`
- **Templates**: Files ending in `.tmpl` that use Go template syntax for machine-specific content
- **Apply step**: Changes only affect `$HOME` when you explicitly run `chezmoi -v apply`

---

## Typical workflow

### Edit a managed dotfile

```bash
chezmoi edit ~/.bashrc    # Opens source template in $EDITOR
chezmoi diff              # Preview changes
chezmoi -v apply          # Apply to $HOME
```

### Add a new dotfile

```bash
chezmoi add ~/.config/tool/config           # Add as regular file
chezmoi add --template ~/.config/tool/config  # Add as template (for machine-specific content)
```

### Sync edits made outside chezmoi

```bash
chezmoi re-add ~/.bashrc
```

### Pull changes from another machine

```bash
chezmoi update    # git pull + apply
```

### Push changes to repo

```bash
chezmoi cd
git add -A
git commit -m "Description of changes"
git push
```
---

## Multi-machine templating

### Template variables

These are the variables that are currently set during `chezmoi init` based on your machine selection. More can be added or these can be edited.

| Variable | Description | Values |
|----------|-------------|--------|
| `.machine` | Machine identifier | `personal-system76`, `work-mac` |
| `.email` | Primary email for this machine | Machine-specific |
| `.gitEmail` | Email for git commits | `adrian@justanesta.com` (both) |
| `.isWork` | Work machine flag | `true` / `false` |
| `.isPersonal` | Personal machine flag | `true` / `false` |
| `.chezmoi.os` | Operating system | `linux`, `darwin` |

### Common template patterns

**Conditional by machine type:**
```
{{- if .isWork }}
# Work-only content
{{- end }}

{{- if .isPersonal }}
# Personal-only content
{{- end }}
```

**Conditional by OS:**
```
{{- if eq .chezmoi.os "darwin" }}
# macOS-only content
{{- else if eq .chezmoi.os "linux" }}
# Linux-only content
{{- end }}
```

**Variable substitution:**
```
email = {{ .gitEmail }}
name = {{ .name | quote }}
```

### Testing templates

```bash
# Test a template expression
chezmoi execute-template '{{ .machine }}'
chezmoi execute-template '{{ .chezmoi.os }}'

# Preview a file's rendered output
chezmoi cat ~/.bashrc

# See all available data
chezmoi data
```

---

## Password manager integration

### ProtonPass (both machines)

```bash
# Test CLI access
pass-cli vault list
pass-cli item list

# URI format: pass://vault/item/field
pass-cli item view "pass://Personal/Census Bureau API Key/API Key"
```

**In templates:**
```
{{ protonPass "pass://Personal/item-name/field" }}
{{ protonPassJSON "pass://Personal/item-name" }}
```

### 1Password (work Mac)

```bash
# Test CLI access
op vault list
op item list

# URI format: op://vault/item/field
op read "op://Employee/Prism Lens Personal API Keys/<ITEM_NAME>"
```

**In templates:**
```
{{ onepasswordRead "op://Vault/item/field" }}
{{ onepassword "item-uuid" }}
{{ onepasswordDetailsFields "item-uuid" }}
```

### Secrets files

Secrets are stored in password managers, referenced in templates, and generated locally:

```
Source (public repo)                         Target (local machine)
────────────────────                         ─────────────────────
api-keys.env.tmpl                     -->    ~/.config/secrets/api-keys.env
Contains: pass://Personal/item/field         Contains: ACTUAL_KEY="secret123"
```

**Always make secrets sourced in `.bashrc`**
This will make the secrets always available in terminal environments that source `.bashrc`

```bash
chezmoi edit ~/.bashrc
```

Add before the `### FUNCTIONS ###` section:

```bash
### SECRETS ###
# Source API keys (managed by chezmoi, fetched from password managers)
if [ -f ~/.config/secrets/api-keys.env ]; then
    source ~/.config/secrets/api-keys.env
fi

{{- if .isWork }}
if [ -f ~/.config/secrets/work-api-keys.env ]; then
    source ~/.config/secrets/work-api-keys.env
fi
{{- end }}

```

Then chezmoi apply, and add and commit in git.

```bash
chezmoi cd
git add -A
git commit -m "Source secrets files in bashrc"
git push
```


**Source secrets directly in bash scripts:**
```bash
#!/bin/bash
# Load API keys
source ~/.config/secrets/api-keys.env

# Now use them
curl "https://api.census.gov/data?key=${CENSUS_API_KEY}&..."
```

**Source in Python:**
```python
import os
from dotenv import load_dotenv

load_dotenv(os.path.expanduser("~/.config/secrets/api-keys.env"))

census_key = os.environ.get("CENSUS_API_KEY")
```

**Source in R:**
```R
# Using dotenv package
dotenv::load_dot_env("~/.config/secrets/api-keys.env")

census_key <- Sys.getenv("CENSUS_API_KEY")
```


---

## Command reference

### Essential commands

| Command | Description |
|---------|-------------|
| `chezmoi init <repo>` | Clone dotfiles repo and generate config |
| `chezmoi apply` | Apply source state to `$HOME` |
| `chezmoi apply -v` | Apply with verbose output |
| `chezmoi diff` | Preview changes before applying |
| `chezmoi update` | Pull from remote and apply |
| `chezmoi edit <file>` | Edit a managed file's source |
| `chezmoi add <file>` | Start managing a new file |
| `chezmoi cd` | Open shell in source directory |

### Troubleshooting commands

| Command | Description |
|---------|-------------|
| `chezmoi doctor` | Check for common problems |
| `chezmoi status` | Show managed files and their state |
| `chezmoi data` | Show available template variables |
| `chezmoi cat <file>` | Preview rendered file without applying |
| `chezmoi execute-template '{{ expr }}'` | Test template expressions |
| `chezmoi managed` | List all managed files |
| `chezmoi ignored` | List ignored files |

### Re-initialize config

If you change `.chezmoi.toml.tmpl`, regenerate your local config:

```bash
chezmoi init
```

---

## File structure

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl              # Config template (machine selection, variables)
├── .chezmoiignore                  # Files to ignore per machine
├── dot_bash_aliases.tmpl           # ~/.bash_aliases
├── dot_bash_profile.tmpl           # ~/.bash_profile (for macOS login shells)
├── dot_bashrc.tmpl                 # ~/.bashrc
├── dot_gitconfig.tmpl              # ~/.gitconfig
├── dot_profile.tmpl                # ~/.profile
├── private_dot_config/
│   ├── git/
│   │   └── ignore                  # ~/.config/git/ignore
│   └── private_secrets/
│       ├── api-keys.env.tmpl       # Shared API keys (ProtonPass)
│       └── work-api-keys.env.tmpl  # Work API keys (1Password)
└── README.md
```

---

## Adding a new machine

1. Add the machine identifier to `.chezmoi.toml.tmpl`:
   ```
   {{- $machineChoices := list "personal-system76" "work-mac" "new-machine" -}}
   ```

2. Add machine-specific logic as needed:
   ```
   {{- $isNewMachine := eq $machine "new-machine" -}}
   ```

3. Commit and push, then on the new machine:
   ```bash
   chezmoi init --apply justanesta
   ```

---

## References

- [chezmoi.io](https://www.chezmoi.io/)
- [Quick start](https://www.chezmoi.io/quick-start/)
- [Templating guide](https://www.chezmoi.io/user-guide/templating/)
- [Password managers](https://www.chezmoi.io/user-guide/password-managers/)
- [ProtonPass CLI docs](https://protonpass.github.io/pass-cli/)
- [1Password CLI docs](https://developer.1password.com/docs/cli/)