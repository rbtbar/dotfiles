#!/usr/bin/env bash
set -euo pipefail

echo "[dotfiles] macOS bootstrap starting..."

# ------------------------------------------------------------
# Helper: install brew formula/cask only if not already installed
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

npm_install_global() {
  local pkg="$1"
  if ! npm list -g "$pkg" &>/dev/null; then
    echo "[dotfiles] Installing npm package $pkg..."
    npm install -g "$pkg"
  fi
}

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "[dotfiles] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon-only brew setup
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"

  if ! grep -q 'brew shellenv' "${HOME}/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
    echo "[dotfiles] Added brew shellenv to ~/.zprofile"
  fi
else
  echo "[dotfiles] WARNING: /opt/homebrew not found. Apple Silicon Mac?" >&2
fi

# Make sure chezmoi itself is installed via Homebrew
if ! brew list chezmoi >/dev/null 2>&1; then
  echo "[dotfiles] Installing chezmoi via Homebrew..."
  brew install chezmoi
fi

# ------------------------------------------------------------
# CLI tools
# ------------------------------------------------------------
echo "[dotfiles] Checking CLI tools..."

brew_install jq
brew_install yq
brew_install fd
brew_install bat
brew_install eza
brew_install zoxide
brew_install direnv

# Zsh goodies
brew_install zsh-syntax-highlighting
brew_install zsh-autosuggestions
brew_install zsh-completions
brew_install fzf

# oh-my-posh (tap formula)
if ! brew list oh-my-posh &>/dev/null; then
  brew install --formula jandedobbeleer/oh-my-posh/oh-my-posh
fi

brew_install tmux

# Dev tooling
if ! brew list go-task &>/dev/null; then
  brew install go-task/tap/go-task
fi
brew_install uv
brew_install autossh
brew_install gh
brew_install pyenv
brew_install fnm
brew_install lazygit

# ------------------------------------------------------------
# Fonts & GUI apps
# ------------------------------------------------------------
echo "[dotfiles] Checking fonts and GUI apps..."

brew_install_cask font-meslo-lg-nerd-font
brew_install_cask wezterm
brew_install_cask docker

# ------------------------------------------------------------
# Editor & plugins
# ------------------------------------------------------------
echo "[dotfiles] Checking editor tools..."

brew_install neovim
brew_install ripgrep
brew_install tree-sitter-cli

# ------------------------------------------------------------
# LSP servers
# ------------------------------------------------------------
echo "[dotfiles] Checking LSP servers..."

brew_install pyright
brew_install ruff
brew_install black
brew_install lua-language-server
brew_install node
brew_install yaml-language-server
brew_install vscode-langservers-extracted
brew_install docker-language-server
brew_install bash-language-server

# TypeScript LSP (npm)
npm_install_global typescript
npm_install_global typescript-language-server

# ------------------------------------------------------------
# Python via pyenv
# ------------------------------------------------------------
PYTHON_VERSION="3.14.2"

echo "[dotfiles] Checking Python $PYTHON_VERSION..."

if [ ! -d "${HOME}/.pyenv/versions/${PYTHON_VERSION}" ]; then
  echo "[dotfiles] Installing Python $PYTHON_VERSION..."
  pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"
eval "$(pyenv init -)"

# Ensure debugpy is installed
if ! python -m pip show debugpy &>/dev/null; then
  python -m pip install --upgrade pip
  python -m pip install debugpy
fi

# ------------------------------------------------------------
# Claude Code
# ------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "[dotfiles] Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "[dotfiles] macOS bootstrap finished."
