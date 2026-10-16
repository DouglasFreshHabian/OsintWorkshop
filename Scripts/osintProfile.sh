#!/usr/bin/env bash

# =============================================================================
# Fresh Forensics
# OSINT Firefox Profile Installer
# =============================================================================
#
# Description:
#   Downloads the Fresh Forensics OSINT Firefox template, creates a dedicated
#   Firefox profile named Osint, and installs the template into that profile.
#
# Usage:
#   ./osint_firefox.sh
#
# Launch the installed profile manually:
#   firefox --no-remote -P Osint
#
# Requirements:
#   Firefox, curl or wget, unzip, awk, and standard Linux utilities.
#
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_NAME="OSINT FIREFOX INSTALLER"
PROFILE_NAME="Osint"

TEMPLATE_URL="https://raw.githubusercontent.com/DouglasFreshHabian/OsintWorkshop/main/ff-template.zip"

# =============================================================================
# COLORS
# =============================================================================

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    WHITE='\033[0;37m'
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
    BOLD=''
    RESET=''
fi

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================

TEMP_DIR=""
FIREFOX_BIN=""
PROFILES_INI=""
PROFILE_DIR=""
PROFILE_CREATED=0

# =============================================================================
# OUTPUT HELPERS
# =============================================================================

line() {
    printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

section() {
    printf '\n'
    line
    printf '%b\n' "${BOLD}${MAGENTA}  $1${RESET}"
    line
}

info() {
    printf '%b\n' "${BLUE}[*]${RESET} $1"
}

success() {
    printf '%b\n' "${GREEN}[✓]${RESET} $1"
}

warn() {
    printf '%b\n' "${YELLOW}[!]${RESET} $1"
}

error() {
    printf '%b\n' "${RED}[✗]${RESET} $1" >&2
}

fatal() {
    error "$1"
    exit 1
}

cleanup() {
    local exit_code=$?

    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi

    if (( exit_code != 0 )) && (( PROFILE_CREATED == 1 )); then
        warn "Installation failed after profile creation."
        warn "The Osint profile may still exist at:"
        printf '    %s\n' "${PROFILE_DIR:-Unknown}"
        warn "Inspect it before attempting another installation."
    fi

    return "$exit_code"
}

trap cleanup EXIT

# =============================================================================
# BANNER
# =============================================================================

banner() {
    clear 2>/dev/null || true

    printf '%b\n' "${CYAN}"
    cat <<'EOF'
   _____                 __ _      _______                 _
  |  ___| __ ___  ___ __/ _| |_   |  ___(_)_ __ ___  ___  / |
  | |_ | '__/ _ \/ __|  _| __| |  | |_  | | '__/ _ \/ _ \ | |
  |  _|| | | (_) \__ \ | | |_| |  |  _| | | | |  __/  __/ | |
  |_|  |_|  \___/|___/_|  \__|_|  |_|   |_|_|  \___|\___| |_|

                  FRESH FORENSICS
                 OSINT PROFILE SETUP
EOF
    printf '%b\n' "${RESET}"

    printf '\n'
    printf '%b\n' "${BOLD}${WHITE}  Automate your OSINT browser setup.${RESET}"
    printf '\n'
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

check_dependencies() {
    section "DEPENDENCY CHECK"

    local missing=()

    if command -v curl >/dev/null 2>&1; then
        :
    elif command -v wget >/dev/null 2>&1; then
        :
    else
        missing+=("curl or wget")
    fi

    for cmd in unzip awk cp find mktemp; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        error "Missing required dependencies:"

        printf '    %s\n' "${missing[@]}"

        fatal "Install the missing dependencies and run the script again."
    fi

    success "Required utilities are available."
}

# =============================================================================
# FIREFOX DETECTION
# =============================================================================

find_firefox() {
    section "FIREFOX DETECTION"

    if command -v firefox >/dev/null 2>&1; then
        FIREFOX_BIN="$(command -v firefox)"

    elif command -v firefox-esr >/dev/null 2>&1; then
        FIREFOX_BIN="$(command -v firefox-esr)"

    elif command -v flatpak >/dev/null 2>&1 &&
         flatpak info org.mozilla.firefox >/dev/null 2>&1; then

        FIREFOX_BIN="flatpak"

    else
        fatal "Firefox was not found. Install Firefox before continuing."
    fi

    success "Firefox launcher detected: $FIREFOX_BIN"

    if [[ "$FIREFOX_BIN" == "flatpak" ]]; then
        warn "Flatpak requires a separate profile path check."
        fatal "This version of the installer requires additional Flatpak profile handling."
    fi
}

# =============================================================================
# PROFILE CONFIGURATION DISCOVERY
# =============================================================================

find_profiles_ini() {
    local candidates=(
        "$HOME/.mozilla/firefox/profiles.ini"
        "$HOME/.config/mozilla/firefox/profiles.ini"
        "$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini"
        "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox/profiles.ini"
    )

    local candidate

    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            PROFILES_INI="$candidate"
            return 0
        fi
    done

    return 1
}

get_profile_path() {
    local profile_name="$1"
    local ini_file="$2"

    awk -v target="$profile_name" '
        /^\[Profile[0-9]+\]/ {
            if (found && path != "") {
                print path "|" relative
                exit
            }

            found = 0
            path = ""
            relative = 1
        }

        /^\[Install/ {
            found = 0
        }

        /^Name=/ {
            if (substr($0, 6) == target) {
                found = 1
            }
        }

        /^Path=/ {
            path = substr($0, 6)
        }

        /^IsRelative=/ {
            relative = substr($0, 12)
        }

        END {
            if (found && path != "") {
                print path "|" relative
            }
        }
    ' "$ini_file" | head -n 1
}

resolve_profile_path() {
    local profile_entry="$1"
    local base_dir

    local relative_path
    local is_relative

    relative_path="${profile_entry%|*}"
    is_relative="${profile_entry##*|}"

    base_dir="$(dirname "$PROFILES_INI")"

    if [[ "$is_relative" == "1" ]]; then
        PROFILE_DIR="$base_dir/$relative_path"
    else
        PROFILE_DIR="$relative_path"
    fi
}

# =============================================================================
# PROFILE CREATION
# =============================================================================

create_profile() {
    section "PROFILE CREATION"

    if ! find_profiles_ini; then
        fatal "Could not locate an existing Firefox profiles.ini file."
    fi

    info "Profile configuration: $PROFILES_INI"

    local existing_profile

    existing_profile="$(get_profile_path "$PROFILE_NAME" "$PROFILES_INI" || true)"

    if [[ -n "$existing_profile" ]]; then
        fatal "A profile named '$PROFILE_NAME' already exists. No changes were made."
    fi

    info "Creating Firefox profile: $PROFILE_NAME"

    if ! "$FIREFOX_BIN" -CreateProfile "$PROFILE_NAME"; then
        fatal "Firefox could not create the requested profile."
    fi

    PROFILE_CREATED=1

    # Firefox may update profiles.ini during profile creation.
    if ! find_profiles_ini; then
        fatal "Firefox created a profile, but profiles.ini could not be located."
    fi

    local profile_entry

    profile_entry="$(get_profile_path "$PROFILE_NAME" "$PROFILES_INI" || true)"

    if [[ -z "$profile_entry" ]]; then
        fatal "Firefox did not register the new profile as expected."
    fi

    resolve_profile_path "$profile_entry"

    if [[ ! -d "$PROFILE_DIR" ]]; then
        fatal "The registered profile directory does not exist."
    fi

    success "Firefox profile registered successfully."
    info "Profile directory: $PROFILE_DIR"
}

# =============================================================================
# TEMPLATE DOWNLOAD
# =============================================================================

download_template() {
    section "TEMPLATE DOWNLOAD"

    TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/osint-firefox.XXXXXX")"

    local archive="$TEMP_DIR/ff-template.zip"

    info "Downloading OSINT Firefox template..."

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL --retry 2 --connect-timeout 15 \
            "$TEMPLATE_URL" -o "$archive"; then
            fatal "Template download failed. Check the repository URL."
        fi
    else
        if ! wget -O "$archive" "$TEMPLATE_URL"; then
            fatal "Template download failed. Check the repository URL."
        fi
    fi

    if [[ ! -s "$archive" ]]; then
        fatal "The downloaded archive is empty."
    fi

    if ! unzip -tq "$archive" >/dev/null 2>&1; then
        fatal "The downloaded file is not a valid ZIP archive."
    fi

    success "Template downloaded and verified."
}

# =============================================================================
# TEMPLATE EXTRACTION
# =============================================================================

install_template() {
    section "TEMPLATE INSTALLATION"

    local archive="$TEMP_DIR/ff-template.zip"
    local extract_dir="$TEMP_DIR/extracted"
    local source_dir

    mkdir -p "$extract_dir"

    info "Extracting template..."

    if ! unzip -q "$archive" -d "$extract_dir"; then
        fatal "Could not extract the template archive."
    fi

    # If the archive contains one enclosing directory, use its contents.
    local -a entries=("$extract_dir"/* "$extract_dir"/.[!.]*)

    local entry
    local count=0
    local only_entry=""

    for entry in "${entries[@]}"; do
        [[ -e "$entry" ]] || continue

        ((count += 1))
        only_entry="$entry"
    done

    if (( count == 1 )) && [[ -d "$only_entry" ]]; then
        source_dir="$only_entry"
    else
        source_dir="$extract_dir"
    fi

    if [[ -z "$(find "$source_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
        fatal "The template archive contains no files."
    fi

    info "Copying template files into the Osint profile..."

    cp -a "$source_dir"/. "$PROFILE_DIR"/

    success "OSINT template installed successfully."
}

# =============================================================================
# LAUNCH PROMPT
# =============================================================================

launch_profile() {
    section "INSTALLATION COMPLETE"

    printf '\n'

    success "Your OSINT Firefox profile is ready."
    printf '\n'

    printf '%b\n' "${CYAN}Profile name:${RESET}      $PROFILE_NAME"
    printf '%b\n' "${CYAN}Profile directory:${RESET} $PROFILE_DIR"

    printf '\n'

    printf '%b' "${YELLOW}Would you like to launch the Osint profile now? [y/N]: ${RESET}"

    local answer
    read -r answer || answer="n"

    case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            info "Launching Firefox with the Osint profile..."

            "$FIREFOX_BIN" --no-remote -P "$PROFILE_NAME" \
                >/dev/null 2>&1 &

            success "Firefox launch requested."
            ;;

        *)
            info "You can launch the profile later using:"
            printf '\n'
            printf '%b\n' "${GREEN}firefox --no-remote -P Osint${RESET}"
            ;;
    esac

    printf '\n'
    line

    printf '%b\n' "${BOLD}${GREEN}  FRESH FORENSICS | OSINT READY${RESET}"

    line
    printf '\n'
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    banner

    check_dependencies
    find_firefox
    create_profile
    download_template
    install_template
    launch_profile
}

main "$@"
