#!/usr/bin/env bash
# Fresh Forensics - GitHub Repository Privacy & Secret Audit
set -u
RESET='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'; RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'
SCRIPT_NAME="$(basename "$0")"
info(){ printf "${BLUE}${BOLD}[INFO]${RESET} %s\n" "$1"; }
warning(){ printf "${YELLOW}${BOLD}[!]${RESET} %s\n" "$1"; }
success(){ printf "${GREEN}${BOLD}[+]${RESET} %s\n" "$1"; }
error(){ printf "${RED}${BOLD}[ERROR]${RESET} %s\n" "$1" >&2; }
run_header(){ printf "\n${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n${YELLOW}${BOLD}%s${RESET}\n${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n" "$1"; }
banner(){ [[ -t 1 && -n "${TERM:-}" ]] && clear; printf "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗\n║              FRESH FORENSICS GIT AUDIT                     ║\n║        GitHub Privacy & Sensitive Data Scanner              ║\n╚══════════════════════════════════════════════════════════════╝${RESET}\n\n"; }
pause_screen(){ printf "\n${DIM}Press Enter to return to the menu...${RESET}"; read -r _; }
usage(){
    [[ -t 1 && -n "${TERM:-}" ]] && clear

    printf "${CYAN}${BOLD}\n"
    printf '%s\n' '  ____ _ _   _           _       _             _ _ _   '
    printf '%s\n' ' / ___/ | |_| |__  _   _| |__   / \  _   _  __| / | |_ '
    printf '%s\n' "| |  _| | __| '_ \\| | | | '_ \\ / _ \\| | | |/ _\` | | __|"
    printf '%s\n' ' | |_| | | |_| | | | |_| | |_) / ___ \ |_| | (_| | | |_ '
    printf '%s\n' ' \____|_|\__|_| |_|\__,_|_.__/_/   \_\__,_|\__,_|_|\__|'
    printf "${RESET}\n"

    printf "${MAGENTA}${BOLD}Fresh Forensics — GitHub Repository Privacy & Secret Audit${RESET}\n\n"

    printf "${WHITE}${BOLD}USAGE${RESET}\n"
    printf "  ${CYAN}%-40s${RESET} Open the interactive audit menu\n" "$SCRIPT_NAME REPO_PATH"
    printf "  ${CYAN}%-40s${RESET} Run a specific check (1-9 or A)\n" "$SCRIPT_NAME REPO_PATH CHECK"
    printf "  ${CYAN}%-40s${RESET} Audit all immediate child repositories\n" "$SCRIPT_NAME --all-repos DIR"
    printf "  ${CYAN}%-40s${RESET} Audit all repos with a specific check\n" "$SCRIPT_NAME --all-repos DIR CHECK"
    printf "  ${CYAN}%-40s${RESET} Display this help screen\n" "$SCRIPT_NAME --help"
    printf "\n"

    printf "${WHITE}${BOLD}AUDIT CHECKS${RESET}\n\n"
    printf "  ${CYAN}1)${RESET} 10-Digit Numbers — Current Files\n"
    printf "  ${CYAN}2)${RESET} 10-Digit Numbers — Git History\n"
    printf "  ${CYAN}3)${RESET} Credential Keywords — Current Files\n"
    printf "  ${CYAN}4)${RESET} Credential Keywords — Git History\n"
    printf "  ${CYAN}5)${RESET} Private Keys — Git History\n"
    printf "  ${CYAN}6)${RESET} Common API Token Patterns\n"
    printf "  ${CYAN}7)${RESET} Sensitive Filenames — Git History\n"
    printf "  ${CYAN}8)${RESET} Email Addresses — Current Files\n"
    printf "  ${CYAN}9)${RESET} Gitleaks Secret Scan\n"
    printf "  ${CYAN}A)${RESET} Run ALL Checks\n\n"

    printf "${WHITE}${BOLD}EXAMPLES${RESET}\n"
    printf "  ${DIM}$SCRIPT_NAME ~/GitHub/MyRepo${RESET}\n"
    printf "  ${DIM}$SCRIPT_NAME ~/GitHub/MyRepo 9${RESET}\n"
    printf "  ${DIM}$SCRIPT_NAME --all-repos ~/GitHub${RESET}\n"
    printf "  ${DIM}$SCRIPT_NAME --all-repos ~/GitHub A${RESET}\n\n"
}
check_gitleaks(){ if ! command -v gitleaks >/dev/null 2>&1; then warning 'Gitleaks is not installed or is not in PATH.'; printf 'Install Gitleaks: https://github.com/gitleaks/gitleaks#installing\n'; return 1; fi; }
check_history(){ local count; count="$(git rev-list --all 2>/dev/null | wc -l | tr -d ' ')"; if [[ "$count" == 0 ]]; then warning 'No commits were found in Git history.'; return 1; fi; info "Searching ${count} reachable commit(s)."; }
# Stream commits into git grep in bounded batches; no unsafe word splitting.
history_grep(){ local pattern="$1"; local -a commits=(); local commit; while IFS= read -r commit; do commits+=("$commit"); if (( ${#commits[@]} >= 100 )); then git grep -inE "$pattern" "${commits[@]}" -- 2>/dev/null || :; commits=(); fi; done < <(git rev-list --all); if (( ${#commits[@]} )); then git grep -inE "$pattern" "${commits[@]}" -- 2>/dev/null || :; fi; }
current_grep(){ grep -RniE --exclude-dir=.git -- "$1" . || :; }
scan_10_current(){ run_header '10-DIGIT NUMBERS — CURRENT FILES'; info 'Searching current files for possible unformatted 10-digit phone numbers.'; current_grep '\b[0-9]{10}\b'; }
scan_10_history(){ run_header '10-DIGIT NUMBERS — GIT HISTORY'; check_history || return; history_grep '\b[0-9]{10}\b'; }
scan_credentials_current(){ run_header 'CREDENTIAL KEYWORDS — CURRENT FILES'; info 'Terms: password, passwd, secret, api-key, token, credential'; current_grep 'password|passwd|secret|api[_-]?key|token|credential'; }
scan_credentials_history(){ run_header 'CREDENTIAL KEYWORDS — GIT HISTORY'; check_history || return; history_grep 'password|passwd|secret|api[_-]?key|token|credential'; }
scan_private_keys_history(){ run_header 'PRIVATE KEYS — GIT HISTORY'; check_history || return; history_grep 'BEGIN (RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY'; }
scan_api_tokens(){ run_header 'COMMON API TOKEN PATTERNS — CURRENT FILES'; warning 'Matches do not prove credentials are active.'; current_grep 'AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]+|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9_-]+'; }
scan_sensitive_filenames(){ run_header 'SENSITIVE FILENAMES — GIT HISTORY'; git log --all --name-only --pretty=format: 2>/dev/null | sort -u | grep -Ei '(\.env|\.pem|\.key|\.p12|\.pfx|credential|password|secret|config)' || :; }
scan_emails_current(){ run_header 'EMAIL ADDRESSES — CURRENT FILES'; current_grep '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'; }
scan_gitleaks(){ run_header 'GITLEAKS SECRET SCAN'; check_gitleaks || return 2; info 'Running Gitleaks against all Git refs with redaction.'; local rc=0; gitleaks git --log-opts='--all' --redact --verbose . || rc=$?; if (( rc == 1 )); then warning 'Gitleaks reported findings (exit status 1).'; elif (( rc != 0 )); then error "Gitleaks failed (exit status $rc)."; fi; return "$rc"; }
run_all(){ scan_10_current; scan_10_history; scan_credentials_current; scan_credentials_history; scan_private_keys_history; scan_api_tokens; scan_sensitive_filenames; scan_emails_current; local rc=0; scan_gitleaks || rc=$?; run_header 'AUDIT SUMMARY'; if (( rc == 2 )); then warning 'Other checks finished; Gitleaks was unavailable.'; elif (( rc != 0 )); then warning "Other checks finished; Gitleaks exited with status $rc."; else success 'All audit checks finished. Review any matches above.'; fi; return "$rc"; }
show_menu(){ banner; printf "${WHITE}${BOLD}Repository:${RESET} %s\n\n${WHITE}${BOLD}AUDIT OPTIONS${RESET}\n\n" "$PWD"; printf '  1) 10-Digit Numbers — Current Files\n  2) 10-Digit Numbers — Git History\n  3) Credential Keywords — Current Files\n  4) Credential Keywords — Git History\n  5) Private Keys — Git History\n  6) Common API Token Patterns\n  7) Sensitive Filenames — Git History\n  8) Email Addresses — Current Files\n  9) Gitleaks Secret Scan\n  A) Run ALL Checks\n  0) Exit\n\n'; printf "${YELLOW}Select an option: ${RESET}"; }
run_check(){ case "$1" in 1) scan_10_current;; 2) scan_10_history;; 3) scan_credentials_current;; 4) scan_credentials_history;; 5) scan_private_keys_history;; 6) scan_api_tokens;; 7) scan_sensitive_filenames;; 8) scan_emails_current;; 9) scan_gitleaks;; a|A) run_all;; *) error "Unknown check: $1"; return 64;; esac; }
is_repo_root(){ [[ -d "$1/.git" || -f "$1/.git" ]] && git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }
run_in_repo(){ local repo="$1" check="$2"; printf "\n${CYAN}${BOLD}Repository: %s${RESET}\n" "$repo"; (cd "$repo" && run_check "$check"); }
main(){ local mode=single target=. check='' repo rc=0 result;
case "${1:-}" in
    '') usage; return 0 ;;
    -h|--help) usage; return 0 ;;
    --all-repos)
        mode=batch; target="${2:-}"; check="${3:-A}"
        [[ -n "$target" && $# -le 3 ]] || { usage; return 64; }
        ;;
    *)
        target="$1"; check="${2:-}"
        [[ $# -le 2 ]] || { usage; return 64; }
        if [[ "$target" =~ ^[1-9aA]$ && $# -eq 1 ]]; then check="$target"; target=.; fi
        ;;
esac
[[ -d "$target" ]] || { error "Directory not found: $target"; return 1; }
target="$(cd "$target" && pwd -P)" || return 1
if [[ "$mode" == batch ]]; then
    local found=0
    for repo in "$target"/* "$target"/.[!.]* "$target"/..?*; do
        [[ -d "$repo" ]] || continue
        if is_repo_root "$repo"; then found=1; run_in_repo "$repo" "$check" || { result=$?; (( rc == 0 )) && rc=$result; }; fi
    done
    (( found )) || { warning "No immediate child Git repositories found in $target"; return 1; }
    return "$rc"
fi
if ! git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then error "Not inside a Git repository: $target"; return 1; fi
target="$(git -C "$target" rev-parse --show-toplevel)" || return 1
if [[ -n "$check" ]]; then run_in_repo "$target" "$check"; return $?; fi
cd "$target" || return 1
while true; do show_menu; read -r result || return 0; case "$result" in 0) success 'Exiting. Stay secure.'; return 0;; [1-9]|a|A) run_check "$result" || :; pause_screen;; *) warning 'Invalid option.';; esac; done
}
main "$@"
