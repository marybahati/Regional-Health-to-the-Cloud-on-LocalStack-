# CONTRIBUTIONS.md

A summary — the record is git history. Each member owns one service root on the same group modules.

| Member | Authored (PR links) | Reviewed (PR links) |
|---|---|---|
| Mary Bahati (`marybahati`) | Service A root `terraform/environments/service-a`; group `modules/data` (PR #2) | pending — review Service B/C roots |
| Warga (`Gatchang-nyawargak`) | Service B root `terraform/environments/service-b` | pending — review Service A + Service C |
| Sharon (`sharon2719`, Service C) | Service C root `terraform/environments/service-c`; CI wiring `.github/workflows/rehost-service-c.yml`; parameterized the shared `Makefile`/scripts/`golden.yml` with a `SERVICE` variable so Service C builds without colliding with Service A | pending — review Service A + Service B |

Anti-free-rider: Mary is sole author of the Service A root and the data module on `main`. Warga is sole author of the Service B root. Sharon is sole author of the Service C root. Approving reviews on the other module/root PRs land as those PRs are open against the group platform.
