# Rehosting Capacity Lab — starter pack

This is a **starter pack, not a repo**. You complete the assignment **in your
existing Assignment-1 repo** (the one with your `api/`, `load-tests/`,
`monitoring/`, incidents, etc.). These files are starting points for the *new*
rehost pieces — copy the ones you need into your repo and fill in the `TODO`s.

## What's here

| File | What it is |
|---|---|
| `ASSIGNMENT.md` | **The brief.** Read it first — especially "The four things that will break first". |
| `terraform/modules/data/main.tf` | Stub for the RDS + Secrets Manager module (you build it). |
| `terraform/modules/service/main.tf` | Stub for the EC2 + nginx + ALB module (you build it). |
| `api/secrets.js` | Stub for resolving DB creds from Secrets Manager at boot. |
| `evidence/README.md` | The exact evidence bundle you must produce. |
| `FIDELITY.md` | Template — where the emulator lied to you (graded). |
| `CONTRIBUTIONS.md` | Template — who authored/reviewed which module PR. |

## What's NOT here (you provide it)

Your app and k6 scripts already live in your A1 repo. You also write your own
`Makefile`, CI workflow (`.github/workflows/`), and observability wiring — the
brief tells you exactly what each must do and what evidence proves it.

## First moves

1. Read `ASSIGNMENT.md` end to end.
2. Sort your **free Hobby** LocalStack token and a **Linux Codespace** (see the
   Environment section — don't fight a Mac).
3. Copy the stubs into your repo, wire them up, and make the evidence real.
