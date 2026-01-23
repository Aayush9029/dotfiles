# Prompt and Theme Configuration

# Detect if we're in an SSH session and set theme accordingly
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CONNECTION" ]]; then
  # SSH session detected - use robbyrussell-style prompt
  autoload -Uz vcs_info
  precmd() { vcs_info }

  zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f '
  zstyle ':vcs_info:*' enable git

  setopt PROMPT_SUBST
  PROMPT='%F{green}➜%f  %F{cyan}%1~%f ${vcs_info_msg_0_}'
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
