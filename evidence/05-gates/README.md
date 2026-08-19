# Gates that actually block (C5)

Scan jobs run `permissions: contents: read` with **no secrets**. `step-security/harden-runner` is in egress-audit on every job. Actions are pinned to full SHAs; bumps come through Dependabot PRs.

## What each gate does NOT catch

- **gitleaks:** Does not catch a secret that never enters git (pasted into an issue, stored in Terraform state, or injected at runtime). It also will not flag a well-formed random password that matches no rule. It also scans full history — once a secret is committed, only rewriting history removes the finding; a later commit that deletes the file does not.
- **trivy:** Config scanning does not prove LocalStack *enforced* the control (`storage_encrypted` is a good example — see FIDELITY.md). Image scanning misses zero-days not yet in the DB and vulns in dependencies pulled at runtime, not baked into the image. Its ingress-CIDR rule here (`aws-ec2-no-public-ingress-sgr`-class) only fires when the port range overlaps SSH(22)/RDP(3389) — widening `0.0.0.0/0` on an arbitrary app port (80, 3000, ...) is silently **not** flagged; verified empirically (see Red PRs below).
- **zizmor:** Does not catch a malicious commit already at a pinned SHA, a compromised maintainer, or a runner that phones home after the workflow YAML looks clean — that is why harden-runner sits next to it. Also, contrary to assumption, its `unpinned-uses` audit is a `help`-severity finding that **never affects zizmor's own exit code**, even with `--pedantic` (`--min-severity`'s floor is `unknown`, not `help` — there is no flag to promote it). `golden.yml` now greps its output for `unpinned-uses` and force-fails the step; without that, an unpinned action would pass this gate silently.

## Red PRs (introduce a bad change, let the gate fail, then fix)

All three ran against PR #7 (`feat/service-c` → `main`), except gitleaks which ran on a throwaway branch/PR (gitleaks scans full git history, so a revert commit doesn't clear a finding — only keeping the secret out of shared history does).

| Gate | Insecure change | Red PR / run | Fix commit |
|---|---|---|---|
| gitleaks | committed AWS's public example key `AKIAIOSFODNN7EXAMPLE` in `api/test/fixtures/leaked-credential.txt` on branch `demo/gitleaks-c5` | _pending — user to open throwaway PR and share link_ | n/a — branch closed/deleted unmerged, not reverted |
| trivy config | widened `ingress_cidrs` to `0.0.0.0/0` **and** the nginx ingress port range to 0-65535 (PR #7, commit [`d102c6e`](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/commit/d102c6e60865bcebfaba8f29861c45a3b4167b3c)) — [red run](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/actions/runs/32240582632/job/96030012974): `HIGH` "Security groups should not allow unrestricted ingress to SSH or RDP from any IP address" | [`fccf6d9`](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/commit/fccf6d9) |
| zizmor | unpinned `actions/checkout` to `@v4.2.2` (tag, not SHA) on both the gitleaks and zizmor jobs (PR #7, commit [`fd229a5`](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/commit/fd229a5)) — [red run](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/actions/runs/32244967207/job/96043387855): `zizmor found an unpinned action reference (unpinned-uses)` | [`a899d53`](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/commit/a899d53) |

Note on the trivy-config and zizmor rows: the *first* attempt at each (widening only the CIDR; unpinning without the enforcement check) passed CI unexpectedly — both are documented above as real, verified gate limitations rather than hidden. The red runs linked above are the corrected attempts, confirmed red before their fix commits were pushed.

Scanner outputs after a green run live beside this file: `trivy-image.json`, `trivy-config-terraform.json`, `trivy-config-api.json`, `zizmor.txt` (uploaded as CI artifacts by `golden.yml`; download from the latest green run to refresh the copies here).
