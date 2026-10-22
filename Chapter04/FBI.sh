#!/usr/bin/env bash
#
# F.B.I. - Forensic Behavioral Intelligence
# Search, inspect, and export YouTube comment archives.
#
# Requirements: Bash 4+, jq, find, sort, uniq, awk, date, base64
#
# Usage:
#   ./FBI.sh
#   ./FBI.sh /path/to/comments
#   COMMENTS_DIR=/path/to/comments ./FBI.sh
#
# Supported input: JSON arrays and JSONL files.
# Video IDs are derived from filenames, with extensions removed.
#

set -uo pipefail

# --------------------------------------------------
# Configuration
# --------------------------------------------------
COMMENTS_DIR="${1:-${COMMENTS_DIR:-TheSlimyShow/comments}}"
# If EXPORT_DIR is not explicitly set, reports go beside the comments directory.
EXPORT_DIR="${EXPORT_DIR:-}"

if [[ $# -gt 1 ]]; then
    printf 'Usage: %s [COMMENTS_DIRECTORY]\n' "$0" >&2
    exit 2
fi

# --------------------------------------------------
# Terminal colors
# --------------------------------------------------
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
    RED='' GREEN='' YELLOW='' BLUE='' CYAN=''
    MAGENTA='' WHITE='' GRAY='' BOLD='' RESET=''
fi

info()    { printf '%s[*]%s %s\n' "$CYAN" "$RESET" "$*"; }
success() { printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()    { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"; }
error()   { printf '%s[-]%s %s\n' "$RED" "$RESET" "$*" >&2; }
rule()    { printf '%s%s%s\n' "$GRAY" '============================================================' "$RESET"; }

pause() {
    printf '\n'
    read -r -p "Press Enter to return to the menu..." _ || true
}

# --------------------------------------------------
# Temporary results
# --------------------------------------------------
RESULT_FILE=""

cleanup() {
    if [[ -n "$RESULT_FILE" ]]; then
        rm -f -- "$RESULT_FILE"
    fi
}

trap cleanup EXIT

new_result_file() {
    if [[ -n "$RESULT_FILE" ]]; then
        rm -f -- "$RESULT_FILE"
    fi

    RESULT_FILE=$(mktemp "${TMPDIR:-/tmp}/fbi-results.XXXXXX") || {
        error "Unable to create temporary results file."
        RESULT_FILE=""
        return 1
    }
}

# --------------------------------------------------
# Banner and dependencies
# --------------------------------------------------
banner() {
    printf '%s%s' "$RED" "$BOLD"
    cat <<'BANNER'
        ███████╗██████╗ ██╗
        ██╔════ ██╔══██╗██║
        █████╗  ██████╔╝██║
        ██╔══╝  ██╔══██╗██║
        ██║     ██████╔╝██║
        ╚═╝     ╚═════╝ ╚═╝
BANNER
    printf '%s%sF.B.I. — Forensic Behavioral Intelligence%s\n' \
        "$WHITE" "$BOLD" "$RESET"
    printf '%sSearch, correlate, and export YouTube comment archives%s\n\n' \
        "$GRAY" "$RESET"
    printf '%sComments directory:%s %s\n' "$CYAN" "$RESET" "$COMMENTS_DIR"
    printf '%sExport directory:%s   %s\n' "$CYAN" "$RESET" "$EXPORT_DIR"
    rule
}

check_dependencies() {
    local missing=0 cmd

    for cmd in jq find sort uniq awk date base64; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd"
            missing=1
        fi
    done

    if (( missing )); then
        error "Install the missing dependencies and run FBI.sh again."
        exit 1
    fi
}

# --------------------------------------------------
# Input files and comment streaming
# --------------------------------------------------
list_files() {
    [[ -d "$COMMENTS_DIR" ]] || return 0

    find "$COMMENTS_DIR" -maxdepth 1 -type f \
        \( -iname '*.json' -o -iname '*.jsonl' \) \
        -print 2>/dev/null | sort
}

file_count() {
    list_files | awk 'END { print NR+0 }'
}

# Each output record has:
# {"video_id":"...","comment":{...original fields...}}
#
# The filename, minus its extension, is the video ID.
stream_comments() {
    local file video_id

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue

        video_id=$(basename "$file")
        video_id="${video_id%.*}"

        jq -c --arg video "$video_id" '
            if type == "array" then .[] else . end
            | select(type == "object")
            | {video_id: $video, comment: .}
        ' "$file" 2>/dev/null || true

    done < <(list_files)
}

need_files() {
    if [[ ! -d "$COMMENTS_DIR" ]]; then
        error "Comments directory does not exist: $COMMENTS_DIR"
        printf 'Usage: %s /path/to/comments\n' "$0"
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

# --------------------------------------------------
# Colorized display
# --------------------------------------------------
display_results() {
    local encoded record video author channel time text

    if [[ ! -s "$RESULT_FILE" ]]; then
        warn "No matching records found."
        return
    fi

    while IFS= read -r encoded; do
        [[ -n "$encoded" ]] || continue

        record=$(printf '%s' "$encoded" | base64 --decode 2>/dev/null) ||
            continue

        video=$(jq -r '.video_id // "Unknown video"' <<< "$record")
        author=$(jq -r '.comment.author // "Unknown author"' <<< "$record")
        channel=$(jq -r '.comment.channel // "Unknown channel"' <<< "$record")
        time=$(jq -r '.comment.time // "Unknown time"' <<< "$record")
        text=$(jq -r '.comment.text // ""' <<< "$record")

        printf '%s[%s]%s ' "$BLUE" "$video" "$RESET"
        printf '%s%s%s ' "$GREEN" "$author" "$RESET"
        printf '%s[channel: %s]%s\n' "$GRAY" "$channel" "$RESET"
        printf '  %sTime:%s %s\n' "$CYAN" "$RESET" "$time"
        printf '  %s%s%s\n\n' "$WHITE" "$text" "$RESET"

    done < <(jq -r '@base64' "$RESULT_FILE")
}

# --------------------------------------------------
# Reusable result export
# --------------------------------------------------
export_results() {
    local format timestamp outfile

    [[ -s "$RESULT_FILE" ]] || return 0

    printf '\n'
    read -r -p "Export these results? [y/N] " answer || return

    case "${answer,,}" in
        y|yes) ;;
        *) return ;;
    esac

    printf '\n'
    printf '  1) JSONL\n'
    printf '  2) CSV\n'
    printf '  3) TXT\n'

    read -r -p "Export format: " format || return

    case "$format" in
        1|jsonl) format="jsonl" ;;
        2|csv)   format="csv" ;;
        3|txt)   format="txt" ;;
        *)
            warn "Invalid export format."
            return
            ;;
    esac

    mkdir -p "$EXPORT_DIR" || {
        error "Cannot create export directory: $EXPORT_DIR"
        return
    }

    timestamp=$(date '+%Y%m%d_%H%M%S')
    outfile="$EXPORT_DIR/results_${timestamp}.${format}"

    case "$format" in
        jsonl)
            cp -- "$RESULT_FILE" "$outfile" || {
                error "Export failed."
                return
            }
            ;;

        csv)
            {
                printf '"video_id","cid","author","channel","time",'
                printf '"time_parsed","votes","replies","heart","reply","text"\n'

                jq -r '
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
                ' "$RESULT_FILE"
            } > "$outfile" || {
                error "CSV export failed."
                return
            }
            ;;

        txt)
            jq -r '
                "[\(.video_id)] \(.comment.author // "Unknown author")",
                "Channel: \(.comment.channel // "Unknown channel")",
                "Time: \(.comment.time // "Unknown time")",
                (.comment.text // ""),
                ""
            ' "$RESULT_FILE" > "$outfile" || {
                error "TXT export failed."
                return
            }
            ;;
    esac

    success "Results exported: $outfile"
}

finish_results() {
    local count
    count=$(jq -s 'length' "$RESULT_FILE" 2>/dev/null) || count=0

    printf '\n'
    info "Matching records: $count"
    display_results
    export_results
    pause
}

