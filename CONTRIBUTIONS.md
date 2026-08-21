# CONTRIBUTIONS.md

A summary — the record is git history. Each member owns one service root on the same group modules.

| Member | Authored (PR links) | Reviewed (PR links) |
|---|---|---|
| Mary Bahati (`marybahati`) | Service A root `terraform/environments/service-a`; group `modules/data` ([PR #2](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/2)) | [PR #8](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/8) (Service B), [PR #7](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/7) (Service C) |
| Warga (`Gatchang-nyawargak`) | Service B root `terraform/environments/service-b` ([PR #8](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/8)); CI gates dedupe ([PR #10](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/10)) | [PR #2](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/2) (Service A), [PR #7](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/7) (Service C) |
| Sharon (`sharon2719`, Service C) | Service C root `terraform/environments/service-c`; CI wiring `.github/workflows/rehost-service-c.yml`; parameterized the shared `Makefile`/scripts/`golden.yml` with a `SERVICE` variable so Service C builds without colliding with Service A ([PR #7](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/7)) | [PR #2](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/2) (Service A), [PR #8](https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-/pull/8) (Service B) |

Anti-free-rider: Mary is sole author of the Service A root and the data module on `main`. Warga is sole author of the Service B root. Sharon is sole author of the Service C root. Each member reviewed at least two other members’ PRs against the group platform.
