# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

Do not open a public GitHub issue for security vulnerabilities.

Instead, email the maintainers directly with:

1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

## Scope

This project contains SQL scripts that modify Snowflake account-level settings (session policies, RSS scopes). Security concerns include:

- ACCOUNTADMIN lockout — Adding `blocked_roles` to an account-level session policy
- Privilege escalation — RSS scope granting more privileges than intended
- CoCo disruption — RSS scope removing privileges CoCo needs to operate

## Known Risks

See [README.md — ACCOUNTADMIN Lockout Warning](README.md#accountadmin-lockout-warning) for the primary known risk and its mitigation.
