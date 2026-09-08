# Architecture



Detailed component breakdown for the Snowflake RSS + Cortex Agent governance POC.

## System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│  SNOWFLAKE ACCOUNT: ct52611                                              │
│                                                                          │
│  ┌─────────────────────┐    ┌──────────────────────────────────────────┐ │
│  │  GOVERNANCE_DB       │    │  RETAIL_ANALYTICS                       │ │
│  │  └─ RSS (schema)     │    │  └─ RAW_DATA (schema)                   │ │
│  │     └─ RESTRICT_     │    │     ├─ RETAIL_SV (Semantic View)        │ │
│  │        SESSION_SCOPE │    │     │  └─ TPCH_SF1.ORDERS              │ │
│  │                      │    │     │  └─ TPCH_SF1.CUSTOMER            │ │
│  └──────────┬───────────┘    │     └─ RETAIL_AGENT (Cortex Agent)     │ │
│             │                └──────────────────────────────────────────┘ │
│             │ references                                                 │
│             ▼                                                            │
│  ┌─────────────────────┐                                                 │
│  │  AGENT_SANDBOX_DB    │                                                │
│  │  └─ PUBLIC (schema)  │                                                │
│  │     └─ AGENT_        │                                                │
│  │        SESSION_POLICY │──── attached at ────► ACCOUNT                 │
│  └─────────────────────┘                                                 │
│                                                                          │
│  AGENT_USER (role) ──► SATISH (user)                                     │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. RSS Scope — `GOVERNANCE_DB.RSS.RESTRICT_SESSION_SCOPE`

Type: Restrict Session Scope object
Purpose: Defines the privilege whitelist for governed sessions

The RSS scope is the core governance object. It contains a list of `ALLOWED_PRIVILEGES` — the only privileges that a governed session may exercise. Any privilege not listed is implicitly denied, regardless of the role's actual grants.

```sql
ALLOWED_PRIVILEGES = ('SELECT', 'USAGE', 'OPERATE', 'USER', 'OBJECT MANAGEMENT')
```

Design decision: No `blocked_roles`. Privilege restrictions only. This avoids the ACCOUNTADMIN lockout risk entirely.

### 2. Session Policy — `AGENT_SANDBOX_DB.PUBLIC.AGENT_SESSION_POLICY`

Type: Session Policy object
Purpose: Binds the RSS scope to sessions and configures timeouts

The session policy is the delivery mechanism for RSS. It references the RSS scope and adds session management parameters (idle timeouts). When attached to an account or user, all matching sessions get the RSS restrictions applied at session start.

Attachment level: Account (POC). Production should use user-level attachment.

### 3. Semantic View — `RETAIL_ANALYTICS.RAW_DATA.RETAIL_SV`

Type: Semantic View
Purpose: Scopes which tables and columns the agent can see

The semantic view wraps two TPCH tables:
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` — 5,000 orders
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` — customer demographics

It provides the table-level scope: the agent can only see what the semantic view exposes. Combined with RSS (privilege-level scope), this creates two independent governance layers.

### 4. Cortex Agent — `RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT`

Type: Cortex Agent
Purpose: Natural-language to SQL engine

The agent receives natural-language questions, generates SQL using the semantic view's schema, and executes the SQL. RSS governs the execution — the agent's SQL runs with only the whitelisted privileges.

### 5. AGENT_USER Role

Type: Role
Purpose: Purpose-built role with minimum necessary grants

Grant chain:
```
COMPUTE_WH           → USAGE
SNOWFLAKE_SAMPLE_DATA → IMPORTED PRIVILEGES
RETAIL_ANALYTICS      → USAGE (database + schema)
RETAIL_SV             → SELECT
RETAIL_AGENT          → USAGE
GOVERNANCE_DB         → USAGE (database + schema)
AGENT_SANDBOX_DB      → USAGE (database + schema)
```

## Data Flow

```
1. User asks question (natural language)
       │
2. RETAIL_AGENT receives question
       │
3. Agent generates SQL using RETAIL_SV schema
       │
4. SQL submitted for execution
       │
5. Session Policy intercepts ──► RSS Scope applied
       │                           │
       │                     Privilege check:
       │                     ✅ SELECT → allowed
       │                     ❌ INSERT → denied
       │
6a. SELECT query → executes → results returned
6b. INSERT query → denied → privilege error
```

## Governance Layers

```
┌─────────────────────────────────────┐
│ Layer 1: Network Policy             │  ← IP allowlist (not in this POC)
├─────────────────────────────────────┤
│ Layer 2: Session Policy + RSS       │  ← THIS POC
│  └─ Privilege restriction           │
├─────────────────────────────────────┤
│ Layer 3: Semantic View              │  ← THIS POC
│  └─ Table/column scope             │
├─────────────────────────────────────┤
│ Layer 4: Row Access Policy          │  ← Not in this POC
│  └─ Row-level filtering            │
├─────────────────────────────────────┤
│ Layer 5: Dynamic Data Masking       │  ← Not in this POC
│  └─ Column-level redaction          │
└─────────────────────────────────────┘
```

## Object Dependencies

```
05_cleanup.sql must respect this order:

1. ALTER ACCOUNT UNSET SESSION POLICY  ← detach first
2. DROP SESSION POLICY                 ← then drop policy
3. DROP RESTRICT SESSION SCOPE         ← then drop scope
4. DROP CORTEX AGENT                   ← then drop agent
5. DROP SEMANTIC VIEW                  ← then drop view
6. DROP ROLE                           ← then drop role
7. DROP DATABASE (×2)                  ← finally databases
```

Reversing steps 1–2 will fail: you cannot drop a policy that is still attached.
