-- Deploy the Cortex Agent backed by the RETAIL_SV semantic view.

--
-- Account: ct52611 | Run as: ACCOUNTADMIN
-- Run AFTER 01b_semantic_view.sql. Run BEFORE 02_rss_scope.sql.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- CORTEX AGENT
--
-- The agent takes natural-language questions, generates SQL via the semantic
-- view, and returns results. This is the object that RSS will govern.
--
-- Tools:
--   cortex_analyst_text_to_sql — generates SQL from the semantic view
--
-- Instructions:
--   Concise retail analytics assistant. Shows numbers when asked.
-- ============================================================================

CREATE OR REPLACE AGENT RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT
FROM SPECIFICATION $$
instructions:
  system: |
    You are a retail analytics assistant. Answer questions about orders,
    customers, and products using the RETAIL_ANALYTICS data.
    Be concise. Show numbers and totals when asked.
  sample_questions:
    - question: "How many orders are there and what is the total revenue?"
    - question: "What are the top market segments by number of customers?"
    - question: "What is the order count and revenue by status?"

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "retail_data"
      description: "Query retail orders, customers, and products data"

tool_resources:
  retail_data:
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
    semantic_view: "RETAIL_ANALYTICS.RAW_DATA.RETAIL_SV"
$$;

-- ============================================================================
-- GRANT USAGE TO AGENT_USER
-- ============================================================================

GRANT USAGE ON CORTEX AGENT RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT TO ROLE AGENT_USER;

-- ============================================================================
-- VERIFY
-- ============================================================================

-- Quick test: ask the agent a question
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--     'RETAIL_ANALYTICS.RAW_DATA.RETAIL_AGENT',
--     'How many orders are there and what is the total revenue?'
-- );

-- ============================================================================
-- NEXT: Execute sql/02_rss_scope.sql
-- ============================================================================
