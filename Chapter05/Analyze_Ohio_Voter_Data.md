# 🕵️ OSINT Walkthrough: Acquiring and Analyzing Ohio Voter Registration Data Using Linux

In this walkthrough, we're going to explore how publicly available voter registration records can be acquired, consolidated, and processed using nothing but Linux command-line tools. We'll use the Ohio Secretary of State's official Voter Files Download Page to obtain publicly available voter registration datasets and demonstrate how tools like `cat`, `sed`, `wc`, and other Linux utilities can help process millions of records.

## 🌐 1. Locate the Ohio Voter Registration Files

The Ohio Secretary of State provides a public Voter Files Download Page where voter registration datasets can be downloaded.

🔗 **Official Download Page:**

https://www6.ohiosos.gov/ords/f?p=VOTERFTP:HOME

According to the Ohio Secretary of State, voter files can be downloaded by:

- County
- State Senate District
- State Representative District
- Congressional District
- Entire State of Ohio

The statewide voter file is divided into four ZIP archives:

| Archive | County Range |
|---|---|
| SWVF_1_22 | Adams – Erie |
| SWVF_23_44 | Fairfield – Lawrence |
| SWVF_45_66 | Licking – Pike |
| SWVF_67_88 | Portage – Wyandot |

The available voter files are updated weekly.

Ohio has 88 counties in total.

## 📥 2. Download the Voter Files

Download the available voter files from the Ohio Secretary of State website.

For this demonstration, we are acquiring the HTML files containing the downloaded voter information and organizing them inside a directory named `downthemall`.

Inspect the downloaded files:

```bash
ls downthemall/
```

Example output:

```text
'f(1).html'   'f(18).html'  'f(26).html'
'f(34).html'  'f(42).html'  'f(50).html'
'f(59).html'  'f(67).html'  'f(75).html'
'f(83).html'
```

## 🔗 3. Combine Everything Into One Master File

Rather than working with individual downloaded files, we can concatenate them into a single master file using `cat`.

```bash
cat *.html > master.txt
```

This combines the contents of all matching HTML files into one searchable text file.

Now let's see how much data we're working with:

```bash
wc -l master.txt
```

Example output:

```text
8021851 master.txt
```

That's over eight million lines of data!

## 🧹 4. Clean and Normalize the Master File

Before searching through the dataset, we want to normalize some of the formatting.

We'll use `sed` to perform several in-place substitutions.

Replace groups of four spaces with colons:

```bash
sed -i 's/    /:/g' master.txt
```

Replace consecutive double colons:

```bash
sed -i 's/::/:/g' master.txt
```

Replace empty quoted fields:

```bash
sed -i 's/,"",/:/g' master.txt
```

These operations help standardize some of the delimiters in the file.

Note that these are basic text substitutions, not a complete HTML parser or CSV normalization process. Always preserve an original copy before modifying downloaded source files.

## 📖 5. Understand the Voter File Layout

Before attempting to interpret the records, download and review the official Voter File Layout document.

This document explains the structure of the voter records and the meaning of the individual fields.

Open the document using LibreOffice:

```bash
libreoffice Voter_File_Layout.docx
```

Pay attention to the field definitions, data types, and symbols used throughout the dataset.

Understanding the file layout is essential before attempting to interpret or correlate individual fields.

## 🔎 6. Prepare for OSINT Analysis

With the files consolidated, we now have a large dataset that can be examined using Linux command-line tools.

Some useful tools for further investigation include:

- `grep` for searching specific strings.
- `ripgrep` for fast recursive searching.
- `sed` for transforming text.
- `awk` for extracting and analyzing fields.
- `sort` for organizing results.
- `uniq` for identifying recurring values.
- `wc` for counting records and lines.

For example, a basic search using ripgrep:

```bash
rg -aFiN "SEARCH_TERM" master.txt
```

This provides a starting point for exploring the dataset without needing a graphical database application.

## ⚠️ Responsible OSINT

Public availability does not mean unrestricted use. Voter registration records can contain sensitive personal information. Keep investigations focused on legitimate research, data validation, and aggregate analysis. Avoid publishing personal information, targeting individuals, or attempting to expose private details.

## 🧠 Final Thoughts

One of the most powerful aspects of Linux is the ability to acquire, process, and search enormous amounts of information directly from the command line. With a handful of standard utilities, we can turn millions of lines of publicly available records into searchable datasets and demonstrate the practical value of OSINT without relying on expensive commercial software.
