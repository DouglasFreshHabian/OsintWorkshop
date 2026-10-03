# 🔎 Chapter 01: From YouTube to a Full OSINT Investigation

This chapter lays the foundation for a multi-chapter OSINT workshop built around a simulated investigation.

Our target is **Fresh**, a fictionalized investigation subject whose online presence begins with a YouTube video. From that initial piece of media, we follow publicly accessible breadcrumbs through videos, usernames, social media accounts, livestreams, GitHub repositories, commit history, email addresses, and other identifiers.

The goal is not simply to run a collection of OSINT tools. The goal is to understand how one discovery can become the starting point for the next phase of an investigation.

---

# 📚 Chapter Information

**Chapter:** 01

**Title:** 🔎 From YouTube to a Full OSINT Investigation | Fresh Forensics Live! 💣

**Focus:** Linux-based OSINT, username enumeration, video analysis, GitHub investigation, and investigative pivoting

**Primary Tools:**

- 🎬 VideoToolkit
- 🐍 Python
- 📺 yt-dlp
- 🔎 Sherlock
- 🕵️ Maigret
- 🦅 Blackbird
- 📡 Streamlink
- 🐙 GitHub
- 📥 cloneRepo
- 🧬 Git
- 🔐 Gitleaks
- 🔎 G1thubAudit
- 🕷️ SpiderFoot
- 🐚 Linux shell

---

# ⚠️ Workshop Premise

For this workshop, **Fresh** is the target of a simulated OSINT investigation being conducted by an FBI agent.

The investigation begins with a publicly available YouTube video.

From there, we follow the breadcrumbs.

```text
YouTube Video
      │
      ▼
VideoToolkit
      │
      ├── Video
      ├── Frames
      ├── Subtitles
      ├── Audio
      └── Metadata
      │
      ▼
freshforensics
      │
      ├── Sherlock
      ├── Maigret
      └── Blackbird
      │
      ▼
Twitch
      │
      └── Streamlink
      │
      ▼
GitHub
      │
      └── cloneRepo
              │
              ▼
        GitHub Repositories
              │
              ├── Git
              ├── Commit History
              ├── Gitleaks
              └── G1thubAudit
                       │
                       ▼
                New Identifiers
                       │
                       ▼
                  SpiderFoot
                       │
                       ▼
              Follow the Breadcrumbs
```

The investigation is intentionally iterative.

Every new identifier becomes a possible pivot.

---

# 🎬 Part 1: Start With a YouTube Video

The investigation starts with a YouTube video associated with our target.

Before looking for usernames, accounts, or email addresses, we first examine the source material itself.

A video can contain much more information than what is immediately visible on screen.

Depending on the source, we may be able to obtain:

- 🎥 The original video
- 📝 Subtitles or captions
- 🖼️ Individual video frames
- 🔊 Audio
- 🧬 Video metadata
- 📺 Available YouTube formats
- 🔗 Additional URLs or identifiers visible in the video

For this workshop, we use the custom **VideoToolkit** script.

---

# 🧰 Part 2: VideoToolkit

`VideoToolkit` is a custom Fresh Forensics Bash script for performing basic video analysis and working with YouTube media.

The toolkit provides options for:

```text
Play video
Convert video to MP4
Extract video frames
Extract audio as MP3
Rotate video
Show video information
yt-dlp tools
```

The script also provides a dedicated yt-dlp menu for examining available formats and subtitles and downloading English auto-generated subtitles.

### 📦 Install Dependencies

The basic environment requires FFmpeg and Python tooling.

```bash
sudo apt update
sudo apt install jq ffmpeg -y
sudo apt install python python3-pip python3-venv
```

Make the script executable:

```bash
chmod +x VideoToolkit.sh
```

Run it:

```bash
./VideoToolkit.sh
```

With no argument, the toolkit opens its help screen.

---

# 📺 Part 3: Examine the YouTube Source

Before downloading anything, use the yt-dlp tools to inspect the source.

Run:

```bash
./VideoToolkit.sh --yt-dlp
```

The yt-dlp toolkit provides an option to list available video and audio formats.

Select:

```text
1) List available video/audio formats
```

Then provide the YouTube URL.

This lets us examine what media formats are available before selecting what we want to acquire.

---

# 📝 Part 4: Examine Available Subtitles

Subtitles can be an important source of investigative information.

They may contain:

- Names
- Usernames
- Email addresses
- URLs
- Locations
- Organizations
- Technical terminology
- Statements that are difficult to identify by watching the video alone

From the yt-dlp menu, select:

```text
2) List available subtitles/captions
```

Enter the YouTube URL.

If English auto-generated subtitles are available, the toolkit can download them as an SRT file.

Select:

```text
3) Download English auto-generated subtitles
```

The underlying workflow is:

