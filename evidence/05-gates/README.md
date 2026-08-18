# Gate evidence (C5)

For each gate: a PR that went **red**, the scanner output, and the fix commit.
A scanner that runs but never fails the build is theatre.

| Gate | Red PR | Scanner output | Fix commit | What this gate does NOT catch |
|---|---|---|---|---|
| gitleaks | TBD | `gitleaks.json` | TBD | Encrypted/obfuscated secrets, runtime-injected creds, secrets never committed |
| trivy | TBD | `trivy-config.json`, `trivy-image.json` | TBD | Logic bugs, unsound IAM, vulns below HIGH if we fail only HIGH/CRITICAL |
| zizmor | TBD | `zizmor.txt` | TBD | Malicious commits already at a pinned SHA, compromised maintainer |

Deliberate insecure changes to introduce:

1. **gitleaks** — commit a fake `password=supersecret123`, let CI fail, revert.
2. **trivy** — add `0.0.0.0/0` on the app SG (or `:latest` base image), let CI fail, revert.
3. **zizmor** — use `actions/checkout@v4` (tag, not SHA), let CI fail, pin SHA.
