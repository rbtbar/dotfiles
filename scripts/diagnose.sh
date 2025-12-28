#!/usr/bin/env bash
# ============================================================================
# Dotfiles Diagnostic Script
# Run this to verify your environment is configured correctly
# ============================================================================

set -u

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------
check_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((PASS++))
}

check_fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((FAIL++))
}

check_warn() {
  echo -e "  ${YELLOW}!${NC} $1"
  ((WARN++))
}

check_info() {
  echo -e "  ${BLUE}→${NC} $1"
}

section() {
  echo ""
  echo -e "${BLUE}[$1]${NC}"
}

check_command() {
  local cmd="$1"
  local desc="${2:-$cmd}"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version=$("$cmd" --version 2>&1 | head -1 || echo "unknown")
    check_pass "$desc: $version"
    return 0
  else
    check_fail "$desc: not found"
    return 1
  fi
}

# Check command exists AND runs a test
check_tool() {
  local cmd="$1"
  local test_cmd="$2"
  local desc="${3:-$cmd}"
  if command -v "$cmd" >/dev/null 2>&1; then
    if eval "$test_cmd" >/dev/null 2>&1; then
      local version
      version=$("$cmd" --version 2>&1 | head -1 || echo "unknown")
      check_pass "$desc: $version"
      return 0
    else
      check_fail "$desc: installed but test failed"
      return 1
    fi
  else
    check_fail "$desc: not found"
    return 1
  fi
}

# ------------------------------------------------------------
# System Info
# ------------------------------------------------------------
section "System"
OS=$(uname -s)
ARCH=$(uname -m)
check_info "OS: $OS ($ARCH)"

if [ "$OS" = "Darwin" ]; then
  check_info "macOS $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