```bash
yt-dlp     --write-auto-subs     --sub-langs "en"     --convert-subs srt     "VIDEO_URL"
```

Now we have another artifact that can be searched and examined independently of the video.

---

# 🖼️ Part 5: Extract Video Frames

A video can contain useful information that exists for only a few seconds.

A username might appear on screen.

A terminal window might expose a hostname.

A website might briefly appear.

A location might be visible in the background.

A frame-extraction workflow allows us to turn the video into a collection of still images that can be examined individually.

Run:

```bash
./VideoToolkit.sh video.mp4
```

Select:

```text
3) Extract video frames
```

The toolkit extracts frames at 10 frames per second.

The frames are stored in a directory similar to:

```text
video_frames/
```

This allows us to inspect individual frames rather than repeatedly scrubbing through the video.

---

# 🔊 Part 6: Extract the Audio

The audio can also be separated from the video.

Select:

```text
4) Extract audio as MP3
```

The toolkit uses FFmpeg to create an MP3 copy of the audio.

This can be useful when the next phase of an investigation requires audio analysis or transcription.

The important concept is that the video is now being treated as several different evidence sources:

```text
Video
 │
 ├── Frames
 ├── Audio
 ├── Subtitles
 └── Metadata
```

Each artifact can reveal something different.

---

# 🧬 Part 7: Examine Video Information

VideoToolkit also provides:

```text
6) Show video information
```

This uses `ffprobe` to display information about the media file.

You can also use FFmpeg tools directly:

```bash
ffprobe video.mp4
```

This provides another perspective on the acquired media.

---

# 🔄 Part 8: The First Major Pivot — Username

During our examination of the YouTube channel, we identify the channel name:

```text
Fresh Forensics
```

This gives us our first username pivot:

```text
freshforensics
```

This is where the investigation changes direction.

Instead of continuing to examine only the video, we now ask:

> Where else does this username appear?

We can test the username against multiple public services.

This is one of the fundamental ideas behind username OSINT.

---

# 🔎 Part 9: Sherlock

Sherlock searches for usernames across online services.

Clone the project:

```bash
git clone https://github.com/sherlock-project/sherlock
cd sherlock
```

Create a dedicated Python environment:

```bash
python3 -m venv SherlockEnvironment
source SherlockEnvironment/bin/activate
```

Install Sherlock:

```bash
pip install .
```

Now search for our first username:

```bash
sherlock freshforensics
```

The results give us potential accounts to investigate.

---

# 🕵️ Part 10: Maigret

Sherlock is not the only username-enumeration tool available to us.

Maigret provides another way to search for a username across online services.

The important concept is **cross-validation**.

A username appearing on one site does not automatically prove that it belongs to the same person.

We want multiple indicators.

For example:

```text
Username
   │
   ├── Same profile image
   ├── Same biography
   ├── Same website
   ├── Same linked account
   └── Same public email
```

Run Maigret against:

```text
freshforensics
```

Record potentially relevant results and treat them as leads rather than confirmed identities.

---

# 🦅 Part 11: Blackbird

Blackbird provides another username and email-oriented OSINT workflow.

Clone the repository:

```bash
git clone https://github.com/antoniaci/blackbird.git
cd blackbird
```

Create a Python environment:

```bash
python3 -m venv blackbirdEnvironment
source blackbirdEnvironment/bin/activate
```

Activate it:

```bash
source blackbirdEnvironment/bin/activate
```

Search the username:

```bash
python blackbird.py -u freshforensics
```

We can also investigate an email address when one has been legitimately discovered during the investigation:

```bash
python blackbird.py -email freshforensicsllc@tuta.com
```

The important workflow is:

```text
YouTube
   │
   ▼
freshforensics
   │
   ├── Sherlock
   ├── Maigret
   └── Blackbird
```

Each tool can potentially produce another breadcrumb.

---

# 📡 Part 12: Discovering Twitch

Our username investigation leads us to a Twitch presence associated with:

```text
freshforensics
```

Now we have another potential source of publicly accessible information:

```text
YouTube
   │
   └── freshforensics
          │
          └── Twitch
```

Live video introduces a different type of OSINT opportunity.

Instead of analyzing only previously published content, we can observe and capture a publicly accessible livestream.

---

# 📺 Part 13: Streamlink

`streamlink` is a command-line tool for accessing streams from supported platforms.

Create a dedicated directory:

```bash
mkdir Streamlink
cd Streamlink
```

Create a Python virtual environment:

```bash
python3 -m venv streamlinkEnvironment
source streamlinkEnvironment/bin/activate
```

Install Streamlink:

```bash
pip install streamlink
```

Open the Twitch stream at the best available quality:

```bash
streamlink https://www.twitch.tv/freshforensics best
```

You can also save the stream to a local file:

```bash
streamlink https://www.twitch.tv/freshforensics best -o freshforensic.twitch
```

