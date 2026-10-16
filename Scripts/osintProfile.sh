#!/usr/bin/env bash

# =============================================================================
# Fresh Forensics
# OSINT Firefox Profile Installer
# =============================================================================
#
# Downloads the Fresh Forensics OSINT Firefox template from GitHub Releases,
# creates a dedicated Firefox profile named Osint, installs the template,
# and optionally launches Firefox.
#
# Usage:
#   chmod +x osint_firefox.sh
#   ./osint_firefox.sh
#
# Manual launch:
#   firefox --no-remote -P Osint
#
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_NAME="OSINT FIREFOX INSTALLER"
PROFILE_NAME="Osint"

TEMPLATE_URL="https://github.com/DouglasFreshHabian/OsintWorkshop/releases/download/v1.0.0/ff-template.zip"

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
# TERMINAL OUTPUT
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

# =============================================================================
# CLEANUP
# =============================================================================

cleanup() {
    local exit_code=$?

    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi

    if (( exit_code != 0 )) && (( PROFILE_CREATED == 1 )); then
        warn "Installation did not complete successfully."
        warn "The newly created profile may still exist."

        if [[ -n "$PROFILE_DIR" ]]; then
            printf '    Profile: %s\n' "$PROFILE_DIR"
        fi

        warn "Inspect the profile before running the installer again."
    fi

    return "$exit_code"
}

trap cleanup EXIT

# =============================================================================
# BANNER
# =============================================================================

banner() {
    printf '\033[2J\033[H' 2>/dev/null || true

    printf '%b\n' "${CYAN}"
    cat <<'EOF'
 _____ _          _____         
|  ___(_)_ __ ___|  ___|____  __
| |_  | | '__/ _ \ |_ / _ \ \/ /
|  _| | | | |  __/  _| (_) >  < 
|_|   |_|_|  \___|_|  \___/_/\_\
                                
       FRESH FORENSICS
     OSINT PROFILE SETUP
EOF
    printf '%b\n' "${RESET}"

    printf '%b\n' "${BOLD}${WHITE}Automate your OSINT browser setup.${RESET}"
    printf '\n'
}

# =============================================================================
# DEPENDENCIES
# =============================================================================

