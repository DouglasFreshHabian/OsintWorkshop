#!/bin/bash

# ============================================================
# cloneRepo - GitHub Repository Cloner
# ============================================================

# Define ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
CYAN='\033[1;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================
# Banner
# ============================================================

banner() {
    clear
    echo -e "${CYAN}"
    cat <<'EOF'
      _                  ____                  
  ___| | ___  _ __   ___|  _ \ ___ _ __   ___  
 / __| |/ _ \| '_ \ / _ \ |_) / _ \ '_ \ / _ \ 
| (__| | (_) | | | |  __/  _ <  __/ |_) | (_) |
 \___|_|\___/|_| |_|\___|_| \_\___| .__/ \___/ 
                                  |_|           
EOF
    echo -e "${NC}"
    echo -e "${DIM}GitHub Repository Cloner${NC}"
    echo
}

# ============================================================
# Help
# ============================================================

show_help() {
    banner

    echo -e "${WHITE}${BOLD}USAGE${NC}"
    echo
    echo -e "${DIM}  $0 [OPTIONS]${NC}"
    echo

    echo -e "${WHITE}${BOLD}OPTIONS${NC}"
    echo
    echo -e "${CYAN}  -a, --all${NC}"
    echo -e "${DIM}      Automatically clone all repositories owned by the user.${NC}"
    echo
    echo -e "${CYAN}  -h, --help${NC}"
    echo -e "${DIM}      Display this help menu.${NC}"
    echo

    echo -e "${WHITE}${BOLD}EXAMPLES${NC}"
    echo
    echo -e "${DIM}  $0${NC}"
    echo -e "${DIM}  $0 -a${NC}"
    echo -e "${DIM}  $0 --all${NC}"
    echo -e "${DIM}  $0 -h${NC}"
    echo
}

# ============================================================
# Auto Clone Menu
# ============================================================

auto_clone_menu() {
    banner

    echo -e "${WHITE}${BOLD}AUTO CLONE ALL REPOSITORIES${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    echo -e "${CYAN}  1)${NC} ${BOLD}Clone All Repositories${NC}"
    echo -e "${DIM}     Automatically clone every repository owned by the user.${NC}"
    echo

    echo -e "${CYAN}  2)${NC} ${BOLD}Cancel${NC}"
    echo -e "${DIM}     Return without cloning anything.${NC}"
    echo

    while true; do
        echo -ne "${YELLOW}Select an option [1-2]: ${NC}"
        read -r choice

        case "$choice" in
            1)
                AUTO_CLONE=true
                echo
                echo -e "${GREEN}[+] Automatic cloning enabled.${NC}"
                echo
                break
                ;;
            2)
                echo
                echo -e "${YELLOW}Operation cancelled.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option.${NC}"
                echo
                ;;
        esac
    done
}

# ============================================================
# Check Dependencies
# ============================================================

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}jq not found. Please install it with:${NC}"
    echo -e "${DIM}apt install jq${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl not found. Please install it with:${NC}"
    echo -e "${DIM}apt install curl${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}git not found. Please install it with:${NC}"
    echo -e "${DIM}apt install git${NC}"
    exit 1
fi

# ============================================================
# Process Arguments
# ============================================================

AUTO_CLONE=false

case "${1:-}" in
    --all|-a)
        auto_clone_menu
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    "")
        ;;
    *)
        echo -e "${RED}[ERROR] Unknown option: $1${NC}"
        echo
        show_help
        exit 1
        ;;
esac

# ============================================================
# Repository Checks
# ============================================================

check_repo_exists() {
    local url="$1"
    local response

    response=$(curl --write-out "%{http_code}" \
        --silent \
        --output /dev/null \
        "$url")

    if [[ "$response" -eq 200 ]]; then
        echo -e "${GREEN}Repository exists: ${url}${NC}"
        return 0
    else
        echo -e "${RED}Repository does not exist: ${url}${NC}"
        return 1
    fi
}

# ============================================================
# Clone Repository
# ============================================================

clone_repo() {
    echo -e "${WHITE}"
    git clone "$1"
    echo -e "${NC}"
}

# ============================================================
# Main
# ============================================================

banner

echo -e "${WHITE}"
read -p "Enter the GitHub username (e.g., DouglasFreshHabian): " username
echo -e "${NC}"

# Validate username
profile_url="https://github.com/$username"

if ! check_repo_exists "$profile_url"; then
    exit 1
fi

# GitHub API URL
api_url="https://api.github.com/users/$username/repos?type=owner&per_page=100"

echo
echo -e "${BLUE}Fetching repositories under the username: ${username}...${NC}"
echo

# Fetch repositories
api_response=$(curl -s "$api_url")

# Check API response
if [[ -z "$api_response" ]]; then
    echo -e "${RED}Error: Failed to fetch repositories. Please check the username and try again.${NC}"
    exit 1
fi

# Validate JSON
echo "$api_response" | jq . > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: The API response is not valid JSON.${NC}"
    echo "$api_response"
    exit 1
fi

# Extract clone URLs
repos=$(echo "$api_response" | jq -r '.[].clone_url')

# Check repositories
if [[ -z "$repos" ]]; then
    echo -e "${YELLOW}No repositories found under: $username${NC}"
    exit 0
fi

# ============================================================
# Clone Repositories
# ============================================================

for repo in $repos; do

    echo
    echo -e "${BLUE}${BOLD}Found repository:${NC} ${repo}"

    if $AUTO_CLONE; then

        echo -e "${GREEN}Auto-cloning ${repo}...${NC}"
        clone_repo "$repo"

    else

        echo -ne "${YELLOW}Do you want to clone this repository? (Y/N, default Y): ${NC}"
        read -r response

        response=${response:-Y}

        case "$response" in

            [Yy]*)
                echo -e "${GREEN}Cloning ${repo}...${NC}"
                clone_repo "$repo"
                ;;

            [Nn]*)
                echo -e "${YELLOW}Skipping ${repo}${NC}"
                ;;

            *)
                echo -e "${RED}Invalid input, skipping...${NC}"
                ;;

        esac
    fi

done

echo
echo -e "${GREEN}${BOLD}All done!${NC}"
echo