elif [ "$OS" = "Linux" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    check_info "Distribution: $NAME $VERSION"
  fi
  GLIBC_VERSION=$(ldd --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+$' || echo "unknown")
  check_info "glibc: $GLIBC_VERSION"
fi

# ------------------------------------------------------------
# Shell
# ------------------------------------------------------------
section "Shell"
check_command zsh

if [ "$SHELL" = "$(command -v zsh 2>/dev/null)" ]; then
  check_pass "Default shell is zsh"
else
  check_warn "Default shell is $SHELL (expected zsh)"
fi

# ------------------------------------------------------------
# Locale
# ------------------------------------------------------------
section "Locale"
if [ -n "${LANG:-}" ]; then
  check_pass "LANG=$LANG"
else
  check_fail "LANG not set (icons may not display)"
fi

if [ -n "${LC_ALL:-}" ]; then
  check_info "LC_ALL=$LC_ALL"
fi

# ------------------------------------------------------------
# Package Manager
# ------------------------------------------------------------
section "Package Manager"
if [ "$OS" = "Darwin" ]; then
  check_command brew "Homebrew"
elif [ "$OS" = "Linux" ]; then
  if command -v apt-get >/dev/null 2>&1; then
    check_pass "apt-get available"
  else
    check_fail "apt-get not found"
  fi
fi

# ------------------------------------------------------------
# Core CLI Tools (with functional tests)
# ------------------------------------------------------------
section "CLI Tools"

# bat/batcat (Debian/Ubuntu names it batcat)
if command -v bat >/dev/null 2>&1; then
  if echo "test" | bat --style=plain >/dev/null 2>&1; then
    version=$(bat --version 2>&1 | head -1)
    check_pass "bat: $version"
  else
    check_fail "bat: installed but test failed"
  fi
elif command -v batcat >/dev/null 2>&1; then
  if echo "test" | batcat --style=plain >/dev/null 2>&1; then
    version=$(batcat --version 2>&1 | head -1)
    check_pass "bat (batcat): $version"
  else
    check_fail "bat (batcat): installed but test failed"
  fi
else
  check_fail "bat: not found"
fi

# fd/fdfind (Debian/Ubuntu names it fdfind)
if command -v fd >/dev/null 2>&1; then
  if fd --max-depth 1 . / >/dev/null 2>&1; then
    version=$(fd --version 2>&1 | head -1)
    check_pass "fd: $version"
  else
    check_fail "fd: installed but test failed"
  fi
elif command -v fdfind >/dev/null 2>&1; then
  if fdfind --max-depth 1 . / >/dev/null 2>&1; then
    version=$(fdfind --version 2>&1 | head -1)
    check_pass "fd (fdfind): $version"
  else
    check_fail "fd (fdfind): installed but test failed"
  fi
else
  check_fail "fd: not found"
fi

# eza - list current directory
check_tool eza "eza --version" "eza"

# zoxide - init test
check_tool zoxide "zoxide init bash" "zoxide"

# fzf - version check (no stdin test)
check_tool fzf "fzf --version" "fzf"

# ripgrep - search test
check_tool rg "echo test | rg test" "ripgrep"

# jq - parse JSON
check_tool jq "echo '{\"a\":1}' | jq .a" "jq"

# yq - parse YAML
check_tool yq "echo 'a: 1' | yq .a" "yq"

# direnv - hook test
check_tool direnv "direnv hook bash" "direnv"

# GitHub CLI - auth status (may fail if not logged in, just check it runs)
check_tool gh "gh --version" "GitHub CLI"

# lazygit - version
check_tool lazygit "lazygit --version" "lazygit"

# ------------------------------------------------------------
# Prompt
# ------------------------------------------------------------
section "Prompt"
check_command oh-my-posh

if [ -f "$HOME/.config/oh-my-posh/spaceship.omp.json" ]; then
  check_pass "oh-my-posh config exists"
else
  check_warn "oh-my-posh config not found at ~/.config/oh-my-posh/spaceship.omp.json"
fi

# ------------------------------------------------------------
# Python (pyenv)
# ------------------------------------------------------------
section "Python"
if [ -d "$HOME/.pyenv" ]; then
  check_pass "pyenv directory exists"

  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"

  if command -v pyenv >/dev/null 2>&1; then
    PYENV_VERSION=$(pyenv --version 2>&1)
    check_pass "pyenv: $PYENV_VERSION"

    PYTHON_VERSION=$(pyenv global 2>/dev/null || echo "not set")
    check_info "pyenv global: $PYTHON_VERSION"
  fi
fi

if command -v python >/dev/null 2>&1; then
  PY_VERSION=$(python --version 2>&1)
  check_pass "python: $PY_VERSION"

  # Check debugpy
  if python -m pip show debugpy &>/dev/null; then
    check_pass "debugpy installed"
  else
    check_warn "debugpy not installed"
  fi
else
  check_fail "python not found in PATH"
fi

# ------------------------------------------------------------
# Node.js (fnm)
# ------------------------------------------------------------
section "Node.js"
if [ "$OS" = "Linux" ]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
fi

if command -v fnm >/dev/null 2>&1; then
  FNM_VERSION=$(fnm --version 2>&1)
  check_pass "fnm: $FNM_VERSION"

  # Source fnm for this script
  eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

if command -v node >/dev/null 2>&1; then
  NODE_VERSION=$(node --version 2>&1)
  check_pass "node: $NODE_VERSION"
else
  check_fail "node not found"
fi

if command -v npm >/dev/null 2>&1; then
  NPM_VERSION=$(npm --version 2>&1)
  check_pass "npm: $NPM_VERSION"
else
  check_fail "npm not found"
fi

# ------------------------------------------------------------
# Editor
# ------------------------------------------------------------
section "Editor"

# Neovim - headless test
if command -v nvim >/dev/null 2>&1; then
  if nvim --version >/dev/null 2>&1; then
    version=$(nvim --version 2>&1 | head -1)
    check_pass "Neovim: $version"

    # Quick headless startup test
    if nvim --headless -c 'quit' 2>/dev/null; then
      check_pass "Neovim headless startup OK"
    else
      check_warn "Neovim headless startup had issues"
    fi
  else
    check_fail "Neovim: installed but test failed"
  fi
else
  check_fail "Neovim: not found"
fi

if [ -d "$HOME/.config/nvim" ]; then
  check_pass "Neovim config directory exists"
else
  check_warn "Neovim config not found at ~/.config/nvim"
fi

# tree-sitter CLI (optional on older glibc)
if command -v tree-sitter >/dev/null 2>&1; then
  if tree-sitter --version >/dev/null 2>&1; then
    TS_VERSION=$(tree-sitter --version 2>&1 | head -1)
    check_pass "tree-sitter: $TS_VERSION"
  else
    check_fail "tree-sitter: installed but test failed"
  fi
else
  if [ "$OS" = "Linux" ]; then
    check_info "tree-sitter-cli not installed (requires glibc >= 2.39)"
  else
    check_warn "tree-sitter-cli not installed"
  fi
fi

# ------------------------------------------------------------
# LSP Servers (with functional tests)
# ------------------------------------------------------------
section "LSP Servers"

# pyright - version check
check_tool pyright "pyright --version" "pyright"

# ruff - check test
check_tool ruff "echo 'x=1' | ruff check --stdin-filename=test.py" "ruff"

# lua-language-server - version
check_tool lua-language-server "lua-language-server --version" "lua-language-server"

# typescript-language-server - version
check_tool typescript-language-server "typescript-language-server --version" "TypeScript LSP"

# bash-language-server - version
check_tool bash-language-server "bash-language-server --version" "Bash LSP"

# yaml-language-server - stdio server, just check it exists
if command -v yaml-language-server >/dev/null 2>&1; then
  check_pass "YAML LSP: $(command -v yaml-language-server)"
else
  check_fail "YAML LSP: not found"
fi

# vscode-langservers-extracted - stdio servers, just check they exist
if command -v vscode-json-language-server >/dev/null 2>&1; then
  check_pass "vscode-langservers-extracted (JSON/HTML/CSS)"
else
  check_warn "vscode-langservers-extracted not found"
fi

# ------------------------------------------------------------
# Terminal Multiplexer
# ------------------------------------------------------------
section "Tmux"

# tmux - start-server test
if command -v tmux >/dev/null 2>&1; then
  if tmux -V >/dev/null 2>&1; then
    version=$(tmux -V 2>&1)
    check_pass "tmux: $version"
  else
    check_fail "tmux: installed but test failed"
  fi
else
  check_fail "tmux: not found"
fi

if [ -f "$HOME/.tmux.conf" ]; then
  check_pass "tmux.conf exists"
else
  check_warn "tmux.conf not found"
fi

# Check if inside tmux
if [ -n "${TMUX:-}" ]; then
  check_info "Currently inside tmux session"
  check_info "TERM=$TERM"
fi

# ------------------------------------------------------------
# FZF
# ------------------------------------------------------------
section "FZF Integration"
if command -v fzf >/dev/null 2>&1; then
  # Check keybindings file
  if [ "$OS" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      FZF_PREFIX="$(brew --prefix 2>/dev/null)/opt/fzf"
      if [ -f "$FZF_PREFIX/shell/key-bindings.zsh" ]; then
        check_pass "fzf keybindings available (Homebrew)"
      else
        check_warn "fzf keybindings not found"
      fi
    fi
  elif [ "$OS" = "Linux" ]; then
    if [ -f "$HOME/.fzf/shell/key-bindings.zsh" ]; then
      check_pass "fzf keybindings available (git install)"
    elif [ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ]; then
      check_pass "fzf keybindings available (apt)"
    else
      check_warn "fzf keybindings not found"
    fi
  fi

  if [ -n "${FZF_DEFAULT_OPTS:-}" ]; then
    check_pass "FZF_DEFAULT_OPTS is set"
  else
    check_warn "FZF_DEFAULT_OPTS not set"
  fi
fi

# ------------------------------------------------------------
# Fonts (visual check)
# ------------------------------------------------------------
section "Fonts & Icons"
echo -e "  Icon test: \uf015 \uf07c \ue725 \uf120 \uf1d3"
echo -e "  If you see boxes or ? above, Nerd Font is not working"
check_info "Expected: house, folder, JS logo, terminal, git icon"

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
echo ""
echo "============================================================"
echo -e "Summary: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$WARN warnings${NC}"
echo "============================================================"

if [ $FAIL -gt 0 ]; then
  exit 1
fi
exit 0
