#!/usr/bin/env zsh
# git-replace-branch.zsh - Git branch replacement utility
#
# Usage: git-replace-branch <branch-to-replace> --with <source-branch>
# Example: git-replace-branch staging --with develop
#
# This function completely replaces a target branch with another branch.
# WARNING: This will destroy all changes in the target branch!

# Git branch replacement function
git-replace-branch() {
    local replace_branch=""
    local with_branch=""

    # Parse arguments - first arg is branch to replace, then --with flag
    if [[ $# -lt 3 ]]; then
        echo "❌ Missing arguments!"
        echo "Usage: git-replace-branch <branch-to-replace> --with <source-branch>"
        echo "Example: git-replace-branch staging --with develop"
        return 1
    fi

    replace_branch="$1"
    shift

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --with)
                with_branch="$2"
                shift 2
                ;;
            *)
                echo "❌ Unknown argument: $1"
                echo "Usage: replace_branch <branch-to-replace> --with <source-branch>"
                echo "Example: replace_branch staging --with develop"
                return 1
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$replace_branch" ]] || [[ -z "$with_branch" ]]; then
        echo "❌ Missing arguments!"
        echo "Usage: git-replace-branch <branch-to-replace> --with <source-branch>"
        echo "Example: git-replace-branch staging --with develop"
        return 1
    fi

    # Show what will happen
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  BRANCH REPLACEMENT WARNING"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "This will COMPLETELY REPLACE:"
    echo "  📍 Branch: $replace_branch"
    echo "  📦 With:   $with_branch"
    echo ""
    echo "⚠️  ALL changes in '$replace_branch' will be LOST!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Ask for confirmation
    echo -n "Are you sure? Type 'yes' to continue: "
    read confirmation

    if [[ "$confirmation" != "yes" ]]; then
        echo "❌ Cancelled"
        return 1
    fi

    echo ""
    echo "🔄 Starting branch replacement..."

    # Execute the replacement
    echo "📥 Fetching latest from origin..."
    git fetch origin || { echo "❌ Failed to fetch"; return 1; }

    echo "🔄 Updating $with_branch..."
    git checkout "$with_branch" || { echo "❌ Failed to checkout $with_branch"; return 1; }
    git pull origin "$with_branch" || { echo "❌ Failed to pull $with_branch"; return 1; }

    echo "🔄 Switching to $replace_branch..."
    git checkout "$replace_branch" || { echo "❌ Failed to checkout $replace_branch"; return 1; }

    echo "⚡ Resetting $replace_branch to match $with_branch..."
    git reset --hard "origin/$with_branch" || { echo "❌ Failed to reset"; return 1; }

    echo "📤 Force pushing to origin/$replace_branch..."
    git push --force origin "$replace_branch" || { echo "❌ Failed to force push"; return 1; }

    echo ""
    echo "✅ Successfully replaced '$replace_branch' with '$with_branch'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
