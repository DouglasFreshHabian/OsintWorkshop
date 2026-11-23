# 🕵️ OSINT Walkthrough: Acquiring LIUsers.7z Using Internet Archive CLI

## 🎯 Introduction

In this walkthrough, we're exploring how to use the Internet Archive command-line interface (`ia`) to discover, inspect, acquire, and examine an archived dataset.

Our target is **LIUsers.7z**, an approximately 1.7 GB dataset identified as the MIT LI Data Set for User ID Analytic Research.

We'll use Linux command-line tools to investigate the archive, inspect its metadata, download the original file, verify its integrity, and extract its contents for further OSINT research.

The objective is to demonstrate how publicly accessible archives can become useful sources of information during digital investigations and personal exposure assessments.

---

## 🔎 1. Inspect the Archived Item

Before downloading anything, let's investigate what Internet Archive knows about this particular item.

Retrieve its metadata:

```bash
ia metadata LIUsers.7z
```

This displays information about the archived item without downloading the 1.7 GB dataset.

Next, inspect the files associated with the archive:

```bash
ia list LIUsers.7z
```

We can also save the metadata locally for documentation and future reference:

```bash
ia metadata LIUsers.7z > LIUsers_metadata.json
```

Having a local metadata record is useful when documenting where a dataset originated and preserving information about the archived item.

## 📂 2. Examine the Available Files

Let's get a cleaner listing of the filenames, sizes, and formats:

```bash
ia list LIUsers.7z --columns name,size,format
```

This helps identify the original uploaded files and any additional files associated with the archive.

You can also inspect the available metadata formats:

```bash
ia metadata --formats LIUsers.7z
```

Remember that an Internet Archive item can contain multiple files, including original uploads, metadata, and automatically generated derivatives.

Understanding what is available before downloading can save time and bandwidth.

---

## 💾 3. Prepare Your OSINT Storage Directory

Since we're maintaining a dedicated drive for our OSINT research, let's create a directory specifically for this dataset.

```bash
mkdir -p /mnt/osint/archives/LIUsers
```

Move into the directory:

```bash
cd /mnt/osint/archives/LIUsers
```

Keeping datasets separated makes it easier to organize investigations, preserve original files, and manage extracted material.

---

## ⬇️ 4. Preview and Download the Archive

Before downloading a large archive, it's good practice to preview what the command will retrieve.

```bash
ia download LIUsers.7z --dry-run
```

If the output confirms that we're retrieving the expected archive, initiate the download:

```bash
ia download LIUsers.7z --destdir=/mnt/osint/archives/LIUsers
```

The Internet Archive CLI supports downloading entire items, individual files, and selected file formats.

📚 Official documentation:

https://internetarchive.readthedocs.io/en/stable/cli.html

---

## 🔐 5. Verify the Downloaded Archive

Once the download finishes, let's verify what we received.

Check the file size:

```bash
ls -lh /mnt/osint/archives/LIUsers/
```

Identify the file type:

```bash
file LIUsers.7z
```

Test the archive for integrity:

```bash
7z t LIUsers.7z
```

List the contents without extracting anything:

```bash
7z l LIUsers.7z
```

These checks help establish that the downloaded file is readable and that the archive can be inspected before extraction.

For additional forensic documentation, calculate a SHA-256 hash:

```bash
sha256sum LIUsers.7z > SHA256SUMS
```

This gives us a checksum that can later be used to verify that the original downloaded archive has not changed.

---

## 📦 6. Extract the Dataset

Now that we've inspected and tested the archive, let's extract its contents.

```bash
7z x LIUsers.7z
```

The `x` option extracts files while preserving their directory structure.

After extraction, inspect the resulting files:

```bash
ls -lah
```

If the archive contains multiple files or directories, we can investigate their structure using:

```bash
find . -type f
```

At this point, we have moved from acquiring an archived dataset to examining its contents.

---

## 🔍 7. Begin OSINT Analysis

Now we can use Linux command-line tools to search the extracted dataset.

For example, `ripgrep` (`rg`) can search large text files for specific strings.

If the extracted dataset contains a file named `linkedin_users.txt`, we can search for a particular email address:

```bash
rg -aFiN 'freshforensics@gmail.com' linkedin_users.txt
```

Here's what the options mean:

- `-a` — Treat binary-looking files as text.
- `-F` — Search for literal strings rather than regular expressions.
- `-i` — Ignore case.
- `-N` — Disable line numbers.

The search term is an example. In an actual investigation, use identifiers you own or are authorized to examine.

You can also search for other known identifiers associated with your own digital footprint, provided the dataset's structure supports those searches.

---

## 🧠 8. Why This Matters for OSINT

The Internet Archive is more than a place to retrieve old websites and documents.

It can also provide access to historical research datasets and archived material that can help investigators understand how information was collected, stored, and exposed.

The important part of this exercise is understanding the complete acquisition workflow:

1. 🔎 Discover an archived dataset.
2. 📋 Inspect its metadata.
3. 📂 Examine available files.
4. 💾 Prepare dedicated storage.
5. ⬇️ Download the original archive.
6. 🔐 Verify its integrity.
7. 📦 Extract its contents.
8. 🔍 Search and analyze relevant information.

### ⚠️ Responsible OSINT Research

A dataset being publicly accessible does not automatically make every use of its contents appropriate.

Keep investigations focused on your own information, authorized research, and legitimate security assessments. Avoid publishing personal records or using discovered identifiers to target other people.

---

## 🚀 Final Thoughts

This walkthrough demonstrates how a Linux terminal can be used to acquire and examine large historical datasets without relying on a graphical browser.

By combining Internet Archive's `ia` CLI with tools like `7z`, `file`, `sha256sum`, `find`, and `ripgrep`, we can build a repeatable workflow for archival acquisition and OSINT research.

Sometimes the most interesting discoveries aren't sitting on the surface of the internet. They're buried inside archives waiting to be investigated.
