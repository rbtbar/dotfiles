#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping."
  exit 0
fi

echo "[dotfiles] macOS editor setup starting..."

# ------------------------------------------------------------
# Optional env overrides (NVIM_VERSION must come from env)
# ------------------------------------------------------------
if [ -f "$HOME/.config/dotfiles/env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.config/dotfiles/env"
fi

if [ -z "${NVIM_VERSION:-}" ]; then
  echo "[dotfiles] ERROR: NVIM_VERSION is not set."
  echo "[dotfiles] Set it via: export NVIM_VERSION='v0.11.0' (or create ~/.config/dotfiles/env)"
  exit 1
fi

export NVIM_VERSION

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
# Terminal utilities (for AstroNvim toggles)
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

# ------------------------------------------------------------
# AstroNvim (side-by-side via NVIM_APPNAME=astronvim)
# ------------------------------------------------------------
ASTRO_DIR="$HOME/.config/astronvim"
if [ ! -d "$ASTRO_DIR/lua/plugins" ]; then
  echo "[dotfiles] Installing AstroNvim template..."
  rm -rf "$ASTRO_DIR"
  git clone https://github.com/AstroNvim/template "$ASTRO_DIR"
  rm -rf "$ASTRO_DIR/.git"
fi

echo "[dotfiles] Bootstrapping AstroNvim..."
NVIM_APPNAME=astronvim nvim --headless "+qall" || true

echo "[dotfiles] Editor setup finished."