This creates another local artifact that can be examined using the same video-analysis concepts introduced earlier.

The investigation is beginning to loop back on itself:

```text
YouTube
   │
   ▼
Video Analysis
   │
   ▼
Username
   │
   ▼
Twitch
   │
   ▼
Stream Capture
   │
   ▼
Video Analysis
```

---

# 🐙 Part 14: Discovering GitHub

The username investigation also identifies a GitHub presence.

The target has a GitHub account containing approximately 33 repositories.

This creates an entirely new investigative surface.

A GitHub account can expose publicly accessible:

- Repository names
- Source code
- Documentation
- Configuration files
- Commit history
- Author information
- Email addresses
- File names
- Development patterns
- Historical data

The important point is that a repository is not necessarily just the files currently visible on GitHub.

Git preserves history.

---

# 📥 Part 15: Clone the Repositories With cloneRepo

Manually cloning dozens of repositories is repetitive.

For this workshop, we use the custom `cloneRepo.sh` script.

Make it executable:

```bash
chmod +x cloneRepo.sh
```

Run it:

```bash
./cloneRepo.sh
```

The script prompts for the GitHub username.

When the `-a` or `--all` option is used, the script can automatically clone all repositories owned by that account.

```bash
./cloneRepo.s --all
```

or:

```bash
./cloneRepo.sh -a
```

The script retrieves the repository list through the GitHub API and clones the repositories locally.

We now have a local copy of the target's publicly accessible repositories.

---

# 🗂️ Part 16: Begin the GitHub Investigation

Move into the directory containing the cloned repositories.

```bash
cd ~/GitHub
```

The exact directory will depend on where you chose to store the repositories.

At this point, we can begin examining them individually.

For a repository:

```bash
cd RepositoryName
```

Start with basic Git information:

```bash
git status
```

Examine the remote:

```bash
git remote -v
```

View the commit history:

```bash
git log --oneline --all
```

The `--all` option is important because we are interested in more than just the current branch.

---

# 🧬 Part 17: Git History

One of the most important concepts in this chapter is that deleting something from the current version of a repository does not necessarily mean it disappeared from Git history.

A developer might accidentally commit:

```text
.env
password
API key
private key
configuration file
email address
phone number
```

and remove it later.

The current working tree may look clean while the historical commit still contains the information.

This is why the investigation needs to examine both:

```text
Current Files
      │
      └── Current State

Git History
      │
      └── Historical State
```

---

# 🔐 Part 18: Gitleaks

Gitleaks is designed to detect secrets and credentials in Git repositories.

First check whether it is installed:

```bash
gitleaks version
```

If it is not installed, install it using the current installation instructions provided by the Gitleaks project.

Then run it against the repository.

The exact command can depend on the installed Gitleaks version, so check:

```bash
gitleaks --help
```

and:

```bash
gitleaks git --help
```

The goal is to search the repository and its Git history for known secret patterns.

---

# 🔎 Part 19: G1thubAudit

The investigation becomes significantly more efficient with another custom Fresh Forensics script:

```text
G1thubAudit
```

This script was created specifically to audit Git repositories for potentially sensitive information.

Make it executable:

```bash
chmod +x G1thubAudit.sh
```

Display the help screen:

```bash
./G1thubAudit.sh --help
```

The script can audit a specific repository:

```bash
./G1thubAudit ~/GitHub/RepositoryName
```

It can also run a specific check:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 9
```

The available checks include:

```text
1) 10-Digit Numbers — Current Files
2) 10-Digit Numbers — Git History
3) Credential Keywords — Current Files
4) Credential Keywords — Git History
5) Private Keys — Git History
6) Common API Token Patterns
7) Sensitive Filenames — Git History
8) Email Addresses — Current Files
9) Gitleaks Secret Scan
A) Run ALL Checks
```

---

# 📱 Part 20: Searching for Phone Numbers

The first checks search for possible 10-digit numbers.

Current files:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 1
```

Git history:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 2
```

These are pattern searches.

A match is not automatically proof that the number is a person's telephone number.

It could be:

```text
Documentation
Test data
A serial number
A timestamp
A random numeric value
A legitimate phone number
```

Every finding needs to be examined in context.

---

# 🔑 Part 21: Searching for Credentials

Search current files for credential-related keywords:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 3
```

Search Git history:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 4
```

The audit searches for terms such as:

```text
password
passwd
secret
api-key
token
credential
```

Again, a keyword match is a lead, not proof that a credential exists.

---

# 🔐 Part 22: Private Keys

Private keys deserve special attention because accidentally committed private-key material can have serious consequences.

Search Git history:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 5
```

The audit looks for common private-key headers including:

```text
RSA
DSA
EC
OPENSSH
PGP
```

A finding should be examined carefully and handled as sensitive information.

Do not publish discovered credentials or private keys as part of the workshop.

