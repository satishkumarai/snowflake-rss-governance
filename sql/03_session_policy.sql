-- Session policy: bind RSS scope and attach at account level.

-- ============================================================================
-- Account: ct52611 | Run as: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- 1. CREATE SESSION POLICY
-- ============================================================================

CREATE OR REPLACE SESSION POLICY AGENT_SANDBOX_DB.PUBLIC.AGENT_SESSION_POLICY
    SESSION_IDLE_TIMEOUT_MINS = 60
    SESSION_UI_IDLE_TIMEOUT_MINS = 30
    RESTRICT_SESSION_SCOPE = GOVERNANCE_DB.RSS.RESTRICT_SESSION_SCOPE
    COMMENT = 'Enforces RSS privilege restrictions on agent sessions.';

-- ============================================================================
-- 2. ATTACH AT ACCOUNT LEVEL
--
-- ⚠️  Production: attach at USER level instead (agent service user only).
--     Account-level is for POC convenience only.
-- ============================================================================

ALTER ACCOUNT SET SESSION POLICY AGENT_SANDBOX_DB.PUBLIC.AGENT_SESSION_POLICY;

-- ============================================================================
-- 3. VERIFY
-- ============================================================================

SHOW SESSION POLICIES IN ACCOUNT;
DESCRIBE SESSION POLICY AGENT_SANDBOX_DB.PUBLIC.AGENT_SESSION_POLICY;

-- ============================================================================
-- NEXT: Execute sql/04_test_governance.sql
-- ============================================================================
