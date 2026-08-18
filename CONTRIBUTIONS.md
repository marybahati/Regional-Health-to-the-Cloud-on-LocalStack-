# CONTRIBUTIONS.md

A summary — the record is git history. Service A is this checkout. B and C are teammate roots on the same modules.

| Member | Authored (PR links) | Reviewed (PR links) |
|---|---|---|
| Mary Bahati (`marybahati`) | Service A root `terraform/environments/service-a`; `modules/data` (this fork until the group PR lands) | pending — review teammate PRs for `modules/service` and Service B/C roots |
| Teammate (Service B) | pending | pending |
| Teammate (Service C) | pending | pending |

Anti-free-rider: Mary is sole author of the Service A root and the data module in this repo. Approving reviews on two other module PRs land when B/C open them against the group platform.

If the group `modules/service` PR is delayed, this repo already contains a working fork. Divergence is documented in the README.
