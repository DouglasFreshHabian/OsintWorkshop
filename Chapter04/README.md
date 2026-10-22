# 🕵️ F.B.I. — Forensic Behavioral Intelligence

**F.B.I. (Forensic Behavioral Intelligence)** is a Bash-based toolkit for acquiring, organizing, searching, and analyzing YouTube comment archives. Built for the **Fresh Forensics OSINT Workshop**, it brings data acquisition and behavioral analysis together in one practical workflow.

> 🧭 Follow the breadcrumbs. Preserve context. Verify findings before drawing conclusions.

## 🔎 The F.B.I. Workflow

F.B.I. is organized into two stages:

```text
📺 YouTube Channel
        │
        ▼
📥 ytcExtractor.sh
   DATA ACQUISITION
        │
        ▼
🗂️ Comment Archive
        │
        ▼
🕵️ FBI.sh
    DATA ANALYSIS
        │
        ▼
📊 Reports • 🔗 URL Findings • 🧩 Activity Patterns • 📝 Case Notes
```

### 📥 Stage 1 — Data Acquisition

`ytcExtractor.sh` gathers comments available from videos on a YouTube channel you provide at runtime.

It uses:

- 🎞️ [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) to enumerate channel videos
- 💬 [`youtube-comment-downloader`](https://github.com/egbertbouman/youtube-comment-downloader) to retrieve available comments
- 🐍 Python 3 and a virtual environment to manage its Python packages

**Quick start:**

```bash
chmod +x ytcExtractor.sh
./ytcExtractor.sh
```

Follow the prompts to enter a channel URL or `@handle`. You can also supply it directly:

```bash
./ytcExtractor.sh https://www.youtube.com/@ExampleChannel
```

The interactive menu includes dependency checks, system-package installation on supported `apt-get` distributions, Python virtual-environment setup, package details, and comment extraction.

📚 **More details:** [Data Acquisition Guide](Docs/DATA_ACQUISITION.md)

### 🧠 Stage 2 — Data Analysis

`FBI.sh` analyzes the collected archive through an interactive, colorized command-line interface.

Key capabilities include:

- 🔍 Search comments by keyword or phrase
- 👤 Search by displayed author name, handle, or channel ID
- 📈 Rank commenters and compare activity across videos
- 🔗 Find comments containing URLs
- 🗓️ Filter records by date range
- 🧾 Inspect archive fields and count records
- 📤 Export records and search results to supported formats
- 🧩 Explore audience overlap and shared participation across videos
- 🗺️ Generate an interactive relationship map
- 🗃️ Track commenters and annotate selected comments with case notes

F.B.I. helps surface patterns and leads for further review. It does not automatically prove identity, relationships, intent, or wrongdoing.

**Quick start:**

```bash
chmod +x FBI.sh
./FBI.sh
```

The default report directory is `fbi-reports/`. If your archive is stored elsewhere, set the comments directory when launching the script:

```bash
COMMENTS_DIR="/path/to/comment/files" ./FBI.sh
```

📚 **More details:** [Data Analysis Guide](Docs/DATA_ANALYSIS.md)

## 🧰 Requirements

- 🐧 Linux or a compatible Unix-like environment
- 🖥️ Bash
- 🧰 `jq` for data analysis
- 🐍 Python 3, `python3-venv`, and `python3-pip` for acquisition
- 🌐 Internet access to retrieve available video and comment data

The extractor's automatic system-package installation supports `apt-get`-based distributions such as Ubuntu, Debian, Kali Linux, and Parrot OS. Python packages are installed inside the extractor's virtual environment.

## 🗂️ Repository Layout

```text
F.B.I/
├── README.md
├── ytcExtractor.sh              # 📥 Stage 1: Data acquisition
├── FBI.sh                     # 🧠 Stage 2: Data analysis
└── Docs/
    ├── DATA_ACQUISITION.md      # 📥 Extractor guide
    └── DATA_ANALYSIS.md         # 🧠 Analysis guide
    └── JQ_COMMANDS.md         # 🔬 Walkthrough
```

Your downloaded archive and generated reports can be stored separately from the repository. **🚫 Do not commit private investigation data, large comment archives, or sensitive reports to a public repository.**

## ⚠️ Important Collection Limitations

The extractor retrieves comments available to `youtube-comment-downloader`. It does **not** access private data in YouTube Studio and should not be expected to retrieve comments held for review, deleted comments, or other content unavailable through the downloader's accessible interface.

A missing comment does not establish why it is absent. Availability can vary by video, channel, and changes to YouTube or the downloader.

## ⚖️ Responsible Use

Use F.B.I. for lawful research, authorized investigations, and responsible analysis of publicly accessible information.

- 🧩 A pattern is a lead, not a conclusion.
- 👤 A displayed name does not independently verify a person's identity.
- 🔗 A URL found in a comment is not proof that it is safe, malicious, or controlled by the commenter.
- 🧾 Preserve original files and document collection methods and dates.
- 🔐 Protect personal data and corroborate important findings with independent evidence.

## 🛠️ Built With

- 🐚 Bash
- 🧰 [`jq`](https://jqlang.org/)
- 🎞️ [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)
- 💬 [`youtube-comment-downloader`](https://github.com/egbertbouman/youtube-comment-downloader)
- 🐍 Python 3

## ☕ Support This Project

If **Forensic Behavioral Intelligence** helped your YouTube OSINT, consider supporting continued development of this project:

<p align="center">
  <a href="https://www.buymeacoffee.com/dfreshZ" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
</p>

---

