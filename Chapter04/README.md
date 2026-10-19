# 🕵️ F.B.I. — Forensic Behavioral Intelligence

**F.B.I.** is a Bash and `jq` command-line utility for searching and analyzing YouTube comment archives collected with [`youtube-comment-downloader`](https://github.com/egbertbouman/youtube-comment-downloader). It provides an interactive menu for keyword searches, author lookups, frequent-commenter rankings, URL discovery, timestamp filtering, and CSV/JSONL exports.

> **Fresh Forensics | OSINT Workshop**
>
> Follow the breadcrumbs. Work with publicly accessible information responsibly, preserve context, and verify findings before drawing conclusions.

## ✨ Features

- Search comment text for a keyword or phrase (case-insensitive literal search)
- Search by displayed author name, `@handle`, or channel ID
- Rank frequent displayed author names
- Find comments containing URLs
- Filter records by `time_parsed` Unix timestamp
- Export all records to CSV, including the source video ID
- Export keyword matches to JSONL
- Inspect the fields in a sample comment record
- Count files and comment records
- Colorized terminal interface
- Supports JSON Lines (`.jsonl`) and `.json` files containing JSON objects or arrays

## ⚠️ Important: Understand the data format

The common output from `youtube-comment-downloader` is **JSON Lines (JSONL)**: each line is a separate JSON object. Your archive will look similar to:

```json
{"cid":"Ugwe7yWa-VeU6hHJd894AaABAg","text":"Hey I have a question","time":"2 years ago","author":"@ExampleUser","channel":"UC_example","votes":"1","replies":"","heart":true,"reply":false,"time_parsed":1729239350.252727}
{"cid":"Ugwe7yWa-VeU6hHJd894AaABAh","text":"Another comment","time":"1 year ago","author":"@AnotherUser","channel":"UC_example2","votes":"0","replies":"","heart":false,"reply":false,"time_parsed":1750000000}
```

The examples above are illustrative. Fields may be missing, empty, or represented as strings depending on the record.

### Common fields

| Field | Meaning |
|---|---|
| `cid` | Comment identifier |
| `text` | Comment body |
| `time` | Human-readable relative time |
| `author` | Displayed author name or handle |
| `channel` | YouTube channel identifier for the author |
| `votes` | Vote count, commonly stored as text |
| `replies` | Reply count, commonly stored as text |
| `photo` | URL for the author's avatar, when present |
| `heart` | Whether the creator hearted the comment |
| `reply` | Whether the record is marked as a reply |
| `time_parsed` | Numeric timestamp, useful for date filtering |

`author` is not a guaranteed unique account identifier. When present, `channel` is generally a better field for distinguishing accounts. A relative value such as `"2 years ago"` is not a precise timestamp; use `time_parsed` for chronological filters.

## 🧰 Requirements

- Linux
- Bash
- `jq`
- Standard command-line tools such as `find`, `sort`, `uniq`, `awk`, and `date`
- Comment files downloaded by `youtube-comment-downloader` or compatible JSON/JSONL files

## 📦 Installation

### 1. Install `jq`

On Ubuntu, Debian, Kali Linux, or Parrot OS:

```bash
apt update
apt install jq
```

If you are not running as root, use `sudo apt update` and `sudo apt install jq`.

Confirm the installation:

```bash
jq --version
```

### 2. Place the script in your project

Save the script as `F.B.I.sh` in your repository, then make it executable:

```bash
chmod +x F.B.I.sh
```

### 3. Check your comment archive

By default, F.B.I. expects this directory layout:

```text
your-project/
├── F.B.I.sh
└── youtube-comments/
    └── comments/
        ├── 0-58NqzONK8.json
        ├── A2UDhfw0eFU.json
        └── ...
```

This matches the default output directory in the downloader script. Each filename is the YouTube video ID followed by `.json`.

If your files are stored elsewhere, set `COMMENTS_DIR` when launching F.B.I.:

```bash
COMMENTS_DIR="/path/to/comment/files" ./F.B.I.sh
```

## 🚀 Launch F.B.I.

From the directory containing the script and `youtube-comments/`:

```bash
./F.B.I.sh
```

You will see an interactive menu. Enter the number for the action you want, then follow the prompts. Exports are written to `fbi-reports/` by default.

To change the export directory:

```bash
EXPORT_DIR="reports" ./F.B.I.sh
```

To disable ANSI colors, set `NO_COLOR`:

```bash
NO_COLOR=1 ./F.B.I.sh
```

## 🔬 Walkthrough: Inspect your JSON data with `jq`

Before searching a large archive, inspect a real record so you know which fields are available.

### 1. View the first comment object

For the example file used in this walkthrough:

```bash
jq -c 'if type == "array" then .[0] else . end' \
  youtube-comments/comments/0-58NqzONK8.json | head -n 1 | jq .
```

Because your downloader writes JSONL, the first input object is usually the first comment. The conditional also accommodates a file containing a JSON array.

### 2. List the fields in the first record

```bash
jq -r 'if type == "array" then .[0] else . end | keys[]' \
  youtube-comments/comments/0-58NqzONK8.json | sort
```

This prints the keys present in that record. Other comments may have additional or missing fields.

### 3. Search for a keyword across every file

```bash
jq -r '
  select((.text // "" | ascii_downcase) | contains("macchanger"))
  | "\(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

This reads each JSONL record, performs a case-insensitive literal search, and prints the author and matching text.

To search for several terms using a regular expression:

```bash
jq -r '
  select((.text // "" | test("password|forensics|hashcat"; "i")))
  | "\(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

The terms separated by `|` are alternatives. Unlike `contains()`, `test()` interprets the search as a regular expression.

### 4. List unique author handles

```bash
jq -r '.author // empty' youtube-comments/comments/*.json |
  sort -fu
```

Count the distinct displayed author values:

```bash
jq -r '.author // empty' youtube-comments/comments/*.json |
  sort -fu | wc -l
```

This counts distinct names/handles, not necessarily distinct people or accounts.

### 5. Rank frequent commenters

```bash
jq -r '.author // empty' youtube-comments/comments/*.json |
  sort -f | uniq -ci | sort -rn | head -20
```

This is a quick overview. It groups by displayed author text, so different accounts with the same displayed name may be combined.

### 6. Search by channel ID

```bash
jq -r '
  select(.channel == "UCpglThiKg2Tl2S25GXFr_pw")
  | "\(.author // "Unknown") | \(.time // "Unknown time") | \(.text // "")"
' youtube-comments/comments/*.json
```

Replace the channel ID with the identifier you want to search for.

### 7. Find comments containing URLs

```bash
jq -r '
  select((.text // "") | test("https?://|www\\."; "i"))
  | "\(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

Extract URL-like strings from comments:

```bash
jq -r '
  .text // empty
  | scan("https?://[^[:space:]]+|www\\.[^[:space:]]+")
' youtube-comments/comments/*.json | sort -fu
```

These expressions find URL-like text; they do not verify whether a URL is safe, live, or malicious.

### 8. Count the comment records

For JSONL files, each nonblank line is normally one comment:

```bash
cat youtube-comments/comments/*.json | wc -l
```

This simple count assumes all matched files are JSONL and contain no blank lines. F.B.I.'s count function instead parses the records with `jq`.

### 9. Export comments to CSV

```bash
jq -r '
  [
    .author // "",
    .channel // "",
    .time // "",
    .votes // "",
    .replies // "",
    .text // ""
  ] | @csv
' youtube-comments/comments/*.json > comments-report.csv
```

This creates a CSV with author, channel ID, relative time, votes, replies, and text. The `@csv` filter handles commas and quotation marks in fields.

F.B.I.'s built-in CSV export adds the source video ID, comment ID, parsed timestamp, and heart/reply flags.

### 10. Filter by `time_parsed`

`time_parsed` is a Unix timestamp in seconds. Supply numeric start and end values:

```bash
jq -r --argjson start 1729000000 --argjson end 1730000000 '
  select((.time_parsed | type) == "number")
  | select(.time_parsed >= $start and .time_parsed <= $end)
  | "\(.time_parsed) | \(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

Replace the sample values with your desired timestamp range. F.B.I. provides a menu option for the same type of filter.

## 🧭 F.B.I. menu reference

| Menu | Function |
|---|---|
| `1` | Search comment text for a keyword or phrase |
| `2` | Search displayed author name or channel ID |
| `3` | Rank frequent commenters |
| `4` | Find comments containing URLs |
| `5` | Export all records to CSV |
| `6` | Export keyword matches to JSONL |
| `7` | Filter by Unix timestamp range |
| `8` | Inspect a sample record and its fields |
| `9` | Count comment records and source files |
| `0` | Exit |

## 📁 Output files

F.B.I. creates the `fbi-reports/` directory when an export is requested.

- `comments_YYYYMMDD_HHMMSS.csv` — all records in spreadsheet-friendly format
- `keyword_matches_YYYYMMDD_HHMMSS.jsonl` — matching records with their source video IDs

The source video ID is derived from the comment file's filename. Keep the original files unchanged if you need to preserve your collection as evidence.

## 🧪 Troubleshooting

### `jq: command not found`

Install `jq` using the instructions above.

### No comment files found

Check the directory:

```bash
ls -lh youtube-comments/comments/
```

If the archive is elsewhere, set `COMMENTS_DIR` when launching the script.

### No results returned

- Try a shorter keyword.
- Check spelling and punctuation.
- Confirm the target file is inside the configured directory.
- Inspect a sample record and make sure the field is named `text`, `author`, or `channel` as expected.

### Large archives

Searching every file can take time because the utility scans the archive for each query. For very large collections, consider indexing records into SQLite or creating a normalized search dataset.

## ⚖️ Responsible OSINT use

Use F.B.I. for lawful research, analysis of public information, and authorized investigations. A comment's presence does not independently verify a person's identity, location, intent, or conduct. Display names can change, multiple accounts can share names, and comment text can be misleading. Preserve source context, document collection times and methods, and corroborate important findings with independent evidence.

## ☕ Support This Project

If **Forensic Behavioral Intelligence** helped your YouTube OSINT, consider supporting continued development of this project:

<p align="center">
  <a href="https://www.buymeacoffee.com/dfreshZ" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
</p>

---


