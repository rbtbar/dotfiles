#!/usr/bin/env bash
set -euo pipefail

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "[dotfiles] Not Linux, skipping."
  exit 0
fi

echo "[dotfiles] Linux editor setup starting..."

# ------------------------------------------------------------
# Use sudo only if not root
# ------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# ------------------------------------------------------------
# Optional env overrides (NVIM_VERSION must come from env)
# ------------------------------------------------------------
if [ -f "$HOME/.config/dotfiles/env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.config/dotfiles/env"
fi

if [ -z "${NVIM_VERSION:-}" ]; then
  echo "[dotfiles] ERROR: NVIM_VERSION is not set."
  echo "[dotfiles] Set it via: export NVIM_VERSION='v0.11.0' (or create ~/.config/dotfiles/env)"
  exit 1
fi

export NVIM_VERSION

# ------------------------------------------------------------
# Terminal utilities (for AstroNvim toggles)
# ------------------------------------------------------------

# gdu (disk usage - for AstroNvim <Leader>tu)
if ! command -v gdu >/dev/null 2>&1; then
  echo "[dotfiles] Installing gdu..."
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    GDU_ARCH="amd64"
  elif [ "$ARCH" = "aarch64" ]; then
    GDU_ARCH="arm64"
  else
    GDU_ARCH="amd64"
  fi
  curl -Lo gdu.tgz "https://github.com/dundee/gdu/releases/latest/download/gdu_linux_${GDU_ARCH}.tgz"
  tar xf gdu.tgz
  $SUDO install "gdu_linux_${GDU_ARCH}" /usr/local/bin/gdu
  rm gdu.tgz "gdu_linux_${GDU_ARCH}"
fi

# bottom (process viewer - for AstroNvim <Leader>tt)
if ! command -v btm >/dev/null 2>&1; then
  echo "[dotfiles] Installing bottom..."
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    BTM_ARCH="x86_64"
  elif [ "$ARCH" = "aarch64" ]; then
    BTM_ARCH="aarch64"
  else
    BTM_ARCH="x86_64"
  fi
  curl -Lo bottom.tar.gz "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_${BTM_ARCH}-unknown-linux-gnu.tar.gz"
  tar xf bottom.tar.gz btm
  $SUDO install btm /usr/local/bin
  rm bottom.tar.gz btm
fi

# ------------------------------------------------------------
# Neovim via bob (version-managed)
# ------------------------------------------------------------
if ! command -v bob >/dev/null 2>&1; then
  echo "[dotfiles] Installing bob..."
  curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
fi

export PATH="$HOME/.local/bin:$HOME/.local/share/bob/nvim-bin:$PATH"

echo "[dotfiles] Installing Neovim $NVIM_VERSION via bob..."
bob install "$NVIM_VERSION"
bob use "$NVIM_VERSION"

# Fallback: if bob's nvim binary doesn't work (old glibc), build from source
if ! nvim --version >/dev/null 2>&1; then
  echo "[dotfiles] WARNING: nvim from bob failed to run; falling back to source build for $NVIM_VERSION"
  ORIG_DIR="$(pwd)"
  cd /tmp
  rm -rf neovim
  git clone --depth 1 --branch "$NVIM_VERSION" https://github.com/neovim/neovim.git
  cd neovim
  make CMAKE_BUILD_TYPE=Release
  $SUDO make install
  cd "$ORIG_DIR"
  rm -rf /tmp/neovim
fi

echo "[dotfiles] Neovim: $(nvim --version | head -n 1)"

# ------------------------------------------------------------
# AstroNvim (side-by-side via NVIM_APPNAME=astronvim)
# ------------------------------------------------------------
ASTRO_DIR="$HOME/.config/astronvim"
if [ ! -d "$ASTRO_DIR/lua/plugins" ]; then
  echo "[dotfiles] Installing AstroNvim template..."
  rm -rf "$ASTRO_DIR"
  git clone https://github.com/AstroNvim/template "$ASTRO_DIR"
  rm -rf "$ASTRO_DIR/.git"
fi

echo "[dotfiles] Bootstrapping AstroNvim..."
NVIM_APPNAME=astronvim nvim --headless "+qall" || true

echo "[dotfiles] Editor setup finished."
