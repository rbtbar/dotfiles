#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Claude Code setup starting..."

# ------------------------------------------------------------
# Claude Code
# ------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "[dotfiles] Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "[dotfiles] Claude Code setup finished."
