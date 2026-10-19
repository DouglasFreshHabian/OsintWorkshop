#!/usr/bin/env bash
#
# F.B.I. - Forensic Browser & Investigator
# Search and analyze YouTube comment-downloader JSON/JSONL archives.
#
# Requirements: bash, jq, coreutils, grep (standard on most Linux systems)
#
set -uo pipefail

# ------------------------------
# Configuration
# ------------------------------
COMMENTS_DIR="${COMMENTS_DIR:-youtube-comments/comments}"
EXPORT_DIR="${EXPORT_DIR:-fbi-reports}"

# ------------------------------
# Terminal colors
# ------------------------------
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
warn()    { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"; }
error()   { printf '%s[-]%s %s\n' "$RED" "$RESET" "$*" >&2; }
pause()   { printf '\n'; read -r -p "Press Enter to return to the menu..." _ || true; }
rule()    { printf '%s%s%s\n' "$GRAY" '============================================================' "$RESET"; }

banner() {
    printf '%s%s' "$RED" "$BOLD"
    cat <<'BANNER'
        ███████╗██████╗ ██╗
        ██╔════╝██╔══██╗██║
        █████╗  ██████╔╝██║
        ██╔══╝  ██╔══██╗██║
        ██║     ██████╔╝██║
        ╚═╝     ╚═════╝ ╚═╝
BANNER
    printf '%s%sF.B.I. — Forensic Behavorial Intelligence%s\n' "$WHITE" "$BOLD" "$RESET"
    printf '%sSearch, correlate, and export YouTube comment archives%s\n\n' "$GRAY" "$RESET"
    printf '%sComments directory:%s %s\n' "$CYAN" "$RESET" "$COMMENTS_DIR"
    rule
}

check_dependencies() {
    local missing=0
    for cmd in jq find sort uniq awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd"
            missing=1
        fi
    done
    if (( missing )); then
        error "Install jq and standard command-line utilities, then run F.B.I. again."
        exit 1
    fi
}

# Print discovered JSON/JSONL files, one per line.
list_files() {
    [[ -d "$COMMENTS_DIR" ]] || return 0
    find "$COMMENTS_DIR" -maxdepth 1 -type f \( -iname '*.json' -o -iname '*.jsonl' \) -print 2>/dev/null | sort
}

file_count() {
    list_files | awk 'END { print NR+0 }'
}

# Stream comment objects from either JSON Lines files or JSON arrays.
# The common youtube-comment-downloader output is JSONL (one object per line).
stream_comments() {
    local file
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        jq -c 'if type == "array" then .[] else . end' "$file" 2>/dev/null |
        jq -c --arg video "$(basename "$file" | sed -E 's/\.jsonl?$//I')" \
            '{video_id:$video, comment:.}'
    done < <(list_files)
}

need_files() {
    if [[ ! -d "$COMMENTS_DIR" ]]; then
        error "Comments directory does not exist: $COMMENTS_DIR"
        printf 'Set COMMENTS_DIR or place your downloaded files in that directory.\n'
        return 1
    fi
    local count
    count=$(file_count)
    if [[ "$count" -eq 0 ]]; then
        error "No .json or .jsonl files found in: $COMMENTS_DIR"
        return 1
    fi
    return 0
}

read_nonempty() {
    local prompt="$1" value
    while true; do
        read -r -p "$prompt" value || return 1
        if [[ -n "$value" ]]; then
            printf '%s' "$value"
            return 0
        fi
        warn "Please enter a value."
    done
}

search_keyword() {
    local term
    term=$(read_nonempty "Keyword or phrase (literal text): ") || return
    printf '\n'
    stream_comments | jq -r --arg q "${term,,}" '
        select(((.comment.text // "") | ascii_downcase | contains($q)))
        | "[\(.video_id)] \(.comment.author // "Unknown author") | \(.comment.time // "Unknown time")\n  \(.comment.text // "")\n"
    '
    pause
}

search_author() {
    local author
    author=$(read_nonempty "Author handle or displayed name: ") || return
    printf '\n'
    stream_comments | jq -r --arg q "${author,,}" '
        select(
            ((.comment.author // "") | ascii_downcase | contains($q))
            or ((.comment.channel // "") | ascii_downcase | contains($q))
        )
        | "[\(.video_id)] \(.comment.author // "Unknown author") [channel: \(.comment.channel // "unknown")]\n  \(.comment.time // "Unknown time") | \(.comment.text // "")\n"
    '
    pause
}

top_commenters() {
    local limit
    read -r -p "How many rows to show? [20] " limit || true
    limit="${limit:-20}"
    if [[ ! "$limit" =~ ^[0-9]+$ ]] || (( limit < 1 )); then
        warn "Enter a positive whole number."
        pause
        return
    fi
    printf '\n%s\n' "Comment count | Author | Channel ID"
    stream_comments | jq -r '[.comment.author // "Unknown", .comment.channel // "unknown"] | @tsv' |
        sort -f | uniq -ci | sort -rn | head -n "$limit"
    pause
}

find_urls() {
    printf '\n'
    stream_comments | jq -r '
        (.comment.text // "") as $text
        | select($text | test("https?://|www\\."; "i"))
        | "[\(.video_id)] \(.comment.author // "Unknown author") | \($text)"
    '
    pause
}

export_csv() {
    mkdir -p "$EXPORT_DIR" || { error "Cannot create export directory: $EXPORT_DIR"; pause; return; }
    local timestamp outfile
    timestamp=$(date '+%Y%m%d_%H%M%S')
    outfile="$EXPORT_DIR/comments_${timestamp}.csv"
    {
        printf '"video_id","cid","author","channel","time","time_parsed","votes","replies","heart","reply","text"\n'
        stream_comments | jq -r '
            [
              .video_id,
              (.comment.cid // ""),
              (.comment.author // ""),
              (.comment.channel // ""),
              (.comment.time // ""),
              (.comment.time_parsed // ""),
              (.comment.votes // ""),
              (.comment.replies // ""),
              (.comment.heart // false),
              (.comment.reply // false),
              (.comment.text // "")
            ] | @csv
        '
    } > "$outfile"
    success "CSV exported to: $outfile"
    pause
}

export_keyword_json() {
    local term timestamp outfile
    term=$(read_nonempty "Keyword or phrase to export: ") || return
    mkdir -p "$EXPORT_DIR" || { error "Cannot create export directory: $EXPORT_DIR"; pause; return; }
    timestamp=$(date '+%Y%m%d_%H%M%S')
    outfile="$EXPORT_DIR/keyword_matches_${timestamp}.jsonl"
    stream_comments | jq -c --arg q "${term,,}" '
        select(((.comment.text // "") | ascii_downcase | contains($q)))
    ' > "$outfile"
    success "Matching records exported to: $outfile"
    pause
}

inspect_fields() {
    local file
    file=$(list_files | head -n 1)
    if [[ -z "$file" ]]; then
        error "No comment files found."
        pause
        return
    fi
    printf '\n%s\n' "Sample file: $file"
    printf '%s\n' "First comment object:"
    jq -c 'if type == "array" then .[0] else . end' "$file" 2>/dev/null | head -n 1 | jq .
    printf '\n%s\n' "Fields present in the first record:"
    jq -r 'if type == "array" then .[0] else . end | keys[]' "$file" 2>/dev/null | sort
    pause
}

count_comments() {
    local count
    count=$(stream_comments | jq -s 'length')
    printf '\n'
    success "Comment records found: $count"
    info "Comment files found: $(file_count)"
    pause
}

date_range_search() {
    local start end
    start=$(read_nonempty "Start Unix timestamp (seconds): ") || return
    end=$(read_nonempty "End Unix timestamp (seconds): ") || return
    if [[ ! "$start" =~ ^[0-9]+([.][0-9]+)?$ || ! "$end" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        error "Enter numeric Unix timestamps in seconds."
        pause
        return
    fi
    if awk -v s="$start" -v e="$end" 'BEGIN { exit !(s <= e) }'; then :; else
        error "Start timestamp must be less than or equal to end timestamp."
        pause
        return
    fi
    printf '\n'
    stream_comments | jq -r --argjson start "$start" --argjson end "$end" '
        select((.comment.time_parsed | type) == "number")
        | select(.comment.time_parsed >= $start and .comment.time_parsed <= $end)
        | "[\(.video_id)] \(.comment.author // "Unknown author") | \(.comment.time_parsed)\n  \(.comment.text // "")\n"
    '
    pause
}

main_menu() {
    while true; do
        printf '\n'
        rule
        printf '%s%s  F.B.I. MAIN MENU%s\n' "$WHITE" "$BOLD" "$RESET"
        rule
        printf '  %s1%s  Search comments by keyword or phrase\n' "$GREEN" "$RESET"
        printf '  %s2%s  Search by author name or channel ID\n' "$GREEN" "$RESET"
        printf '  %s3%s  Rank frequent commenters\n' "$GREEN" "$RESET"
        printf '  %s4%s  Find comments containing URLs\n' "$GREEN" "$RESET"
        printf '  %s5%s  Export all comments to CSV\n' "$GREEN" "$RESET"
        printf '  %s6%s  Export keyword matches to JSONL\n' "$GREEN" "$RESET"
        printf '  %s7%s  Search by Unix timestamp range\n' "$GREEN" "$RESET"
        printf '  %s8%s  Inspect sample JSON fields\n' "$GREEN" "$RESET"
        printf '  %s9%s  Count comments and files\n' "$GREEN" "$RESET"
        printf '  %s0%s  Exit\n\n' "$RED" "$RESET"

        read -r -p "F.B.I. > " choice || break
        case "$choice" in
            1) search_keyword ;;
            2) search_author ;;
            3) top_commenters ;;
            4) find_urls ;;
            5) export_csv ;;
            6) export_keyword_json ;;
            7) date_range_search ;;
            8) inspect_fields ;;
            9) count_comments ;;
            0) printf '%sGoodbye. Follow the breadcrumbs.%s\n' "$CYAN" "$RESET"; break ;;
            *) warn "Invalid selection." ;;
        esac
    done
}

check_dependencies
banner
if ! need_files; then
    printf '\nExample: COMMENTS_DIR="/path/to/comments" ./F.B.I.sh\n'
    exit 1
fi
main_menu
