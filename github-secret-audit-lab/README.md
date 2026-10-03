# GitHub Secret Audit Lab

A deliberately vulnerable, **fictional** repository for demonstrating Git security auditing tools such as Gitleaks, grep, git grep, and Git history inspection.

> **IMPORTANT:** Everything in this repository is fabricated for training. Do not use any values here as real credentials. The domain names use reserved/example domains and the IP addresses are documentation ranges.

## Learning objectives

This lab demonstrates how sensitive-looking information can appear in:

- Current source files
- `.env` files
- Configuration files
- URLs containing credentials
- Private-key files
- Phone numbers and email addresses
- Internal-looking IP addresses
- Git history after a file has been deleted or a value has been replaced

## Suggested workflow

```bash
git clone <your-repository-url>
cd github-secret-audit-lab

gitleaks detect --source . --redact --verbose
gitleaks detect --source . --log-opts="--all" --redact --verbose

git rev-list --all

git log --all --oneline
```

Then try the manual searches from the Fresh Forensics GitHub Repository Audit walkthrough.

## Important teaching point

Deleting a secret from the current version of a repository does **not** remove it from Git history. This lab intentionally includes historical findings so that students can see why history scanning matters.

## Safety

All credentials, keys, phone numbers, email addresses, hostnames, and other identifying information are fictional. The sample private key is deliberately nonfunctional and is included only to demonstrate pattern detection.
