# 🔎 Data Analysis

`FBI.sh` is the analysis stage of **F.B.I. — Forensic Behavioral Intelligence**. It searches and organizes the comment archive produced during data acquisition, helping you examine comment content, account activity, cross-video participation, and potential leads for further review.

⚠️ F.B.I. is an investigative aid. Its output can help direct attention, but it does not independently establish identity, intent, or wrongdoing.

## 📋 Requirements

- 🐧 Linux or a compatible Unix-like environment
- 💻 Bash
- 📦 `jq`
- 📂 A comment archive containing compatible JSON or JSONL records

On Ubuntu, Debian, Kali Linux, or Parrot OS, install `jq` with:

```
apt update
apt install jq
```

Use `sudo` before these commands if you are not running as root.

## 🚀 Start F.B.I.

From the repository directory:

```
chmod +x FBI.sh
./FBI.sh
```

F.B.I. opens an interactive, colorized menu. Follow the prompts for the action you want to perform. The default report directory is `fbi-reports/`.

If the comment archive is stored somewhere other than the script's default location, set `COMMENTS_DIR` when launching the script:

```
COMMENTS_DIR="/path/to/comment/files" ./FBI.sh
```

To change the report destination:

```
EXPORT_DIR="reports" ./FBI.sh
```

To disable ANSI colors:

```
NO_COLOR=1 ./FBI.sh
```

## 🛠️ Main analysis capabilities

The menu provides tools for exploring an archive, including:

- 🔍 **Keyword and phrase search** — find comment text containing a term or phrase.
- 👤 **Author search** — search by displayed author name, handle, or channel ID.
- 📊 **Commenter rankings** — identify accounts with repeated comment activity.
- 🔗 **URL discovery** — find comments containing URLs and review URL-like strings.
- 📅 **Date filtering** — narrow results using parsed timestamps.
- 🗂️ **Archive inspection** — inspect sample records and fields, and count source files and comment records.
- 📤 **Exports** — save selected records or matches in supported formats such as CSV and JSONL.
- 🎯 **Combined filters** — narrow a search using multiple criteria.
- 🎥 **Cross-video activity reports** — compare commenter activity across videos.
- 🕸️ **Audience overlap and relationship mapping** — explore shared participation among selected repeat commenters.
- 📝 **Commenter case tracking** — save notes and categories for selected commenters and comments.

Exact prompts and available actions are shown in the interactive menu. The archive format and fields can vary, so inspect a sample record when working with a new data source.

## 🧾 Understanding the records

The acquisition workflow commonly produces JSON Lines (JSONL): each nonblank line is a separate JSON object. Depending on the source, records may include fields such as:

| Field | Typical meaning |
| --- | --- |
| `cid` | 🆔 Comment identifier |
| `text` | 💬 Comment text |
| `author` | 👤 Displayed author name or handle |
| `channel` | 📺 Author's YouTube channel identifier, when available |
| `time` | 🕒 Human-readable relative time |
| `time_parsed` | ⏱️ Parsed Unix timestamp, when available |
| `votes` | 👍 Vote count, often represented as text |
| `replies` | ↩️ Reply count, often represented as text |
| `heart` | ❤️ Whether the creator hearted the comment, when provided |
| `reply` | 💭 Whether the record is marked as a reply, when provided |

Not every record contains every field, and field types may differ. A displayed name is not a unique identifier. When present, a channel ID is generally more useful for distinguishing accounts than the displayed name alone.

## ⚖️ Reading results responsibly

- 📊 Repeated comments indicate activity in the archive; they do not necessarily represent a person's broader behavior.
- 👥 Similar displayed names do not prove two records belong to the same account.
- 🔗 Shared participation in videos is an observed overlap, not proof of a relationship between people.
- 🌐 URLs are leads for review, not proof that a destination is safe, malicious, or controlled by the commenter.
- ⚠️ Missing records do not prove that a comment was deleted or held for review.
- 🛡️ Preserve original data and corroborate important findings with independent sources.

## 📁 Reports and case notes

Exports and analysis outputs are written to `fbi-reports/` by default, unless configured otherwise. The Commenter Case Tracker stores case data in this report area, including `commenter_cases.json` when that feature is used.

Treat reports and case notes as derived working material. Keep the original acquisition archive unchanged, protect investigation data, and clearly distinguish observed facts from hypotheses or interpretations.

## 🧰 Troubleshooting

### 📦 `jq: command not found`

Install `jq` using the instructions above.

### 📂 No comment files are found

Check the configured archive path and confirm that the directory contains comment files:

```
ls -lh /path/to/comment/files/
```

If necessary, launch F.B.I. with `COMMENTS_DIR` set to the correct directory.

### 🔍 Searches return no results

Try a shorter search term, check spelling and punctuation, and inspect a sample record to confirm that the expected fields are present.

⬅️ Continue to Data Acquisition for instructions on collecting an archive.

<!-- 
    Fresh Forensics, LLC | Douglas Fresh Habian | 2026
    github.com/DouglasFreshHabian
    freshforensicsllc@tuta.com
-->

