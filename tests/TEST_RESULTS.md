# Test Results



Detailed test evidence for the RSS + Cortex Agent governance POC.

## Environment

| Parameter | Value |
|-----------|-------|
| Account | `ct52611` |
| User | `SATISH` |
| Role | `AGENT_USER` (governed by RSS) |
| Warehouse | `COMPUTE_WH` |
| Data Source | `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` |
| Agent | `RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT` |
| RSS Scope | `GOVERNANCE_DB.RSS.RESTRICT_SESSION_SCOPE` |

## Results

### Test 1 — Read Orders

| Field | Value |
|-------|-------|
| Operation | `SELECT COUNT(*), SUM(O_TOTALPRICE) FROM ORDERS` |
| RSS Privilege | SELECT |
| RSS Verdict | ALLOWED |
| total_orders | `5,000` |
| total_revenue | `$758,200,000` |
| Status | PASS |

### Test 2 — Read Customers by Segment

| Field | Value |
|-------|-------|
| Operation | `SELECT C_MKTSEGMENT, COUNT(*) ... GROUP BY ... ORDER BY DESC` |
| RSS Privilege | SELECT |
| RSS Verdict | ALLOWED |
| Top 3 | FURNITURE > MACHINERY > AUTOMOBILE |
| Status | PASS |

### Test 3 — Blocked Write

| Field | Value |
|-------|-------|
| Operation | `INSERT INTO ORDERS VALUES (99999, ...)` |
| RSS Privilege | INSERT |
| RSS Verdict | DENIED |
| Error | Insufficient privileges |
| Status | PASS |

> This test validates the core governance guarantee: the role has sufficient grants,
> but RSS strips INSERT at the session level. The agent cannot write.

### Test 4 — Orders by Status

| Field | Value |
|-------|-------|
| Operation | `SELECT O_ORDERSTATUS, COUNT(*) ... GROUP BY ... ORDER BY DESC` |
| RSS Privilege | SELECT |
| RSS Verdict | ALLOWED |
| F (Fulfilled) | `2,511` |
| O (Open) | `2,370` |
| P (Pending) | `119` |
| Status | PASS |

## Summary

| # | Test | Operation | RSS Verdict | Status |
|---|------|-----------|-------------|--------|
| 1 | Read Orders | SELECT | ALLOWED | PASS |
| 2 | Read Customers | SELECT | ALLOWED | PASS |
| 3 | Blocked Write | INSERT | DENIED | PASS |
| 4 | Orders by Status | SELECT | ALLOWED | PASS |

4/4 passing. RSS correctly allows reads and blocks writes at the session level.
