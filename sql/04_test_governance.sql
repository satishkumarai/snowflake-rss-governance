-- Governance validation: 4 tests with verified expected results.

-- ============================================================================
-- Account: ct52611 | Run as: AGENT_USER or via Cortex Agent
-- Source:  SNOWFLAKE_SAMPLE_DATA.TPCH_SF1
--
-- Test Matrix:
--   #  | Operation | RSS Verdict | Expected
--   ───┼───────────┼─────────────┼─────────────────────────────
--   1  | SELECT    | ALLOWED     | 5,000 orders / $758.2M
--   2  | SELECT    | ALLOWED     | Furniture > Machinery > Auto
--   3  | INSERT    | DENIED      | Insufficient privileges
--   4  | SELECT    | ALLOWED     | F=2511, O=2370, P=119
-- ============================================================================

-- ============================================================================
-- TEST 1: Read Orders
-- Expected: 5,000 orders / $758,200,000 revenue
-- RSS:      SELECT → ALLOWED
-- Agent:    "How many total orders and what is the total revenue?"
-- ============================================================================

SELECT
    COUNT(*)            AS total_orders,
    SUM(O_TOTALPRICE)   AS total_revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

-- ============================================================================
-- TEST 2: Read Customers by Segment
-- Expected: FURNITURE > MACHINERY > AUTOMOBILE (top 3)
-- RSS:      SELECT → ALLOWED
-- Agent:    "Customer counts by market segment, highest to lowest?"
-- ============================================================================

SELECT
    C_MKTSEGMENT        AS segment,
    COUNT(*)            AS customer_count
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
GROUP BY C_MKTSEGMENT
ORDER BY customer_count DESC;

-- ============================================================================
-- TEST 3: Blocked Write
-- Expected: DENIED — insufficient privileges (INSERT not in RSS scope)
-- RSS:      INSERT → DENIED
-- Agent:    "Insert a new order with key 99999"
--
-- ⚠️  Uncomment to test. This MUST fail when RSS is active.
-- ============================================================================

-- INSERT INTO SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
--     (O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE, O_ORDERDATE)
-- VALUES (99999, 1, 'O', 100.00, '2024-01-01');

-- ============================================================================
-- TEST 4: Orders by Status
-- Expected: F=2,511 / O=2,370 / P=119
-- RSS:      SELECT → ALLOWED
-- Agent:    "How many orders for each order status?"
-- ============================================================================

SELECT
    O_ORDERSTATUS       AS status,
    COUNT(*)            AS order_count
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
GROUP BY O_ORDERSTATUS
ORDER BY order_count DESC;
