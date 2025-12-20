#!/usr/bin/env bash
set -euo pipefail

echo "[dotfiles] macOS bootstrap starting..."

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping Homebrew/bootstrap."
  exit 0
fi

# Install Homebrew if missing (Apple official script)
if ! command -v brew >/dev/null 2>&1; then
  echo "[dotfiles] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[dotfiles] Homebrew already installed, skipping install."
fi

# Apple Silicon-only brew setup (no Intel fallback)
if [ -d /opt/homebrew ]; then
  echo "[dotfiles] Configuring Homebrew shellenv for Apple Silicon..."
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Ensure brew shellenv is loaded in future shells
  if ! grep -q 'brew shellenv' "${HOME}/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
    echo "[dotfiles] Added brew shellenv to ~/.zprofile"
  fi
else
  echo "[dotfiles] WARNING: /opt/homebrew not found. Are you sure this is an Apple Silicon Mac?" >&2
fi

# Make sure chezmoi itself is installed via Homebrew
if ! brew list chezmoi >/dev/null 2>&1; then
  echo "[dotfiles] Installing chezmoi via Homebrew..."
  brew install chezmoi
else
  echo "[dotfiles] chezmoi already installed via Homebrew."
fi

echo "[dotfiles] Installing CLI tools and extras..."

# Core CLI tools
brew install jq yq fd bat eza zoxide direnv

# Zsh goodies
brew install zsh-syntax-highlighting zsh-autosuggestions zsh-completions fzf

brew install --formula jandedobbeleer/oh-my-posh/oh-my-posh

# Dev tooling
brew install go-task/tap/go-task uv autossh gh pyenv fnm 

# Fonts (need cask-fonts tap)
brew tap homebrew/cask-fonts || true
brew install --cask font-meslo-lg-nerd-font

# GUI apps
brew install --cask wezterm
brew install --cask docker

echo "[dotfiles] macOS bootstrap finished."

