#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping."
  exit 0
fi

echo "[dotfiles] macOS dev tooling setup starting..."

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------
brew_install() {
  local pkg="$1"
  if ! brew list "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing $pkg..."
    brew install "$pkg"
  fi
}

brew_install_cask() {
  local pkg="$1"
  if ! brew list --cask "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing cask $pkg..."
    brew install --cask "$pkg"
  fi
}

# ------------------------------------------------------------
# Dev tools
# ------------------------------------------------------------
if ! brew list go-task &>/dev/null; then
  brew install go-task/tap/go-task
fi

brew_install uv
brew_install autossh
brew_install gh
brew_install pyenv
brew_install fnm
brew_install lazygit
brew_install ruff
brew_install black

brew_install_cask docker

# ------------------------------------------------------------
# Python via pyenv
# ------------------------------------------------------------
PYTHON_VERSION="3.14.2"

echo "[dotfiles] Checking Python $PYTHON_VERSION..."

eval "$(pyenv init -)"

if [ ! -d "${HOME}/.pyenv/versions/${PYTHON_VERSION}" ]; then
  echo "[dotfiles] Installing Python $PYTHON_VERSION..."
  pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"

# Ensure debugpy is installed
if ! python -m pip show debugpy &>/dev/null; then
  python -m pip install --upgrade pip
  python -m pip install debugpy
fi

# ------------------------------------------------------------
# Node.js via fnm
# ------------------------------------------------------------
eval "$(fnm env --shell bash)"

if ! command -v node >/dev/null 2>&1; then
  echo "[dotfiles] Installing Node.js LTS..."
  fnm install --lts
  fnm default lts-latest
fi

echo "[dotfiles] Dev tooling setup finished."