check_dependencies() {
    section "DEPENDENCY CHECK"

    local missing=()
    local cmd

    for cmd in awk cp find mktemp head; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if ! command -v curl >/dev/null 2>&1 &&
       ! command -v wget >/dev/null 2>&1; then
        missing+=("curl or wget")
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        missing+=("unzip")
    fi

    if (( ${#missing[@]} > 0 )); then
        error "Missing required dependencies:"
        printf '    %s\n' "${missing[@]}"
        fatal "Install the missing dependencies and try again."
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

    else
        fatal "Firefox was not found. Install Firefox before continuing."
    fi

    success "Firefox launcher detected."
    info "Launcher: $FIREFOX_BIN"
}

# =============================================================================
# PROFILE CONFIGURATION DISCOVERY
# =============================================================================

find_profiles_ini() {
    local candidate

    local -a candidates=(
        "$HOME/.config/mozilla/firefox/profiles.ini"
        "$HOME/.mozilla/firefox/profiles.ini"
        "$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini"
        "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox/profiles.ini"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            PROFILES_INI="$candidate"
            return 0
        fi
    done

    return 1
}

# =============================================================================
# PROFILE LOOKUP
# =============================================================================

get_profile_path() {
    local profile_name="$1"
    local ini_file="$2"

    awk -v target="$profile_name" '
        /^\[/ {
            section = $0
            next
        }

        section ~ /^\[Profile[0-9]+\]$/ && /^Name=/ {
            names[section] = substr($0, 6)
        }

        section ~ /^\[Profile[0-9]+\]$/ && /^Path=/ {
            paths[section] = substr($0, 6)
        }

        section ~ /^\[Profile[0-9]+\]$/ && /^IsRelative=/ {
            relative[section] = substr($0, 12)
        }

        END {
            for (s in names) {
                if (names[s] == target && paths[s] != "") {
                    r = relative[s]

                    if (r == "") {
                        r = "1"
                    }

                    print paths[s] "|" r
                    exit
                }
            }
        }
    ' "$ini_file"
}

resolve_profile_path() {
    local profile_entry="$1"
    local relative_path
    local is_relative
    local base_dir

    relative_path="${profile_entry%|*}"
    is_relative="${profile_entry##*|}"

    if [[ "$is_relative" == "1" ]]; then
        base_dir="$(dirname "$PROFILES_INI")"
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

    local profile_entry=""
    local create_log="$TEMP_DIR/profile-creation.log"

    if find_profiles_ini; then
        info "Profile configuration: $PROFILES_INI"

        profile_entry="$(get_profile_path "$PROFILE_NAME" "$PROFILES_INI")"

        if [[ -n "$profile_entry" ]]; then
            fatal "A profile named '$PROFILE_NAME' already exists. Remove it before continuing."
        fi
    else
        info "No existing profiles.ini found. Firefox will initialize its profile configuration."
    fi

    info "Creating Firefox profile: $PROFILE_NAME"

    # Firefox can emit sandbox warnings even when profile creation succeeds.
    # Capture the output and verify registration rather than trusting the
    # command's exit status alone.

    "$FIREFOX_BIN" -CreateProfile "$PROFILE_NAME" \
        >"$create_log" 2>&1 || true

    # Firefox may create profiles.ini in a different supported location.
    if ! find_profiles_ini; then
        if [[ -s "$create_log" ]]; then
            warn "Firefox profile creation output:"
            cat "$create_log"
        fi

        fatal "Could not locate profiles.ini after profile creation."
    fi

    profile_entry="$(get_profile_path "$PROFILE_NAME" "$PROFILES_INI")"

    if [[ -z "$profile_entry" ]]; then
        if [[ -s "$create_log" ]]; then
            warn "Firefox profile creation output:"
            cat "$create_log"
        fi

        fatal "Firefox did not register the Osint profile."
    fi

    resolve_profile_path "$profile_entry"

    if [[ ! -d "$PROFILE_DIR" ]]; then
        fatal "The registered profile directory does not exist: $PROFILE_DIR"
    fi

    PROFILE_CREATED=1

    success "Firefox profile registered successfully."
    info "Profile configuration: $PROFILES_INI"
    info "Profile directory: $PROFILE_DIR"
}

# =============================================================================
# TEMPLATE DOWNLOAD
# =============================================================================

download_template() {
    section "TEMPLATE DOWNLOAD"

    local archive="$TEMP_DIR/ff-template.zip"

    info "Downloading the Fresh Forensics OSINT template..."
    info "Source: GitHub Releases"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL --retry 2 --connect-timeout 15 \
            "$TEMPLATE_URL" -o "$archive"; then
            fatal "Template download failed. Check the release URL."
        fi
    else
        if ! wget -O "$archive" "$TEMPLATE_URL"; then
            fatal "Template download failed. Check the release URL."
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
    local entry
    local count=0
    local only_entry=""

    mkdir -p "$extract_dir"

    info "Extracting template..."

    if ! unzip -q "$archive" -d "$extract_dir"; then
        fatal "Could not extract the template archive."
    fi

    # Handle archives that contain a single enclosing directory.

    shopt -s dotglob nullglob
    local -a entries=("$extract_dir"/*)
    shopt -u dotglob nullglob

    for entry in "${entries[@]}"; do
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

    info "Installing template into the Osint profile..."

    if ! cp -a "$source_dir"/. "$PROFILE_DIR"/; then
        fatal "Failed to copy template files into the profile."
    fi

    success "Template files installed."
}

# =============================================================================
# LAUNCH PROFILE
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
            info "Launching Firefox..."

            if "$FIREFOX_BIN" --no-remote -P "$PROFILE_NAME" \
                >/dev/null 2>&1 & then
                success "Firefox launch requested."
            else
                warn "Could not start Firefox automatically."
                info "Launch it manually with:"
                printf '    firefox --no-remote -P Osint\n'
            fi
            ;;

        *)
            info "You can launch the profile later with:"
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

    TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/osint-firefox.XXXXXX")"

    find_firefox
    create_profile
    download_template
    install_template
    launch_profile
}

main "$@"
