#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Linux (Debian/Ubuntu) bootstrap starting..."

# ------------------------------------------------------------
# Use sudo only if not root
# ------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------
apt_install() {
  local pkg="$1"
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing $pkg..."
    $SUDO apt-get install -y "$pkg"
  fi
}

npm_install_global() {
  local pkg="$1"
  if ! npm list -g "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing npm package $pkg..."
    npm install -g "$pkg"
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
  if chsh -s "$(which zsh)" 2>/dev/null; then
    echo "[dotfiles] Default shell changed to zsh"
  else
    echo "[dotfiles] WARNING: Could not change default shell (OS Login or similar)."
    echo "[dotfiles] Adding 'exec zsh' to ~/.bashrc"
    echo 'if [ -x "$(command -v zsh)" ]; then exec zsh; fi' >> ~/.bashrc
  fi
fi

# ------------------------------------------------------------
# CLI tools (apt)
# ------------------------------------------------------------
echo "[dotfiles] Checking CLI tools..."

apt_install jq
apt_install fd-find
apt_install bat
apt_install tmux
apt_install ripgrep
apt_install direnv
apt_install curl
apt_install wget
apt_install git
apt_install unzip
apt_install gnupg
apt_install fontconfig
apt_install build-essential  # needed for treesitter parser compilation

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

# GitHub CLI
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
# Neovim (from GitHub releases)
# ------------------------------------------------------------
if ! command -v nvim >/dev/null 2>&1; then
  echo "[dotfiles] Installing Neovim..."
  NVIM_VERSION=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  elif [ "$ARCH" = "aarch64" ]; then
    curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-arm64.tar.gz"
  fi
  tar xzf nvim.tar.gz
  $SUDO mv nvim-linux-*/  /opt/nvim
  $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf nvim.tar.gz nvim-linux-*
fi

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
eval "$(fnm env --shell bash)"  # Re-source to get node/npm in PATH

# ------------------------------------------------------------
# Python via pyenv
# ------------------------------------------------------------
PYTHON_VERSION="3.14.2"

# pyenv compiles Python from source - install build dependencies
# Source: https://github.com/pyenv/pyenv/wiki#suggested-build-environment
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

# Ensure debugpy is installed
if ! python -m pip show debugpy &>/dev/null; then
  python -m pip install --upgrade pip
  python -m pip install debugpy
fi

# ------------------------------------------------------------
# LSP servers
# ------------------------------------------------------------
echo "[dotfiles] Checking LSP servers..."

# Python LSPs (via pip)
python -m pip install --quiet pyright ruff black

# TypeScript LSP and tools (npm)
npm_install_global typescript
npm_install_global typescript-language-server
npm_install_global bash-language-server
npm_install_global yaml-language-server
npm_install_global vscode-langservers-extracted

# tree-sitter-cli requires glibc >= 2.39 (Ubuntu 24.04+)
GLIBC_VERSION=$(ldd --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+$' || echo "0.0")
GLIBC_MAJOR=$(echo "$GLIBC_VERSION" | cut -d. -f1)
GLIBC_MINOR=$(echo "$GLIBC_VERSION" | cut -d. -f2)
if [ "$GLIBC_MAJOR" -ge 2 ] && [ "$GLIBC_MINOR" -ge 39 ]; then
  npm_install_global tree-sitter-cli
else
  echo "[dotfiles] Skipping tree-sitter-cli (requires glibc >= 2.39, found $GLIBC_VERSION)"
fi

# Lua LSP (binary)
if ! command -v lua-language-server >/dev/null 2>&1; then
  echo "[dotfiles] Installing lua-language-server..."
  LUA_LS_VERSION=$(curl -s "https://api.github.com/repos/LuaLS/lua-language-server/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    LUA_LS_ARCH="linux-x64"
  elif [ "$ARCH" = "aarch64" ]; then
    LUA_LS_ARCH="linux-arm64"
  else
    echo "[dotfiles] WARNING: Unsupported architecture $ARCH for lua-language-server"
    LUA_LS_ARCH=""
  fi
  if [ -n "$LUA_LS_ARCH" ]; then
    curl -Lo lua-language-server.tar.gz "https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/lua-language-server-${LUA_LS_VERSION}-${LUA_LS_ARCH}.tar.gz"
    $SUDO mkdir -p /opt/lua-language-server
    $SUDO tar xf lua-language-server.tar.gz -C /opt/lua-language-server
    $SUDO ln -sf /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
    rm lua-language-server.tar.gz
  fi
fi

# ------------------------------------------------------------
# Claude Code
# ------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "[dotfiles] Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "[dotfiles] Linux bootstrap finished."
echo "[dotfiles] Please log out and back in for shell change to take effect."
