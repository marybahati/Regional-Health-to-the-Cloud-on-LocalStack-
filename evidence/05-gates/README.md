# Gates that actually block (C5)

Scan jobs run `permissions: contents: read` with **no secrets**. `step-security/harden-runner` is in egress-audit on every job. Actions are pinned to full SHAs; bumps come through Dependabot PRs.

## What each gate does NOT catch

- **gitleaks:** Does not catch a secret that never enters git (pasted into an issue, stored in Terraform state, or injected at runtime). It also will not flag a well-formed random password that matches no rule.
- **trivy:** Config scanning does not prove LocalStack *enforced* the control (`storage_encrypted` is a good example — see FIDELITY.md). Image scanning misses zero-days not yet in the DB and vulns in dependencies pulled at runtime, not baked into the image.
- **zizmor:** Does not catch a malicious commit already at a pinned SHA, a compromised maintainer, or a runner that phones home after the workflow YAML looks clean. That is why harden-runner sits next to it.

## Red PRs (introduce a bad change, let the gate fail, then fix)

Replace these with the real GitHub PR links after the three deliberate-fail PRs are opened:

| Gate | Insecure change | Red PR | Fix commit |
|---|---|---|---|
| gitleaks | committed fake AWS key `AKIA...` in a fixture | _pending_ | _pending_ |
| trivy config | `0.0.0.0/0` on `aws_security_group.app` ingress | _pending_ | _pending_ |
| zizmor | unpinned `actions/checkout@v4` (tag, not SHA) | _pending_ | _pending_ |

Scanner outputs after a green run live beside this file: `trivy-image.json`, `trivy-config.json`, `zizmor.txt`.
