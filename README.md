# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io/).

**Supported platforms:** macOS, Linux (apt-get)

## Installation

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply "https://github.com/rbtbar/dotfiles.git"
```

## Update

```bash
chezmoi git pull && chezmoi apply
```


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
