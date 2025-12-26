
. "$HOME/.local/share/../bin/env"
source "$HOME/.zsh/antigen.zsh"
antigen use oh-my-zsh

### ---- history config -------------------------------------
export HISTFILE=~/.zsh/.zsh_history

# How many commands zsh will load to memory.
export HISTSIZE=10000

# How many commands history will save on file.
export SAVEHIST=10000

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

# Write the history file in the ":start:elapsed;command" format.
setopt EXTENDED_HISTORY          

### ---- plugins ---------------------------------------

antigen bundle zdharma-continuum/fast-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen apply

# zsh-history-substring-search configuration
bindkey '^[[A' history-substring-search-up # or '\eOA'
bindkey '^[[B' history-substring-search-down # or '\eOB'
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

### ---- aliases ------------------------------------

alias avenv="source .venv/bin/activate"
alias v="nvim"
alias lg="lazygit"
alias wg_prod_up="wg-quick up alpas_prod"
alias wg_prod_down="wg-quick down alpas_prod"

alias wg_stg_up="wg-quick up alpas_stg"
alias wg_stg_down="wg-quick down alpas_stg"

alias wg_all_up="wg_stg_up && wg_prod_up"
alias wg_all_down="wg_stg_down && wg_prod_down"
alias clipboard="wl-copy"

# File system
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

if command -v zoxide &> /dev/null; then
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

envexport() {
  set -o allexport
  source "$1"
  set +o allexport
}

eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
