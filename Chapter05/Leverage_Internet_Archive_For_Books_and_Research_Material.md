# 📚 Internet Archive OSINT: Finding, Searching, and Acquiring Books and Research Material

## 🕵️ Introduction

The Internet Archive is much more than a digital library. It is an enormous collection of archived books, research papers, government publications, historical documents, technical manuals, and other material that can be valuable during OSINT investigations.

In this walkthrough, we're using Linux and the Internet Archive command-line interface (`ia`) to discover, search, inspect, and acquire archived material.

We'll start by locating an archived copy of *Extreme Privacy: What It Takes to Disappear* by Michael Bazzell.

Then we'll expand our investigation by searching the Internet Archive using titles, authors, subjects, and full-text search queries.

We'll also demonstrate how a broad search for hacking-related material led us to the FBI Handbook of Forensic Services (2019), along with several other interesting historical documents.

The goal is to demonstrate how much information can be discovered using nothing more than a Linux terminal.

---

## 🛠️ 1. Install the Internet Archive CLI

If you haven't already installed the Internet Archive command-line tool:

```bash
apt install internetarchive
```

Verify that it's available:

```bash
ia --version
```

The `ia` utility allows us to interact with Internet Archive directly from the Linux terminal without relying on a web browser.

---

# 🔎 PART ONE: FINDING BOOKS AND PUBLICATIONS

## 2. Search the Internet Archive for a Specific Book

Let's start with Michael Bazzell and his book *Extreme Privacy*.

We can use the Internet Archive's full-text search functionality to look for references to the author's name and book title:

```bash
ia search -F '"Michael Bazzell" "Extreme Privacy"'
```

The `-F` option searches indexed full text rather than limiting the search to item metadata.

Among the results, we identified an item with this identifier:

```text
extPrivDownload
```

The search results included references to *Extreme Privacy: What It Takes to Disappear, Second Edition*.

This demonstrates an important distinction: we can search the contents of indexed documents, not just their filenames or titles.

## 3. Search by Title, Author, and Subject

We aren't limited to searching for a particular book.

The Internet Archive supports metadata searches using fields such as `title`, `creator`, and `subject`.

### 📖 Search by title

```bash
ia search 'mediatype:texts AND title:Linux'
```

### 👤 Search by author

```bash
ia search 'mediatype:texts AND creator:"Michael Bazzell"'
```

### 🔐 Search by subject

```bash
ia search 'mediatype:texts AND subject:hacking'
```

### 🛡️ Search computer security material

```bash
ia search 'mediatype:texts AND subject:"computer security"'
```

### 🕵️ Search surveillance publications

```bash
ia search 'mediatype:texts AND subject:surveillance'
```

The `mediatype:texts` condition limits the results to Internet Archive text items.

The other conditions narrow the search to the subject or publication information we're interested in.

These searches can uncover books, research papers, government publications, technical documentation, and other archived material.

## 4. Search the Full Text of Archived Documents

One of the most useful features is full-text searching.

For example:

```bash
ia search -F '"digital forensics"'
```

Search for references to wireless security:

```bash
ia search -F '"wireless security"'
```

Search for references to GrapheneOS:

```bash
ia search -F 'GrapheneOS'
```

Search for a particular phrase:

```bash
ia search -F '"penetration testing"'
```

Unlike metadata searches, full-text searches can find documents containing your search terms even when those terms aren't included in the item's title or subject metadata.

This is particularly useful when researching older publications or discovering material you wouldn't necessarily find through a conventional title search.

Remember that full-text search depends on the document being indexed and searchable by Internet Archive.

---

# 🧠 PART TWO: DISCOVERING MATERIAL THROUGH OSINT SEARCHES

## 5. Search for Hacking-Related Publications

Let's take our research beyond a specific author or book.

I ran the following command:

```bash
ia search 'mediatype:texts AND subject:hacking'
```

This returned several interesting archive identifiers.

Among the results were:

```text
using-wi-fi-to-see-through-walls

fbi_-_handbook_of_forensic_services_2019-20250402_174339

fbi_admits_it_controlled_tor_servers_behind_mass_malware_attack_2013-20250402_174339

fbi_taps_cell_phone_mic_as_eavesdropping_tool_-_cnet_2006-20250402_174339

fbi_-_pia_ftp_servers_2017-20250402_174339

gray-hat-hacking-the-ethical-hackers-handbook-fourth-edition-by-daniel-regalado-
```

Notice that we weren't searching for the FBI handbook specifically.

