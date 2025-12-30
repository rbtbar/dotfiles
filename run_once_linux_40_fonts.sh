#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Linux fonts setup starting..."

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------
apt_install() {
  if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
  else
    SUDO="sudo"
  fi
  local pkg="$1"
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing $pkg..."
    $SUDO apt-get install -y "$pkg"
  fi
}

apt_install fontconfig

# ------------------------------------------------------------
# Nerd Font (for icons in terminal/nvim)
# ------------------------------------------------------------
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -d "$FONT_DIR/MesloLGS" ]; then
  echo "[dotfiles] Installing MesloLGS Nerd Font..."
  mkdir -p "$FONT_DIR/MesloLGS"
  curl -Lo "$FONT_DIR/MesloLGS/MesloLGSNerdFont-Regular.ttf" \
    "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Meslo/S/Regular/MesloLGSNerdFont-Regular.ttf"
  curl -Lo "$FONT_DIR/MesloLGS/MesloLGSNerdFont-Bold.ttf" \
    "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Meslo/S/Bold/MesloLGSNerdFont-Bold.ttf"
  curl -Lo "$FONT_DIR/MesloLGS/MesloLGSNerdFont-Italic.ttf" \
    "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Meslo/S/Italic/MesloLGSNerdFont-Italic.ttf"
  curl -Lo "$FONT_DIR/MesloLGS/MesloLGSNerdFont-BoldItalic.ttf" \
    "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Meslo/S/BoldItalic/MesloLGSNerdFont-BoldItalic.ttf"
  fc-cache -fv "$FONT_DIR" 2>/dev/null || true
fi

echo "[dotfiles] Fonts setup finished."
