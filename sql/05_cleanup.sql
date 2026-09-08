-- Full teardown of the RSS + Cortex Agent POC.

-- ============================================================================
-- Account: ct52611 | Run as: ACCOUNTADMIN
--
-- ⚠️  Run from a Snowsight SQL worksheet, NOT CoCo.
-- ⚠️  Run statements ONE AT A TIME in order.
-- ⚠️  Step 1 MUST complete before Step 2.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- 1. DETACH session policy (MUST happen before drop)
-- ============================================================================

ALTER ACCOUNT UNSET SESSION POLICY;

-- ============================================================================
-- 2. DROP session policy
-- ============================================================================

DROP SESSION POLICY IF EXISTS AGENT_SANDBOX_DB.PUBLIC.AGENT_SESSION_POLICY;

-- ============================================================================
-- 3. DROP RSS scope
-- ============================================================================

DROP RESTRICT SESSION SCOPE IF EXISTS GOVERNANCE_DB.RSS.RESTRICT_SESSION_SCOPE;

-- ============================================================================
-- 4. DROP Cortex Agent
-- ============================================================================

DROP CORTEX AGENT IF EXISTS RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT;

-- ============================================================================
-- 5. DROP Semantic View
-- ============================================================================

DROP SEMANTIC VIEW IF EXISTS RETAIL_ANALYTICS.RAW_DATA.RETAIL_SV;

-- ============================================================================
-- 6. DROP role (revokes all grants automatically)
-- ============================================================================

DROP ROLE IF EXISTS AGENT_USER;

-- ============================================================================
-- 7. DROP databases (cascades to all schemas and objects)
-- ============================================================================

DROP DATABASE IF EXISTS AGENT_SANDBOX_DB;
DROP DATABASE IF EXISTS GOVERNANCE_DB;

-- RETAIL_ANALYTICS intentionally NOT dropped — may contain other objects.
-- Uncomment to remove: DROP DATABASE IF EXISTS RETAIL_ANALYTICS;
