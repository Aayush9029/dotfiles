#!/usr/bin/env zsh
# copydocs.zsh - Copy markdown files from ~/.claude/commands with multi-select UI
#
# Usage: copy_docs --folder <folder_name>
#
# This function allows you to interactively select markdown files from the
# ~/.claude/commands directory and copy them to a specified folder.
# Uses gum (if available) or fzf for file selection.

copy_docs() {
    local folder_name=""
    local commands_dir="$HOME/.claude/commands"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --folder)
                folder_name="$2"
                shift 2
                ;;
            *)
                echo "Usage: copy_docs --folder <folder_name>"
                return 1
                ;;
        esac
    done

    # Check if folder name was provided
    if [[ -z "$folder_name" ]]; then
        echo "Error: Folder name is required"
        echo "Usage: copy_docs --folder <folder_name>"
        return 1
    fi

    # Check if commands directory exists
    if [[ ! -d "$commands_dir" ]]; then
        echo "Error: Directory $commands_dir does not exist"
        return 1
    fi

    # Get all .md files with full paths
    local md_files=("$commands_dir"/*.md(N))

    if [[ ${#md_files[@]} -eq 0 ]]; then
        echo "No .md files found in $commands_dir"
        return 1
    fi

    # Use fzf for multi-select (or gum if available)
    local selected_files
    if command -v gum &> /dev/null; then
        # Use gum for checkbox UI (Space to select, Enter to confirm)
        # Pass full paths and use basename for display
        selected_files=($(printf '%s\n' "${md_files[@]}" | xargs -I {} basename {} | gum choose --no-limit --header "Select files to copy (Space to select, Enter to confirm):"))
        # Convert basenames back to full paths for gum
        local full_paths=()
        for file in "${selected_files[@]}"; do
            full_paths+=("$commands_dir/$file")
        done
        selected_files=("${full_paths[@]}")
    else
        # Use fzf for multi-select with full paths (TAB to select, Enter to confirm)
        # Using 'command' to bypass alias and avoid preview issues
        selected_files=($(printf '%s\n' "${md_files[@]}" | command fzf --multi --prompt="Select files (TAB to select, Enter to confirm): " --height=40% --border --header="↑↓ Navigate | TAB Select | Enter Confirm" --preview 'bat --color=always --style=numbers {}' --preview-window=right:60%))
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

    # Copy selected files
    echo "\nCopying files to $folder_name:"
    for file in "${selected_files[@]}"; do
        local basename_file="$(basename "$file")"
        cp "$file" "$folder_name/"
        echo "  ✓ $basename_file"
    done

    echo "\nSuccessfully copied ${#selected_files[@]} file(s) to $folder_name"
}
