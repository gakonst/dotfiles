alias tmux="TERM=xterm-256color tmux"
export ZSH_TMUX_AUTOSTART=true

# Auto-start tmux on new terminal (keeps same working dir)
if [[ -z "$TMUX" ]] && [[ $- == *i* ]] && command -v tmux &>/dev/null; then
  if [[ -t 0 ]] && [[ -t 1 ]] && [[ -t 2 ]]; then
    tmux attach-session -t main 2>/dev/null || tmux new-session -s main
  fi
fi

# Bun global binaries - highest priority
export BUN_INSTALL="$HOME/.bun"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh-custom"

# Base PATH (bun first, then Homebrew/system, then cargo; foundry appended below)
export PATH="$BUN_INSTALL/bin:/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.cargo/bin:$HOME/.foundry/bin"

# Foundry (forge/anvil/cast)
export PATH="$PATH:$HOME/.foundry/bin"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git git-extras zsh-autosuggestions history vi-mode tmux rust fzf)
plugins+=(fasd brew common-aliases macos taskwarrior extract vagrant docker vscode poetry minikube)

export DISABLE_AUTO_UPDATE=true
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'

source $ZSH/oh-my-zsh.sh
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

export EDITOR='nvim'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# aliases
alias cat=bat
alias grep=rg
alias vim=nvim
alias v=nvim
alias vi=nvim

# PATH add-ons
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.poetry/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$PATH:$HOME/.shadow/bin"

export GPG_TTY=$(tty)

# Google Cloud SDK (if installed)
if [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"; fi

# Keep default oh-my-zsh placeholders below

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# (PATH already set above)

alias ls='eza'
alias l='eza -l'
alias ll='eza -la'
alias la='eza -a'
alias find='fd'
alias du='dust'
alias df='duf'
alias ps='procs'
alias top='btm'
alias dig='doggo'
alias man='tldr'
alias sed='sd'
alias diff='delta'
alias ping='gping'

# Initialize zoxide for smarter cd
eval "$(zoxide init zsh)"

# Alias cd to use zoxide and list files
cd() {
    builtin cd "$@" && l
}

# Quick aliases
alias c='cd'
alias v='nvim'
alias vim='nvim'

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.tar.xz) tar xJf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar e "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Kill process with fzf
fkill() {
    local pid
    pid=$(ps aux | sed 1d | fzf -m --header="Select process to kill" --preview 'echo {}' --preview-window down:3:wrap | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
        echo "Killing process(es): $pid"
        echo $pid | xargs kill -${1:-9}
    fi
}

# Initialize fzf if it's not already loaded by oh-my-zsh
if ! type __fzfcmd > /dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
alias f="rg --files | fzf"

. "$HOME/.local/bin/env"

# bun completions (when installed)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Source enhanced FZF history configuration
source ~/fzf-zsh-history-config.zsh 2>/dev/null

# FZF Configuration
if command -v fzf &> /dev/null; then
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" 2>/dev/null || true
  source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2>/dev/null || true
  export FZF_COMPLETION_TRIGGER='**'
  export FZF_DEFAULT_OPTS='--height 70% --layout=reverse --border'
  if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
  fi
fi

# ZSH Autosuggestions Configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^ ' autosuggest-accept
bindkey '^[[F' autosuggest-accept
bindkey '^[[C' autosuggest-accept

# Keybindings: vi mode but keep common insert bindings
bindkey -e
bindkey -v
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

alias spotdl="uvx spotdl"
alias demucs="uvx demucs"
