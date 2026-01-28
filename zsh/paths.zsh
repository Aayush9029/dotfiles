# Environment Path Configuration

# Homebrew
export PATH=/opt/homebrew/bin:$PATH
export PATH="/opt/homebrew/sbin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Custom bin directory
export PATH="$HOME/Documents/bin:$PATH"
export PATH="$HOME/.oh-my-zsh/custom/dotfiles/bin:$PATH"

# Local bin (highest priority - sourced last to override everything)
. "$HOME/.local/bin/env"
