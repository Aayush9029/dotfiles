#!/usr/bin/env zsh
# release-push-cycle.zsh - Automate release workflow: develop → staging → main
#
# Usage: release-push-cycle [main-pr-title]
# Example: release-push-cycle "3.2.2 Groups hotfix, leaderboard changes"

release-push-cycle() {
    local main_pr_title=""
    local existing_dev_staging_pr=""
    local existing_staging_main_pr=""

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not in a git repository"
        return 1
    fi

    # Check if gh CLI is available
    if ! command -v gh &>/dev/null; then
        echo "❌ GitHub CLI (gh) is not installed"
        return 1
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 RELEASE PUSH CYCLE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Always fetch latest first
    echo ""
    echo "Fetching latest..."
    git fetch origin || { echo "❌ Failed to fetch"; return 1; }

    # Check for existing PRs
    echo "Checking for existing PRs..."

    existing_dev_staging_pr=$(gh pr list --head develop --base staging --json number,url --jq '.[0].url' 2>/dev/null)
    existing_staging_main_pr=$(gh pr list --head staging --base main --json number,url --jq '.[0].url' 2>/dev/null)

    local skip_dev_staging=false
    local skip_staging_main=false

    if [[ -n "$existing_dev_staging_pr" ]]; then
        echo "  ✓ Found existing PR: develop → staging"
        echo "    $existing_dev_staging_pr"
        skip_dev_staging=true
    else
        echo "  ○ No existing PR: develop → staging"
    fi

    if [[ -n "$existing_staging_main_pr" ]]; then
        echo "  ✓ Found existing PR: staging → main"
        echo "    $existing_staging_main_pr"
        skip_staging_main=true
    else
        echo "  ○ No existing PR: staging → main"
    fi

    # Get main PR title if we need to create staging → main PR
    if [[ "$skip_staging_main" == "false" ]]; then
        # Pre-fill with arg if provided, let user edit
        [[ $# -ge 1 ]] && main_pr_title="$1"
        echo ""
        echo "PR title for staging → main:"
        vared -p "> " main_pr_title

        if [[ -z "$main_pr_title" ]]; then
            echo "❌ PR title cannot be empty"
            return 1
        fi
    fi

    # Show plan
    echo ""
    echo "Plan:"
    if [[ "$skip_dev_staging" == "true" ]]; then
        echo "  1. Merge existing PR: develop → staging"
    else
        echo "  1. Create & merge PR: develop → staging"
    fi
    if [[ "$skip_staging_main" == "true" ]]; then
        echo "  2. Merge existing PR: staging → main"
    else
        echo "  2. Create & merge PR: staging → main"
        echo "     Title: \"$main_pr_title\""
    fi

    echo ""
    echo -n "Continue? [enter/any] "
    read -k1 confirmation
    echo ""
    if [[ "$confirmation" != $'\n' ]]; then
        echo "Cancelled"
        return 1
    fi

    # ═══════════════════════════════════════════
    # PHASE 1: develop → staging
    # ═══════════════════════════════════════════
    echo ""
    echo "─── develop → staging ───"

    # Always sync develop first
    echo "Syncing develop..."
    git checkout develop || { echo "❌ Failed to checkout develop"; return 1; }
    git pull origin develop || { echo "❌ Failed to pull develop"; return 1; }

    if [[ "$skip_dev_staging" == "true" ]]; then
        echo "Merging existing PR..."
        if ! gh pr merge "$existing_dev_staging_pr" --admin --merge --delete-branch=false 2>/dev/null; then
            echo "⚠️  Normal merge failed"
            echo -n "Try with admin override? [enter/any] "
            read -k1 force_confirm
            echo ""
            if [[ "$force_confirm" != $'\n' ]]; then
                echo "❌ Merge cancelled"
                return 1
            fi
            gh pr merge "$existing_dev_staging_pr" --admin --merge --delete-branch=false || { echo "❌ Failed to merge PR"; return 1; }
        fi
    else
        echo "Creating PR..."
        local pr_url_staging
        pr_url_staging=$(gh pr create --title "Staging < Develop" --base staging --body "" 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "❌ Failed to create PR: $pr_url_staging"
            return 1
        fi
        echo "Created: $pr_url_staging"

        echo "Merging..."
        if ! gh pr merge --merge --delete-branch=false 2>/dev/null; then
            echo "⚠️  Normal merge failed"
            echo -n "Try with admin override? [enter/any] "
            read -k1 force_confirm
            echo ""
            if [[ "$force_confirm" != $'\n' ]]; then
                echo "❌ Merge cancelled"
                return 1
            fi
            gh pr merge --admin --merge --delete-branch=false || { echo "❌ Failed to merge PR"; return 1; }
        fi
    fi
    echo "✓ develop → staging merged"

    # ═══════════════════════════════════════════
    # PHASE 2: staging → main
    # ═══════════════════════════════════════════
    echo ""
    echo "─── staging → main ───"

    # Always sync staging first
    echo "Syncing staging..."
    git checkout staging || { echo "❌ Failed to checkout staging"; return 1; }
    git pull origin staging || { echo "❌ Failed to pull staging"; return 1; }

    if [[ "$skip_staging_main" == "true" ]]; then
        echo "Merging existing PR..."
        if ! gh pr merge "$existing_staging_main_pr" --admin --merge --delete-branch=false 2>/dev/null; then
            echo "⚠️  Normal merge failed"
            echo -n "Try with admin override? [enter/any] "
            read -k1 force_confirm
            echo ""
            if [[ "$force_confirm" != $'\n' ]]; then
                echo "❌ Merge cancelled"
                return 1
            fi
            gh pr merge "$existing_staging_main_pr" --admin --merge --delete-branch=false || { echo "❌ Failed to merge PR"; return 1; }
        fi
    else
        echo "Creating PR: \"$main_pr_title\"..."
        local pr_url_main
        pr_url_main=$(gh pr create --title "$main_pr_title" --base main --body "" 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "❌ Failed to create PR: $pr_url_main"
            return 1
        fi
        echo "Created: $pr_url_main"

        echo "Merging..."
        if ! gh pr merge --merge --delete-branch=false 2>/dev/null; then
            echo "⚠️  Normal merge failed"
            echo -n "Try with admin override? [enter/any] "
            read -k1 force_confirm
            echo ""
            if [[ "$force_confirm" != $'\n' ]]; then
                echo "❌ Merge cancelled"
                return 1
            fi
            gh pr merge --admin --merge --delete-branch=false || { echo "❌ Failed to merge PR"; return 1; }
        fi
    fi
    echo "✓ staging → main merged"

    # ═══════════════════════════════════════════
    # DONE
    # ═══════════════════════════════════════════
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Release complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