# --------------------------------------------------
# 1. Keyword or phrase search
# --------------------------------------------------
search_keyword() {
    local term

    term=$(read_nonempty "Keyword or phrase: ") || return
    new_result_file || return

    stream_comments |
        jq -c --arg q "${term,,}" '
            select(
                ((.comment.text // "") | ascii_downcase | contains($q))
            )
        ' > "$RESULT_FILE"

    finish_results
}

# --------------------------------------------------
# 2. Author or channel search
# --------------------------------------------------
search_author() {
    local author

    author=$(read_nonempty "Author name or channel ID: ") || return
    new_result_file || return

    stream_comments |
        jq -c --arg q "${author,,}" '
            select(
                ((.comment.author // "") | ascii_downcase | contains($q))
                or
                ((.comment.channel // "") | ascii_downcase | contains($q))
            )
        ' > "$RESULT_FILE"

    finish_results
}

# --------------------------------------------------
# 3. Rank frequent commenters
# --------------------------------------------------
top_commenters() {
    local limit

    read -r -p "How many rows to show? [20] " limit || return
    limit="${limit:-20}"

    if [[ ! "$limit" =~ ^[0-9]+$ ]] || (( limit < 1 )); then
        warn "Enter a positive whole number."
        pause
        return
    fi

    printf '\n'
    printf '%sComment count | Author | Channel ID%s\n' "$BOLD" "$RESET"

    stream_comments |
        jq -r '[
            (.comment.author // "Unknown"),
            (.comment.channel // "unknown")
        ] | @tsv' |
        sort -f |
        uniq -ci |
        sort -rn |
        head -n "$limit" |
        awk -v g="$GREEN" -v c="$CYAN" -v r="$RESET" '
            {
                count=$1
                $1=""
                sub(/^[[:space:]]+/, "")
                printf "%s%s%s | %s\n", g, count, r, $0
            }
        '

    pause
}

# --------------------------------------------------
# 4. Extract comments containing URLs
# --------------------------------------------------
find_urls() {
    new_result_file || return

    stream_comments |
        jq -c '
            select(
                ((.comment.text // "") | test("https?://|www\\."; "i"))
            )
        ' > "$RESULT_FILE"

    finish_results
}

# --------------------------------------------------
# 5. Export all comments
# --------------------------------------------------
export_all_comments() {
    new_result_file || return

    stream_comments > "$RESULT_FILE"

    if [[ ! -s "$RESULT_FILE" ]]; then
        warn "No readable comment records found."
        pause
        return
    fi

    info "All readable comment records are ready for export."
    export_results
    pause
}

# --------------------------------------------------
# 6. Export keyword matches
# --------------------------------------------------
export_keyword_json() {
    local term

    term=$(read_nonempty "Keyword or phrase to export: ") || return
    new_result_file || return

    stream_comments |
        jq -c --arg q "${term,,}" '
            select(
                ((.comment.text // "") | ascii_downcase | contains($q))
            )
        ' > "$RESULT_FILE"

    if [[ ! -s "$RESULT_FILE" ]]; then
        warn "No matching records found."
        pause
        return
    fi

    info "Matching records are ready for export."
    export_results
    pause
}

# --------------------------------------------------
# 7. Search by readable date range
# --------------------------------------------------

date_range_search() {
    local start end start_ts end_exclusive end_ts

    start=$(read_nonempty "Start date (YYYY-MM-DD): ") || return
    end=$(read_nonempty "End date   (YYYY-MM-DD): ") || return

    if [[ ! "$start" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
       [[ ! "$end" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        error "Dates must use YYYY-MM-DD format (example: 2026-09-01)."
        pause
        return
    fi

    # Validate calendar dates using the original input strings.
    start_ts=$(date -d "$start" '+%s' 2>/dev/null) || {
        error "Invalid start date: $start"
        pause
        return
    }

    end_ts=$(date -d "$end" '+%s' 2>/dev/null) || {
        error "Invalid end date: $end"
        pause
        return
    }

    if [[ "$(date -d "$start" '+%Y-%m-%d')" != "$start" ]]; then
        error "Invalid start date: $start"
        pause
        return
    fi

    if [[ "$(date -d "$end" '+%Y-%m-%d')" != "$end" ]]; then
        error "Invalid end date: $end"
        pause
        return
    fi

    # Reject reversed ranges.
    if (( start_ts > end_ts )); then
        error "Start date must not be after end date."
        pause
        return
    fi

    # Include the entire end date.
    end_exclusive=$(date -d "$end + 1 day" '+%s' 2>/dev/null) || {
        error "Unable to calculate the end date."
        pause
        return
    }

    new_result_file || return

    stream_comments |
        jq -c --argjson start "$start_ts" \
              --argjson end "$end_exclusive" '
            (
                .comment.time_parsed
                | if type == "number" then .
                  elif type == "string" then (tonumber? // null)
                  else null
                  end
            ) as $ts
            | select($ts != null)
            | select($ts >= $start and $ts < $end)
        ' > "$RESULT_FILE"

    finish_results
}

# --------------------------------------------------
# 8. Archive inspector
# --------------------------------------------------
inspect_fields() {
    local total_files valid_files invalid_files total_records
    local sample

    total_files=$(file_count)
    valid_files=0
    invalid_files=0

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue

        if jq -e . "$file" >/dev/null 2>&1; then
            ((valid_files += 1))
        else
            ((invalid_files += 1))
        fi
    done < <(list_files)

    total_records=$(stream_comments | jq -s 'length')

    printf '\n'
    rule
    printf '%s%s ARCHIVE INSPECTOR%s\n' "$WHITE" "$BOLD" "$RESET"
    rule

    printf '%sComments directory:%s %s\n' "$CYAN" "$RESET" "$COMMENTS_DIR"
    printf '%sFiles discovered:%s   %s\n' "$CYAN" "$RESET" "$total_files"
    printf '%sValid files:%s        %s\n' "$GREEN" "$RESET" "$valid_files"
    printf '%sFiles with errors:%s  %s\n' "$YELLOW" "$RESET" "$invalid_files"
    printf '%sReadable records:%s   %s\n' "$CYAN" "$RESET" "$total_records"

    printf '\n%sFields found across readable records:%s\n' "$BOLD" "$RESET"

    stream_comments |
        jq -r '.comment | keys[]?' |
        sort -u |
        while IFS= read -r field; do
            printf '  %s•%s %s\n' "$BLUE" "$RESET" "$field"
        done

    printf '\n%sExpected-field coverage:%s\n' "$BOLD" "$RESET"

    stream_comments |
        jq -s '
            {
                total: length,
                author: ([.[] | select(.comment.author != null)] | length),
                channel: ([.[] | select(.comment.channel != null)] | length),
                text: ([.[] | select(.comment.text != null)] | length),
                time: ([.[] | select(.comment.time_parsed != null)] | length),
                cid: ([.[] | select(.comment.cid != null)] | length)
            }
        ' |
        jq -r '
            "  Author:     \(.author)/\(.total)",
            "  Channel:    \(.channel)/\(.total)",
            "  Text:       \(.text)/\(.total)",
            "  Timestamp:  \(.time)/\(.total)",
            "  Comment ID: \(.cid)/\(.total)"
        ' |
        while IFS= read -r line; do
            printf '  %s\n' "$line"
        done

    sample=$(stream_comments | head -n 1)

    if [[ -n "$sample" ]]; then
        printf '\n%sSample comment:%s\n' "$BOLD" "$RESET"
        jq '.' <<< "$sample"
    fi

    if (( invalid_files > 0 )); then
        printf '\n'
        warn "Some files failed JSON validation."
        warn "JSONL files may contain valid records alongside malformed lines."
        warn "Inspect the affected files before relying on complete results."
    fi

    pause
}

# --------------------------------------------------
# 9. Count records and files
# --------------------------------------------------
count_comments() {
    local count files

    count=$(stream_comments | jq -s 'length')
    files=$(file_count)

    printf '\n'
    success "Readable comment records: $count"
    info "Comment files discovered: $files"
    pause
}

# --------------------------------------------------
# 10. Combined search across multiple criteria
# --------------------------------------------------
combined_search() {
    local keyword author video start end
    local start_ts=0 end_exclusive=0 end_ts=0
    local use_start=false use_end=false

    printf '\n%sLeave a field blank to skip that filter.%s\n' "$CYAN" "$RESET"
    read -r -p "Keyword or phrase: " keyword || return
    read -r -p "Author name or channel ID: " author || return
    read -r -p "Video ID (or part of it): " video || return
    read -r -p "Start date (YYYY-MM-DD, optional): " start || return
    read -r -p "End date   (YYYY-MM-DD, optional): " end || return

    if [[ -z "$keyword" && -z "$author" && -z "$video" && -z "$start" && -z "$end" ]]; then
        warn "Enter at least one search criterion."
        pause
        return
    fi

    if [[ -n "$start" ]]; then
        if [[ ! "$start" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            error "Start date must use YYYY-MM-DD format."
            pause
            return
        fi
        start_ts=$(date -d "$start" '+%s' 2>/dev/null) || {
            error "Invalid start date: $start"
            pause
            return
        }
        if [[ "$(date -d "$start" '+%Y-%m-%d' 2>/dev/null)" != "$start" ]]; then
            error "Invalid start date: $start"
            pause
            return
        fi
        use_start=true
    fi

    if [[ -n "$end" ]]; then
        if [[ ! "$end" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            error "End date must use YYYY-MM-DD format."
            pause
            return
        fi
        end_ts=$(date -d "$end" '+%s' 2>/dev/null) || {
            error "Invalid end date: $end"
            pause
            return
        }
        if [[ "$(date -d "$end" '+%Y-%m-%d' 2>/dev/null)" != "$end" ]]; then
            error "Invalid end date: $end"
            pause
            return
        fi
        end_exclusive=$(date -d "$end + 1 day" '+%s' 2>/dev/null) || {
            error "Unable to calculate the end date."
            pause
            return
        }
        use_end=true
    fi

    if [[ -n "$start" && -n "$end" ]] && (( start_ts > end_ts )); then
        error "Start date must not be after end date."
        pause
        return
    fi

    new_result_file || return
    info "Applying all supplied filters..."

    stream_comments |
        jq -c \
            --arg keyword "${keyword,,}" \
            --arg author "${author,,}" \
            --arg video "${video,,}" \
            --argjson use_start "$use_start" \
            --argjson start_ts "$start_ts" \
            --argjson use_end "$use_end" \
            --argjson end_exclusive "$end_exclusive" '
            def parsed_timestamp:
                (.comment.time_parsed // null) as $raw |
                (if ($raw | type) == "number" then $raw
                 elif ($raw | type) == "string" then ($raw | tonumber? // null)
                 else null end) as $value |
                if $value == null or $value <= 0 then null
                elif $value > 100000000000 then ($value / 1000)
                else $value end;
            parsed_timestamp as $ts |
            select($keyword == "" or
                ((.comment.text // "") | ascii_downcase | contains($keyword))) |
            select($author == "" or
                ((.comment.author // "") | ascii_downcase | contains($author)) or
                ((.comment.channel // "") | ascii_downcase | contains($author))) |
            select($video == "" or
                ((.video_id // "") | ascii_downcase | contains($video))) |
            select((($use_start | not) or ($ts != null and $ts >= $start_ts)) and
                   (($use_end | not) or ($ts != null and $ts < $end_exclusive)))
        ' > "$RESULT_FILE"

    finish_results
}

# --------------------------------------------------
# Analysis Mode
# --------------------------------------------------

# --------------------------------------------------
# Phrase analysis helper
# Prints recurring two-word or three-word phrases from comment text.
# --------------------------------------------------
phrase_counts() {
    local data_file="$1" ngram_size="$2" output

    # Expand common contractions before tokenization so don't/didn't/can't
    # do not become misleading fragments such as "don t" or "didn t".
    output=$(jq -r '
        (.comment.text // "") |
        ascii_downcase |
        # Remove URLs before tokenization so domains and path components do
        # not pollute phrase rankings. Original archive text remains untouched.
        gsub("https?://[^[:space:]]+"; " ") |
        gsub("www\\.[^[:space:]]+"; " ") |
        gsub("[’‘]"; "\u0027") |
        gsub("\\bdon\\x27t\\b"; "do not") |
        gsub("\\bdoesn\\x27t\\b"; "does not") |
        gsub("\\bdidn\\x27t\\b"; "did not") |
        gsub("\\bcan\\x27t\\b"; "cannot") |
        gsub("\\bcannot\\x27t\\b"; "cannot") |
        gsub("\\bwon\\x27t\\b"; "will not") |
        gsub("\\bwouldn\\x27t\\b"; "would not") |
        gsub("\\bshouldn\\x27t\\b"; "should not") |
        gsub("\\bcouldn\\x27t\\b"; "could not") |
        gsub("\\bisn\\x27t\\b"; "is not") |
        gsub("\\baren\\x27t\\b"; "are not") |
        gsub("\\bwasn\\x27t\\b"; "was not") |
        gsub("\\bweren\\x27t\\b"; "were not") |
        gsub("\\bhaven\\x27t\\b"; "have not") |
        gsub("\\bhasn\\x27t\\b"; "has not") |
        gsub("\\bhadn\\x27t\\b"; "had not") |
        gsub("\\bi\\x27m\\b"; "i am") |
        gsub("\\byou\\x27re\\b"; "you are") |
        gsub("\\bwe\\x27re\\b"; "we are") |
        gsub("\\bthey\\x27re\\b"; "they are") |
        gsub("\\bit\\x27s\\b"; "it is") |
        gsub("\\bthat\\x27s\\b"; "that is") |
        gsub("\\bwhat\\x27s\\b"; "what is") |
        gsub("[^a-z0-9]+"; " ")
    ' "$data_file" |
        awk -v n="$ngram_size" '
            BEGIN {
                # Common conversational words, auxiliary verbs, and generic
                # engagement language. Keep technical terms such as "usb",
                # "debugging", "kali", "linux", and "forensics" searchable.
                split("a an and are am as at be been being but by can cannot could did do does doing for from had has have he her here hers him his how i if in into is it its just me more most my no not of on or our out over she so some than that the their them then there these they this those through to too up us very was we were what when where which while who why will with would you your about after again also because before both each even every few get got going good great hello hey hi how like look love make much need nice only other really same say see should since still such thank thanks thats thing things think time today together use used using video videos want well work yeah yes right appreciate please channel comments comment never people keep something anything watching watch way glad enjoyed enjoy hope thanks thank welcome subscribe subscribed following watching watched share support appreciate " , words, " ")
                for (i in words) stop[words[i]] = 1

                # The channel handle appears frequently in comments
                # and is not a useful phrase-analysis signal.
                stop["douglashabian"] = 1
                stop["tq5ck"] = 1
            }
            {
                word_count = split($0, words, /[[:space:]]+/)
                for (i = 1; i <= word_count - n + 1; i++) {
                    phrase = words[i]
                    # Custom channel emoji names contain "tux". Preserve them
                    # even when a matching token would otherwise be filtered.
                    meaningful = (!stop[words[i]] || index(words[i], "tux") > 0)
                    valid = (words[i] != "")
                    for (j = 1; j < n; j++) {
                        next_word = words[i + j]
                        if (next_word == "") valid = 0
                        phrase = phrase " " next_word
                        if (!stop[next_word] || index(next_word, "tux") > 0) meaningful++
                    }
                    # Require at least two meaningful terms, which suppresses
                    # most filler phrases. Report only phrases seen more than once.
                    if (valid && meaningful >= 2) count[phrase]++
                }
            }
            END {
                for (phrase in count)
                    if (count[phrase] > 1)
                        printf "%7d occurrences  %s\n", count[phrase], phrase
            }
        ' |
        sort -rn |
        head -n 10
    )

    if [[ -n "$output" ]]; then
        printf '%s\n' "$output"
    else
        printf '  No recurring phrases found.\n'
    fi
}

# --------------------------------------------------
# 10. Automated archive analysis
# --------------------------------------------------
analyze_archive() {
    local workdir data report timestamp
    local total videos commenters unique_domains timestamped

    workdir=$(mktemp -d "${TMPDIR:-/tmp}/fbi-analysis.XXXXXX") || {
        error "Unable to create analysis workspace."
        pause
        return
    }

    data="$workdir/comments.jsonl"
    report="$workdir/report.txt"

    info "Collecting comment records..."
    stream_comments > "$data"

    if [[ ! -s "$data" ]]; then
        error "No readable comment records found."
        rm -rf -- "$workdir"
        pause
        return
    fi

    timestamp=$(date '+%Y%m%d_%H%M%S')
    mkdir -p "$EXPORT_DIR" || {
        error "Cannot create export directory: $EXPORT_DIR"
        rm -rf -- "$workdir"
        pause
        return
    }

    report="$EXPORT_DIR/analysis_${timestamp}.txt"

    total=$(jq -s 'length' "$data")
    videos=$(jq -s '[.[].video_id] | unique | length' "$data")

    commenters=$(jq -s '
        [
            .[] |
            (.comment.channel // "") as $channel |
            if ($channel | length) > 0 then $channel
            else (.comment.author // "" | select(length > 0))
            end
        ] | unique | length
    ' "$data")

    # Count unique hostnames, not full URL paths. Keep this metric's label honest.
    unique_domains=$(
        jq -r '
            .comment.text // "" |
            scan("https?://[^/[:space:]?#<>]+|www\\.[^/[:space:]?#<>]+") |
            sub("^https?://"; "") |
            sub("^www\\."; "") |
            sub("[),.;!?]+$"; "") |
            ascii_downcase |
            split(":")[0]
        ' "$data" | grep -E '.' | sort -u | awk 'END { print NR+0 }'
    )

    timestamped=$(
        jq -s '
            [ .[] |
              (.comment.time_parsed // null) as $raw |
              (if ($raw | type) == "number" then $raw
               elif ($raw | type) == "string" then ($raw | tonumber? // null)
               else null end) as $ts |
              select($ts != null and $ts > 0)
            ] | length
        ' "$data"
    )

    {
        printf '%s\n' "F.B.I. — FORENSIC BEHAVIORAL INTELLIGENCE"
        printf '%s\n' "AUTOMATED COMMENT ARCHIVE ANALYSIS"
        printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf 'Source directory: %s\n' "$COMMENTS_DIR"
        printf '%s\n\n' \
            "============================================================"

        printf '%s\n' "1. DATASET OVERVIEW"
        printf '%s\n' "-------------------"
        printf 'Total comment records: %s\n' "$total"
        printf 'Videos represented:    %s\n' "$videos"
        printf 'Unique commenters:     %s\n' "$commenters"
        printf 'Unique URL domains:    %s\n' "$unique_domains"
        printf 'Records with numeric timestamps: %s\n\n' "$timestamped"


        printf '\n%s\n' "2. TOP 10 COMMENTERS"
        printf '%s\n' "--------------------"

        jq -s -r '
            map({
                id: (
                    if ((.comment.channel // "") | length) > 0
                    then .comment.channel
                    else (.comment.author // "Unknown")
                    end
                ),
                author: (.comment.author // "Unknown")
            })
            | group_by(.id)
            | map({
                id: .[0].id,
                author: .[0].author,
                count: length
            })
            | sort_by(-.count)
            | .[:10][]
            | [.count, .author, .id]
            | @tsv
        ' "$data" |
            while IFS=$'\t' read -r count author channel_id; do
                printf '%7s comments  %s%s%s  [%s%s%s]\n' \
                    "$count" "$GREEN" "$author" "$RESET" \
                    "$CYAN" "$channel_id" "$RESET"
            done

        printf '\n%s\n' "3. COMMENTERS ACTIVE ON MULTIPLE VIDEOS"
        printf '%s\n' "---------------------------------------"

        jq -s -r '
            map({
                id: (if ((.comment.channel // "") | length) > 0
                     then .comment.channel else (.comment.author // "Unknown") end),
                author: (.comment.author // "Unknown"),
                video: .video_id
            })
            | group_by(.id)
            | map({
                id: .[0].id,
                author: (map(select(.author != "Unknown") | .author) | .[0] // "Unknown"),
                videos: (map(.video) | unique | length)
            })
            | map(select(.videos > 1))
            | sort_by(-.videos)
            | .[:15][]
            | [.videos, .author, .id]
            | @tsv
        ' "$data" |
            while IFS=$'\t' read -r video_count author channel_id; do
                printf '%7s videos  %s%s%s [%s%s%s]\n' \
                    "$video_count" "$GREEN" "$author" "$RESET" \
                    "$CYAN" "$channel_id" "$RESET"
            done

        printf '\n%s\n' "4. MOST FREQUENT TERMS (MINIMUM 4 CHARACTERS)"
        printf '%s\n' "---------------------------------------------"

        jq -r '
            .comment.text // "" |
            ascii_downcase |
            scan("[a-z0-9]{4,}") |
            . as $word |
            select(
                ([
                    "about","after","again","also","been","before",
                    "being","could","does","doing","from","have",
                    "here","just","more","most","much","only",
                    "other","over","same","some","such","than",
                    "that","their","them","then","there","these",
                    "they","this","those","through","very","want",
                    "were","what","when","where","which","while",
                    "will","with","would","your","https","http",
                    "video","videos","like","know","thanks","thank",
                    "great","good","using","need","people","into",
                    "work","love","even","tq5ck","douglashabian",
                    "channel","comment","comments","please","really",
                    "make","much","well","look","still","going",
                    "something","anything","every","couldn","wouldn"
                ] | index($word)) == null
            )
        ' "$data" |
            sort |
            uniq -c |
            sort -rn |
            head -n 20 |
            awk '{ printf "%7s occurrences  %s\n", $1, $2 }'

        printf '\n%s\n' "5. MOST FREQUENT PHRASES"
        printf '%s\n' "-------------------------"

        printf '%s\n' "Two-word phrases (top 10)"
        phrase_counts "$data" 2

        printf '\n%s\n' "Three-word phrases (top 10)"
        phrase_counts "$data" 3

        printf '\n%s\n' "6. MOST FREQUENT URL DOMAINS"
        printf '%s\n' "----------------------------"

        jq -r '
            .comment.text // "" |
            scan("https?://[^/[:space:]?#<>]+|www\\.[^/[:space:]?#<>]+") |
            sub("^https?://"; "") |
            sub("^www\\."; "") |
            sub("[),.;!?]+$"; "") |
            ascii_downcase |
            split(":")[0]
        ' "$data" |
            grep -E '.' |
            sort |
            uniq -c |
            sort -rn |
            head -n 15 |
            awk '{ printf "%7s references  %s\n", $1, substr($0, index($0,$2)) }'

        printf '\n%s\n' "7. REPEATED COMMENT TEXT"
        printf '%s\n' "------------------------"

        jq -r '
            (.comment.text // "") |
            gsub("[[:space:]]+"; " ") |
            ascii_downcase |
            select(length > 0)
        ' "$data" |
            sort |
            uniq -c |
            awk '$1 > 1 { print }' |
            sort -rn |
            head -n 10 |
            awk '{ printf "%7s copies  %s\n", $1, substr($0, index($0,$2)) }'

        printf '\n%s\n' "8. ESTIMATED COMMENT DATES (UTC)"
        printf '%s\n' "---------------------------------"

        jq -r '
            (.comment.time_parsed // null) as $raw |
            (if ($raw | type) == "number" then $raw
             elif ($raw | type) == "string" then ($raw | tonumber? // null)
             else null end) as $value |
            if $value == null or $value <= 0 then empty
            else
                (if $value > 100000000000 then ($value / 1000 | floor)
                 else ($value | floor) end) as $seconds |
                if $seconds < 946684800 or $seconds > 4102444800 then empty
                else ($seconds | gmtime | strftime("%Y-%m-%d")) end
            end
        ' "$data" |
            sort |
            uniq -c |
            sort -k2 |
            awk '{ printf "%s  %7s comments\n", $2, $1 }'

        printf '\n%s\n' "9. ANALYSIS NOTES"
        printf '%s\n' "-----------------"
        printf '%s\n' \
            "- Commenter identity uses channel ID when available." \
            "- Frequent terms exclude common words and known channel-promotion fragments." \
            "- Phrase analysis filters URLs, common phrases, and channel noise while preserving Tux terms." \
            "- Repeated text is case-insensitive and whitespace-normalized." \
            "- Dates are displayed in UTC; numeric timestamps in seconds or milliseconds are accepted." \
            "- Source timestamps may be relative, so parsed dates can be estimates." \
            "- Timeline excludes missing, nonnumeric, and implausible timestamps (outside 2000-2100)." \
            "- Shared activity does not prove coordination or identity." \
            "- Findings depend on the completeness of the supplied archives."

        printf '\n%s\n' "END OF REPORT"
    } > "$report"

    printf '\n'
    rule
    printf '%s%s ANALYSIS COMPLETE%s\n' "$GREEN" "$BOLD" "$RESET"
    rule
    cat "$report"
    printf '\n'
    success "Report saved to: $report"

    rm -rf -- "$workdir"
    pause
}

# --------------------------------------------------
# 11. Cross-video commenter correlation report
# --------------------------------------------------
cross_video_report() {
    local workdir data limit count answer format timestamp outfile
    local owner_channel_id owner_author total_videos max_videos bar_len bar
    local rank color_index bar_color padding
    local -a bar_colors

    # Owner identity cannot be reliably inferred from comment frequency. Require
    # the channel ID so this works across arbitrary channel archives without
    # hardcoding a specific creator or silently guessing the owner.
    owner_channel_id="${FBI_OWNER_CHANNEL_ID:-}"
    if [[ -z "$owner_channel_id" ]]; then
        read -r -p "Channel owner's channel ID (required; always excluded): " owner_channel_id || return
    fi
    if [[ -z "$owner_channel_id" ]]; then
        error "A channel owner ID is required to exclude the owner reliably."
        pause
        return
    fi

    read -r -p "How many commenters to display? [10] " limit || return
    limit="${limit:-10}"

    if [[ ! "$limit" =~ ^[0-9]+$ ]] || (( limit < 1 )); then
        warn "Enter a positive whole number."
        pause
        return
    fi

    workdir=$(mktemp -d "${TMPDIR:-/tmp}/fbi-correlation.XXXXXX") || {
        error "Unable to create correlation workspace."
        pause
        return
    }
    data="$workdir/cross_video_commenters.jsonl"

    # Count archive files as videos, including files that happen to contain no
    # readable comments. If a record lacks a channel ID, also exclude the
    # owner's matching author handle when it can be learned from owner records.
    total_videos=$(file_count) || total_videos=0
    owner_author=$(stream_comments | jq -r --arg owner "$owner_channel_id" \
        'select((.comment.channel // "") == $owner) | .comment.author // empty' | head -n 1)
    owner_author="${owner_author:-${FBI_OWNER_AUTHOR:-}}"
    if [[ -z "$owner_author" ]]; then
        read -r -p "Owner's author handle (required when owner ID is absent from comments): " owner_author || return
    fi
    if [[ -z "$owner_author" ]]; then
        error "Cannot guarantee owner exclusion without an owner handle fallback."
        pause
        return
    fi
    if (( total_videos < 1 )); then
        error "Could not determine the number of videos in the archive."
        rm -rf -- "$workdir"
        pause
        return
    fi

    info "Correlating audience activity across videos; excluding the channel owner..."
    stream_comments |
        jq -s -c --arg owner "$owner_channel_id" --arg owner_author "$owner_author" --argjson total_videos "$total_videos" '
            map(
                . as $record |
                (.comment.channel // "") as $channel |
                (.comment.author // "") as $author |
                select($channel != $owner and
                    (($channel | length) > 0 or ($author | ascii_downcase) != ($owner_author | ascii_downcase))) |
                {
                    id: (if ($channel | length) > 0 then $channel else $author end),
                    author: (if ($author | length) > 0 then $author else "Unknown" end),
                    video_id: ($record.video_id // "Unknown video")
                }
                | select(.id != "" and .id != $owner)
            )
            | group_by(.id)
            | map({
                channel_id: .[0].id,
                author: (map(select(.author != "Unknown") | .author) | .[0] // "Unknown"),
                comment_count: length,
                video_ids: (map(.video_id) | unique | sort),
                video_count: (map(.video_id) | unique | length),
                coverage_percent: ((((map(.video_id) | unique | length) / $total_videos) * 10000 | round) / 100)
            })
            | map(select(.video_count > 1))
            | sort_by(-.video_count, -.comment_count, .author)
            | .[]
        ' > "$data"

    count=$(awk 'END { print NR+0 }' "$data")
    max_videos=$(jq -s '[.[].video_count] | max // 1' "$data" 2>/dev/null) || max_videos=1
    (( max_videos > 0 )) || max_videos=1

    printf '\n'
    rule
    printf '%s%s AUDIENCE CROSS-VIDEO REPORT%s\n' "$WHITE" "$BOLD" "$RESET"
    rule
    printf 'Archive videos: %s | Owner excluded: %s\n' "$total_videos" "$owner_channel_id"
    printf 'Audience commenters appearing on multiple videos: %s\n' "$count"

    if (( count == 0 )); then
        info "No audience commenters were found on more than one video."
        rm -rf -- "$workdir"
        pause
        return
    fi

    printf '\n%sRank  Videos  Comments  Coverage  Activity              Author [Channel ID]%s\n' "$BOLD" "$RESET"
    printf '%s%s%s\n' "$GRAY" '-------------------------------------------------------------------------------' "$RESET"

    # Cycle through the existing terminal palette so each row's activity bar
    # is visually distinct. Color variables are empty for NO_COLOR/non-TTY.
    bar_colors=("$GREEN" "$CYAN" "$YELLOW" "$MAGENTA" "$BLUE" "$RED")

    jq -r '[.video_count, .comment_count, .coverage_percent, .author, .channel_id] | @tsv' "$data" |
        head -n "$limit" |
        {
            rank=0
            while IFS=$'\t' read -r video_count comment_count coverage author channel_id; do
                ((rank += 1))
                bar_len=$(( (video_count * 20 + max_videos / 2) / max_videos ))
                (( bar_len < 1 )) && bar_len=1
                (( bar_len > 20 )) && bar_len=20
                bar=$(printf '%*s' "$bar_len" '' | tr ' ' '#')
                color_index=$(((rank - 1) % ${#bar_colors[@]}))
                bar_color="${bar_colors[$color_index]}"
                padding=$((20 - bar_len))

                printf '%-4s  %5s  %8s  %6s%%  ' \
                    "$rank" "$video_count" "$comment_count" "$coverage"
                printf '%s%s%s' "$bar_color" "$bar" "$RESET"
                printf '%*s  %s [%s]\n' "$padding" '' "$author" "$channel_id"
            done
        }

    printf '\n%sTip:%s The activity bar compares video coverage among the matching audience commenters. Full video ID lists remain in the export, not the terminal table.\n' "$CYAN" "$RESET"
    printf '\n'
    read -r -p "Export the full report, including video IDs? [y/N] " answer || answer="n"
    case "${answer,,}" in
        y|yes)
            printf '\n  1) JSONL\n  2) CSV\n  3) TXT\n'
            read -r -p "Export format: " format || format=""
            case "$format" in
                1|jsonl) format="jsonl" ;;
                2|csv) format="csv" ;;
                3|txt) format="txt" ;;
                *)
                    warn "Invalid export format."
                    rm -rf -- "$workdir"
                    pause
                    return
                    ;;
            esac

            mkdir -p "$EXPORT_DIR" || {
                error "Cannot create export directory: $EXPORT_DIR"
                rm -rf -- "$workdir"
                pause
                return
            }
            timestamp=$(date '+%Y%m%d_%H%M%S')
            outfile="$EXPORT_DIR/cross_video_commenters_${timestamp}.${format}"
            case "$format" in
                jsonl)
                    cp -- "$data" "$outfile" || {
                        error "Export failed."
                        rm -rf -- "$workdir"
                        pause
                        return
                    }
                    ;;
                csv)
                    {
                        printf '"channel_id","author","comment_count","video_count","coverage_percent","video_ids"\n'
                        jq -r '[.channel_id, .author, .comment_count, .video_count, .coverage_percent, (.video_ids | join("; "))] | @csv' "$data"
                    } > "$outfile" || {
                        error "CSV export failed."
                        rm -rf -- "$workdir"
                        pause
                        return
                    }
                    ;;
                txt)
                    jq -r '"Author: \(.author)", "Channel ID: \(.channel_id)", "Comments: \(.comment_count)", "Videos: \(.video_count) of archive (\(.coverage_percent)%)", "Video IDs (\(.video_count)): \(.video_ids | join(", "))", ""' "$data" > "$outfile" || {
                        error "TXT export failed."
                        rm -rf -- "$workdir"
                        pause
                        return
                    }
                    ;;
            esac
            success "Full audience report exported: $outfile"
            ;;
        *) ;;
    esac

    rm -rf -- "$workdir"
    pause
}

# --------------------------------------------------
# 12. Audience overlap analysis and relationship map
# --------------------------------------------------
audience_overlap_map() {
    local owner_channel_id owner_author total_videos limit workdir raw nodes edges graph_json graph_b64
    local node_count edge_count timestamp html_out answer format outfile
    local shared_count author_a author_b id_a id_b

    owner_channel_id="${FBI_OWNER_CHANNEL_ID:-}"
    if [[ -z "$owner_channel_id" ]]; then
        read -r -p "Channel owner's channel ID (required; always excluded): " owner_channel_id || return
    fi
    if [[ -z "$owner_channel_id" ]]; then
        error "A channel owner ID is required to exclude the owner reliably."
        pause
        return
    fi

    read -r -p "How many commenters to include in the relationship map? [25] " limit || return
    limit="${limit:-25}"
    if [[ ! "$limit" =~ ^[0-9]+$ ]] || (( limit < 2 || limit > 100 )); then
        warn "Enter a whole number from 2 to 100."
        pause
        return
    fi

    workdir=$(mktemp -d "${TMPDIR:-/tmp}/fbi-overlap.XXXXXX") || {
        error "Unable to create overlap-analysis workspace."
        pause
        return
    }
    raw="$workdir/audience.json"
    nodes="$workdir/nodes.json"
    edges="$workdir/edges.json"

    total_videos=$(file_count) || total_videos=0
    if (( total_videos < 1 )); then
        error "Could not determine the number of videos in the archive."
        rm -rf -- "$workdir"
        pause
        return
    fi

    # If comments have no channel ID, use the owner's author handle only when
    # it can be tied to the supplied owner channel ID elsewhere in this archive.
    owner_author=$(stream_comments | jq -r --arg owner "$owner_channel_id" \
        'select((.comment.channel // "") == $owner) | .comment.author // empty' | head -n 1)
    owner_author="${owner_author:-${FBI_OWNER_AUTHOR:-}}"
    if [[ -z "$owner_author" ]]; then
        read -r -p "Owner's author handle (required when owner ID is absent from comments): " owner_author || {
            rm -rf -- "$workdir"
            return
        }
    fi
    if [[ -z "$owner_author" ]]; then
        error "Cannot guarantee owner exclusion without an owner handle fallback."
        rm -rf -- "$workdir"
        pause
        return
    fi

    info "Analyzing audience overlap; excluding the channel owner..."
    stream_comments |
        jq -s -c --arg owner "$owner_channel_id" --arg owner_author "$owner_author" '
            map(
                . as $record |
                (.comment.channel // "") as $channel |
                (.comment.author // "") as $author |
                select($channel != $owner and
                    (($channel | length) > 0 or ($author | ascii_downcase) != ($owner_author | ascii_downcase))) |
                {
                    id: (if ($channel | length) > 0 then $channel else $author end),
                    author: (if ($author | length) > 0 then $author else "Unknown" end),
                    video_id: ($record.video_id // "Unknown video")
                } |
                select(.id != "" and .id != $owner and .video_id != "Unknown video")
            )
        ' > "$raw"

    # Rank by distinct videos first, then comment volume. Only repeat cross-video
    # commenters enter the map; the full video membership remains in node data.
    jq -c --argjson limit "$limit" '
        group_by(.id)
        | map({
            id: .[0].id,
            author: (map(select(.author != "Unknown") | .author) | .[0] // "Unknown"),
            comment_count: length,
            video_ids: (map(.video_id) | unique | sort),
            video_count: (map(.video_id) | unique | length)
        })
        | map(select(.video_count > 1))
        | sort_by(-.video_count, -.comment_count, .author)
        | .[:$limit]
    ' "$raw" > "$nodes"

    # An edge means two commenters appeared on at least one same video. The
    # edge weight is the number of shared videos; this is overlap, not proof of
    # direct interaction, coordination, or a relationship between people.
    jq -c '
        . as $nodes
        | [range(0; length) as $i
           | range($i + 1; ($nodes | length)) as $j
           | $nodes[$i] as $a
           | $nodes[$j] as $b
           | ([$a.video_ids[] as $vid | select(($b.video_ids | index($vid)) != null) | $vid]) as $shared
           | select(($shared | length) > 0)
           | {
               source: $a.id,
               source_author: $a.author,
               target: $b.id,
               target_author: $b.author,
               shared_video_count: ($shared | length),
               shared_video_ids: $shared
           }
          ]
        | sort_by(-.shared_video_count, .source_author, .target_author)
    ' "$nodes" > "$edges"

    node_count=$(jq 'length' "$nodes" 2>/dev/null) || node_count=0
    edge_count=$(jq 'length' "$edges" 2>/dev/null) || edge_count=0

    printf '\n'
    rule
    printf '%s%s AUDIENCE OVERLAP ANALYSIS%s\n' "$WHITE" "$BOLD" "$RESET"
    rule
    printf 'Archive videos: %s | Owner excluded: %s\n' "$total_videos" "$owner_channel_id"
    printf 'Commenters mapped: %s | Shared-video connections: %s\n' "$node_count" "$edge_count"
    printf '\n%sTop shared-video pairs%s\n' "$BOLD" "$RESET"
    if (( edge_count == 0 )); then
        info "No shared-video connections were found among the selected commenters."
    else
        printf '%sShared videos | Commenter A | Commenter B%s\n' "$BOLD" "$RESET"
        printf '%s%s%s\n' "$GRAY" '-----------------------------------------------------------------------' "$RESET"
        jq -r '.[:10][] | [.shared_video_count, .source_author, .target_author, .source, .target] | @tsv' "$edges" |
            while IFS=$'\t' read -r shared_count author_a author_b id_a id_b; do
                printf '%3s shared  %s [%s]\n             ↔ %s [%s]\n\n' \
                    "$shared_count" "$author_a" "$id_a" "$author_b" "$id_b"
            done
    fi

    mkdir -p "$EXPORT_DIR" || {
        error "Cannot create export directory: $EXPORT_DIR"
        rm -rf -- "$workdir"
        pause
        return
    }
    timestamp=$(date '+%Y%m%d_%H%M%S')
    html_out="$EXPORT_DIR/audience_overlap_${timestamp}.html"
    graph_json="$workdir/graph.json"
    jq -c -n --slurpfile nodes "$nodes" --slurpfile edges "$edges" \
        --arg owner "$owner_channel_id" --argjson total_videos "$total_videos" \
        '{nodes:$nodes[0],edges:$edges[0],owner_channel_id:$owner,total_videos:$total_videos}' > "$graph_json"
    graph_b64=$(base64 -w0 "$graph_json") || graph_b64=""
    if [[ -z "$graph_b64" ]]; then
        error "Could not encode relationship-map data."
        rm -rf -- "$workdir"
        pause
        return
    fi

    cat > "$workdir/map_template.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>F.B.I. Audience Overlap Map</title>
<style>
:root{color-scheme:dark;--bg:#0b1020;--panel:#121a2d;--line:#26344f;--text:#e8eefc;--muted:#9eacc8;--accent:#65d6ce}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(ellipse at top,#17233e,var(--bg) 60%);color:var(--text);font:15px/1.45 system-ui,-apple-system,Segoe UI,sans-serif}
header{padding:24px clamp(16px,4vw,44px) 18px;border-bottom:1px solid var(--line)}h1{margin:0 0 6px;font-size:clamp(24px,4vw,36px);letter-spacing:.02em}p{margin:4px 0;color:var(--muted)}.metrics{display:flex;gap:10px;flex-wrap:wrap;margin-top:15px}.metric{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:10px 14px}.metric b{display:block;font-size:21px;color:var(--accent)}
main{padding:18px clamp(12px,3vw,32px) 32px}.controls{display:flex;gap:14px;align-items:center;flex-wrap:wrap;margin-bottom:14px}.controls label{color:var(--muted)}select{margin-left:8px;background:var(--panel);border:1px solid var(--line);color:var(--text);padding:9px;border-radius:8px}.hint{font-size:13px;color:var(--muted)}.layout{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:14px}.panel{background:rgba(18,26,45,.9);border:1px solid var(--line);border-radius:14px;overflow:hidden}.panel h2{font-size:15px;margin:0;padding:14px 16px;border-bottom:1px solid var(--line)}#network{display:block;width:100%;height:650px;cursor:grab}#network:active{cursor:grabbing}.side-list{padding:8px;max-height:650px;overflow:auto}.person{display:grid;grid-template-columns:28px 1fr auto;gap:9px;align-items:center;padding:9px;border-radius:9px;cursor:pointer}.person:hover,.person.active{background:#24324e}.dot{width:12px;height:12px;border-radius:50%;margin:auto}.name{font-weight:650;overflow-wrap:anywhere}.sub{font-size:12px;color:var(--muted)}.count{font-variant-numeric:tabular-nums;color:var(--accent);white-space:nowrap}.details{margin-top:14px;padding:15px 17px;background:var(--panel);border:1px solid var(--line);border-radius:12px;min-height:66px}.legend{display:flex;gap:14px;flex-wrap:wrap;margin-top:10px;font-size:12px;color:var(--muted)}.legend span{display:inline-flex;align-items:center;gap:6px}.legend i{display:inline-block;width:24px;border-top:3px solid var(--accent)}footer{padding:0 clamp(16px,4vw,44px) 24px;color:var(--muted);font-size:12px}
@media(max-width:900px){.layout{grid-template-columns:1fr}#network{height:540px}.side-list{max-height:360px}}
</style>
</head>
<body>
<header><h1>Audience Overlap Map</h1><p>F.B.I. · Forensic Behavioral Intelligence</p><p>Connections indicate commenters who appeared on the same archived videos. They do not prove direct interaction or coordination.</p><div class="metrics"><div class="metric"><b id="videoMetric">—</b><span>archived videos</span></div><div class="metric"><b id="nodeMetric">—</b><span>commenters mapped</span></div><div class="metric"><b id="edgeMetric">—</b><span>shared-video connections</span></div><div class="metric"><b>Excluded</b><span>channel owner</span></div></div></header>
<main><div class="controls"><label>Show connections sharing<select id="threshold"><option value="1">at least 1 video</option><option value="2" selected>at least 2 videos</option><option value="3">at least 3 videos</option></select></label><span class="hint">Select a person to highlight their connections. Hover over a node for details.</span></div>
<div class="layout"><section class="panel"><h2>Commenter relationship network</h2><canvas id="network" aria-label="Interactive network graph"></canvas></section><aside class="panel"><h2>Ranked by video coverage</h2><div id="people" class="side-list"></div></aside></div><div class="details" id="details">Select a node or a person in the list to inspect their shared-video connections.</div><div class="legend"><span><i></i> Line thickness represents number of shared videos</span><span>Node size represents distinct videos</span></div></main>
<footer>Owner channel ID was excluded from the underlying dataset. Only the top selected repeat commenters are drawn. Use the companion export for the full shared-video ID lists for this map.</footer>
<script>
const DATA_B64 = "REPLACE_DATA_B64";
const bytes = Uint8Array.from(atob(DATA_B64), c => c.charCodeAt(0));
const data = JSON.parse(new TextDecoder().decode(bytes));
const palette = ["#5eead4","#60a5fa","#fbbf24","#c084fc","#fb7185","#a3e635","#f97316","#22d3ee","#f472b6","#818cf8"];
const nodes = data.nodes.map((n,i)=>({...n,color:palette[i%palette.length],x:0,y:0,vx:(Math.random()-.5),vy:(Math.random()-.5)}));
const byId = new Map(nodes.map(n=>[n.id,n]));
const edges = data.edges.filter(e=>byId.has(e.source)&&byId.has(e.target));
const canvas=document.getElementById('network'),ctx=canvas.getContext('2d'),threshold=document.getElementById('threshold');
let width=0,height=0,dpr=1,selected=null,hovered=null,frame=0;
function resize(){const r=canvas.getBoundingClientRect();dpr=window.devicePixelRatio||1;width=r.width;height=r.height;canvas.width=Math.round(width*dpr);canvas.height=Math.round(height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);nodes.forEach((n,i)=>{if(!n.x&&!n.y){const a=2*Math.PI*i/Math.max(nodes.length,1);n.x=width/2+Math.cos(a)*Math.min(width,height)*.3;n.y=height/2+Math.sin(a)*Math.min(width,height)*.3;}})}
function activeEdges(){return edges.filter(e=>e.shared_video_count>=Number(threshold.value))}
function nodeRadius(n){const max=Math.max(1,...nodes.map(x=>x.video_count));return 6+13*n.video_count/max}
function draw(){ctx.clearRect(0,0,width,height);const es=activeEdges();const connected=new Set();es.forEach(e=>{const a=byId.get(e.source),b=byId.get(e.target);if(!a||!b)return;connected.add(a.id);connected.add(b.id);const focus=!selected||(selected===a.id||selected===b.id);ctx.globalAlpha=focus?.68:.08;ctx.strokeStyle=focus?'#7c91b7':'#52617b';ctx.lineWidth=Math.min(6,1+e.shared_video_count*1.1);ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();ctx.globalAlpha=1;});
 nodes.forEach((n,i)=>{const r=nodeRadius(n),focus=!selected||selected===n.id||es.some(e=>(e.source===selected&&e.target===n.id)||(e.target===selected&&e.source===n.id));ctx.globalAlpha=focus?1:.22;ctx.beginPath();ctx.arc(n.x,n.y,r,0,Math.PI*2);ctx.fillStyle=n.color;ctx.fill();ctx.strokeStyle=selected===n.id?'#ffffff':'#101827';ctx.lineWidth=selected===n.id?3:1.5;ctx.stroke();if(i<8||n.id===hovered||n.id===selected){ctx.font=(n.id===selected?'700 ':'500 ')+(n.id===selected?'13':'11')+'px system-ui';ctx.fillStyle='#e8eefc';ctx.textAlign='center';ctx.fillText(n.author.length>22?n.author.slice(0,20)+'…':n.author,n.x,n.y+r+14);}ctx.globalAlpha=1;});
 if(!nodes.length){ctx.fillStyle='#9eacc8';ctx.textAlign='center';ctx.font='16px system-ui';ctx.fillText('No repeat commenters to display.',width/2,height/2)}else if(!es.length){ctx.fillStyle='#9eacc8';ctx.textAlign='center';ctx.font='14px system-ui';ctx.fillText('No connections meet this threshold. Try a lower threshold.',width/2,height-18)}
 frame=requestAnimationFrame(step)}
function step(){const es=activeEdges(),n=nodes.length;if(!n){draw();return}for(let i=0;i<n;i++){const a=nodes[i];for(let j=i+1;j<n;j++){const b=nodes[j],dx=a.x-b.x,dy=a.y-b.y,d2=dx*dx+dy*dy+1,force=650/d2;a.vx+=dx*force;a.vy+=dy*force;b.vx-=dx*force;b.vy-=dy*force;}}
 es.forEach(e=>{const a=byId.get(e.source),b=byId.get(e.target);if(!a||!b)return;const dx=b.x-a.x,dy=b.y-a.y,d=Math.sqrt(dx*dx+dy*dy)||1,force=(d-120)*.0025*Math.min(3,e.shared_video_count);a.vx+=dx/d*force;b.vx-=dx/d*force;a.vy+=dy/d*force;b.vy-=dy/d*force;});nodes.forEach(a=>{a.vx+=(width/2-a.x)*.0008;a.vy+=(height/2-a.y)*.0008;a.vx*=.88;a.vy*=.88;a.x=Math.max(24,Math.min(width-24,a.x+a.vx));a.y=Math.max(24,Math.min(height-24,a.y+a.vy));});draw()}
function selectNode(id){selected=id;const n=byId.get(id);if(!n)return;const links=activeEdges().filter(e=>e.source===id||e.target===id);const lines=links.slice(0,12).map(e=>{const other=byId.get(e.source===id?e.target:e.source);return `<li>${escapeHtml(other?.author||'Unknown')} — shared ${e.shared_video_count} video(s)</li>`}).join('');document.getElementById('details').innerHTML=`<strong>${escapeHtml(n.author)}</strong><br><span class="sub">Channel ID: ${escapeHtml(n.id)} · ${n.comment_count} comments · ${n.video_count} videos (${(100*n.video_count/data.total_videos).toFixed(1)}% of archive)</span><p>Shared connections visible at the selected threshold: ${links.length}</p>${lines?`<ul>${lines}</ul>`:'<p>No connections meet the current threshold.</p>'}`;document.querySelectorAll('.person').forEach(el=>el.classList.toggle('active',el.dataset.id===id));}
function escapeHtml(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function renderList(){document.getElementById('people').innerHTML=nodes.map(n=>`<div class="person" data-id="${escapeHtml(n.id)}"><span class="dot" style="background:${n.color}"></span><div><div class="name">${escapeHtml(n.author)}</div><div class="sub">${n.video_count} videos · ${n.comment_count} comments</div></div><span class="count">${(100*n.video_count/data.total_videos).toFixed(1)}%</span></div>`).join('');document.querySelectorAll('.person').forEach(el=>el.addEventListener('click',()=>selectNode(el.dataset.id)));}
canvas.addEventListener('mousemove',ev=>{const r=canvas.getBoundingClientRect(),x=ev.clientX-r.left,y=ev.clientY-r.top;hovered=null;for(const n of nodes){if(Math.hypot(n.x-x,n.y-y)<nodeRadius(n)+5){hovered=n.id;canvas.title=`${n.author}: ${n.video_count} videos, ${n.comment_count} comments`;break}}});canvas.addEventListener('click',ev=>{const r=canvas.getBoundingClientRect(),x=ev.clientX-r.left,y=ev.clientY-r.top;let best=null,dist=Infinity;nodes.forEach(n=>{const d=Math.hypot(n.x-x,n.y-y);if(d<nodeRadius(n)+7&&d<dist){best=n;dist=d}});if(best)selectNode(best.id)});threshold.addEventListener('change',()=>{if(selected)selectNode(selected)});window.addEventListener('resize',resize);
document.getElementById('videoMetric').textContent=data.total_videos;document.getElementById('nodeMetric').textContent=nodes.length;document.getElementById('edgeMetric').textContent=edges.length;renderList();resize();step();
</script></body></html>
HTML
    sed "s|REPLACE_DATA_B64|$graph_b64|" "$workdir/map_template.html" > "$html_out" || {
        error "Could not write relationship map."
        rm -rf -- "$workdir"
        pause
        return
    }
    success "Interactive relationship map saved: $html_out"

    printf '\n%sExport overlap pairs for further analysis? [y/N] %s' "$CYAN" "$RESET"
    read -r answer || answer="n"
    case "${answer,,}" in
        y|yes)
            printf '\n  1) JSONL\n  2) CSV\n  3) TXT\n'
            read -r -p "Export format: " format || format=""
            case "$format" in
                1|jsonl) format="jsonl" ;;
                2|csv) format="csv" ;;
                3|txt) format="txt" ;;
                *)
                    warn "Invalid export format."
                    rm -rf -- "$workdir"
                    pause
                    return
                    ;;
            esac
            outfile="$EXPORT_DIR/audience_overlap_${timestamp}.${format}"
            case "$format" in
                jsonl)
                    jq -c '.[]' "$edges" > "$outfile" || {
                        error "JSONL export failed."
                        rm -rf -- "$workdir"
                        pause
                        return
                    }
                    ;;
                csv)
                    {
                        printf '"shared_video_count","source_author","source_channel_id","target_author","target_channel_id","shared_video_ids"\n'
                        jq -r '.[] | [.shared_video_count,.source_author,.source,.target_author,.target,(.shared_video_ids|join("; "))] | @csv' "$edges"
                    } > "$outfile" || {
                        error "CSV export failed."
                        rm -rf -- "$workdir"
                        pause
                        return
                    }
                    ;;
                txt)
                    jq -r '.[] | "Shared videos: \(.shared_video_count)", "Commenter A: \(.source_author) [\(.source)]", "Commenter B: \(.target_author) [\(.target)]", "Video IDs: \(.shared_video_ids|join(", "))", ""' "$edges" > "$outfile" || {
                        error "TXT export failed."
                        rm -rf -- "$workdir"
                        pause
                        return
                    }
                    ;;
            esac
            success "Overlap-pair export saved: $outfile"
            ;;
        *) ;;
    esac

    printf '\n%sNote:%s A shared video indicates audience overlap only; it does not prove that commenters interacted or coordinated. The graph and pair export cover the top %s repeat commenters selected for this run.\n' "$CYAN" "$RESET" "$node_count"
    rm -rf -- "$workdir"
    pause
}


# --------------------------------------------------
# 12. Commenter case tracker
# Persistent, user-annotated records for comments that merit review.
# Original comment text is preserved; interpretations are stored separately.
# --------------------------------------------------
commenter_case_tracker() {
    local db choice channel_id workdir matches encoded record count index selection
    local author video time text cid category note timestamp outfile format case_author

    mkdir -p -- "$EXPORT_DIR" || {
        error "Cannot create export directory: $EXPORT_DIR"
        pause
        return
    }
    db="$EXPORT_DIR/commenter_cases.json"
    if [[ ! -f "$db" ]]; then printf '[]\n' > "$db"; fi
    if ! jq -e 'type == "array"' "$db" >/dev/null 2>&1; then
        error "Case database is not valid JSON: $db"
        warn "Back up the file before making any changes."
        pause
        return
    fi

    printf '\n%sCOMMENTER CASE TRACKER%s\n' "$WHITE" "$RESET"
    rule
    printf '  1) Review comments and flag examples\n'
    printf '  2) View saved case notes / export report\n'
    read -r -p "Select action: " choice || return

    case "$choice" in
        1)
            channel_id=$(read_nonempty "Commenter's channel ID: ") || return
            new_result_file || return
            stream_comments | jq -c --arg id "$channel_id" '
                select((.comment.channel // "") == $id)
                | {video_id, comment}
            ' > "$RESULT_FILE"
            count=$(jq -s 'length' "$RESULT_FILE" 2>/dev/null) || count=0
            if (( count == 0 )); then
                warn "No comments found for channel ID: $channel_id"
                pause
                return
            fi

            case_author=$(head -n 1 "$RESULT_FILE" | jq -r '.comment.author // "Unknown author"')
            printf '\n%sCase profile%s: %s [%s]\n' "$BOLD" "$RESET" "$case_author" "$channel_id"
            printf 'Archived comments found: %s\n\n' "$count"
            printf 'Comments are shown in archive order. Choose a number to annotate one.\n'
            index=0
            while IFS= read -r encoded; do
                [[ -n "$encoded" ]] || continue
                record=$(printf '%s' "$encoded" | base64 --decode 2>/dev/null) || continue
                ((index += 1))
                video=$(jq -r '.video_id // "Unknown video"' <<< "$record")
                author=$(jq -r '.comment.author // "Unknown author"' <<< "$record")
                time=$(jq -r '.comment.time // "Unknown time"' <<< "$record")
                text=$(jq -r '.comment.text // ""' <<< "$record")
                printf '%s%3d)%s [%s] %s\n' "$CYAN" "$index" "$RESET" "$video" "$time"
                printf '     %s\n\n' "$text"
                # Keep the interactive review readable; the full archive remains searchable.
                if (( index >= 100 )); then
                    printf '%sOnly the first 100 matching comments are shown in this review.%s\n' "$YELLOW" "$RESET"
                    break
                fi
            done < <(jq -r '@base64' "$RESULT_FILE")

            read -r -p "Comment number to flag (blank to return): " selection || return
            [[ -n "$selection" ]] || { pause; return; }
            if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > index )); then
                warn "Choose a displayed comment number."
                pause
                return
            fi
            record=$(sed -n "${selection}p" "$RESULT_FILE")
            video=$(jq -r '.video_id // "Unknown video"' <<< "$record")
            author=$(jq -r '.comment.author // "Unknown author"' <<< "$record")
            cid=$(jq -r '.comment.cid // ""' <<< "$record")
            time=$(jq -r '.comment.time // "Unknown time"' <<< "$record")
            text=$(jq -r '.comment.text // ""' <<< "$record")

            printf '\nChoose an annotation category:\n'
            printf '  1) Contradiction / changing a previous claim\n'
            printf '  2) Personal attack framed as concern\n'
            printf '  3) Repeated boundary pushing\n'
            printf '  4) Deflection / avoiding the question\n'
            printf '  5) Other / review later\n'
            read -r -p "Category: " choice || return
            case "$choice" in
                1) category="Contradiction / changing a previous claim" ;;
                2) category="Personal attack framed as concern" ;;
                3) category="Repeated boundary pushing" ;;
                4) category="Deflection / avoiding the question" ;;
                5) category="Other / review later" ;;
                *) warn "Invalid category."; pause; return ;;
            esac
            read -r -p "Your note (optional; describe what you observed): " note || return
            timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
            workdir=$(mktemp -d "${TMPDIR:-/tmp}/fbi-case.XXXXXX") || { error "Cannot create temporary workspace."; pause; return; }
            # Store annotations separately from the original comment, keyed by channel ID.
            jq --arg id "$channel_id" --arg author "$author" --arg video "$video" \
               --arg cid "$cid" --arg time "$time" --arg text "$text" \
               --arg category "$category" --arg note "$note" --arg created "$timestamp" '
                . as $db |
                ([$db[] | select(.channel_id == $id)][0] // {channel_id:$id, author:$author, created_at:$created, flags:[]}) as $existing |
                ($existing + {author:$author, flags:($existing.flags + [{video_id:$video, comment_id:$cid, source_time:$time, original_text:$text, category:$category, note:$note, flagged_at:$created}])}) as $updated |
                if any($db[]; .channel_id == $id) then
                    map(if .channel_id == $id then $updated else . end)
                else . + [$updated] end
            ' "$db" > "$workdir/cases.json" || { rm -rf -- "$workdir"; error "Could not update case database."; pause; return; }
            if jq -e 'type == "array"' "$workdir/cases.json" >/dev/null 2>&1; then
                mv -- "$workdir/cases.json" "$db"
                success "Comment annotation saved to: $db"
            else
                error "Generated case data failed validation; original database was preserved."
            fi
            rm -rf -- "$workdir"
            printf '\n%sReminder:%s This is your annotation of the comment, not an automated finding about intent. Original comment text is preserved.\n' "$CYAN" "$RESET"
            pause
            ;;
        2)
            printf '\n%sSAVED COMMENTER CASES%s\n' "$BOLD" "$RESET"
            jq -r 'if length == 0 then "No cases have been created yet." else .[] | "\(.author // "Unknown author") [\(.channel_id)] — \(.flags|length) annotation(s)" end' "$db"
            read -r -p "Channel ID to view/export (blank to return): " channel_id || return
            [[ -n "$channel_id" ]] || { pause; return; }
            if ! jq -e --arg id "$channel_id" 'any(.[]; .channel_id == $id)' "$db" >/dev/null; then
                warn "No saved case for that channel ID."
                pause
                return
            fi
            printf '\n'
            jq -r --arg id "$channel_id" '.[] | select(.channel_id == $id) as $case | "Case: \($case.author) [\($case.channel_id)]", "Annotations: \($case.flags|length)", ($case.flags[] | "\nVideo: \(.video_id)\nSource time: \(.source_time)\nCategory: \(.category)\nFlagged at: \(.flagged_at)\nNote: \(.note)\nOriginal comment: \(.original_text)"), ""' "$db"
            read -r -p "Export this case report? [y/N] " choice || return
            case "${choice,,}" in
                y|yes)
                    timestamp=$(date '+%Y%m%d_%H%M%S')
                    outfile="$EXPORT_DIR/commenter_case_${timestamp}.txt"
                    jq -r --arg id "$channel_id" '.[] | select(.channel_id == $id) as $case | "F.B.I. COMMENTER CASE REPORT", "Author: \($case.author)", "Channel ID: \($case.channel_id)", "Created: \($case.created_at)", "", ($case.flags[] | "Video ID: \(.video_id)\nComment ID: \(.comment_id)\nSource time: \(.source_time)\nCategory: \(.category)\nFlagged at: \(.flagged_at)\nNote: \(.note)\nOriginal comment: \(.original_text)\n"), "", "Note: annotations are user interpretations and do not establish intent."' "$db" > "$outfile" || { error "Case export failed."; pause; return; }
                    success "Case report exported: $outfile"
                    ;;
                *) ;;
            esac
            pause
            ;;
        *) warn "Invalid selection."; pause ;;
    esac
}

# --------------------------------------------------
# Main menu
# --------------------------------------------------
main_menu() {
    local choice

    while true; do
        printf '\n'
        rule
        printf '%s%s  F.B.I. MAIN MENU%s\n' "$WHITE" "$BOLD" "$RESET"
        rule

        printf '  %s1%s  Search by keyword or phrase\n' "$GREEN" "$RESET"
        printf '  %s2%s  Search by author or channel ID\n' "$GREEN" "$RESET"
        printf '  %s3%s  Rank frequent commenters\n' "$GREEN" "$RESET"
        printf '  %s4%s  Find comments containing URLs\n' "$GREEN" "$RESET"
        printf '  %s5%s  Export all comments\n' "$GREEN" "$RESET"
        printf '  %s6%s  Export keyword matches\n' "$GREEN" "$RESET"
        printf '  %s7%s  Search by date range\n' "$GREEN" "$RESET"
        printf '  %s8%s  Inspect archive and fields\n' "$GREEN" "$RESET"
        printf '  %s9%s  Count comments and files\n' "$GREEN" "$RESET"
        printf ' %s10%s  Analyze comment archives\n' "$GREEN" "$RESET"
        printf ' %s11%s  Combined search (multiple filters)\n' "$GREEN" "$RESET"
        printf ' %s12%s  Cross-video commenter report\n' "$GREEN" "$RESET"
        printf ' %s13%s  Audience overlap & relationship map\n' "$GREEN" "$RESET"
        printf ' %s14%s  Commenter case tracker\n' "$GREEN" "$RESET"
        printf '  %s0%s  Exit\n\n' "$RED" "$RESET"

        read -r -p "F.B.I. > " choice || break

        case "$choice" in
            1) search_keyword ;;
            2) search_author ;;
            3) top_commenters ;;
            4) find_urls ;;
            5) export_all_comments ;;
            6) export_keyword_json ;;
            7) date_range_search ;;
            8) inspect_fields ;;
            9) count_comments ;;
           10) analyze_archive ;;
           11) combined_search ;;
           12) cross_video_report ;;
           13) audience_overlap_map ;;
           14) commenter_case_tracker ;;
            0)
                printf '%sGoodbye. Follow the breadcrumbs.%s\n' "$CYAN" "$RESET"
                break
                ;;
            *) warn "Invalid selection." ;;
        esac
    done
}

# --------------------------------------------------
# Startup
# --------------------------------------------------
check_dependencies

# Resolve the comments directory so relative input paths reliably place reports
# in the channel/archive parent, regardless of the current working directory.
if [[ -d "$COMMENTS_DIR" ]]; then
    COMMENTS_DIR="$(cd -- "$COMMENTS_DIR" && pwd -P)" || {
        error "Unable to resolve comments directory: $COMMENTS_DIR"
        exit 1
    }
fi

if [[ -z "$EXPORT_DIR" ]]; then
    EXPORT_DIR="$(dirname -- "$COMMENTS_DIR")/fbi-reports"
fi

banner

if ! need_files; then
    exit 1
fi

main_menu
