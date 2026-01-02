# Dotfiles (managed with chezmoi)

This repository manages my dotfiles using **[chezmoi](https://www.chezmoi.io/)**.

Chezmoi maintains a **source-of-truth directory** under version control and applies changes explicitly to `$HOME`. You edit the source, review changes, then apply them—making dotfile management safe, repeatable, and portable across machines.

---

## Core concepts

- **Target files**  
  The actual dotfiles in `$HOME` (e.g. `~/.bashrc`, `~/.gitconfig`).

- **Source state**  
  Chezmoi’s managed copies (e.g. `dot_bashrc`) stored under: `~/.local/share/chezmoi`

- **Apply step**  
Changes only affect `$HOME` when you explicitly apply them:
```bash
chezmoi -v apply
```
## Typical workflow

### Edit an existing dotfile
```bash
chezmoi edit ~/.bashrc
```
* Opens the chezmoi-managed source file
* Uses `$VISUAL` or `$EDITOR`
* Does not modify `$HOME` yet  

Review changes:
```bash
chezmoi diff
```

Apply changes:
```bash
chezmoi -v apply
```
### Add a new dotfile
```bash
chezmoi add ~/.config/git/ignore
```
* Copies the file into the chezmoi source state
* Converts filenames automatically (`dot_`, `private_`, etc.)

### Sync changes made outside chezmoi
```bash
chezmoi re-add ~/.bash_aliases
```
## Common commands
| Command                 | Description                                |
| ----------------------- | ------------------------------------------ |
| `chezmoi init`          | Initialize chezmoi on this machine         |
| `chezmoi init <repo>`   | Clone an existing dotfiles repo            |
| `chezmoi edit <path>`   | Edit a managed dotfile (source state)      |
| `chezmoi add <path>`    | Start managing a new dotfile               |
| `chezmoi re-add <path>` | Sync external edits into chezmoi           |
| `chezmoi diff`          | Show differences between source and target |
| `chezmoi apply`         | Apply source state to `$HOME`              |
| `chezmoi apply -v`      | Apply with verbose output                  |
| `chezmoi cd`            | Open a shell in the source directory       |
| `chezmoi status`        | Show managed files and their state         |
| `chezmoi update`        | Pull repo updates and apply them           |
| `chezmoi doctor`        | Diagnose common configuration issues       |

## Fresh machine setup
```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# Initialize from this repository and apply
chezmoi init --apply https://github.com/justanesta/dotfiles.git

# OR if you use GitHub adn your dotfiles repo is called `dotfiles` this can be shortened to

chezmoi init --apply justanesta
```

## Chezmoi references
* [Install](https://www.chezmoi.io/install/)
* [Quick start](https://www.chezmoi.io/quick-start/)
* [Usage FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/)
* [Command overview](https://www.chezmoi.io/user-guide/command-overview/)

This installs chezmoi, clones the dotfiles repo, and applies all managed dotfiles to `$HOME` in one step.