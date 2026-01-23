# Swift Package Update Helper
# Usage: swift-package-update [path-to-Package.swift]
# If no path provided, searches current directory and common subdirectories

function swift-package-update {
    # Colors
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local NC='\033[0m'

    local PACKAGE_SWIFT=""

    # If argument provided, use it
    if [[ -n "$1" ]]; then
        if [[ -f "$1" ]]; then
            PACKAGE_SWIFT="$1"
        elif [[ -f "$1/Package.swift" ]]; then
            PACKAGE_SWIFT="$1/Package.swift"
        else
            echo -e "${RED}Error: Package.swift not found at $1${NC}"
            return 1
        fi
    else
        # Find all Package.swift files in non-hidden directories
        local -a found_packages
        found_packages=("${(@f)$(find . -name "Package.swift" -not -path "*/.*" -not -path "*/Build/*" -not -path "*/build/*" -not -path "*/DerivedData/*" -not -path "*/Pods/*" 2>/dev/null | sort)}")

        # Remove empty entries
        found_packages=(${found_packages:#})

        if [[ ${#found_packages[@]} -eq 0 ]]; then
            PACKAGE_SWIFT=""
        elif [[ ${#found_packages[@]} -eq 1 ]]; then
            PACKAGE_SWIFT="${found_packages[1]}"
        else
            # Multiple found - show selection menu
            echo ""
            echo -e "${CYAN}${BOLD}Multiple Package.swift files found:${NC}"
            echo ""
            for i in {1..${#found_packages[@]}}; do
                echo -e "  ${YELLOW}${BOLD}$i)${NC} ${BLUE}${found_packages[$i]}${NC}"
            done
            echo ""
            echo -ne "${CYAN}Select [1-${#found_packages[@]}]:${NC} "
            read pkg_selection

            if [[ "$pkg_selection" =~ ^[0-9]+$ && "$pkg_selection" -ge 1 && "$pkg_selection" -le ${#found_packages[@]} ]]; then
                PACKAGE_SWIFT="${found_packages[$pkg_selection]}"
            else
                echo -e "${RED}Invalid selection${NC}"
                return 1
            fi
        fi
    fi

    if [[ -z "$PACKAGE_SWIFT" || ! -f "$PACKAGE_SWIFT" ]]; then
        echo -e "${RED}Error: No Package.swift found in current directory or subdirectories${NC}"
        echo -e "Usage: swift-package-update [path-to-Package.swift]"
        return 1
    fi

    echo -e "${CYAN}${BOLD}Using: $PACKAGE_SWIFT${NC}"
    echo -e "${CYAN}${BOLD}Checking package versions...${NC}\n"

    # Arrays to store package info
    local -a repos
    local -a current_versions
    local -a latest_versions
    local -a package_names
    local -a needs_update

    # Parse Package.swift for dependencies (skip commented lines)
    while IFS= read -r line; do
        # Skip commented lines
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        if [[ "$trimmed" == //* ]]; then
            continue
        fi
        if [[ $line =~ '\.package\(url: *"https://github\.com/([^"]+)".*from: *"([^"]+)"' ]]; then
            repos+=("${match[1]}")
            current_versions+=("${match[2]}")
            package_names+=("${match[1]:t}")
        fi
    done < "$PACKAGE_SWIFT"

    if [[ ${#repos[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No GitHub dependencies found in Package.swift${NC}"
        return 0
    fi

    # Get latest versions from GitHub
    echo -e "${BLUE}Fetching latest versions from GitHub...${NC}\n"

    local repo_name latest_tag
    local gh_cmd="${commands[gh]:-/opt/homebrew/bin/gh}"
    for i in {1..${#repos[@]}}; do
        repo_name="${repos[$i]}"
        # Strip .git suffix if present
        repo_name="${repo_name%.git}"
        latest_tag=$("$gh_cmd" release view --repo "$repo_name" --json tagName -q '.tagName' 2>/dev/null)

        # Fallback to tags API if no release found
        if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
            latest_tag=$("$gh_cmd" api "repos/$repo_name/tags" --jq '.[0].name' 2>/dev/null)
        fi

        # Strip leading 'v' if present
        latest_tag="${latest_tag#v}"

        # Validate: must be a semver-like string (digits and dots), not JSON error
        if [[ -z "$latest_tag" || "$latest_tag" == "null" || "$latest_tag" =~ ^\{ || ! "$latest_tag" =~ ^[0-9] ]]; then
            latest_tag="unknown"
        fi

        latest_versions+=("$latest_tag")

        # Check if update needed
        if [[ "${current_versions[$i]}" != "$latest_tag" && "$latest_tag" != "unknown" ]]; then
            needs_update+=("$i")
        fi
    done

    # Print table header
    printf "${BOLD}%-4s %-35s %-12s %-12s %s${NC}\n" "#" "Package" "Current" "Latest" "Status"
    printf "%-4s %-35s %-12s %-12s %s\n" "---" "-----------------------------------" "------------" "------------" "------"

    # Print each package
    local name current latest pkg_status
    for i in {1..${#repos[@]}}; do
        name="${package_names[$i]}"
        current="${current_versions[$i]}"
        latest="${latest_versions[$i]}"

        if [[ "$current" == "$latest" ]]; then
            pkg_status="${GREEN}up to date${NC}"
        elif [[ "$latest" == "unknown" ]]; then
            pkg_status="${YELLOW}?${NC}"
        else
            pkg_status="${YELLOW}update available${NC}"
        fi

        # Highlight packages that need update
        if [[ "$current" != "$latest" && "$latest" != "unknown" ]]; then
            printf "${YELLOW}%-4s %-35s %-12s %-12s %b${NC}\n" "$i" "$name" "$current" "$latest" "$pkg_status"
        else
            printf "%-4s %-35s %-12s %-12s %b\n" "$i" "$name" "$current" "$latest" "$pkg_status"
        fi
    done

    echo ""

    # Check if any updates available
    if [[ ${#needs_update[@]} -eq 0 ]]; then
        echo -e "${GREEN}All packages are up to date!${NC}"
        return 0
    fi

    echo -e "${CYAN}${BOLD}Packages with available updates: ${#needs_update[@]}${NC}"
    echo -e "Enter package numbers separated by spaces, 'all' to update all, or 'q' to quit:"
    echo -n "> "
    read selection

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        return 0
    fi

    # Determine which packages to update
    local -a to_update

    if [[ "$selection" == "all" || "$selection" == "ALL" ]]; then
        to_update=("${needs_update[@]}")
    else
        # Parse space-separated numbers
        local sel_current sel_latest
        for num in ${=selection}; do
            if [[ $num -ge 1 && $num -le ${#repos[@]} ]]; then
                sel_current="${current_versions[$num]}"
                sel_latest="${latest_versions[$num]}"
                if [[ "$sel_current" != "$sel_latest" && "$sel_latest" != "unknown" ]]; then
                    to_update+=("$num")
                else
                    echo -e "${YELLOW}Package #$num (${package_names[$num]}) is already up to date, skipping.${NC}"
                fi
            else
                echo -e "${RED}Invalid package number: $num${NC}"
            fi
        done
    fi

    if [[ ${#to_update[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No packages to update.${NC}"
        return 0
    fi

    echo ""
    echo -e "${CYAN}Updating ${#to_update[@]} package(s)...${NC}"

    # Update Package.swift
    local upd_repo upd_name upd_current upd_latest
    local sed_cmd="/usr/bin/sed"
    for idx in "${to_update[@]}"; do
        upd_repo="${repos[$idx]}"
        upd_name="${package_names[$idx]}"
        upd_current="${current_versions[$idx]}"
        upd_latest="${latest_versions[$idx]}"

        echo -e "  ${BLUE}Updating ${BOLD}$upd_name${NC}${BLUE}: $upd_current -> $upd_latest${NC}"

        # Use sed to update the version in Package.swift
        "$sed_cmd" -i '' "s|github.com/$upd_repo\", from: \"$upd_current\"|github.com/$upd_repo\", from: \"$upd_latest\"|g" "$PACKAGE_SWIFT"
    done

    echo ""
    echo -e "${GREEN}${BOLD}Done!${NC} Updated ${#to_update[@]} package(s) in Package.swift"
    echo -e "${YELLOW}Remember to resolve packages in Xcode or run: swift package resolve${NC}"
}
