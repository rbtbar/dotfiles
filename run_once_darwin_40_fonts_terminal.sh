#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping."
  exit 0
fi

echo "[dotfiles] macOS fonts & terminal setup starting..."

# ------------------------------------------------------------
# Helper: install brew cask only if not already installed
# ------------------------------------------------------------
brew_install_cask() {
  local pkg="$1"
  if ! brew list --cask "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing cask $pkg..."
    brew install --cask "$pkg"
  fi
}

# ------------------------------------------------------------
# Fonts & GUI apps
# ------------------------------------------------------------
brew_install_cask font-meslo-lg-nerd-font
brew_install_cask wezterm

echo "[dotfiles] Fonts & terminal setup finished."
