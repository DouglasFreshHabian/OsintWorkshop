# 🔎 COMB — Compilation of Many Breaches
## 🐧 Using Linux to Investigate Your Own Digital Footprint

### 🎯 Objective

In this investigation, we're examining COMB (Compilation of Many Breaches), a large collection of historical breach data, to demonstrate how exposed personal information can affect our digital footprint.

The purpose of this exercise is OSINT and personal security research. I am using myself as the target to investigate whether my own email address appears in historical breach records.

We will examine COMB's organization, understand its scripts, inspect database statistics, and demonstrate how historical credential exposure can reveal risks associated with password reuse.

### 1. 🧩 Understanding COMB

COMB stands for Compilation of Many Breaches.

Unlike a conventional database stored in one enormous file, COMB organizes its records into a directory structure based on the first characters of the indexed terms.

The extracted directory contains:

- 📁 `data/` — The organized database.
- 🔍 `query.sh` — The database search interface.
- ⚙️ `sorter.sh` — The import and organization script.
- 📊 `count_total.sh` — The database counting script.

### 2. 📦 Extracting the Archive

The original COMB archive was approximately 19 GB.

After downloading and extracting it, the resulting directory was:

`CompilationOfManyBreaches/`

Let's examine the archive and extracted directory using `ls -lh`:

```bash
ls -lh *
```

📊 Our output:

```text
-rw-r--r-- 1 fresh fresh 19G Nov 23 02:34 CompilationOfManyBreaches.7z

CompilationOfManyBreaches:
total 16K
-rwxrwxr-x  1 fresh fresh  472 Apr  5  2020 count_total.sh*
drwxrwxr-x 30 fresh fresh 4.0K Feb 16  2019 data/
-rwxrwxr-x  1 fresh fresh 1.1K Apr  5  2020 query.sh*
-rwxrwxr-x  1 fresh fresh 1.7K Apr  5  2020 sorter.sh*
```

🔍 A quick breakdown of what we're looking at:

- 📦 `CompilationOfManyBreaches.7z` — The original compressed archive, approximately 19 GB.
- 📁 `CompilationOfManyBreaches/` — The extracted directory containing the database and supporting scripts.
- 📂 `data/` — The database, organized into 30 subdirectories.
- 📊 `count_total.sh` — 472 bytes.
- 🔎 `query.sh` — 1.1 KB.
- ⚙️ `sorter.sh` — 1.7 KB.

💡 Notice that the directory itself reports only 16 KB in this listing. This is directory metadata and the sizes of its immediate entries, not the total size of the extracted database. The actual database contents are stored underneath `data/`.

To investigate the extracted database size, run:

```bash
du -sh CompilationOfManyBreaches/
```

This gives us a better picture of how much disk space the extracted collection actually consumes.

🚀 With the archive extracted and its directory structure understood, we're ready to investigate the database.

### 3. 📊 Examining the Database

Before investigating anything, we want to understand the scale of the collection.

Run:

```bash
./count_total.sh
```

This reports the number of lines in each database file and maintains a running total.

The output reveals how COMB divides its records into smaller files.

For example:

```text
[*] data/0 -          7120713   (total: 7120713)
[*] data/1/0 -        3271202   (total: 10391915)
[*] data/1/1 -        3656490   (total: 14048405)
[*] data/1/2 -        4885947   (total: 18934352)
```

💡 This gives us an understanding of the database's scale and organization.

### 4. ⚙️ Understanding the Query Engine

The `query.sh` script uses the first characters of a search term to locate the corresponding database file.

It then uses case-insensitive matching to locate records beginning with the supplied term.

🧠 This is an important part of COMB's architecture: instead of searching every database file, it narrows the search to a smaller portion of the collection.

### 5. 🕵️ Conducting a Personal Exposure Audit

For this demonstration, I used my own historical email identifier as the investigation target.

The results showed that my address appeared in historical breach records alongside exposed password values.

🚨 This illustrates several important security risks:

- 🔑 Password reuse across multiple services.
- 📧 Historical exposure of account credentials.
- ⏳ Long-term persistence of leaked information.
- 🌐 The difficulty of controlling information after a breach.

⚠️ The presence of an old password does not establish that it remains valid today.

### 6. 🛡️ Understanding the Security Implications

Historical breach collections demonstrate why unique passwords and multifactor authentication matter.

If a password has appeared in a breach, it should not be reused anywhere.

🔐 For personal security:

- 🔄 Change any potentially exposed passwords.
- 🔑 Use unique passwords for every account.
- 🔒 Enable multifactor authentication.
- 🗝️ Use a reputable password manager.
- 🚫 Never test exposed credentials against other people's accounts.

### 7. 🧠 Final Thoughts

COMB demonstrates the long-term consequences of data breaches.

Information exposed years ago can continue circulating, being copied, indexed, combined, and rediscovered.

From an OSINT perspective, the important lesson is that your digital footprint doesn't disappear simply because a website experiences a breach or removes the original data.

🔎 Understanding what has been exposed is an important part of understanding your personal attack surface.

### ⚖️ Responsible Use

This investigation is intended for educational, cybersecurity research, and personal security purposes. Handle breach datasets responsibly, minimize exposure of sensitive information, and never attempt to access accounts using exposed credentials. Respect privacy and applicable laws when conducting OSINT investigations.