We searched for the subject `hacking`, and the Internet Archive returned a collection of potentially relevant publications.

This is where archive research becomes interesting.

A single broad search can reveal documents, articles, research material, and historical publications that lead to entirely different investigative paths.

### More searches worth exploring

**Wireless security:**

```bash
ia search 'mediatype:texts AND subject:wireless'
```

**Digital forensics:**

```bash
ia search 'mediatype:texts AND subject:"digital forensics"'
```

**Reverse engineering:**

```bash
ia search 'mediatype:texts AND subject:"reverse engineering"'
```

**Social engineering:**

```bash
ia search 'mediatype:texts AND subject:"social engineering"'
```

**Penetration testing:**

```bash
ia search 'mediatype:texts AND subject:"penetration testing"'
```

**OSINT:**

```bash
ia search 'mediatype:texts AND subject:OSINT'
```

You can also save search results for later investigation.

For example:

```bash
ia search 'mediatype:texts AND subject:hacking' -i > hacking_books.txt
```

This creates a text file containing the matching item identifiers.

You can review the results:

```bash
cat hacking_books.txt
```

Or search through them:

```bash
rg -i 'fbi|forensic|wireless|hacking' hacking_books.txt
```

---

# 🏛️ PART THREE: INVESTIGATING THE FBI HANDBOOK

## 6. Inspect an Interesting Search Result

One of the results caught my attention:

```text
fbi_-_handbook_of_forensic_services_2019-20250402_174339
```

This is an archived copy of the FBI Handbook of Forensic Services (2019).

Instead of immediately downloading it, let's investigate the archive item.

Retrieve its metadata:

```bash
ia metadata fbi_-_handbook_of_forensic_services_2019-20250402_174339
```

This provides information about the archived item, including its available files and associated metadata.

Next, list the contents:

```bash
ia list fbi_-_handbook_of_forensic_services_2019-20250402_174339
```

Our results included:

```text
FBI_-_Handbook_of_Forensic_Services_(2019).pdf

fbi_-_handbook_of_forensic_services_2019-20250402_174339_archive.torrent

fbi_-_handbook_of_forensic_services_2019-20250402_174339_files.xml

fbi_-_handbook_of_forensic_services_2019-20250402_174339_meta.sqlite

fbi_-_handbook_of_forensic_services_2019-20250402_174339_meta.xml
```

We can see that the actual handbook is available as a PDF, accompanied by several Internet Archive metadata files.

## 7. Download the FBI Handbook

Once we've confirmed the file is available for download:

```bash
ia download fbi_-_handbook_of_forensic_services_2019-20250402_174339 --glob="*.pdf"
```

The `--glob` option limits the download to matching PDF files rather than retrieving every file associated with the archive item.

## 8. Examine the Downloaded Document

Identify the file:

```bash
file FBI_-_Handbook_of_Forensic_Services_\(2019\).pdf
```

Inspect its internal PDF metadata:

```bash
pdfinfo FBI_-_Handbook_of_Forensic_Services_\(2019\).pdf
```

We can also extract searchable text using Poppler:

```bash
pdftotext -layout FBI_-_Handbook_of_Forensic_Services_\(2019\).pdf FBI_Handbook.txt
```

Now we can search the handbook using ripgrep:

```bash
rg -in 'fingerprints|DNA|firearms|digital evidence|trace evidence' FBI_Handbook.txt
```

Or search for a specific forensic discipline:

```bash
rg -in 'digital evidence' FBI_Handbook.txt
```

This demonstrates another useful workflow: discover a document through Internet Archive metadata, acquire it, extract its text, and then use Linux tools to investigate its contents.

---

# 📋 PART FOUR: INSPECTING AND ACQUIRING OTHER ARCHIVED BOOKS

## 9. Inspect the Extreme Privacy Archive Item

Let's return to our original discovery:

```bash
ia metadata extPrivDownload
```

We can use `jq` to extract information about the PDF without dumping the entire metadata response to the terminal:

```bash
ia metadata extPrivDownload | jq '.files[] | select(.name == "Extreme Privacy - Michael Bazzell.pdf") | {name, size, format}'
```

Our output identifies:

```json
{
  "name": "Extreme Privacy - Michael Bazzell.pdf",
  "size": "40322014",
  "format": "Text PDF"
}
```

That's approximately 38.5 MB.

Next, list the available files:

```bash
ia list extPrivDownload
```

The archive contains several formats and derivatives, including:

