#!/usr/bin/env bash

set -u

# ==============================
# CONFIGURATION
# ==============================

CHANNEL_URL="https://www.youtube.com/@DouglasHabian-tq5ck"

OUTPUT_DIR="youtube-comments"
COMMENTS_DIR="$OUTPUT_DIR/comments"
VIDEO_LIST="$OUTPUT_DIR/video_ids.txt"
FAILED_LIST="$OUTPUT_DIR/failed_videos.txt"

# Delay between video downloads (seconds)
DELAY=2

# ==============================
# TERMINAL COLORS
# ==============================

if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    CYAN='\033[1;36m'
    MAGENTA='\033[1;35m'
    WHITE='\033[1;37m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    WHITE=''
    GRAY=''
    BOLD=''
    RESET=''
fi

# ==============================
# OUTPUT FUNCTIONS
# ==============================

info() {
    printf "${CYAN}[*]${RESET} %s\n" "$1"
}

success() {
    printf "${GREEN}[+]${RESET} %s\n" "$1"
}

warning() {
    printf "${YELLOW}[!]${RESET} %s\n" "$1"
}

error() {
    printf "${RED}[-]${RESET} %s\n" "$1" >&2
}

line() {
    printf "${GRAY}%s${RESET}\n" \
        "============================================================"
}

# ==============================
# RED ASCII ART BANNER
# ==============================

banner() {
    printf "${RED}${BOLD}"
    cat <<'BANNER'
    ⠀⠀⠀⢲⣦⠀⢠⣶⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠘⣿⡄⣼⡟⢀⣤⣤⣄⠀⢠⣄⠀⣠⡄⠀⠀⠀⠀
    ⠀⠀⠀⠀⢹⣷⣿⠁⣿⡏⠙⣿⡆⢸⣿⠀⣿⡇⠀⠀⠀⠀
    ⠀⠀⠀⠀⠈⣿⡏⠀⣿⡇⠀⣿⡇⢸⣿⠀⣿⡇⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⣿⡇⠀⢿⣧⣰⣿⠇⢸⣿⣤⣿⡇⠀⠀⠀⠀
    ⠀⠀⣀⣀⣀⣉⣁⣀⣀⣉⣉⣁⣀⣀⣉⣁⣈⣁⣀⣀⠀⠀
    ⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶
    ⣿⣿⣿⣉⠉⠉⣉⣿⣿⣿⣿⠉⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⡇⢸⡟⠛⣿⠛⢻⠀⠘⠛⠻⡿⠛⡛⠻⣿⣿⣿
    ⣿⣿⣿⣿⡇⢸⡇⠀⣿⠀⢸⠀⢸⡇⠀⡇⠀⠿⠀⣿⣿⣿
    ⣿⣿⣿⣿⡇⢸⡇⠀⣿⠀⢸⠀⢸⡇⠀⡇⠀⣶⠒⣿⣿⣿
    ⣿⣿⣿⣿⣧⣼⣷⣤⣴⣦⣾⣤⣶⣤⣼⣿⣦⣤⣴⣿⣿⣿
    ⠙⠻⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠟⠋
  YOUTUBE COMMENT EXTRACTION
BANNER
    printf "${RESET}\n"

    printf "${GRAY}  Channel: ${WHITE}%s${RESET}\n" "$CHANNEL_URL"
    printf "${GRAY}  Mode:    ${MAGENTA}Comment Collection${RESET}\n"
    printf "\n"
    line
    printf "\n"
}

# ==============================
# CHECK DEPENDENCIES
# ==============================

check_dependencies() {
    local missing=0

    for cmd in yt-dlp youtube-comment-downloader; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "$cmd is not installed or not in PATH."
            missing=1
        else
            success "$cmd detected"
        fi
    done

    if [[ "$missing" -ne 0 ]]; then
        exit 1
    fi

    printf "\n"
}

# ==============================
# STARTUP
# ==============================

banner
check_dependencies

