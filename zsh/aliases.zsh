# Aliases

# Editor shortcuts
alias cdot="cursor ."

# Claude CLI shortcuts
alias ccc="claude --dangerously-skip-permissions --model=haiku"
alias cco="claude --dangerously-skip-permissions --model=opus"
alias ccd="codex --dangerously-bypass-approvals-and-sandbox"

# Git shortcuts
alias lg="lazygit"

# Shell shortcuts
alias ":wq"="exit"

# Quick Claude Haiku prompt (Python script handles quoting)
alias '??'='ask_claude'

# Homebrew maintenance
alias bubu="brew update; brew upgrade; brew cleanup; brew doctor; brew upgrade --cask"

# ImageMagick
alias convert="magick convert"

# Xcode project version management
alias xcode-version-bump="xcode_version_bump"

# Use bun instead of npm/npx
alias npm="bun"
alias npx="bunx"

