# Prompt and Theme
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
export EDITOR=vi

# Plugins
plugins=(sudo git history taskwarrior tmux tmuxinator zsh-autosuggestions)

source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
set ZSH_AUTOSUGGEST_USE_ASYNC=true
source ~/.config/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh


# Key Bindings
bindkey '^[[Z' reverse-menu-complete
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search
# Disable Ctrl+R for history search
bindkey -r '^R'

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
alias cdot="cursor ."
alias ccc="claude --dangerously-skip-permissions"
alias cco="claude --dangerously-skip-permissions --model=opus"
alias generate-today="ccc -p \"/generate-today is running… everything i have done today Aayush9029, for everything pr merges, branches worked on and
comits\""
alias lg="lazygit"
alias ":wq"="exit"
alias "??"="ghcs"
alias bubu="brew update; brew upgrade; brew cleanup; brew doctor;  brew upgrade --cask;mas upgrade"
alias convert="magick convert"


google() {
  gemini -p "Search google for <query>$*</query> and summarize results"
}


# Environment Variables
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH=/opt/homebrew/bin:$PATH
export PATH="$HOME/Documents/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$(npm config get prefix)/bin:$PATH"
. "$HOME/.local/bin/env"

# API Keys
# LOL nice try

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
export PATH=~/.npm-global/bin:$PATH
# FZF STUFF

export FZF_DEFAULT_COMMAND="fd . $HOME"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d . $HOME"

alias fzf="fzf --style minimal \
    --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

source <(fzf --zsh)

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Git branch replacement function
source ~/.zshrc_git_replace_branch