mkdir -p "$COMMENTS_DIR"

# ==============================
# FETCH VIDEO IDS
# ==============================

info "Fetching video IDs from YouTube..."
printf "${GRAY}    %s${RESET}\n\n" "$CHANNEL_URL"

if ! yt-dlp \
    --flat-playlist \
    --ignore-errors \
    --print "%(id)s" \
    "${CHANNEL_URL%/}/videos" \
    > "$VIDEO_LIST"; then

    error "Failed to retrieve the channel's video list."
    exit 1
fi

# Remove blank lines
sed -i.bak '/^[[:space:]]*$/d' "$VIDEO_LIST"
rm -f "${VIDEO_LIST}.bak"

TOTAL=$(wc -l < "$VIDEO_LIST" | tr -d ' ')

if [[ "$TOTAL" -eq 0 ]]; then
    error "No video IDs found. Check your channel URL."
    exit 1
fi

printf "\n"
success "Found $TOTAL videos."
info "Starting comment downloads..."
printf "\n"

# ==============================
# DOWNLOAD COMMENTS
# ==============================

: > "$FAILED_LIST"

COUNT=0
SUCCESS=0
FAILED=0
SKIPPED=0

while IFS= read -r VIDEO_ID || [[ -n "$VIDEO_ID" ]]; do
    [[ -z "$VIDEO_ID" ]] && continue

    COUNT=$((COUNT + 1))
    OUTPUT_FILE="$COMMENTS_DIR/$VIDEO_ID.json"

    printf "\n"
    line

    printf "${WHITE}${BOLD}  VIDEO ${CYAN}%s${WHITE}/${CYAN}%s${RESET}\n" \
        "$COUNT" "$TOTAL"

    printf "${GRAY}  ID: %s${RESET}\n" "$VIDEO_ID"
    line
    printf "\n"

    # Skip existing nonempty files
    if [[ -s "$OUTPUT_FILE" ]]; then
        warning "Already downloaded. Skipping."
        SUCCESS=$((SUCCESS + 1))
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    info "Downloading comments..."

    if youtube-comment-downloader \
        --youtubeid "$VIDEO_ID" \
        --output "$OUTPUT_FILE"; then

        success "Comments saved: $OUTPUT_FILE"
        SUCCESS=$((SUCCESS + 1))

    else
        error "Download failed: $VIDEO_ID"

        printf '%s\n' "$VIDEO_ID" >> "$FAILED_LIST"

        # Remove potentially incomplete output
        rm -f "$OUTPUT_FILE"

        FAILED=$((FAILED + 1))
    fi

    sleep "$DELAY"

done < "$VIDEO_LIST"

# ==============================
# SUMMARY
# ==============================

printf "\n\n"
line
printf "${RED}${BOLD}"
printf "                 DOWNLOAD COMPLETE\n"
printf "${RESET}"
line

printf "\n"
printf "  ${CYAN}Videos found:       ${WHITE}%s${RESET}\n" "$TOTAL"
printf "  ${GREEN}Successful/skipped: ${WHITE}%s${RESET}\n" "$SUCCESS"
printf "  ${YELLOW}Skipped existing:   ${WHITE}%s${RESET}\n" "$SKIPPED"
printf "  ${RED}Failed:             ${WHITE}%s${RESET}\n" "$FAILED"

printf "\n"
printf "  ${BLUE}Video IDs:          ${WHITE}%s${RESET}\n" "$VIDEO_LIST"
printf "  ${BLUE}Comment files:      ${WHITE}%s/${RESET}\n" "$COMMENTS_DIR"
printf "  ${BLUE}Failed video IDs:   ${WHITE}%s${RESET}\n" "$FAILED_LIST"

printf "\n"
line

if [[ "$FAILED" -gt 0 ]]; then
    printf "\n"
    warning "Some downloads failed."
    info "Review the failed video list: $FAILED_LIST"
    exit 1
fi

printf "\n"
success "All videos processed successfully."
printf "\n"
