#!/usr/bin/env zsh
# copydocs.zsh - Copy markdown files from ~/.claude/skills and ~/.claude/agents
#
# Supports both interactive TUI (default) and non-interactive CLI modes.
# Uses gum (if available) or fzf for interactive selection.

copy_docs() {
    local folder_name=""
    local mode="tui"  # tui | cli | list | all
    local cli_patterns=()
    local skills_dir="$HOME/.claude/skills"
    local agents_dir="$HOME/.claude/agents"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<'HELP'
Usage: copy_docs [options] [pattern ...]

Copy markdown docs from ~/.claude/skills and ~/.claude/agents to a local folder.

Modes:
  (default)              Interactive TUI via gum/fzf
  <pattern> ...          Copy docs matching the given names (substring match)
  -a, --all              Copy all docs without prompting
  -l, --list             List available docs and exit

Options:
  -f, --folder <name>    Destination folder (default: docs)
  -h, --help             Show this help message

Examples:
  copy_docs                          # interactive selection
  copy_docs swift-testing activitykit  # copy matching docs
  copy_docs --all --folder refs      # copy everything to refs/
  copy_docs --list                   # see what's available
HELP
                return 0
                ;;
            -f|--folder)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Error: --folder requires a value"
                    return 1
                fi
                folder_name="$2"
                shift 2
                ;;
            -l|--list)
                mode="list"
                shift
                ;;
            -a|--all)
                mode="all"
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Run 'copy_docs --help' for usage."
                return 1
                ;;
            *)
                mode="cli"
                cli_patterns+=("$1")
                shift
                ;;
        esac
    done

    # Default folder
    if [[ -z "$folder_name" ]]; then
        folder_name="docs"
    fi

    # Check if at least one source directory exists
    if [[ ! -d "$skills_dir" ]] && [[ ! -d "$agents_dir" ]]; then
        echo "Error: Neither $skills_dir nor $agents_dir exists"
        return 1
    fi

    # Get all .md files with full paths from both directories (excluding SKILL.md)
    local md_files=()
    if [[ -d "$skills_dir" ]]; then
        for f in "$skills_dir"/**/*.md(N); do
            [[ "$(basename "$f")" == "SKILL.md" ]] && continue
            md_files+=("$f")
        done
    fi
    if [[ -d "$agents_dir" ]]; then
        md_files+=("$agents_dir"/*.md(N))
    fi

    if [[ ${#md_files[@]} -eq 0 ]]; then
        echo "No .md files found in $skills_dir or $agents_dir"
        return 1
    fi

    # Build clean labels for each file
    local labels=()
    for file in "${md_files[@]}"; do
        local label=""
        if [[ "$file" == "$skills_dir"/* ]]; then
            local rel="${file#$skills_dir/}"
            local skill_name="${rel%%/*}"
            local rest="${rel#*/}"
            if [[ "$rest" == references/* ]]; then
                label="$skill_name/${rest#references/}"
                label="${label%.md}"
            else
                label="$skill_name/${rest%.md}"
            fi
        elif [[ "$file" == "$agents_dir"/* ]]; then
            label="${file#$agents_dir/}"
            label="${label%.md}"
        fi
        labels+=("$label")
    done

    # --- List mode: print labels and exit ---
    if [[ "$mode" == "list" ]]; then
        echo "Available docs (${#labels[@]}):"
        for label in "${labels[@]}"; do
            echo "  $label"
        done
        return 0
    fi

    # --- Resolve which files to copy based on mode ---
    local selected_files=()

    if [[ "$mode" == "all" ]]; then
        selected_files=("${md_files[@]}")

    elif [[ "$mode" == "cli" ]]; then
        # Match each pattern against labels (case-insensitive substring)
        local unmatched=()
        for pattern in "${cli_patterns[@]}"; do
            local found=false
            for i in {1..${#labels[@]}}; do
                if [[ "${labels[$i]:l}" == *"${pattern:l}"* ]]; then
                    selected_files+=("${md_files[$i]}")
                    found=true
                fi
            done
            if [[ "$found" == false ]]; then
                unmatched+=("$pattern")
            fi
        done
        if [[ ${#unmatched[@]} -gt 0 ]]; then
            echo "Warning: no match for: ${unmatched[*]}"
        fi

    else
        # TUI mode: interactive selection via gum or fzf
        local selected_labels
        if command -v gum &> /dev/null; then
            selected_labels=($(printf '%s\n' "${labels[@]}" | gum choose --no-limit --header "Select files to copy (Space to select, Enter to confirm):"))
        else
            selected_labels=($(printf '%s\n' "${labels[@]}" | command fzf --multi --prompt="Select files (TAB to select, Enter to confirm): " --height=40% --border --header="↑↓ Navigate | TAB Select | Enter Confirm"))
        fi

        for sel in "${selected_labels[@]}"; do
            for i in {1..${#labels[@]}}; do
                if [[ "${labels[$i]}" == "$sel" ]]; then
                    selected_files+=("${md_files[$i]}")
                    break
                fi
            done
        done
    fi

    # Check if any files were selected
    if [[ ${#selected_files[@]} -eq 0 ]]; then
        echo "No files selected"
        return 0
    fi

    # Create folder if it doesn't exist
    if [[ ! -d "$folder_name" ]]; then
        echo "Creating folder: $folder_name"
        mkdir -p "$folder_name"
    fi

    # Copy selected files using label-based flat names to avoid collisions
    echo "\nCopying files to $folder_name:"
    for file in "${selected_files[@]}"; do
        local dest_name=""
        for i in {1..${#md_files[@]}}; do
            if [[ "${md_files[$i]}" == "$file" ]]; then
                dest_name="${labels[$i]//\//-}.md"
                break
            fi
        done
        cp "$file" "$folder_name/$dest_name"
        echo "  ✓ $dest_name"
    done

    echo "\nSuccessfully copied ${#selected_files[@]} file(s) to $folder_name"
}
