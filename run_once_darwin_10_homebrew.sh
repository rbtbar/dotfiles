#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[dotfiles] Not macOS, skipping."
  exit 0
fi

echo "[dotfiles] macOS Homebrew setup starting..."

# ------------------------------------------------------------
# Homebrew installation
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

echo "[dotfiles] Homebrew setup finished."
