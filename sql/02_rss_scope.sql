-- RSS scope: privilege-only restrictions for the Cortex Agent POC.

-- ============================================================================
-- Account: ct52611 | Run as: ACCOUNTADMIN
--
-- ╔═════════════════════════════════════════════════════════════════════════╗
-- ║  ██ CRITICAL WARNING ██                                               ║
-- ║                                                                       ║
-- ║  Do NOT add blocked_roles to this scope.                              ║
-- ║                                                                       ║
-- ║  • ACCOUNTADMIN lockout: if blocked + account-level session policy,   ║
-- ║    recovery requires a Snowflake Support ticket.                      ║
-- ║                                                                       ║
-- ║  • CoCo IS an agent: blocking its role kills workspace file access    ║
-- ║    and SQL execution.                                                 ║
-- ║                                                                       ║
-- ║  This scope uses PRIVILEGE RESTRICTIONS ONLY — no blocked_roles.      ║
-- ╚═════════════════════════════════════════════════════════════════════════╝
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE GOVERNANCE_DB;
USE SCHEMA RSS;

-- ============================================================================
-- RSS SCOPE
--
-- allowed_privileges: the ONLY privileges an agent session may exercise.
-- Everything else is implicitly denied (INSERT, UPDATE, DELETE, DROP, etc.).
--
-- Privilege         | Purpose
-- ─────────────────────────────────────────────────────────
-- SELECT            | Read tables/views (agent core function)
-- USAGE             | Traverse databases, schemas, warehouses
-- OPERATE           | Execute queries on the warehouse
-- USER              | Workspace access, CoCo session management
-- OBJECT MANAGEMENT | CoCo file writes (CREATE/ALTER workspace objects)
-- ============================================================================

CREATE OR REPLACE RESTRICT SESSION SCOPE GOVERNANCE_DB.RSS.RESTRICT_SESSION_SCOPE
    ALLOWED_PRIVILEGES = (
        'SELECT',
        'USAGE',
        'OPERATE',
        'USER',
        'OBJECT MANAGEMENT'
    )
    COMMENT = 'RSS for Cortex Agent POC — privilege restrictions only, no blocked_roles.';

-- ============================================================================
-- VERIFY
-- ============================================================================

DESCRIBE RESTRICT SESSION SCOPE GOVERNANCE_DB.RSS.RESTRICT_SESSION_SCOPE;

-- ============================================================================
-- NEXT: Deploy semantic view + agent via CoCo, then execute sql/03_session_policy.sql
-- ============================================================================
