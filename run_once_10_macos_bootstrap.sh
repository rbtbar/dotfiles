#!/usr/bin/env bash
set -euo pipefail

echo "[dotfiles] macOS bootstrap starting..."

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping Homebrew/bootstrap."
  exit 0
fi

# Install Homebrew if missing (Apple official script)
if ! command -v brew >/dev/null 2>&1; then
  echo "[dotfiles] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[dotfiles] Homebrew already installed, skipping install."
fi

# Apple Silicon-only brew setup (no Intel fallback)
if [ -d /opt/homebrew ]; then
  echo "[dotfiles] Configuring Homebrew shellenv for Apple Silicon..."
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Ensure brew shellenv is loaded in future shells
  if ! grep -q 'brew shellenv' "${HOME}/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
    echo "[dotfiles] Added brew shellenv to ~/.zprofile"
  fi
else
  echo "[dotfiles] WARNING: /opt/homebrew not found. Are you sure this is an Apple Silicon Mac?" >&2
fi

# Make sure chezmoi itself is installed via Homebrew
if ! brew list chezmoi >/dev/null 2>&1; then
  echo "[dotfiles] Installing chezmoi via Homebrew..."
  brew install chezmoi
else
  echo "[dotfiles] chezmoi already installed via Homebrew."
fi

echo "[dotfiles] Installing CLI tools and extras..."

# Core CLI tools
brew install jq yq fd bat eza zoxide direnv

# Zsh goodies
brew install zsh-syntax-highlighting zsh-autosuggestions zsh-completions fzf

brew install --formula jandedobbeleer/oh-my-posh/oh-my-posh

# Tmux
brew install tmux

# Dev tooling
brew install go-task/tap/go-task uv autossh gh pyenv fnm 
brew install lazygit

# Fonts (need cask-fonts tap)
brew tap homebrew/cask-fonts || true
brew install --cask font-meslo-lg-nerd-font

# GUI apps
brew install --cask wezterm
brew install --cask docker

# Editor
brew install neovim
# Telescope plugin
brew install ripgrep
# Treesitter plugin
brew install tree-sitter-cli

# -----------------------------------------------------------
# Neovim LSP servers (macOS, Homebrew + Node)
# -----------------------------------------------------------

# 1) Python LSP: Pyright

brew install pyright
brew install ruff black

# 2) Lua LSP: lua-language-server
#    Homebrew formula ships the binary
brew install lua-language-server

# 3) TypeScript / JavaScript LSP: typescript-language-server
brew install node
npm install -g typescript typescript-language-server

# 4) Yaml, JSON, docker, zsh/sh
brew install \
  yaml-language-server \
  vscode-langservers-extracted \
  docker-language-server \
  bash-language-server

# ------------------------------------------------------------ 
# Python/Debugger installation
# ------------------------------------------------------------ 
pyenv install 3.14.2
pyenv global 3.14.2
python -m pip install --upgrade pip
python -m pip install debugpy

# ------------------------------------------------------------ 
# Claude Code 
# ------------------------------------------------------------ 

curl -fsSL https://claude.ai/install.sh | bash

echo "[dotfiles] macOS bootstrap finished."

