# gakonst / dotfiles

Dotfiles for macOS: tmux, Neovim, Zsh, Yabai/SKHD, Alacritty, and a few helpers. All files live in this repo and get symlinked into `$HOME` by the bootstrap script.

## What's inside
- **Shell:** `.zshrc`, `.zshenv`, `.zprofile`, `fzf-zsh-history-config.zsh`, PATH helpers in `.local/bin/env*`, oh-my-zsh with modern CLI aliases, fzf/zoxide setup, tmux auto-attach. `ZSH_CUSTOM` points to `.config/zsh-custom` where `zsh-autosuggestions` is vendored.
- **Neovim:** Lua config (`.config/nvim/init.lua`) with lazy.nvim, gruvbox, LSP (rust/ts/python/lua), nvim-cmp, Treesitter, Conform format-on-save, Trouble, lualine, NvimTree. Lockfile included.
- **Tmux:** `.tmux.conf` with backtick prefix, vim-style splits/movement, catppuccin-ish status, mouse, Alt+number window jumps.
- **Window mgmt:** `.yabairc` (BSP layout, gaps, rules) and `.skhdrc` (bindings for focus/move/resize, spaces, displays).
- **Terminal:** `.config/alacritty` (includes `alacritty-theme` submodule) with `alacritty.toml` importing solarized_light.
- **GitHub CLI:** `.config/gh/config.yml` and `hosts.yml` (no tokens).
- **Python toolchain:** `.config/uv/*` receipt and version pin.
- **SoundCloud dl:** `.config/scdl/scdl.cfg` and `.config/scdl2/scdl.cfg` (contains public client_id; review before pushing).
- **Zed:** `.config/zed/settings.json` (vim mode, fonts, theme prefs).
- **Vim (legacy):** `.vimrc` with vim-plug, gruvbox/solarized, airline, NERDTree, fzf, vim-tmux-navigator, commentary.
- **Misc:** `.gitconfig`, fish snippet `.config/fish/conf.d/uv.env.fish` to share PATH helper.

## Quick start (fresh machine)
```bash
# clone
git clone https://github.com/gakonst/dotfiles.git ~/dotfiles
cd ~/dotfiles

# run bootstrap (installs packages, oh-my-zsh, clones alacritty theme, symlinks files)
./bootstrap.sh
```

Afterwards:
- Restart terminal or `exec zsh` to load the new shell config.
- Start services (macOS): `brew services start skhd && brew services start yabai`.
- Yabai needs SIP disabled + scripting addition (follow yabai README); run `sudo yabai --load-sa` after each macOS update.

### Flags
- Set `SKIP_BREW=1` to skip Homebrew installs (handy when re-linking on an existing machine).
- Set `SKIP_OMZ=1` to skip oh-my-zsh install (if you manage it yourself).
- Set `SKIP_FZF=1` to skip fzf keybinding install.

### Submodules
- `.oh-my-zsh` (ohmyzsh)
- `.config/alacritty/themes` (alacritty-theme)
- `.config/zsh-custom/plugins/zsh-autosuggestions` (zsh-users)

## Notes
- The bootstrap script backs up any existing files it replaces into `~/.dotfiles_backup_<timestamp>`.
- It is macOS-focused (Homebrew). On Linux it will still symlink files but skip package installs.
- Local plugin path for Neovim `~/vibe-producing/vim-strudel` is expected to exist if you want the Strudel integration.
