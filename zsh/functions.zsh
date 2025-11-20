# Custom Functions

# Google search with Gemini
google() {
  gemini -p "Search google for <query>$*</query> and summarize results"
}

# Generate context from files of a specific extension
function context_gen {
    find . -name "*.$1" -type f -exec printf '\n=== %s ===\n' {} \; -exec cat {} \;
}

# Wrap xcodebuild to automatically pipe through xcbeautify
function xcodebuild {
    command xcodebuild "$@" 2>&1 | xcbeautify
}
