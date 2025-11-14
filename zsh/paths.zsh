# Environment Path Configuration

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Homebrew
export PATH=/opt/homebrew/bin:$PATH
export PATH="/opt/homebrew/sbin:$PATH"

# Custom bin directory
export PATH="$HOME/Documents/bin:$PATH"

# npm global packages
export PATH="$(npm config get prefix)/bin:$PATH"

# Local bin
. "$HOME/.local/bin/env"
