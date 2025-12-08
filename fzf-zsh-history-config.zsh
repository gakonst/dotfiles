# Enhanced FZF-based reverse shell history for ZSH
# This configuration provides powerful history search with timestamps, preview, and advanced features

# ============================================
# History Configuration
# ============================================
# Increase history size
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# History options for better experience
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
setopt HIST_VERIFY               # Don't execute immediately upon history expansion

# ============================================
# FZF Configuration
# ============================================
# FZF default options
export FZF_DEFAULT_OPTS="
  --height 60% --layout=reverse --border=rounded
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --prompt='🔍 ' --pointer='▶' --marker='✓'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --bind='ctrl-e:execute(echo {2..} | xargs -o vim)'
  --bind='ctrl-v:execute(echo {2..} | xargs -o code)'
  --preview-window='right:50%:wrap'
  --inline-info
"

# ============================================
# Custom History Widget
# ============================================
# Enhanced history search with timestamps
fzf-history-widget-enhanced() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null

  # Ensure __fzfcmd is available
  if ! type __fzfcmd > /dev/null 2>&1; then
    echo "Error: __fzfcmd not found. Please ensure fzf is properly installed and loaded." >&2
    return 1
  fi

  # Format history with timestamps and line numbers
  selected=( $(fc -rl 1 | perl -ne '
    if (/^\s*(\d+)\*?\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.*)$/) {
      print "$1\t$2 $3\t$4\n";
    } elsif (/^\s*(\d+)\*?\s+(.*)$/) {
      print "$1\t\t$2\n";
    }
  ' | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-60%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort --expect=ctrl-x $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m --preview 'echo {} | cut -f3- | bat --style=plain --color=always --language=bash || echo {} | cut -f3-' --preview-window=down:3:wrap" $(__fzfcmd)) )

  local ret=$?
  if [ -n "$selected" ]; then
    local accept=0
    if [[ $selected[1] == ctrl-x ]]; then
      accept=1
      shift selected
    fi
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
      [[ $accept = 1 ]] && zle accept-line
    fi
  fi
  zle reset-prompt
  return $ret
}

# Replace the default fzf-history-widget
zle -N fzf-history-widget fzf-history-widget-enhanced
bindkey '^R' fzf-history-widget

# ============================================
# Additional History Functions
# ============================================
# Search history by frequency
function history-frequency() {
  fc -l 1 | awk '{CMD[$2]++; count++} END { for (a in CMD) print CMD[a] " " CMD[a]/count*100 "% " a }' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -20
}

# Search history for today only
function history-today() {
  local today=$(date +%Y-%m-%d)
  fc -l 1 | grep "^[[:space:]]*[0-9]*[[:space:]]*$today" | fzf --tac --no-sort --preview 'echo {} | cut -d" " -f4- | bat --style=plain --color=always --language=bash || echo {} | cut -d" " -f4-'
}

# Search history by time range
function history-range() {
  local start_date="$1"
  local end_date="$2"
  fc -l 1 | awk -v start="$start_date" -v end="$end_date" '$2 >= start && $2 <= end' | fzf --tac --no-sort
}

# Show history statistics
function history-stats() {
  echo "=== Command History Statistics ==="
  echo "Total commands: $(fc -l 1 | wc -l)"
  echo "Unique commands: $(fc -l 1 | awk '{print $2}' | sort -u | wc -l)"
  echo ""
  echo "=== Top 20 Most Used Commands ==="
  history-frequency
  echo ""
  echo "=== Recent Failed Commands ==="
  fc -l 1 | grep -E '(command not found|error|failed|Error|Failed)' | tail -10
}

# Clean duplicate entries from history
function history-clean-duplicates() {
  local temp_file=$(mktemp)
  fc -W  # Write current history to file
  awk '!seen[$0]++' "$HISTFILE" > "$temp_file" && mv "$temp_file" "$HISTFILE"
  fc -R  # Reload history from file
  echo "History cleaned. Duplicates removed."
}

# ============================================
# Key Bindings
# ============================================
# Additional key bindings for enhanced functionality
bindkey '^[r' history-frequency        # Alt+R for frequency search
bindkey '^[t' history-today           # Alt+T for today's history

# ============================================
# Integration with zsh-autosuggestions
# ============================================
# If zsh-autosuggestions is installed, configure it to work with our history
if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=true
fi

# ============================================
# Aliases for quick access
# ============================================
alias h='history'
alias hf='history-frequency'
alias ht='history-today'
alias hs='history-stats'
alias hc='history-clean-duplicates'
