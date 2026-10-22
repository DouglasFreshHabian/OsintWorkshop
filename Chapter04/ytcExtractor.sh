#!/usr/bin/env bash
# YouTube Comment Extractor
# Uses yt-dlp to enumerate channel videos and youtube-comment-downloader to fetch comments.
# Requirements: Bash 4+, python3, python3-venv, python3-pip, and (inside venv) yt-dlp,
# youtube-comment-downloader.

set -uo pipefail

# ==============================
# CONFIGURATION
# ==============================
CHANNEL_INPUT="${1:-}"
BASE_DIR="${OUTPUT_DIR:-}"
VENV_DIR="${VENV_DIR:-.venv-ytc}"
DELAY="${DELAY:-2}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
APT_GET="${APT_GET:-apt-get}"

# ==============================
# TERMINAL COLORS
# ==============================
if [[ -t 1 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[1;31m'
    GREEN=$'\033[1;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[1;34m'
    CYAN=$'\033[1;36m'
    MAGENTA=$'\033[1;35m'
    WHITE=$'\033[1;37m'
    GRAY=$'\033[0;90m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' WHITE='' GRAY='' BOLD='' RESET=''
fi

info()    { printf '%s[*]%s %s\n' "$CYAN" "$RESET" "$*"; }
success() { printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"; }
warning() { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"; }
error()   { printf '%s[-]%s %s\n' "$RED" "$RESET" "$*" >&2; }
line()    { printf '%s%s%s\n' "$GRAY" '============================================================' "$RESET"; }
pause()   { printf '\n'; read -r -p "Press Enter to return to the menu..." _ || true; }

usage() {
    cat <<'HELP'
Usage:
  ./ytcExtractor.sh [CHANNEL_URL_OR_HANDLE]
  ./ytcExtractor.sh --help

Examples:
  ./ytcExtractor.sh https://www.youtube.com/@ExampleChannel
  ./ytcExtractor.sh @ExampleChannel

If no channel is supplied, the script asks for one interactively.
The channel can also be changed from the menu.
HELP
}

# ==============================
# BANNER
# ==============================
banner() {
    printf '%s%s' "$RED" "$BOLD"
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
    printf '%s\n' "$RESET"
    printf '%sChannel:%s %s\n' "$CYAN" "$RESET" "${CHANNEL_URL:-not selected}"
    printf '%sPython environment:%s %s\n' "$CYAN" "$RESET" "$VENV_DIR"
    printf '\n'
    line
}

# ==============================
# CHANNEL / PATH SETUP
# ==============================
normalize_channel() {
    local value="$1"
    value="${value%/}"
    if [[ "$value" == @* ]]; then
        CHANNEL_URL="https://www.youtube.com/${value}"
    elif [[ "$value" =~ ^https?:// ]]; then
        CHANNEL_URL="$value"
    else
        error "Enter a YouTube channel URL or @handle."
        return 1
    fi
    # yt-dlp's /videos tab is used to enumerate uploads.
    CHANNEL_URL="${CHANNEL_URL%/}"
    local slug
    slug="${CHANNEL_URL##*/}"
    slug="${slug#@}"
    slug="${slug//[^a-zA-Z0-9._-]/_}"
    [[ -n "$BASE_DIR" ]] || BASE_DIR="${slug:-YouTubeArchive}"
    OUTPUT_DIR="$BASE_DIR"
    COMMENTS_DIR="$OUTPUT_DIR/comments"
    VIDEO_LIST="$OUTPUT_DIR/video_ids.txt"
    FAILED_LIST="$OUTPUT_DIR/failed_videos.txt"
}

choose_channel() {
    local value
    read -r -p "YouTube channel URL or @handle: " value || return 1
    [[ -n "$value" ]] || { warning "Channel cannot be blank."; return 1; }
    normalize_channel "$value"
}

# ==============================
# DEPENDENCIES
# ==============================
check_system_dependencies() {
    local missing=0 cmd
    printf '\n%sSystem dependencies%s\n' "$BOLD" "$RESET"
    for cmd in "$PYTHON_BIN" "$APT_GET"; do
        if [[ "$cmd" == "$APT_GET" ]]; then
            if command -v "$cmd" >/dev/null 2>&1; then success "$cmd detected"; else warning "$cmd not found (needed only for automatic apt installation)"; fi
        elif command -v "$cmd" >/dev/null 2>&1; then success "$cmd detected"; else error "$cmd is missing"; missing=1; fi
    done
    if command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        "$PYTHON_BIN" -m venv --help >/dev/null 2>&1 && success "venv module available" || { error "python3-venv appears to be missing"; missing=1; }
        if "$PYTHON_BIN" -m pip --version >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
            success "pip support detected"
        else
            error "python3-pip appears to be missing"
            missing=1
        fi
    fi
    return "$missing"
}

venv_python() { printf '%s/bin/python' "$VENV_DIR"; }
venv_bin() { printf '%s/bin/%s' "$VENV_DIR" "$1"; }

check_python_packages() {
    local python
    python="$(venv_python)"
    printf '\n%sPython environment packages%s\n' "$BOLD" "$RESET"
    if [[ ! -x "$python" ]]; then
        warning "Virtual environment not found: $VENV_DIR"
        return 1
    fi
    "$python" -m pip show yt-dlp >/dev/null 2>&1 && success "yt-dlp installed in venv" || warning "yt-dlp is missing from venv"
    "$python" -m pip show youtube-comment-downloader >/dev/null 2>&1 && success "youtube-comment-downloader installed in venv" || warning "youtube-comment-downloader is missing from venv"
    "$python" -m pip show yt-dlp >/dev/null 2>&1 && "$python" -m pip show youtube-comment-downloader >/dev/null 2>&1
}

install_system_dependencies() {
    local packages=(python3 python3-venv python3-pip)
    if ! command -v "$APT_GET" >/dev/null 2>&1; then
        error "Automatic system installation currently supports apt-get (Debian/Ubuntu/Kali/Parrot)."
        info "Install these packages with your distribution's package manager: ${packages[*]}"
        return 1
    fi
    local -a privilege=()
    if (( EUID != 0 )); then
        command -v sudo >/dev/null 2>&1 || { error "Run as root or install sudo to install system packages."; return 1; }
        privilege=(sudo)
    fi
    info "Installing system packages: ${packages[*]}"
    "${privilege[@]}" "$APT_GET" update && "${privilege[@]}" "$APT_GET" install -y "${packages[@]}"
}

setup_venv() {
    if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        error "$PYTHON_BIN is not installed."
        return 1
    fi
    if ! "$PYTHON_BIN" -m venv --help >/dev/null 2>&1; then
        error "The Python venv module is unavailable. Install python3-venv first."
        return 1
    fi
    if [[ ! -x "$(venv_python)" ]]; then
        info "Creating virtual environment: $VENV_DIR"
        "$PYTHON_BIN" -m venv "$VENV_DIR" || { error "Could not create virtual environment."; return 1; }
    else
        info "Using existing virtual environment: $VENV_DIR"
    fi
    local python
    python="$(venv_python)"
    info "Upgrading pip in the virtual environment..."
    "$python" -m pip install --upgrade pip || return 1
    info "Installing yt-dlp and youtube-comment-downloader..."
    "$python" -m pip install --upgrade yt-dlp youtube-comment-downloader || return 1
    success "Python environment is ready."
    printf '\n'
    info "Package details (equivalent to python3 -m pip show youtube-comment-downloader):"
    "$python" -m pip show youtube-comment-downloader
    printf '\n'
    info "Activate manually with: source \"$VENV_DIR/bin/activate\""
}

install_everything() {
    if ! check_system_dependencies; then
        warning "Some system dependencies are missing."
        read -r -p "Install python3, python3-venv, and python3-pip now? [y/N] " answer || return 1
        case "${answer,,}" in y|yes) install_system_dependencies || return 1 ;; *) error "System dependencies are required."; return 1 ;; esac
    fi
    setup_venv
}

# ==============================
# COMMENT EXTRACTION
# ==============================
run_extraction() {
    local channel="$CHANNEL_URL" total count success_count failed skipped video_id output_file
    local ytdlp downloader
    [[ -n "${CHANNEL_URL:-}" ]] || { choose_channel || return 1; channel="$CHANNEL_URL"; }
    ytdlp="$(venv_bin yt-dlp)"
    downloader="$(venv_bin youtube-comment-downloader)"
    if [[ ! -x "$ytdlp" || ! -x "$downloader" ]]; then
        error "Required tools are missing from $VENV_DIR. Choose setup or install everything first."
        return 1
    fi

    mkdir -p "$COMMENTS_DIR" || { error "Cannot create $COMMENTS_DIR"; return 1; }
    mkdir -p "$OUTPUT_DIR" || return 1
    info "Fetching video IDs from YouTube..."
    printf '%s\n\n' "$channel"
    if ! "$ytdlp" --flat-playlist --ignore-errors --print '%(id)s' "${channel%/}/videos" > "$VIDEO_LIST"; then
        error "Failed to retrieve the channel's video list."
        return 1
    fi
    # Remove blank lines and duplicate IDs while preserving first-seen order.
    awk 'NF && !seen[$0]++' "$VIDEO_LIST" > "${VIDEO_LIST}.tmp" && mv -- "${VIDEO_LIST}.tmp" "$VIDEO_LIST"
    total=$(wc -l < "$VIDEO_LIST" | tr -d ' ')
    if [[ "$total" -eq 0 ]]; then
        error "No video IDs found. Check the channel URL or whether its videos are accessible."
        return 1
    fi
    success "Found $total videos."
    info "Starting comment downloads..."
    : > "$FAILED_LIST"
    count=0; success_count=0; failed=0; skipped=0
    while IFS= read -r video_id || [[ -n "$video_id" ]]; do
        [[ -n "$video_id" ]] || continue
        count=$((count + 1))
        output_file="$COMMENTS_DIR/$video_id.json"
        printf '\n'
        line
        printf '%s%sVIDEO %s/%s%s\n' "$WHITE" "$BOLD" "$count" "$total" "$RESET"
        printf '%sID: %s%s\n' "$GRAY" "$video_id" "$RESET"
        line
        if [[ -s "$output_file" ]]; then
            warning "Already downloaded. Skipping."
            success_count=$((success_count + 1)); skipped=$((skipped + 1))
            continue
        fi
        info "Downloading comments..."
        if "$downloader" --youtubeid "$video_id" --output "$output_file"; then
            success "Comments saved: $output_file"
            success_count=$((success_count + 1))
        else
            error "Download failed: $video_id"
            printf '%s\n' "$video_id" >> "$FAILED_LIST"
            rm -f -- "$output_file"
            failed=$((failed + 1))
        fi
        sleep "$DELAY"
    done < "$VIDEO_LIST"
    printf '\n\n'
    line
    printf '%s%sDOWNLOAD COMPLETE%s\n' "$RED" "$BOLD" "$RESET"
    line
    printf '\n'
    printf '  %sVideos found:       %s%s\n' "$CYAN" "$WHITE" "$total"
    printf '  %sSuccessful/skipped: %s%s\n' "$GREEN" "$WHITE" "$success_count"
    printf '  %sSkipped existing:   %s%s\n' "$YELLOW" "$WHITE" "$skipped"
    printf '  %sFailed:             %s%s\n' "$RED" "$WHITE" "$failed"
    printf '\n'
    printf '  %sVideo IDs:          %s%s\n' "$BLUE" "$WHITE" "$VIDEO_LIST"
    printf '  %sComment files:      %s%s/\n' "$BLUE" "$WHITE" "$COMMENTS_DIR"
    printf '  %sFailed video IDs:   %s%s\n' "$BLUE" "$WHITE" "$FAILED_LIST"
    printf '\n'
    line
    if (( failed > 0 )); then warning "Some downloads failed. Review $FAILED_LIST"; return 1; fi
    success "All videos processed successfully."
}

help_menu() {
    printf '\n'
    line
    printf '%s%s HELP — YOUTUBE COMMENT EXTRACTION%s\n' "$WHITE" "$BOLD" "$RESET"
    line
    cat <<'HELP'
  1. Check dependencies
     Checks Python, venv/pip support, and packages installed in the local venv.

  2. Install system dependencies
     On apt-based systems, installs python3, python3-venv, and python3-pip.

  3. Create/update Python environment
     Creates the venv and installs yt-dlp plus youtube-comment-downloader.

  4. Show package details / activation command
     Shows pip package metadata and the command to activate the venv.

  5. Do everything
     Checks dependencies, offers to install missing system packages, sets up
     the venv, then downloads video IDs and comments for the selected channel.

  6. Extract comments
     Runs extraction using the selected channel and existing environment.

  7. Change channel
     Select a different channel URL or @handle.

  8. Help
     Shows this menu.

Notes:
  - Existing non-empty comment files are skipped.
  - The channel is supplied at runtime; it is not hardcoded.
  - The default output folder is based on the channel handle.
  - The Python packages are installed inside the venv, not system-wide.
HELP
    printf '\n'
    pause
}

show_package_details() {
    local python
    python="$(venv_python)"
    if [[ ! -x "$python" ]]; then
        warning "Virtual environment not found. Choose option 3 first."
        printf 'Activation command: source "%s/bin/activate"\n' "$VENV_DIR"
        return 1
    fi
    printf '\n'
    "$python" -m pip show youtube-comment-downloader || true
    printf '\n'
    "$python" -m pip show yt-dlp || true
    printf '\nActivation command:\n  source "%s/bin/activate"\n' "$VENV_DIR"
}

check_all_dependencies() {
    local result=0
    check_system_dependencies || result=1
    check_python_packages || result=1
    printf '\n'
    if (( result == 0 )); then success "All required dependencies are available."; else warning "Some dependencies are missing. Use options 2 and 3, or option 5."; fi
    return "$result"
}

main_menu() {
    local choice
    while true; do
        printf '\n'
        line
        printf '%s%s YOUTUBE COMMENT EXTRACTOR%s\n' "$WHITE" "$BOLD" "$RESET"
        line
        printf '%sChannel:%s %s\n\n' "$CYAN" "$RESET" "${CHANNEL_URL:-not selected}"
        printf '  %s1%s  Check all dependencies\n' "$GREEN" "$RESET"
        printf '  %s2%s  Install system dependencies\n' "$GREEN" "$RESET"
        printf '  %s3%s  Create venv and install Python packages\n' "$GREEN" "$RESET"
        printf '  %s4%s  Show package details and activation command\n' "$GREEN" "$RESET"
        printf '  %s5%s  Do everything (setup and extract comments)\n' "$MAGENTA" "$RESET"
        printf '  %s6%s  Extract comments\n' "$GREEN" "$RESET"
        printf '  %s7%s  Change channel\n' "$GREEN" "$RESET"
        printf '  %s8%s  Help\n' "$GREEN" "$RESET"
        printf '  %s0%s  Exit\n\n' "$RED" "$RESET"
        read -r -p "ytcExtractor > " choice || break
        case "$choice" in
            1) check_all_dependencies; pause ;;
            2) install_system_dependencies; pause ;;
            3) setup_venv; pause ;;
            4) show_package_details; pause ;;
            5) install_everything && run_extraction; pause ;;
            6) run_extraction; pause ;;
            7) choose_channel; pause ;;
            8) help_menu ;;
            0) printf '%sGoodbye!%s\n' "$CYAN" "$RESET"; break ;;
            *) warning "Invalid selection." ;;
        esac
    done
}

# ==============================
# STARTUP
# ==============================
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
if [[ $# -gt 1 ]]; then error "Usage: $0 [CHANNEL_URL_OR_HANDLE]"; usage >&2; exit 2; fi
if [[ -n "$CHANNEL_INPUT" ]]; then
    normalize_channel "$CHANNEL_INPUT" || exit 2
else
    # Ask for channel at startup, so the banner/menu always reflects the selected archive.
    printf '%sYouTube channel URL or @handle (blank to choose later): %s' "$GRAY" "$RESET"
    read -r CHANNEL_INPUT || exit 1
    if [[ -n "$CHANNEL_INPUT" ]]; then normalize_channel "$CHANNEL_INPUT" || exit 2; fi
fi
banner
main_menu
