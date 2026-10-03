# 🔎 Chapter 02: Hunting Google Data with OSINT

This chapter focuses on using Linux based terminal tools to investigate publicly accessible Google related information. Starting with a publicly available Google document, we follow the breadcrumbs through document metadata, Google identifiers, email addresses, Google Drive, Gaia information, and other publicly available data.

The goal is to demonstrate how seemingly small pieces of information can lead to additional identifiers and investigative opportunities.

---

# 📚 Chapter Information

**Chapter:** 02

**Title:** 🔎 Hunting Google Data with OSINT | Fresh Forensics Live! 💣

**Focus:** Google OSINT and Linux terminal workflows

**Primary Tools:**

- 🔎 xeuledoc
- 🕷️ GHunt
- 🦊 GHunt Companion
- 🔬 exiftool
- 🗜️ unzip
- 📝 odt2txt
- 🖥️ LibreOffice
- 🐍 Python
- 🐚 Linux shell

---

# 📄 Part 1: Investigating a Google Document

We begin with a publicly accessible Google spreadsheet.

The premise is simple. We have discovered a Google document somewhere during an OSINT investigation and want to determine what information can be extracted from it.

### 🐍 Create a Python Environment

Create a dedicated directory and Python virtual environment for `xeuledoc`.

```bash
mkdir xeuledoc
cd xeuledoc

python3 -m venv xeuledocEnvironment
source xeuledocEnvironment/bin/activate
```

### 📦 Install xeuledoc

Install the tool inside the virtual environment.

```bash
pip install xeuledoc
```

### 🔎 Run xeuledoc

Point `xeuledoc` at the Google document.

```bash
xeuledoc "https://docs.google.com/spreadsheets/d/1jvR93FUJ14Sa1jQx16wWeJUynOn8ZmuI-nxZLw3ESgE/edit?usp=sharing"
```

The tool can extract information associated with the Google document including:

```text
Document ID
Creation date
Last edit date
Public permissions
Owner information
Name
Email address
Google ID
```

The important takeaway is that a document that appears to contain nothing more than a spreadsheet can potentially provide additional identifiers that can be used to continue an investigation.

---

# 📥 Part 2: Download the Document

After identifying the document, download a local copy so it can be examined using standard Linux forensic and document analysis tools.

The downloaded file in this workflow is an OpenDocument spreadsheet:

```text
file.ods
```

Once the document is local, we can move away from Google specific tools and start examining the actual file.

---

# 🔬 Part 3: Examine Document Metadata

### 🧰 exiftool

`exiftool` is one of the first tools to reach for when examining a document.

```bash
exiftool file.ods
```

Depending on the document, metadata can include:

- 👤 Creator or author
- 📅 Creation date
- 📅 Modification date
- 📄 Document title
- 📝 Subject
- ⚙️ Generator or application
- 💻 Editing software
- 🧬 Embedded metadata

For a more comprehensive examination:

```bash
exiftool -a -u -g1 file.ods
```

The additional options allow us to expose a larger amount of available metadata.

---

# 🗜️ Part 4: Examine the ODS Container

An `.ods` file is essentially a ZIP archive containing XML documents and other resources.

We can examine the structure directly from the terminal.

### 📦 List the Contents

```bash
unzip -l file.ods
```

A typical OpenDocument spreadsheet contains files such as:

```text
content.xml
meta.xml
settings.xml
styles.xml
META-INF/manifest.xml
Thumbnails/thumbnail.png
```

The `meta.xml` file is particularly interesting from a forensic perspective.

### 🔎 Extract meta.xml

```bash
unzip -p file.ods meta.xml
```

This can expose information such as:

```xml
<meta:initial-creator>...</meta:initial-creator>
<meta:creation-date>...</meta:creation-date>
<meta:generator>...</meta:generator>
```

### 📄 Extract content.xml

The actual spreadsheet content is contained within `content.xml`.

```bash
unzip -p file.ods content.xml
```

This allows us to examine the underlying XML rather than relying exclusively on the spreadsheet application.

---

# 📝 Part 5: Extract Text From the Spreadsheet

### 🧪 odt2txt

Despite its name, `odt2txt` can be useful for extracting readable text from OpenDocument files.

```bash
odt2txt file.ods
```

The output can also be redirected into a text file:

```bash
odt2txt file.ods > output.txt
```

This provides a simple way to turn the contents into something that can be searched and processed using standard command line tools.

---

