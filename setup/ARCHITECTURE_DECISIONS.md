# Architecture Decision: Cost/Benefit Analysis

## Setup Script Architecture

---

### Separate Scripts
Scripts managed by chezmoi but executed manually.

| Benefits | Costs |
|----------|-------|
| ✅ Clean separation of concerns | ⚠️ One extra manual step: `./setup/install.sh` |
| ✅ Easy to test individually | |
| ✅ Easy to re-run if failures occur | |
| ✅ Clear error messages and progress | |
| ✅ Can run partially (just Mac or Linux script) | |
| ✅ Doesn't slow down `chezmoi apply` | |
| ✅ Version controlled alongside dotfiles | |
| ✅ Iterative improvement friendly | |

**Best for:** Users who value control, testability, and clear feedback.

---

## Installation Method Approaches (Linux)

### Declarative YAML Config (CHOSEN)
Define all installation methods upfront in `linux-apps.yml`.

| Benefits | Costs |
|----------|-------|
| ✅ No prompts - fully automated | ⚠️ Requires upfront decisions |
| ✅ Version controlled | ⚠️ Need to learn YAML syntax (minimal) |
| ✅ Self-documenting | |
| ✅ Easy to modify and iterate | |
| ✅ Testable and reproducible | |
| ✅ Clear at a glance what will be installed | |
| ✅ Can copy between machines | |
| ✅ Aligns with "documentation from the start" philosophy | |

Perfect fit for your stated values (documentation, iteration, clarity).

---

## Installation Method Selection (Linux)

### apt (System Package Manager)

| Benefits | Costs |
|----------|-------|
| ✅ Best system integration | ❌ Often older versions |
| ✅ Automatic security updates | ❌ Some apps not available |
| ✅ Fast installation | ❌ May need custom repos |
| ✅ Small disk footprint | |
| ✅ Standard Debian/Ubuntu way | |

**Best for:** System tools, CLI utilities, well-maintained packages.

---

### snap (Canonical's Sandboxed Apps)

| Benefits | Costs |
|----------|-------|
| ✅ Ubuntu's official method for GUI apps | ❌ Slower startup times |
| ✅ Auto-updates | ❌ Higher disk usage (each snap has dependencies) |
| ✅ Large app selection | ❌ Some integration quirks |
| ✅ Easy to install | ❌ Controversial in Linux community |
| ✅ Sandboxed (more secure) | |

**Best for:** GUI applications, apps not in apt, modern desktop apps.

---

### flatpak (Cross-Distro Sandboxed Apps)

| Benefits | Costs |
|----------|-------|
| ✅ Works across distros | ❌ Requires flatpak setup first |
| ✅ Large app selection (Flathub) | ❌ Higher disk usage |
| ✅ Sandboxed security | ❌ Less Ubuntu-native |
| ✅ Auto-updates | |

**Best for:** Apps not available in apt/snap, cross-platform consistency.

---

### official (Tool's Install Script)

| Benefits | Costs |
|----------|-------|
| ✅ Always latest version | ❌ Less system integration |
| ✅ Direct from source | ❌ Manual updates usually |
| ✅ Works across distros | ❌ May require sudo |
| ✅ Often better maintained | ❌ Less standardized |

**Best for:** Dev tools (pyenv, nvm, uv), tools that change frequently.

---

### manual (Download & Install Yourself)

| Benefits | Costs |
|----------|-------|
| ✅ Full control | ❌ Most manual work |
| ✅ Can inspect before installing | ❌ No automation |
| ✅ Works for any package | ❌ Must track updates yourself |

**Best for:** Niche tools, beta software, when other methods unavailable.

---

## Summary

**Architecture: Separate Scripts**
- Aligns with your values: clear documentation, iterative improvement, testing
- One extra manual step is acceptable trade-off for control and clarity
- Easy to debug and re-run

**Configuration: YAML-Based** (Declarative)
- Version controlled, self-documenting, testable
- No tedious prompts
- Can iterate and improve over time

**Installation Strategy:**
- **Mac:** Simple list → Homebrew handles everything
- **Linux:** YAML with methods → Flexible but decided upfront

**Default Installation Preferences:**
- System tools, CLI apps: `apt` (with official repos when available)
- GUI apps on Ubuntu: `snap` (it's Ubuntu's way)
- Dev tools: `official` scripts (pyenv, nvm, uv)
- Fallback: `manual` with clear instructions

This gives you automation without sacrificing control, documentation without tedium, and flexibility without confusion.
