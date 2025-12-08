# Codex Agent Playbook for gakonst/dotfiles

## Goals
- Keep `$HOME` symlinked to this repo for all managed files/dirs ("turbo symlink").
- Maintain submodules: `.oh-my-zsh`, `.config/alacritty/themes`, `.codex/superpowers` (upstream base skills).
- Personal/custom skills live in `.codex/skills` (these override superpowers); no edits inside the submodule.
- Use `bootstrap.sh` as the single entrypoint; it backs up pre-existing targets to `~/.dotfiles_backup_<timestamp>`.

## Runbook
1. `git clone https://github.com/gakonst/dotfiles.git ~/dotfiles && cd ~/dotfiles` (or use existing checkout).
2. Ensure submodules: `git submodule update --init --recursive` (bootstrap does this automatically) — includes `.codex/superpowers`.
3. Execute bootstrap (installs Homebrew packages on macOS, sets up oh-my-zsh, fzf bindings, links everything):
   - Default: `./bootstrap.sh`
   - Skip installs if desired: `SKIP_BREW=1 ./bootstrap.sh`, `SKIP_OMZ=1`, `SKIP_FZF=1`.
4. Start services (macOS tiling): `brew services start skhd && brew services start yabai` (requires SIP adjustments per yabai docs).

## Managed paths (symlinked whole directories unless noted)
- `.tmux.conf`, `.zshrc`, `.zshenv`, `.zprofile`, `.gitconfig`, `.vimrc`, `.skhdrc`, `.yabairc`, `fzf-zsh-history-config.zsh`.
- `.config/nvim`, `.config/gh`, `.config/uv`, `.config/scdl`, `.config/scdl2`, `.config/zed`, `.config/fish`, `.config/alacritty` (contains submodule `themes`), `.config/zsh-custom` (contains `zsh-autosuggestions`).
- `.local/bin/env`, `.local/bin/env.fish`.
- `.codex` (personal skills + agent configs; secrets excluded via .gitignore).
- Submodules: `.oh-my-zsh`, `.config/alacritty/themes`, `.config/zsh-custom/plugins/zsh-autosuggestions`, `.codex/superpowers`.

## Notes & cautions
- SoundCloud configs contain public client IDs; verify before publishing.
- `bootstrap.sh` moves any existing target into the timestamped backup dir before linking.
- Alacritty themes are vendored as a submodule; keep the `import` path in `alacritty.toml` pointing into `themes/`.
- `.codex/superpowers` is upstream-only; make local tweaks in `.codex/skills` (these take precedence when both exist). Secrets stay out via `.gitignore`.
- The repo is macOS-first; on other OSes, package install steps are skipped but links are applied.

## Verification snippet
```
repo=~/projects/dotfiles; ok=0; while read s d; do t="$repo/$s"; p="$HOME/$d"; [ -L "$p" ] && [ "$(readlink "$p")" = "$t" ] || { echo "BAD $p"; ok=1; }; done <<'MAP'
.config/alacritty .config/alacritty
.config/fish .config/fish
.config/nvim .config/nvim
.config/gh .config/gh
.config/uv .config/uv
.config/scdl .config/scdl
.config/scdl2 .config/scdl2
.config/zed .config/zed
.config/zsh-custom .config/zsh-custom
.tmux.conf .tmux.conf
.zshrc .zshrc
.zshenv .zshenv
.zprofile .zprofile
.gitconfig .gitconfig
.vimrc .vimrc
.skhdrc .skhdrc
.yabairc .yabairc
fzf-zsh-history-config.zsh fzf-zsh-history-config.zsh
.local/bin/env .local/bin/env
.local/bin/env.fish .local/bin/env.fish
.oh-my-zsh .oh-my-zsh
.codex .codex
MAP
exit $ok
```

## Update flow
1. Edit files in repo paths directly.
2. Run `./bootstrap.sh` to refresh links/backup others.
3. `git status` → `git add` → `git commit` → `git push origin master`.