# 🖥️ Part 6: Convert the Document With LibreOffice

LibreOffice can be used from the terminal in headless mode to convert the document into other formats.

### 📊 Convert to CSV

```bash
libreoffice --headless --convert-to csv file.ods
```

### 📈 Convert to XLSX

```bash
libreoffice --headless --convert-to xlsx file.ods
```

### 📄 Convert to PDF

```bash
libreoffice --headless --convert-to pdf file.ods
```

This gives us several different ways to examine the same source material.

---

# 🧪 Fresh Forensics Document Workflow

A basic document examination can therefore be reduced to:

```bash
file file.ods

exiftool -a -u -g1 file.ods

unzip -l file.ods

unzip -p file.ods meta.xml

unzip -p file.ods content.xml

odt2txt file.ods > output.txt

libreoffice --headless --convert-to csv file.ods
```

The important concept is that we are not relying on a single tool.

We are examining the document from several different perspectives:

```text
File
 │
 ├── Metadata
 │
 ├── ZIP structure
 │
 ├── XML metadata
 │
 ├── XML content
 │
 ├── Extracted text
 │
 └── Converted formats
```

---

# 📧 Part 7: Follow the Email Address

The document investigation can produce an email address associated with the Google account or document owner.

This gives us another breadcrumb to follow.

Instead of stopping at the document, we can use the newly discovered email address as the starting point for the next phase of the investigation.

This is where GHunt enters the workflow.

---

# 🕷️ Part 8: Installing GHunt

GHunt is a collection of tools for investigating Google related information.

The version used during this livestream was:

```text
GHunt 2.3.4
Spider Edition
```

GHunt provides several investigation modules:

```text
login
email
gaia
drive
geolocate
spiderdal
```

These allow us to investigate different types of Google related identifiers.

---

## 🐍 Create the GHunt Environment

Create a dedicated environment for the GHunt installation.

```bash
mkdir ghuntEnvironment
cd ghuntEnvironment

python3 -m venv ghuntEnvironment
source ghuntEnvironment/bin/activate
```

Install the required system libraries:

```bash
apt install -y libjpeg-dev zlib1g-dev
```

Install `pipx`:

```bash
pip3 install pipx
```

Make sure the pipx path is configured:

```bash
pipx ensurepath
```

Install GHunt:

```bash
pipx install ghunt
```

---

# 🔐 Part 9: Authenticate GHunt

Start the GHunt authentication process:

```bash
ghunt login
```

GHunt provides several authentication methods.

The login menu includes:

```text
[1] Companion
[2] Paste base64 encoded authentication
[3] Enter the oauth_token
[4] Enter the master token
```

We want to choose 2:

```text
Choice => 2
Paste the encoded credentials here => <PASTE-BASE64-ENCODED-STRING-HERE>

🔑 A master token has been generated for your account and saved in the credentials
file, please keep it safe as if it were your password, because it gives access to a
lot of Google services, and with that, your personal information.
Master token services access : mail, android, cl, youtube, multilogin, memento
Generating cookies and osids...

[+] New token for chrome has been generated
[+] Cookies and osids generated !
```

For this workflow we use the GHunt Companion browser extension.

---

# 🦊 Part 10: GHunt Companion

GHunt Companion is a browser extension that assists with obtaining the required authentication information from a logged in Google account.

The project is available here:

```text
https://github.com/mxrch/ghunt_companion
```

The extension is available for browsers including:

```text
Firefox
Chrome
Edge
Opera
```

The Companion approach makes the authentication process significantly easier because it can populate the required information from the logged in browser session.

---

# 🩹 Part 11: GHunt Compatibility Patch

During the installation and authentication process, GHunt may encounter an error related to Google's response data.

The error encountered during the livestream was:

```text
KeyError: 'container'
```

The problem occurs in GHunt's `coverPhoto` parser when it expects:

```python
cover_photo_data["metadata"]["container"]
```

but Google's response does not contain the expected `container` value.

The compatibility fix is to safely retrieve the value and only add the cover photo when a container exists.

The patch used during the livestream was:

```bash
python3 - <<'PY'
from pathlib import Path

p = Path.home() / ".local/share/pipx/venvs/ghunt/lib/python3.14/site-packages/ghunt/parsers/people.py"
s = p.read_text()

old = '''                self.coverPhotos[cover_photo_data["metadata"]["container"]] = person_cover_photo'''

new = '''                container = cover_photo_data.get("metadata", {}).get("container")
                if container:
                    self.coverPhotos[container] = person_cover_photo'''

if old not in s:
    raise SystemExit("Target line not found; GHunt may have changed.")

p.write_text(s.replace(old, new))
print("Patch applied successfully.")
PY
```

