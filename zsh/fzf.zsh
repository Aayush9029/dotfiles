# FZF Configuration

# FZF default commands
export FZF_DEFAULT_COMMAND="fd . $HOME"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d . $HOME"

# FZF alias with preview
alias fzf="fzf --style minimal \
    --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# Load FZF keybindings
source <(fzf --zsh)
