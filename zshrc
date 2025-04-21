# Prompt and Theme
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
export EDITOR=vi

# Plugins
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
set ZSH_AUTOSUGGEST_USE_ASYNC=true
source ~/.config/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Key Bindings
bindkey '^[[Z' reverse-menu-complete
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' rehash true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;34'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion::complete:*' use-cache true

# Aliases
alias lg="lazygit"
alias ":wq"="exit"
alias "??"="ghcs"
alias bubu="brew update; brew upgrade; brew cleanup; brew doctor"
alias convert="magick convert"
alias gclaude="ANTHROPIC_BASE_URL=http://localhost:8082 claude"

# Environment Variables
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH=/opt/homebrew/bin:$PATH
export PATH="~/Documents/bin:$PATH"
export PATH="$(npm config get prefix)/bin:$PATH"
. "$HOME/.local/bin/env"

# API Keys
# ...

# Bun Completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# Custom Functions

function context_gen {
    find . -name "*.$1" -type f -exec printf '\n=== %s ===\n' {} \; -exec cat {} \;
}

# History
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
