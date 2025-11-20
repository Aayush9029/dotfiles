#!/usr/bin/env zsh
# git-set-as.zsh - Set current commit as new head of a branch
#
# Usage: git-set-as <branch-name>
# Example: git-set-as main
#
# This function sets the current commit as the new head of the specified branch.
# It automatically backs up the original branch before making changes.
# WARNING: This will rewrite history for the target branch!

# Git set-as function
git-set-as() {
    local target_branch=""
    local current_commit=""
    local backup_branch=""
    local date_suffix=""

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not in a git repository!"
        return 1
    fi

    # Parse arguments
    if [[ $# -ne 1 ]]; then
        echo "❌ Invalid arguments!"
        echo "Usage: git-set-as <branch-name>"
        echo "Example: git-set-as main"
        echo ""
        echo "This will set the current commit as the new head of the specified branch."
        return 1
    fi

    target_branch="$1"

    # Get current commit hash
    current_commit=$(git rev-parse HEAD) || { echo "❌ Failed to get current commit"; return 1; }

    # Get short commit hash for display
    short_commit=$(git rev-parse --short HEAD)

    # Create date suffix for backup branch
    date_suffix=$(date +%Y%m%d)
    backup_branch="${target_branch}-backup-${date_suffix}"

    # Check if target branch exists
    if ! git show-ref --verify --quiet "refs/heads/${target_branch}"; then
        echo "❌ Branch '${target_branch}' does not exist locally!"
        echo "Available branches:"
        git branch --format="  - %(refname:short)"
        return 1
    fi

    # Get the current commit of the target branch for comparison
    target_current=$(git rev-parse "${target_branch}")

    # Check if we're already at the same commit
    if [[ "$current_commit" == "$target_current" ]]; then
        echo "✅ Branch '${target_branch}' is already at commit ${short_commit}"
        return 0
    fi

    # Show what will happen
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  BRANCH HEAD REPLACEMENT WARNING"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "This will:"
    echo "  1. Create local backup '${backup_branch}'"
    echo "  2. Set '${target_branch}' to current commit: ${short_commit}"
    echo "  3. Force push changes to remote"
    echo ""
    echo "Current status:"
    echo "  📍 Target branch: ${target_branch}"
    echo "  📍 Current HEAD:  $(git rev-parse --short ${target_branch})"
    echo "  📍 New HEAD:      ${short_commit}"
    echo ""

    # Show commits that will be lost/gained
    echo "Commits that will be lost (if any):"
    git log --oneline "${current_commit}..${target_branch}" 2>/dev/null | head -5 | sed 's/^/  - /'
    if [[ $(git log --oneline "${current_commit}..${target_branch}" 2>/dev/null | wc -l) -gt 5 ]]; then
        echo "  ... and more"
    fi

    echo ""
    echo "⚠️  This operation CANNOT be undone without the backup!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Ask for confirmation
    echo -n "Are you sure? Type 'yes' to continue: "
    read confirmation

    if [[ "$confirmation" != "yes" ]]; then
        echo "❌ Cancelled"
        return 1
    fi

    echo ""
    echo "🔄 Starting branch head replacement..."

    # Fetch latest from origin
    echo "📥 Fetching latest from origin..."
    git fetch origin || { echo "❌ Failed to fetch"; return 1; }

    # Create backup branch
    echo "💾 Creating local backup branch '${backup_branch}'..."
    git checkout "${target_branch}" || { echo "❌ Failed to checkout ${target_branch}"; return 1; }
    git branch "${backup_branch}" || { echo "❌ Failed to create backup branch"; return 1; }

    # Now reset the target branch to the current commit
    echo "⚡ Resetting '${target_branch}' to commit ${short_commit}..."
    git reset --hard "${current_commit}" || { echo "❌ Failed to reset branch"; return 1; }

    # Force push the changes
    echo "📤 Force pushing '${target_branch}' to remote..."
    git push --force origin "${target_branch}" || { echo "❌ Failed to force push"; return 1; }

    echo ""
    echo "✅ Successfully set '${target_branch}' to commit ${short_commit}"
    echo "💾 Backup saved locally as '${backup_branch}'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To restore if needed:"
    echo "  git checkout ${target_branch}"
    echo "  git reset --hard ${backup_branch}"
    echo "  git push --force origin ${target_branch}"
}