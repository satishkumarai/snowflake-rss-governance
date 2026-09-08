# Snowflake RSS Governance for Cortex Agents



[![Snowflake](https://img.shields.io/badge/platform-Snowflake-29B5E8?logo=snowflake&logoColor=white)](https://www.snowflake.com)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Tests: 4/4 Passing](https://img.shields.io/badge/tests-4%2F4_passing-brightgreen.svg)](#verified-test-results)
[![RSS: Privilege Only](https://img.shields.io/badge/RSS-privilege_only-blue.svg)](#rss-scope-design)

Session-level privilege governance for Snowflake Cortex Agents using Restrict Session Scope (RSS). Locks AI agents to read-only SQL — no role changes, no `blocked_roles`, no lockout risk.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [RSS Scope Design](#rss-scope-design)
- [Verified Test Results](#verified-test-results)
- [Repository Structure](#repository-structure)
- [ACCOUNTADMIN Lockout Warning](#accountadmin-lockout-warning)
- [Production Guidance](#production-guidance)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Problem Statement

Cortex Agents generate and execute SQL autonomously. Snowflake RBAC controls what a role can do, but cannot restrict what an agent session does within that role. An agent inheriting a role with INSERT privileges can insert.

RSS fixes this by defining a session-level privilege whitelist. At session start, Snowflake intersects the role's grants with the whitelist — anything not listed is silently denied.

```
Without RSS                          With RSS
─────────────                        ────────
Role ──► Agent Session               Role ──► RSS Filter ──► Agent Session
         │                                    │
         ▼                                    ▼
         SELECT ✅                            SELECT ✅
         INSERT ✅  ← unintended              INSERT ❌  ← stripped
         UPDATE ✅  ← unintended              UPDATE ❌  ← stripped
         DELETE ✅  ← unintended              DELETE ❌  ← stripped
```

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   User ──► RETAIL_AGENT (Cortex Agent)                       │
│                 │                                            │
│                 ▼                                            │
│            RETAIL_SV (Semantic View)                          │
│                 │                                            │
│            ┌────┴────┐                                       │
│            │  ORDERS  │  CUSTOMER  │  (TPCH_SF1)             │
│            └────┬────┘                                       │
│                 │                                            │
│                 ▼                                            │
│   ┌─────────────────────────────────────┐                    │
│   │  SESSION POLICY                     │                    │
│   │  └─ RSS SCOPE                       │                    │
│   │     ✅ SELECT, USAGE, OPERATE       │                    │
│   │     ✅ USER, OBJECT MANAGEMENT      │                    │
│   │     ❌ INSERT, UPDATE, DELETE, DROP  │                    │
│   └─────────────────────────────────────┘                    │
│                 │                                            │
│                 ▼                                            │
│            SQL executes (read-only)                           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

> For a detailed component breakdown, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Prerequisites

| Requirement | Value |
|-------------|-------|
| Snowflake Account | `ct52611` |
| User | `SATISH` |
| Warehouse | `COMPUTE_WH` |
| Setup Role | `ACCOUNTADMIN` |
| Test Role | `AGENT_USER` (created by setup) |
| Data Source | `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (pre-loaded) |

## Quick Start

> All SQL files run in a Snowsight SQL worksheet as `ACCOUNTADMIN`.

```bash
# Step 1 — Create databases, role, and grants
#   Execute: sql/01_setup.sql

# Step 2 — Create RSS scope (privilege restrictions only)
#   Execute: sql/02_rss_scope.sql

# Step 3 — Deploy semantic view + Cortex Agent
#   In CoCo: ask to create RETAIL_SV and RETAIL_AGENT via agent-studio

# Step 4 — Create and attach session policy
#   Execute: sql/03_session_policy.sql

# Step 5 — Run validation tests
#   Execute: sql/04_test_governance.sql

# Step 6 — Teardown (when done)
#   Execute: sql/05_cleanup.sql   ⚠️ Run from SQL worksheet, NOT CoCo
```

## RSS Scope Design

The scope whitelists 5 privileges. Everything else is implicitly denied.

```sql
ALLOWED_PRIVILEGES = ('SELECT', 'USAGE', 'OPERATE', 'USER', 'OBJECT MANAGEMENT')
-- No blocked_roles. No role blocking of any kind.
```

| Privilege | Purpose | Required By |
|-----------|---------|-------------|
| `SELECT` | Read tables and views | Agent core function |
| `USAGE` | Traverse databases, schemas, warehouses | Agent navigation |
| `OPERATE` | Execute queries on warehouse | Agent query execution |
| `USER` | Session management, workspace access | CoCo compatibility |
| `OBJECT MANAGEMENT` | CREATE/ALTER on workspace objects | CoCo file writes |

Implicitly denied: INSERT, UPDATE, DELETE, DROP, TRUNCATE, CREATE TABLE, and all other privileges.

## Verified Test Results

All tests executed against `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` via the Cortex Agent.

| # | Test | Query | Expected Result | RSS Check | Status |
|---|------|-------|-----------------|-----------|--------|
| 1 | Read Orders | Total count + revenue | 5,000 orders / $758.2M | SELECT ✅ | PASS |
| 2 | Read Customers | Counts by segment | Furniture > Machinery > Automobile | SELECT ✅ | PASS |
| 3 | Blocked Write | INSERT order row | Denied — insufficient privileges | INSERT ❌ | PASS |
| 4 | Orders by Status | Counts per status | F=2,511 · O=2,370 · P=119 | SELECT ✅ | PASS |

> Test 3 is the governance proof: the role *could* insert in a normal session, but RSS strips INSERT at the session level.

## Repository Structure

```
snowflake-rss-governance/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── CONTRIBUTING.md                    # Contribution guidelines
├── SECURITY.md                        # Security policy and disclosure
├── CODE_OF_CONDUCT.md                 # Contributor Covenant
├── CHANGELOG.md                       # Version history
├── .gitignore                         # Git ignore rules
│
├── sql/                               # Deployment scripts (run in order)
│   ├── 01_setup.sql                   #   Databases, role, grants
│   ├── 02_rss_scope.sql               #   RSS scope definition
│   ├── 03_session_policy.sql          #   Session policy + attachment
│   ├── 04_test_governance.sql         #   4 validation tests
│   └── 05_cleanup.sql                 #   Full teardown
│
├── tests/                             # Test documentation
│   └── TEST_RESULTS.md               #   Detailed test evidence
│
├── docs/                              # Documentation
│   ├── ARCHITECTURE.md                #   Component deep dive
│   └── medium_article.md             #   Full Medium article draft
│
└── .github/                           # GitHub configuration
    └── ISSUE_TEMPLATE/
        ├── bug_report.md              #   Bug report template
        └── feature_request.md         #   Feature request template
```

## ACCOUNTADMIN Lockout Warning

> Do NOT add `blocked_roles` to the RSS scope.

If you block ACCOUNTADMIN with an account-level session policy:

1. Every session gets the policy — including ACCOUNTADMIN
2. ACCOUNTADMIN is blocked from running `ALTER ACCOUNT UNSET SESSION POLICY`
3. You are locked out of your own account
4. Recovery requires a Snowflake Support ticket

This repo uses privilege restrictions only — no `blocked_roles`, no risk.

Additionally: CoCo (Cortex Code) is an agent. If you block CoCo's operating role, it loses workspace file access and SQL execution. The RSS scope includes `USER` and `OBJECT MANAGEMENT` for CoCo compatibility.

## Production Guidance

| Practice | Recommendation |
|----------|---------------|
| Policy attachment | User-level (agent service user), not account-level |
| Role isolation | Dedicated role + user per agent |
| Audit | Monitor `QUERY_HISTORY` for privilege errors from agent roles |
| CI/CD | Version-control RSS scopes; test write-denial in CI |
| Defense in depth | Layer RSS with Network Policy, Row Access Policy, Dynamic Masking |

```
Layer 1: Network Policy          — IP allowlist
Layer 2: Session Policy + RSS    — privilege restriction
Layer 3: Semantic View           — table/column scope
Layer 4: Row Access Policy       — row-level filtering
Layer 5: Dynamic Data Masking    — column-level redaction
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

## Security

See [`SECURITY.md`](SECURITY.md) for vulnerability reporting.

## License

This project is licensed under the MIT License — see [`LICENSE`](LICENSE) for details.