```text
Extreme Privacy - Michael Bazzell.pdf
Extreme Privacy - Michael Bazzell_djvu.txt
Extreme Privacy - Michael Bazzell_djvu.xml
Extreme Privacy - Michael Bazzell_hocr.html
Extreme Privacy - Michael Bazzell_hocr_searchtext.txt.gz
Extreme Privacy - Michael Bazzell_jp2.zip
extPrivDownload_meta.xml
extPrivDownload_meta.sqlite
```

Some of these files are particularly interesting from a digital forensics perspective:

- `djvu.txt` contains OCR-extracted text.
- `djvu.xml` contains structured OCR data.
- `hocr.html` contains OCR information with page positioning.
- `hocr_searchtext.txt.gz` contains compressed searchable OCR text.
- `jp2.zip` contains processed page images.

The PDF is the primary document we're interested in.

## 10. Preview the Download

Before retrieving the PDF, use the dry-run option:

```bash
ia download extPrivDownload "Extreme Privacy - Michael Bazzell.pdf" --dry-run
```

This displays the download URL without retrieving the file.

The output identifies the resource:

```text
https://archive.org/download/extPrivDownload/Extreme%20Privacy%20-%20Michael%20Bazzell.pdf
```

## 11. Download the PDF

Where the item is freely downloadable or otherwise authorized for your use:

```bash
ia download extPrivDownload "Extreme Privacy - Michael Bazzell.pdf"
```

The Internet Archive CLI will display download progress.

## 12. Examine the Downloaded PDF

Identify the document:

```bash
file "Extreme Privacy - Michael Bazzell.pdf"
```

Inspect its metadata:

```bash
pdfinfo "Extreme Privacy - Michael Bazzell.pdf"
```

Our examination returned:

```text
Creator:         Adobe Acrobat 20.12
Producer:        Adobe Acrobat Pro DC 20 Paper Capture Plug-in
CreationDate:    Tue Sep  8 17:03:44 2020 EDT
ModDate:         Tue Sep  8 17:20:06 2020 EDT
Pages:           577
Encrypted:       no
File size:       40322014 bytes
PDF version:     1.6
```

These properties tell us about the PDF itself, but they do not independently establish the authenticity or publication edition of the archived copy.

---

# 🔐 PART FIVE: DOCUMENTATION AND INTEGRITY

## 13. Calculate a SHA-256 Hash

Whenever we're acquiring material for research, it's good practice to document the original file.

Calculate its SHA-256 hash:

```bash
sha256sum "Extreme Privacy - Michael Bazzell.pdf"
```

Save the result:

```bash
sha256sum "Extreme Privacy - Michael Bazzell.pdf" > SHA256SUMS
```

Later, verify the document:

```bash
sha256sum -c SHA256SUMS
```

This provides a simple way to determine whether the file has changed since the hash was calculated.

## 14. Useful Internet Archive Search Commands

Here are some additional searches worth keeping in your OSINT toolkit.

| Search objective | Command |
|---|---|
| Search hacking publications | `ia search 'mediatype:texts AND subject:hacking'` |
| Search Linux books | `ia search 'mediatype:texts AND title:Linux'` |
| Search an author | `ia search 'mediatype:texts AND creator:"Michael Bazzell"'` |
| Search computer security | `ia search 'mediatype:texts AND subject:"computer security"'` |
| Search digital forensics text | `ia search -F '"digital forensics"'` |
| Search GrapheneOS references | `ia search -F 'GrapheneOS'` |
| Search wireless security | `ia search 'mediatype:texts AND subject:wireless'` |

For more information about the available search syntax and download options, consult the official documentation:

https://internetarchive.readthedocs.io/en/stable/cli.html

---

# 🎯 CONCLUSION

We started with a search for a specific book by Michael Bazzell, but expanded the investigation into something much more interesting.

Using the Internet Archive CLI, we demonstrated how to:

- 🔎 Search for books by title, author, and subject.
- 📖 Search the full text of indexed publications.
- 🕵️ Discover unexpected research material through broad subject searches.
- 🏛️ Locate the FBI Handbook of Forensic Services (2019).
- 📂 Inspect archive metadata and available file formats.
- ⬇️ Acquire accessible publications.
- 🔬 Extract and search document contents using Linux.
- 🔐 Preserve file integrity using SHA-256 hashes.

The important takeaway is that you don't have to know exactly what you're looking for before beginning an OSINT investigation.

Sometimes a broad search leads to an unexpected document, which leads to another discovery, and eventually to an entirely new research direction.

The Internet Archive gives us an enormous collection of historical material to explore, and Linux gives us the tools to investigate it efficiently.
