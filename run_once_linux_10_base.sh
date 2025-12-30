#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Linux base setup starting..."

# ------------------------------------------------------------
# Use sudo only if not root
# ------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------
apt_install() {
  local pkg="$1"
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing $pkg..."
    $SUDO apt-get install -y "$pkg"
  fi
}

# ------------------------------------------------------------
# Update package list
# ------------------------------------------------------------
echo "[dotfiles] Updating apt package list..."
$SUDO apt-get update

# ------------------------------------------------------------
# Install zsh and set as default shell
# ------------------------------------------------------------
apt_install zsh
apt_install locales

# Generate UTF-8 locale
$SUDO sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
$SUDO locale-gen

if [ "$SHELL" != "$(which zsh)" ]; then
  echo "[dotfiles] Setting zsh as default shell..."
  if timeout 5 chsh -s "$(which zsh)" 2>/dev/null; then
    echo "[dotfiles] Default shell changed to zsh"
  else
    echo "[dotfiles] WARNING: Could not change default shell (OS Login or similar)."
    echo "[dotfiles] Adding 'exec zsh' to ~/.bashrc"
    echo 'if [ -x "$(command -v zsh)" ]; then exec zsh; fi' >> ~/.bashrc
  fi
fi

# ------------------------------------------------------------
# Essential build tools
# ------------------------------------------------------------
apt_install curl
apt_install wget
apt_install git
apt_install unzip
apt_install gnupg
apt_install build-essential
apt_install ninja-build
apt_install gettext
apt_install cmake

echo "[dotfiles] Base setup finished."
