#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Linux dev tooling setup starting..."

# ------------------------------------------------------------
# Use sudo only if not root
# ------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# ------------------------------------------------------------
# GitHub CLI
# ------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  echo "[dotfiles] Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  $SUDO apt-get update
  $SUDO apt-get install -y gh
fi

# lazygit
if ! command -v lazygit >/dev/null 2>&1; then
  echo "[dotfiles] Installing lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    LAZYGIT_ARCH="x86_64"
  elif [ "$ARCH" = "aarch64" ]; then
    LAZYGIT_ARCH="arm64"
  else
    LAZYGIT_ARCH="x86_64"
  fi
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
  tar xf lazygit.tar.gz lazygit
  $SUDO install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
fi

# ------------------------------------------------------------
# Node.js via fnm
# ------------------------------------------------------------
if ! command -v fnm >/dev/null 2>&1; then
  echo "[dotfiles] Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

# Source fnm for this script
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --shell bash)"

# Install Node.js LTS if not present
if ! command -v node >/dev/null 2>&1; then
  echo "[dotfiles] Installing Node.js LTS..."
  fnm install --lts
  fnm default lts-latest
fi
eval "$(fnm env --shell bash)"

# ------------------------------------------------------------
# Python via pyenv
# ------------------------------------------------------------
PYTHON_VERSION="3.14.2"

# pyenv compiles Python from source - install build dependencies
echo "[dotfiles] Installing pyenv build dependencies..."
$SUDO apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

if [ ! -d "$HOME/.pyenv" ]; then
  echo "[dotfiles] Installing pyenv..."
  curl https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if [ ! -d "${HOME}/.pyenv/versions/${PYTHON_VERSION}" ]; then
  echo "[dotfiles] Installing Python $PYTHON_VERSION..."
  pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"

echo "[dotfiles] Dev tooling setup finished."
