# FIDELITY.md — where the emulator lied to you

Fill each caveat after you run LocalStack. Do not copy guesses.

## Custom security groups
- **What LocalStack did:**
- **How I detected it:**
- **What I'd verify on real AWS:** that `vpc_security_group_ids` actually filters packets

## SG rules only at instance create
- **What LocalStack did:**
- **How I detected it:**
- **What I'd verify on real AWS:** adding an ingress rule to a live instance opens the port without recreate

## IMDS instance-profile credentials
- **What LocalStack did:**
- **How I detected it:**
- **What I'd verify on real AWS:** `169.254.169.254/latest/meta-data/iam/security-credentials/`

## Aiven vs LocalStack RDS
- **What LocalStack did:** RDS is not used (Hobby / Slack change). Aiven is a real MySQL over TLS on the public internet.
- **How I detected it:** instructor update; RDS APIs missing without paid LocalStack.
- **What I'd verify on real AWS:** RDS endpoint from inside a VPC, security groups, `storage_encrypted` actually encrypts volumes

## ELBv2 health checking
- **What LocalStack did:**
- **How I detected it:**
- **What I'd verify on real AWS:** unhealthy targets are removed; nginx `/readyz` is a lab stand-in

## Docker socket inside EC2
- **What LocalStack did:**
- **How I detected it:**
- **What I'd verify on real AWS:** `docker run` on the instance is a child of that host, not a sibling on the laptop
