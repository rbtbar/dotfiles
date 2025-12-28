# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io/).

**Supported platforms:** macOS (Apple Silicon), Ubuntu 24.04

## Repository Access

### Generate SSH key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Configure SSH agent (macOS)

```bash
eval "$(ssh-agent -s)"
```

Edit `~/.ssh/config`:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519_github
```

Add key to agent:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github
```

### Add key to GitHub

```bash
pbcopy < ~/.ssh/id_ed25519_github.pub
```

Paste at https://github.com/settings/keys

### Test connection

```bash
ssh -T git@github.com
```

## Installation

### With SSH key (recommended for regular machines)

```bash
export GITHUB_USERNAME=rbtbar
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply git@github.com:$GITHUB_USERNAME/dotfiles.git
```

### With GitHub token (for one-time/ephemeral setups)

```bash
export GITHUB_USERNAME=rbtbar
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply "https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/dotfiles.git"
```

Generate a token at https://github.com/settings/tokens (only `repo` scope needed for private repos, or no scope for public).

## Reset

Remove chezmoi completely:

```bash
rm -rf "$HOME/.config/chezmoi" "$HOME/.local/bin/chezmoi" "$HOME/.local/share/chezmoi"
```

## Docker Testing

Test the Linux bootstrap in a container:

```bash
docker run -it --rm -v "$(pwd):/dotfiles" -w /dotfiles ubuntu:24.04 bash
```

Inside the container:

```bash
apt-get update && apt-get install -y curl wget git
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --source .
```
