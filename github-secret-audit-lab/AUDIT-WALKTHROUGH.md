# Audit Walkthrough

Run these from the repository root.

## 1. Count commits

```bash
git rev-list --all
git log --all --oneline
```

## 2. Scan with Gitleaks

```bash
gitleaks detect --source . --redact --verbose
gitleaks detect --source . --log-opts="--all" --redact --verbose
```

## 3. Search credential-like terms

```bash
grep -RniE 'password|passwd|secret|api[_-]?key|token|credential' --exclude-dir=.git .
```

## 4. Search private-key markers

```bash
grep -RniE 'BEGIN (RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY' --exclude-dir=.git .
```

## 5. Search historical commits

```bash
git grep -inE 'password|passwd|secret|api[_-]?key|token|credential' $(git rev-list --all)
git grep -inE 'BEGIN (RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY' $(git rev-list --all)
```

## 6. Search phone numbers

```bash
grep -RniE '(\\+?1[ .-]?)?\\(?[0-9]{3}\\)?[ .-][0-9]{3}[ .-][0-9]{4}' --exclude-dir=.git .
```

Historical search:

```bash
git grep -inE '(\\+?1[ .-]?)?\\(?[0-9]{3}\\)?[ .-][0-9]{3}[ .-][0-9]{4}' $(git rev-list --all)
```

## 7. Inspect files that look sensitive

```bash
find . -type f \\
  \( -iname '*.env' -o -iname '*.pem' -o -iname '*.key' \\
  -o -iname '*.p12' -o -iname '*.pfx' -o -iname '*credential*' \\
  -o -iname '*password*' -o -iname '*secret*' \) \\
  -not -path './.git/*'
```

## 8. Show deleted files in history

```bash
git log --all --diff-filter=D --summary
```

The `history-demo` files were intentionally committed and then deleted. They should still be discoverable through Git history.
