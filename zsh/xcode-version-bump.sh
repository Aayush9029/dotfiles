#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print colored output
print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

# Find Xcode project in current directory
find_xcode_project() {
    # Use nullglob to ensure empty array if no matches
    setopt local_options nullglob
    local projects=(*.xcodeproj)

    if [ ${#projects} -eq 0 ]; then
        print_error "No Xcode project found in current directory"
        return 1
    fi

    if [ ${#projects} -gt 1 ]; then
        print_warning "Multiple Xcode projects found. Using: ${projects[1]}"
    fi

    echo "${projects[1]}"
}

# Get current marketing version from project.pbxproj
get_current_version() {
    local project=$1
    local pbxproj="${project}/project.pbxproj"

    if [ ! -f "$pbxproj" ]; then
        print_error "Could not find project.pbxproj"
        return 1
    fi

    # Extract unique MARKETING_VERSION values
    local versions=$(grep "MARKETING_VERSION = " "$pbxproj" | sed 's/.*MARKETING_VERSION = \(.*\);/\1/' | sort -u)

    if [ -z "$versions" ]; then
        print_error "No MARKETING_VERSION found in project"
        return 1
    fi

    echo "$versions"
}

# Update marketing version in project.pbxproj
update_marketing_version() {
    local project=$1
    local new_version=$2
    local pbxproj="${project}/project.pbxproj"

    # Use sed to replace all MARKETING_VERSION entries
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed requires -i ''
        sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = ${new_version};/" "$pbxproj"
    else
        sed -i "s/MARKETING_VERSION = .*/MARKETING_VERSION = ${new_version};/" "$pbxproj"
    fi

    return $?
}

# Main script
xcode_version_bump() {
    print_header "╔═══════════════════════════════════════╗"
    print_header "║   Xcode Project Version Bump          ║"
    print_header "╚═══════════════════════════════════════╝"
    echo "" >&2

    # Find project
    print_info "Searching for Xcode project..."
    PROJECT=$(find_xcode_project)

    if [ $? -ne 0 ]; then
        return 1
    fi

    print_success "Found project: ${MAGENTA}${PROJECT}${NC}"
    echo "" >&2

    # Get current version
    print_info "Reading current version..."
    CURRENT_VERSION=$(get_current_version "$PROJECT")

    if [ $? -ne 0 ]; then
        return 1
    fi

    # Display current version
    print_header "Current Version:"
    echo -e "  ${GREEN}${CURRENT_VERSION}${NC}" >&2

    # Prompt for new version
    echo "" >&2
    print_header "Enter new version (or press Enter to cancel):"
    echo -ne "${CYAN}→${NC} " >&2
    read NEW_VERSION

    if [ -z "$NEW_VERSION" ]; then
        print_info "Cancelled. No changes made."
        return 0
    fi

    # Validate version format (basic check)
    if ! [[ "$NEW_VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        print_error "Invalid version format. Use format like: 1.0.4 or 1.0.0.1"
        return 1
    fi

    echo "" >&2
    print_info "Updating version to ${BOLD}${NEW_VERSION}${NC}..."

    # Update version
    update_marketing_version "$PROJECT" "$NEW_VERSION"

    if [ $? -eq 0 ]; then
        print_success "Version updated to ${BOLD}${GREEN}${NEW_VERSION}${NC}"
    else
        print_error "Failed to update version in project.pbxproj"
        return 1
    fi
}
