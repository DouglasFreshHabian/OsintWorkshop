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

### 6. 🔍 Searching COMB With h8mail

We've already explored COMB's built-in query scripts. Now let's introduce another tool that can help automate searches across breach data: **h8mail**.

🔗 GitHub repository: https://github.com/khast3x/h8mail

h8mail is an email OSINT and password-exposure investigation tool. It supports searches using different target types and can work with local breach data.

For this demonstration, we'll use its local database search functionality with our extracted COMB directory.

#### 📦 Installing h8mail

Install h8mail using pip:

```bash
pip3 install h8mail
```

💡 If your Linux distribution restricts system-wide Python package installations, use a virtual environment or pipx instead.

#### 📧 Searching by Email Address

We can use h8mail to investigate whether an email address appears in the COMB collection.

Run:

```bash
h8mail -t test@example.com -sk -bc ./CompilationOfManyBreaches/
```

Replace `test@example.com` with an email address you are authorized to investigate.

🔍 This uses the COMB integration to search for matching breach records.

#### 🔑 Searching by Password

We can also search for specific password strings in local breach data.

For example:

```bash
h8mail -t "ExamplePassword123!" "AnotherTestPassword!" -sk -lb ./CompilationOfManyBreaches/ --loose
```

Here we're supplying example password strings as search targets and pointing h8mail at our local COMB directory.

The `--loose` option enables less restrictive matching.

⚠️ Use synthetic test strings or passwords you are authorized to investigate. Avoid publishing actual exposed passwords in screenshots, reports, or videos.

#### 🌐 Searching by Domain

Another option is to investigate a domain rather than an individual email address.

For example:

```bash
h8mail -t example.com aegisec.org -sk -lb ./CompilationOfManyBreaches/ --loose
```

Replace the example domains with domains you own or are authorized to assess.

This can help demonstrate how domain-based searches differ from searches targeting individual email addresses.

#### 🧠 Understanding the Options

Here's a quick breakdown of the options used in these examples:

| Option | Purpose |
|---|---|
| `-t` | Specifies the search target or targets. |
| `-sk` | Enables the skip-key option. |
| `-bc` | Uses the Breach Compilation integration. |
| `-lb` | Searches local breach data. |
| `--loose` | Enables less restrictive matching. |

💡 **Important:** h8mail's COMB integration and its local breach search are different search modes. Use the appropriate option for the type of query you're performing.

Also, h8mail's results depend on the structure and format of the local data. If a search does not return expected results, check the tool's documentation and confirm that the dataset is compatible with the selected search mode.

🚀 By adding h8mail to our workflow, we now have another way to investigate historical exposure using a dedicated OSINT tool.

### 7. 🛡️ Understanding the Security Implications

Historical breach collections demonstrate why unique passwords and multifactor authentication matter.

If a password has appeared in a breach, it should not be reused anywhere.

🔐 For personal security:

- 🔄 Change any potentially exposed passwords.
- 🔑 Use unique passwords for every account.
- 🔒 Enable multifactor authentication.
- 🗝️ Use a reputable password manager.
- 🚫 Never test exposed credentials against other people's accounts.

### 8. 🧠 Final Thoughts

COMB demonstrates the long-term consequences of data breaches.

Information exposed years ago can continue circulating, being copied, indexed, combined, and rediscovered.

From an OSINT perspective, the important lesson is that your digital footprint doesn't disappear simply because a website experiences a breach or removes the original data.

🔎 Understanding what has been exposed is an important part of understanding your personal attack surface.

### ⚖️ Responsible Use

This investigation is intended for educational, cybersecurity research, and personal security purposes. Handle breach datasets responsibly, minimize exposure of sensitive information, and never attempt to access accounts using exposed credentials. Respect privacy and applicable laws when conducting OSINT investigations.
