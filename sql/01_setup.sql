-- Create databases, AGENT_USER role, and grants for the RSS + Cortex Agent POC.

-- ============================================================================
-- Account: ct52611 | User: SATISH | Warehouse: COMPUTE_WH
-- Run as:  ACCOUNTADMIN in a Snowsight SQL worksheet
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- 1. DATABASES
-- ============================================================================

CREATE DATABASE IF NOT EXISTS GOVERNANCE_DB
    COMMENT = 'RSS scope and governance objects for the Cortex Agent POC.';

CREATE SCHEMA IF NOT EXISTS GOVERNANCE_DB.RSS
    COMMENT = 'Restrict Session Scope definitions.';

CREATE DATABASE IF NOT EXISTS AGENT_SANDBOX_DB
    COMMENT = 'Session policies and sandbox objects for agent testing.';

-- ============================================================================
-- 2. ROLE
-- ============================================================================

CREATE ROLE IF NOT EXISTS AGENT_USER
    COMMENT = 'Role for Cortex Agent testing — read-only on TPCH data.';

GRANT ROLE AGENT_USER TO USER SATISH;

-- ============================================================================
-- 3. GRANTS — Warehouse
-- ============================================================================

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE AGENT_USER;

-- ============================================================================
-- 4. GRANTS — Source Data (SNOWFLAKE_SAMPLE_DATA.TPCH_SF1)
-- ============================================================================

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE AGENT_USER;

-- ============================================================================
-- 5. GRANTS — Retail Analytics (semantic view + agent)
-- ============================================================================

GRANT USAGE  ON DATABASE RETAIL_ANALYTICS          TO ROLE AGENT_USER;
GRANT USAGE  ON SCHEMA   RETAIL_ANALYTICS.RAW_DATA TO ROLE AGENT_USER;
GRANT SELECT ON VIEW     RETAIL_ANALYTICS.RAW_DATA.RETAIL_SV TO ROLE AGENT_USER;
GRANT USAGE  ON CORTEX AGENT RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT TO ROLE AGENT_USER;

-- ============================================================================
-- 6. GRANTS — Governance DB (RSS scope)
-- ============================================================================

GRANT USAGE ON DATABASE GOVERNANCE_DB     TO ROLE AGENT_USER;
GRANT USAGE ON SCHEMA   GOVERNANCE_DB.RSS TO ROLE AGENT_USER;

-- ============================================================================
-- 7. GRANTS — Agent Sandbox DB (session policy)
-- ============================================================================

GRANT USAGE ON DATABASE AGENT_SANDBOX_DB        TO ROLE AGENT_USER;
GRANT USAGE ON SCHEMA   AGENT_SANDBOX_DB.PUBLIC TO ROLE AGENT_USER;

-- ============================================================================
-- NEXT: Execute sql/01b_semantic_view.sql
-- ============================================================================