---

# 🪪 Part 23: API Token Patterns

The audit can also search current files for common API-token patterns:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 6
```

The script includes patterns associated with several common token formats.

The script itself warns:

```text
Pattern matches are not proof that credentials are active.
```

This distinction is important.

OSINT is about collecting and correlating information, not automatically assuming that every pattern represents a valid credential.

---

# 📁 Part 24: Sensitive Filenames

Sometimes the filename itself is the clue.

Search Git history:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 7
```

The audit looks for filenames associated with potentially sensitive material, including:

```text
.env
.pem
.key
.p12
.pfx
credential
password
secret
config
```

A historical filename can tell us where to look next even if the file is no longer present in the current version.

---

# 📧 Part 25: Email Addresses

Search the current repository for email addresses:

```bash
./G1thubAudit.sh ~/GitHub/RepositoryName 8
```

An email address can become a major investigative pivot.

For example:

```text
GitHub Repository
      │
      ▼
Email Address
      │
      ├── Username searches
      ├── Search engines
      ├── Public profiles
      └── Other OSINT tools
```

This is where the investigation starts generating new identifiers that were not available when we began.

---

# 🕷️ Part 26: Bring the New Information Into SpiderFoot

At this point, the investigation has produced multiple identifiers.

We may have discovered:

```text
YouTube channel
Username
Twitch account
GitHub account
Repositories
Commit history
Email addresses
Potential phone numbers
Potential usernames
Potential domains
```

Rather than treating each discovery as the end of an investigation, we can feed relevant identifiers into another OSINT platform.

This is where **SpiderFoot** becomes useful.

The basic idea is:

```text
             YouTube
                │
                ▼
             Username
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
    Twitch   GitHub   Other Accounts
       │        │
       │        ▼
       │    Email / Domain
       │        │
       └────────┼────────┘
                ▼
           SpiderFoot
                │
                ▼
       Additional Pivots
```

SpiderFoot becomes another layer in the investigation rather than a replacement for the investigation itself.

---

# 🔁 Part 27: Repeat the Process

The investigation does not necessarily have a fixed endpoint.

Suppose SpiderFoot produces:

```text
New Username
```

We can return to:

```text
Sherlock
Maigret
Blackbird
```

Suppose we discover:

```text
New GitHub Repository
```

We can return to:

```text
cloneRepo
Git
Gitleaks
G1thubAudit
```

Suppose we discover:

```text
New Video
```

We can return to:

```text
VideoToolkit
```

This produces a repeating OSINT cycle:

```text
       ┌─────────────────────────────┐
       │                             │
       ▼                             │
   Discovery                         │
       │                             │
       ▼                             │
   Identifier                        │
       │                             │
       ▼                             │
   Enumeration                       │
       │                             │
       ▼                             │
   New Account / Artifact             │
       │                             │
       ▼                             │
   Analysis                          │
       │                             │
       ▼                             │
   New Identifier ───────────────────┘
```

The investigation grows as new breadcrumbs are discovered.

---

# 🧠 Fresh Forensics Investigation Method

The tools are important, but the workflow is more important.

We began with:

```text
YouTube Video
```

Then:

```text
YouTube
   │
   ▼
Video Analysis
   │
   ▼
Username
   │
   ▼
Account Enumeration
   │
   ▼
Twitch
   │
   ▼
GitHub
   │
   ▼
Repositories
   │
   ▼
Git History
   │
   ▼
Sensitive Information
   │
   ▼
New Identifiers
   │
   ▼
SpiderFoot
   │
   ▼
More Breadcrumbs
```

The investigation works because each stage produces information that can be used to begin the next stage.

That is the central concept of this workshop.

---

# 🧭 Document Your Findings

A real OSINT investigation should be documented as it progresses.

For each discovery, record:

```text
Source
Date / Time
Identifier
Where it was discovered
Tool used
URL
Relevant evidence
Confidence
Next pivot
```

For example:

```text
Source: YouTube
Identifier: freshforensics
Tool: VideoToolkit / manual review
Finding: Username associated with target channel
Next pivot: Username enumeration
```

This prevents the investigation from becoming a collection of disconnected screenshots and terminal output.

It also makes it easier to reproduce the investigation later.

---

# ⚠️ Responsible Use

The techniques demonstrated in this workshop are intended for educational purposes and authorized OSINT investigations.

Only investigate accounts, videos, repositories, systems, and other resources that you are authorized to examine or that are legitimately publicly accessible.

Do not attempt to bypass authentication, defeat privacy controls, access private accounts, or obtain information that is not publicly available.

When a tool produces a potential match, treat it as a lead until it can be independently corroborated.

Do not publish passwords, private keys, active credentials, private personal information, or other sensitive material discovered during an investigation.

For workshop exercises, use the provided fictional or authorized targets and test data whenever possible.

---


