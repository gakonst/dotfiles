# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Auto-start tmux on new terminal
# Only start if not already inside tmux and if this is an interactive shell
if [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
    # Check if tmux is installed
    if command -v tmux &> /dev/null; then
        # Check if we're in a terminal that supports tmux
        if [[ -t 0 ]] && [[ -t 1 ]] && [[ -t 2 ]]; then
            # Try to attach to existing session or create new one
            tmux attach-session -t main 2>/dev/null || tmux new-session -s main
        fi
    fi
fi

# Bun global binaries - highest priority
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh-custom"

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
plugins=(git fzf zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

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
export PATH=/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin

export PATH=$PATH:$HOME/.cargo/bin

# Modern Rust CLI tool aliases
alias ls='eza'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias du='dust'
alias df='duf'
alias ps='procs'
alias top='btm'
alias dig='doggo'
alias man='tldr'
alias sed='sd'
alias diff='delta'
alias ping='gping'
# alias curl='xh'

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
export PATH=/opt/homebrew/bin:/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Users/gakonst/.cargo/bin

alias f="rg --files | fzf"


. "$HOME/.local/bin/env"

# bun completions
[ -s "/Users/gakonst/.bun/_bun" ] && source "/Users/gakonst/.bun/_bun"

# Ensure bun global binaries have highest priority
export PATH="$HOME/.bun/bin:$PATH"

# Source enhanced FZF history configuration
source ~/fzf-zsh-history-config.zsh 2>/dev/null

# FZF Configuration
# Set up fzf key bindings and fuzzy completion
if command -v fzf &> /dev/null; then
  # Source fzf key bindings (CTRL-T, CTRL-R, ALT-C)
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
  
  # Source fzf auto-completion
  source "/opt/homebrew/opt/fzf/shell/completion.zsh"
  
  # Enable fuzzy auto-completion for files and directories
  # Use ** as the trigger sequence (e.g., vim **<TAB>)
  export FZF_COMPLETION_TRIGGER='**'
  
  # Options for fzf
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  
  # Use fd (if available) for better performance
  if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  
  # Advanced: Preview files with bat (if available)
  if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
  fi
fi

# ZSH Autosuggestions Configuration
# Configure autosuggestions to use history
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Set the color for suggestions (gray)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Bind right arrow to accept the current suggestion
bindkey '→' autosuggest-accept
bindkey '^[[C' autosuggest-accept  # Alternative right arrow code

# You can also use these bindings:
# Ctrl+Space to accept suggestion
bindkey '^ ' autosuggest-accept
# End key to accept suggestion
bindkey '^[[F' autosuggest-accept
# Use z for smart directory jumping with zoxide
alias zl='z && l'  # Jump with zoxide and list files

# pnpm
export PNPM_HOME="/Users/gakonst/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Enable Emacs keybindings (default in zsh)
bindkey -e

bindkey -v
# In insert mode, keep familiar readline moves
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
# Edit current command line in $VISUAL/$EDITOR (Esc then v in vi-mode)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

alias spotdl="uvx spotdl"
alias demucs="uvx demucs"
