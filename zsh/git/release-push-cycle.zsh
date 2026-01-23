#!/usr/bin/env zsh
# release-push-cycle.zsh - Automate release workflow: develop → staging → main
#
# Usage: release-push-cycle [main-pr-title]
# Example: release-push-cycle "3.2.2 Groups hotfix, leaderboard changes"
#
# This function automates the release cycle:
# 1. Creates PR from develop → staging (title: "Staging < Develop")
# 2. Merges with admin privileges
# 3. Creates PR from staging → main (with your custom title)
# 4. Merges with admin privileges

release-push-cycle() {
    local main_pr_title=""

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not in a git repository!"
        return 1
    fi

    # Check if gh CLI is available
    if ! command -v gh &>/dev/null; then
        echo "❌ GitHub CLI (gh) is not installed!"
        return 1
    fi

    # Get main PR title from argument or prompt
    if [[ $# -ge 1 ]]; then
        main_pr_title="$1"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 RELEASE PUSH CYCLE"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -n "Enter PR title for staging → main: "
        read main_pr_title

        if [[ -z "$main_pr_title" ]]; then
            echo "❌ PR title cannot be empty!"
            return 1
        fi
    fi

    # Show what will happen
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 RELEASE PUSH CYCLE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This will perform the following steps:"
    echo "  1. Checkout develop and pull latest"
    echo "  2. Create PR: develop → staging"
    echo "     Title: \"Staging < Develop\""
    echo "  3. Merge PR with admin privileges"
    echo "  4. Checkout staging and pull latest"
    echo "  5. Create PR: staging → main"
    echo "     Title: \"$main_pr_title\""
    echo "  6. Merge PR with admin privileges"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Single confirmation before starting
    echo -n "Ready to start? Type 'yes' to continue: "
    read confirmation
    if [[ "$confirmation" != "yes" ]]; then
        echo "❌ Cancelled"
        return 1
    fi
    echo ""
    echo "🚀 Running in auto mode - no further confirmations needed"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 STEP 1: Preparing develop branch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "🔄 Fetching latest from origin..."
    git fetch origin || { echo "❌ Failed to fetch"; return 1; }

    echo "🔄 Checking out develop..."
    git checkout develop || { echo "❌ Failed to checkout develop"; return 1; }

    echo "📥 Pulling latest changes..."
    git pull origin develop || { echo "❌ Failed to pull develop"; return 1; }

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 STEP 2: Creating PR develop → staging"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "📝 Creating PR: develop → staging..."
    local pr_url_staging
    pr_url_staging=$(gh pr create --title "Staging < Develop" --base staging --body "" 2>&1)
    local pr_create_status=$?

    if [[ $pr_create_status -ne 0 ]]; then
        echo "❌ Failed to create PR: $pr_url_staging"
        return 1
    fi

    echo "✅ PR created: $pr_url_staging"

    echo "🔀 Merging PR with admin privileges..."
    gh pr merge --admin --merge --delete-branch=false || { echo "❌ Failed to merge PR"; return 1; }

    echo "✅ Merged develop → staging"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 STEP 3: Preparing staging branch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "🔄 Checking out staging..."
    git checkout staging || { echo "❌ Failed to checkout staging"; return 1; }

    echo "📥 Pulling latest changes..."
    git pull origin staging || { echo "❌ Failed to pull staging"; return 1; }

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 STEP 4: Creating PR staging → main"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "📝 Creating PR: staging → main..."
    echo "   Title: \"$main_pr_title\""
    local pr_url_main
    pr_url_main=$(gh pr create --title "$main_pr_title" --base main --body "" 2>&1)
    local pr_create_main_status=$?

    if [[ $pr_create_main_status -ne 0 ]]; then
        echo "❌ Failed to create PR: $pr_url_main"
        return 1
    fi

    echo "✅ PR created: $pr_url_main"

    echo "🔀 Merging PR with admin privileges..."
    gh pr merge --admin --merge --delete-branch=false || { echo "❌ Failed to merge PR"; return 1; }

    echo "✅ Merged staging → main"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 RELEASE PUSH CYCLE COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Summary:"
    echo "  ✅ develop → staging: Merged"
    echo "  ✅ staging → main: Merged"
    echo "     Title: \"$main_pr_title\""
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
