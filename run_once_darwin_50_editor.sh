#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping."
  exit 0
fi

echo "[dotfiles] macOS editor setup starting..."

NVIM_VERSION="v0.11.5"

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
# Terminal utilities (for nvim toggles)
# ------------------------------------------------------------
brew_install gdu      # disk usage (<Leader>tu)
brew_install bottom   # process viewer (<Leader>tt)

# ------------------------------------------------------------
# Neovim via bob (version-managed)
# ------------------------------------------------------------
if ! command -v bob >/dev/null 2>&1; then
  echo "[dotfiles] Installing bob..."
  curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
fi

export PATH="$HOME/.local/bin:$HOME/.local/share/bob/nvim-bin:$PATH"

echo "[dotfiles] Installing Neovim $NVIM_VERSION via bob..."
bob install "$NVIM_VERSION"
bob use "$NVIM_VERSION"

echo "[dotfiles] Neovim: $(nvim --version | head -n 1)"

echo "[dotfiles] Editor setup finished."
