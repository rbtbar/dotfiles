#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Linux CLI tools setup starting..."

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
# CLI tools (apt)
# ------------------------------------------------------------
apt_install jq
apt_install fd-find
apt_install bat
apt_install tmux
apt_install ripgrep
apt_install direnv

# Zsh plugins
apt_install zsh-syntax-highlighting
apt_install zsh-autosuggestions

# ------------------------------------------------------------
# Tools not in apt - install via binary/script
# ------------------------------------------------------------

# fzf (from git for shell keybindings)
if [ ! -d "$HOME/.fzf" ]; then
  echo "[dotfiles] Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# yq (YAML processor)
if ! command -v yq >/dev/null 2>&1; then
  echo "[dotfiles] Installing yq..."
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    YQ_ARCH="amd64"
  elif [ "$ARCH" = "aarch64" ]; then
    YQ_ARCH="arm64"
  else
    YQ_ARCH="amd64"
  fi
  $SUDO wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}"
  $SUDO chmod +x /usr/local/bin/yq
fi

# eza (modern ls)
if ! command -v eza >/dev/null 2>&1; then
  echo "[dotfiles] Installing eza..."
  $SUDO mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $SUDO tee /etc/apt/sources.list.d/gierens.list
  $SUDO apt-get update
  $SUDO apt-get install -y eza
fi

# zoxide (smart cd)
if ! command -v zoxide >/dev/null 2>&1; then
  echo "[dotfiles] Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# oh-my-posh (prompt)
if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "[dotfiles] Installing oh-my-posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

echo "[dotfiles] CLI tools setup finished."