The important part of the patch is:

```python
container = cover_photo_data.get("metadata", {}).get("container")

if container:
    self.coverPhotos[container] = person_cover_photo
```

Instead of assuming that `metadata.container` always exists, the parser now checks whether the value is actually present.

---

To apply the patch, run this command:

```bash
sed -i 's/self.coverPhotos\[cover_photo_data\["metadata"\]\["container"\]\] = person_cover_photo/self.coverPhotos[cover_photo_data.get("metadata", {}).get("container", "unknown")] = person_cover_photo/' \
~/.local/share/pipx/venvs/ghunt/lib/python3.14/site-packages/ghunt/parsers/people.py
```

Then Verify the patch with this command:

```bash
grep -n "coverPhotos" ~/.local/share/pipx/venvs/ghunt/lib/python3.14/site-packages/ghunt/parsers/people.py
```

# 📧 Part 12: Investigating an Email Address

Once GHunt authentication is configured, an email address can be investigated using:

```bash
ghunt email YOUR_TEST_EMAIL
```

The email investigation can reveal information associated with the Google account depending on what information is publicly accessible and what Google's current responses provide.

This is where the earlier document investigation becomes important.

We started with:

```text
Google Document
```

which produced:

```text
Owner
Email Address
Google ID
```

The email address then becomes the next breadcrumb.

---

# 🆔 Part 13: Investigating a Gaia ID

If a Gaia ID is discovered during the investigation, GHunt can investigate it directly.

```bash
ghunt gaia GAIA_ID
```

A Google Gaia ID can act as another identifier connecting information associated with a Google account.

---

# 📁 Part 14: Investigating Google Drive

GHunt can also investigate Google Drive resources.

```bash
ghunt drive DRIVE_ID
```

This allows us to continue following Google related identifiers discovered during the investigation.

---

# 🌎 Part 15: Geolocating a BSSID

GHunt also includes a geolocation function:

```bash
ghunt geolocate BSSID
```

This functionality is based around wireless network identifiers rather than Google documents or email addresses.

---

# 🕷️ Part 16: SpiderDAL

GHunt also includes the `spiderdal` command.

```bash
ghunt spiderdal
```

SpiderDAL is designed to find assets associated with Digital Asset Links.

---

# 🧰 GHunt Command Reference

The main GHunt command structure used in this chapter is:

```bash
ghunt login
ghunt email YOUR_TEST_EMAIL
ghunt gaia GAIA_ID
ghunt drive DRIVE_ID
ghunt geolocate BSSID
ghunt spiderdal
```

To see the available options:

```bash
ghunt -h
```

The version used during this livestream displayed:

```text
GHunt 2.3.4
Spider Edition
```

---

# 🧠 Following the Breadcrumbs

The most important lesson from this investigation is the workflow.

We do not necessarily begin with an email address, username, or Google account.

We might begin with something as simple as a publicly accessible document.

From that document we can potentially discover:

```text
📄 Google Document
       │
       ▼
👤 Owner
       │
       ▼
📧 Email Address
       │
       ▼
🆔 Google Identifier
       │
       ▼
🕷️ GHunt
       │
       ├── Email
       ├── Gaia
       ├── Drive
       ├── Geolocation
       └── Digital Assets
```

Each piece of information becomes another potential starting point.

---

# 🔍 The Fresh Forensics Method

The objective is not simply to run as many OSINT tools as possible.

The objective is to understand how information connects.

A document can lead to an owner.

An owner can lead to an email address.

An email address can lead to Google identifiers.

A Google identifier can lead to additional publicly accessible information.

The investigation becomes a process of following those breadcrumbs and documenting what each one reveals.

---

# ⚠️ Responsible Use

The techniques demonstrated in this workshop are intended for educational purposes and authorized OSINT investigations.

Only investigate accounts, documents, repositories, systems, and other resources that you are authorized to examine or that are legitimately publicly accessible.

When demonstrating account based functionality, use test accounts or accounts you own whenever possible.

---

## 🧭 Follow The Breadcrumbs

**Every document has a story.**

**Every identifier can become a breadcrumb.**

**Follow the trail. 🔎**
```
