# 🔬 JQ Walkthrough: Inspect Your JSON Data

Before searching a large archive, inspect a real record so you know which fields are available.

## 👀 1. View the First Comment Object

For the example file used in this walkthrough:

```bash
jq -c 'if type == "array" then .[0] else . end' \
  youtube-comments/comments/0-58NqzONK8.json | head -n 1 | jq .
````

💡 Replace the file path in this example (and any other examples) with the proper path to your .json file.

## 🗂️ 2. List the Fields in the First Record

```bash
jq -r 'if type == "array" then .[0] else . end | keys[]' \
  youtube-comments/comments/0-58NqzONK8.json | sort
```

This prints the keys present in that record. Other comments may have additional or missing fields.

## 🔍 3. Search for a Keyword Across Every File

```bash
jq -r '
  select((.text // "" | ascii_downcase) | contains("macchanger"))
  | "\(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

This reads each JSONL record, performs a case-insensitive literal search, and prints the author and matching text.

### 🧪 Search for Multiple Terms

To search for several terms using a regular expression:

```bash
jq -r '
  select((.text // "" | test("password|forensics|hashcat"; "i")))
  | "\(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

The terms separated by `|` are alternatives. Unlike `contains()`, `test()` interprets the search as a regular expression.

## 👤 4. List Unique Author Handles

```bash
jq -r '.author // empty' youtube-comments/comments/*.json |
  sort -fu
```

Count the distinct displayed author values:

```bash
jq -r '.author // empty' youtube-comments/comments/*.json |
  sort -fu | wc -l
```

⚠️ This counts distinct names/handles, not necessarily distinct people or accounts.

## 📊 5. Rank Frequent Commenters

```bash
jq -r '.author // empty' youtube-comments/comments/*.json |
  sort -f | uniq -ci | sort -rn | head -20
```

This is a quick overview. It groups by displayed author text, so different accounts with the same displayed name may be combined.

## 🆔 6. Search by Channel ID

```bash
jq -r '
  select(.channel == "UCpglThiKg2Tl2S25GXFr_pw")
  | "\(.author // "Unknown") | \(.time // "Unknown time") | \(.text // "")"
' youtube-comments/comments/*.json
```

Replace the channel ID with the identifier you want to search for.

## 🔗 7. Find Comments Containing URLs

```bash
jq -r '
  select((.text // "") | test("https?://|www\\."; "i"))
  | "\(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

### 🌐 Extract URL-Like Strings

```bash
jq -r '
  .text // empty
  | scan("https?://[^[:space:]]+|www\\.[^[:space:]]+")
' youtube-comments/comments/*.json | sort -fu
```

⚠️ These expressions find URL-like text; they do not verify whether a URL is safe, live, or malicious.

## 🔢 8. Count the Comment Records

For JSONL files, each nonblank line is normally one comment:

```bash
cat youtube-comments/comments/*.json | wc -l
```

This simple count assumes all matched files are JSONL and contain no blank lines. F.B.I.'s count function instead parses the records with `jq`.

## 📤 9. Export Comments to CSV

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

📌 F.B.I.'s built-in CSV export adds the source video ID, comment ID, parsed timestamp, and heart/reply flags.

## 📅 10. Filter by `time_parsed`

`time_parsed` is a Unix timestamp in seconds. Supply numeric start and end values:

```bash
jq -r --argjson start 1729000000 --argjson end 1730000000 '
  select((.time_parsed | type) == "number")
  | select(.time_parsed >= $start and .time_parsed <= $end)
  | "\(.time_parsed) | \(.author // "Unknown") | \(.text // "")"
' youtube-comments/comments/*.json
```

Replace the sample values with your desired timestamp range. F.B.I. provides a menu option for the same type of filter.

## 🛡️ Responsible Data Analysis

- 📁 Preserve an untouched copy of your original comment archive.
- 🔍 Verify record fields before running queries against a new data source.
- ⚠️ Treat search results as leads for further review, not proof of identity or wrongdoing.
- 🔐 Protect collected data and avoid publishing private investigation archives.

⬅️ Return to Data Analysis for an overview of F.B.I.'s analysis features.

➡️ See Data Acquisition for instructions on collecting a comment archive.
