# 📥 Data Acquisition

`ytcExtractor.sh` is the acquisition stage of **🕵️ F.B.I. — Forensic Behavioral Intelligence**. It gathers available comments from videos published on a YouTube channel and organizes them into files that can be examined by `FBI.sh`.

## ⚙️ How it works

1. 🔗 Supply a YouTube channel URL or `@handle`.
2. 🎥 The script uses `yt-dlp` to enumerate the channel's videos.
3. 💬 It uses `youtube-comment-downloader` to retrieve comments available to that downloader.
4. 📁 Comment files and tracking lists are saved in a channel-specific output directory.
5. 🔎 Run `F.B.I.sh` against the resulting archive for analysis.

## 📋 Requirements

- 🐧 Linux or a compatible Unix-like environment
- 🖥️ Bash
- 🐍 Python 3, `python3-venv`, and `python3-pip`
- 🌐 Internet access
- 📦 `yt-dlp` and `youtube-comment-downloader`, installed into the script's Python virtual environment

The script's automatic system-package installation supports `apt-get`-based distributions, including Ubuntu, Debian, Kali Linux, and Parrot OS.

## 🚀 Start the extractor

From the repository directory:

```
chmod +x ytcExtractor.sh
./ytcExtractor.sh
```

🔗 Enter a channel URL or `@handle` when prompted. You can also provide it as an argument:

```
./ytcExtractor.sh https://www.youtube.com/@ExampleChannel
```

The script opens an interactive menu. Its main actions are:

| Option | Action |
| --- | --- |
| `1` | 🔍 Check system and Python-package dependencies |
| `2` | 📦 Install system dependencies using `apt-get` |
| `3` | 🐍 Create or update the virtual environment and install Python packages |
| `4` | ℹ️ Display package details and the environment activation command |
| `5` | 🛠️ Set up dependencies and extract comments |
| `6` | 💬 Extract comments using the existing environment |
| `7` | 🔄 Change the selected channel |
| `8` | ❓ Display help |
| `0` | 🚪 Exit |

For a first run, choose **Do everything** and follow any prompts. The script installs Python packages inside its virtual environment rather than system-wide.

## 📂 Output

The default output directory is based on the selected channel's handle or URL. The structure is similar to:

```
ExampleChannel/
├── comments/
│   ├── VIDEO_ID_1.json
│   └── VIDEO_ID_2.json
├── video_ids.txt
└── failed_videos.txt
```

- 💬 `comments/` contains comment data files, named using their source video IDs.
- 🎥 `video_ids.txt` records the enumerated video IDs.
- ⚠️ `failed_videos.txt` records video IDs whose comment download failed during the run.

Existing non-empty comment files are skipped, which makes it easier to resume an archive without downloading those files again. Review `failed_videos.txt` after a run if some downloads did not succeed.

## 🔐 What is and is not collected

The extractor collects comments available to `youtube-comment-downloader`. It does **not** access private YouTube Studio data.

In particular, do not expect this workflow to retrieve comments held for review, deleted comments, or other comments that are unavailable through the downloader's accessible interface. A missing comment does not establish why it is absent.

⚠️ Availability can vary by video, channel, and changes to YouTube or the downloader. Treat the archive as a collection of available records, not a guaranteed complete record of every comment ever posted.

## 🧰 Troubleshooting

### 🐍 The virtual environment cannot be created

Make sure Python's venv support is installed. On an apt-based system:

```
apt update
apt install python3 python3-venv python3-pip
```

🔑 If you are not running as root, prefix the commands with `sudo`.

### ⚠️ A video fails to download

Check `failed_videos.txt`, verify that the video is accessible, and retry later. Some videos or comments may not be available to the downloader.

### 🔎 No video IDs are found

Check the channel URL or `@handle`, and make sure the channel's videos are accessible. The extractor uses the channel's `/videos` page to enumerate uploads.

## 🛡️ Evidence-handling suggestions

- 📁 Keep an untouched copy of the acquired archive.
- 📝 Record the channel URL, collection date, and any errors encountered.
- ⚠️ Do not assume the archive is complete.
- 🔒 Protect collected data and avoid committing private investigation archives to a public repository.

➡️ Continue to Data Analysis to examine the archive with F.B.I.
