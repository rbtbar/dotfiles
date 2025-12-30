#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping."
  exit 0
fi

echo "[dotfiles] macOS CLI tools setup starting..."

# ------------------------------------------------------------
# Helper: install brew formula only if not already installed
# ------------------------------------------------------------
brew_install() {
  local pkg="$1"
  if ! brew list "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing $pkg..."
    brew install "$pkg"
  fi
}

# ------------------------------------------------------------
# CLI tools
# ------------------------------------------------------------
brew_install jq
brew_install yq
brew_install fd
brew_install bat
brew_install eza
brew_install zoxide
brew_install direnv
brew_install ripgrep
brew_install tmux

# Zsh goodies
brew_install zsh-syntax-highlighting
brew_install zsh-autosuggestions
brew_install zsh-completions
brew_install fzf

# oh-my-posh (tap formula)
if ! brew list oh-my-posh &>/dev/null; then
  brew install --formula jandedobbeleer/oh-my-posh/oh-my-posh
fi

echo "[dotfiles] CLI tools setup finished."
