# Prompt and Theme Configuration

# Auto-start tmux if not already in tmux
if [[ -z "$TMUX" ]] && command -v tmux &> /dev/null; then
  # Check if any tmux sessions exist
  if tmux ls 2>/dev/null; then
    # Attach to existing session
    exec tmux attach
  else
    # Create new session
    exec tmux new-session
  fi
fi

# Detect if we're in an SSH session
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CONNECTION" ]]; then
  # SSH session detected - use simple theme without special fonts
  ZSH_THEME="bira"

  # Load Oh My Zsh with the simple theme
  export ZSH="$HOME/.oh-my-zsh"
  source $ZSH/oh-my-zsh.sh
else
  # Local session - use Powerlevel10k
  # Powerlevel10k instant prompt
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  # Load p10k configuration
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

  # Load Powerlevel10k theme
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
fi

# Set default editor
export EDITOR=vi
