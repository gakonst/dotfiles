#!/usr/bin/env bash
set -euo pipefail

log() { printf "[dotfiles] %s\n" "$*"; }
warn() { printf "[dotfiles][warn] %s\n" "$*" >&2; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"
SKIP_BREW="${SKIP_BREW:-${DOTFILES_SKIP_BREW:-}}"
SKIP_OMZ="${SKIP_OMZ:-${DOTFILES_SKIP_OMZ:-}}"
SKIP_FZF="${SKIP_FZF:-${DOTFILES_SKIP_FZF:-}}"

init_submodules() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" submodule update --init --recursive >/dev/null 2>&1 || warn "submodule init failed"
  fi
}

backup_and_link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/$2"

  if [[ ! -e "$src" ]]; then
    warn "Source missing: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    # Skip if already the correct symlink
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      return
    fi
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/" 2>/dev/null || rm -rf "$dst"
    log "Backed up $dst to $BACKUP_DIR"
  fi

  ln -sfn "$src" "$dst"
  log "Linked $dst -> $src"
}

ensure_homebrew() {
  if [[ -n "$SKIP_BREW" ]]; then
    warn "Homebrew install skipped (SKIP_BREW set)"
    return
  fi
  if [[ "$(uname)" != "Darwin" ]]; then
    warn "Homebrew install skipped (non-macOS)"
    return
  fi
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

install_brew_packages() {
  if [[ -n "$SKIP_BREW" ]]; then
    warn "brew package install skipped (SKIP_BREW set)"
    return
  fi
  [[ "$(uname)" == "Darwin" ]] || return
  local pkgs=(
    tmux
    neovim
    git
    fzf
    fd
    ripgrep
    eza
    bat
    zoxide
    dust
    duf
    procs
    bottom
    doggo
    gping
    delta
    sd
    tldr
    jq
    unzip
    python
  )
  log "Installing Homebrew packages..."
  for pkg in "${pkgs[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      continue
    fi
    if ! brew install "$pkg" >/dev/null; then
      warn "Failed to install $pkg"
    fi
  done

  # Extras that need taps
  if ! brew list --formula uv >/dev/null 2>&1; then
    brew tap astral-sh/uv >/dev/null 2>&1 || true
    brew install uv >/dev/null 2>&1 || warn "uv install failed"
  fi

  brew tap koekeishiya/formulae >/dev/null 2>&1 || true
  for pkg in yabai skhd; do
    if ! brew list --formula "$pkg" >/dev/null 2>&1; then
      brew install "$pkg" >/dev/null 2>&1 || warn "Failed to install $pkg (needs SIP tweaks)"
    fi
  done

  # Bun (optional)
  if ! command -v bun >/dev/null 2>&1; then
    curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1 || warn "bun install failed"
  fi
}

install_oh_my_zsh() {
  if [[ -n "$SKIP_OMZ" ]]; then
    warn "oh-my-zsh install skipped (SKIP_OMZ set)"
    return
  fi
  local bundled="$DOTFILES_DIR/.oh-my-zsh"
  if [[ -d "$bundled" ]]; then
    backup_and_link ".oh-my-zsh" ".oh-my-zsh"
    return
  fi
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    return
  fi
  log "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 || \
    warn "oh-my-zsh install failed"
}

install_fzf_bindings() {
  if [[ -n "$SKIP_FZF" ]]; then
    warn "fzf bindings install skipped (SKIP_FZF set)"
    return
  fi
  if [[ "$(uname)" != "Darwin" ]]; then return; fi
  if command -v fzf >/dev/null 2>&1; then
    local prefix
    prefix="$(brew --prefix fzf 2>/dev/null)"
    if [[ -d "$prefix" ]]; then
      "$prefix"/install --key-bindings --completion --no-update-rc >/dev/null 2>&1 || true
    fi
  fi
}

link_all() {
  local mappings=(
    ".tmux.conf:.tmux.conf"
    ".zshrc:.zshrc"
    ".zshenv:.zshenv"
    ".zprofile:.zprofile"
    ".gitconfig:.gitconfig"
    ".vimrc:.vimrc"
    ".skhdrc:.skhdrc"
    ".yabairc:.yabairc"
    "fzf-zsh-history-config.zsh:fzf-zsh-history-config.zsh"
    ".config/nvim:.config/nvim"
    ".config/gh:.config/gh"
    ".config/uv:.config/uv"
    ".config/scdl:.config/scdl"
    ".config/scdl2:.config/scdl2"
    ".config/zed:.config/zed"
    ".config/fish:.config/fish"
    ".config/alacritty:.config/alacritty"
    ".local/bin/env:.local/bin/env"
    ".local/bin/env.fish:.local/bin/env.fish"
  )

  for entry in "${mappings[@]}"; do
    local src="${entry%%:*}"
    local dst="${entry#*:}"
    backup_and_link "$src" "$dst"
  done
}

post_notes() {
  cat <<'EON'

[dotfiles] Done.
- Start services: brew services start skhd && brew services start yabai (requires SIP disable + permissions).
- Open a new terminal to let zsh load, or run: exec zsh
- For tmux: prefix is ` (backtick). Reload with `prefix + r`.
EON
}

ensure_homebrew
install_brew_packages
init_submodules
install_oh_my_zsh
install_fzf_bindings
link_all
post_notes
