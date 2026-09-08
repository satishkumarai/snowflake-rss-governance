-- Create base tables, load TPCH data, and deploy the semantic view.

--
-- Account: ct52611 | Run as: ACCOUNTADMIN
-- Run AFTER 01_setup.sql. Run BEFORE 02_rss_scope.sql.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- 1. DATABASE + SCHEMA
-- ============================================================================

CREATE DATABASE IF NOT EXISTS RETAIL_ANALYTICS
    COMMENT = 'Retail data for the RSS + Cortex Agent POC.';

CREATE SCHEMA IF NOT EXISTS RETAIL_ANALYTICS.RAW_DATA;

-- ============================================================================
-- 2. BASE TABLES
-- ============================================================================

CREATE OR REPLACE TABLE RETAIL_ANALYTICS.RAW_DATA.ORDERS (
    ORDER_ID        NUMBER(38,0),
    CUSTOMER_ID     NUMBER(38,0),
    ORDER_STATUS    VARCHAR(50),
    TOTAL_PRICE     NUMBER(12,2),
    ORDER_DATE      DATE,
    ORDER_PRIORITY  VARCHAR(50),
    CLERK           VARCHAR(100),
    SHIP_PRIORITY   NUMBER(38,0),
    COMMENT         VARCHAR(500),
    UPDATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE RETAIL_ANALYTICS.RAW_DATA.CUSTOMERS (
    CUSTOMER_ID     NUMBER(38,0),
    CUSTOMER_NAME   VARCHAR(100),
    ADDRESS         VARCHAR(200),
    NATION_ID       NUMBER(38,0),
    PHONE           VARCHAR(50),
    ACCOUNT_BALANCE NUMBER(12,2),
    MARKET_SEGMENT  VARCHAR(50),
    COMMENT         VARCHAR(500),
    UPDATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE RETAIL_ANALYTICS.RAW_DATA.PRODUCTS (
    PART_ID         NUMBER(38,0),
    PART_NAME       VARCHAR(200),
    MANUFACTURER    VARCHAR(100),
    BRAND           VARCHAR(50),
    PART_TYPE       VARCHAR(100),
    SIZE            NUMBER(38,0),
    CONTAINER       VARCHAR(50),
    RETAIL_PRICE    NUMBER(12,2),
    COMMENT         VARCHAR(500),
    UPDATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- 3. LOAD FROM TPCH_SF1
-- ============================================================================

INSERT INTO RETAIL_ANALYTICS.RAW_DATA.ORDERS
SELECT
    O_ORDERKEY,
    O_CUSTKEY,
    O_ORDERSTATUS,
    O_TOTALPRICE,
    O_ORDERDATE,
    O_ORDERPRIORITY,
    O_CLERK,
    O_SHIPPRIORITY,
    O_COMMENT,
    CURRENT_TIMESTAMP()
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
LIMIT 5000;

INSERT INTO RETAIL_ANALYTICS.RAW_DATA.CUSTOMERS
SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    CURRENT_TIMESTAMP()
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
LIMIT 1000;

INSERT INTO RETAIL_ANALYTICS.RAW_DATA.PRODUCTS
SELECT
    P_PARTKEY,
    P_NAME,
    P_MFGR,
    P_BRAND,
    P_TYPE,
    P_SIZE,
    P_CONTAINER,
    P_RETAILPRICE,
    P_COMMENT,
    CURRENT_TIMESTAMP()
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART
LIMIT 1000;

-- ============================================================================
-- 4. SEMANTIC VIEW
--
-- Exposes ORDERS, CUSTOMERS, PRODUCTS for natural-language querying.
-- Defines facts (numeric measures) and dimensions (grouping columns).
-- Includes 3 verified queries that map to test cases.
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW RETAIL_ANALYTICS.RAW_DATA.RETAIL_SV
    TABLES (
        RETAIL_ANALYTICS.RAW_DATA.ORDERS,
        RETAIL_ANALYTICS.RAW_DATA.CUSTOMERS PRIMARY KEY (CUSTOMER_ID),
        RETAIL_ANALYTICS.RAW_DATA.PRODUCTS
    )
    FACTS (
        ORDERS.TOTAL_PRICE     AS TOTAL_PRICE,
        CUSTOMERS.ACCOUNT_BALANCE AS ACCOUNT_BALANCE,
        PRODUCTS.RETAIL_PRICE  AS RETAIL_PRICE
    )
    DIMENSIONS (
        ORDERS.ORDER_ID        AS ORDER_ID,
        ORDERS.CUSTOMER_ID     AS CUSTOMER_ID,
        ORDERS.ORDER_STATUS    AS ORDER_STATUS,
        ORDERS.ORDER_PRIORITY  AS ORDER_PRIORITY,
        ORDERS.CLERK           AS CLERK,
        ORDERS.ORDER_DATE      AS ORDER_DATE,
        CUSTOMERS.CUSTOMER_ID  AS CUSTOMER_ID,
        CUSTOMERS.CUSTOMER_NAME AS CUSTOMER_NAME,
        CUSTOMERS.MARKET_SEGMENT AS MARKET_SEGMENT,
        PRODUCTS.PART_ID       AS PART_ID,
        PRODUCTS.PART_NAME     AS PART_NAME,
        PRODUCTS.MANUFACTURER  AS MANUFACTURER,
        PRODUCTS.BRAND         AS BRAND,
        PRODUCTS.PART_TYPE     AS PART_TYPE
    )
    COMMENT = 'Retail analytics model for orders, customers, and products'
    AI_VERIFIED_QUERIES (
        "vq_orders" AS (
            QUESTION 'How many orders are there and what is the total revenue?'
            SQL 'SELECT COUNT(*) AS total_orders, SUM(TOTAL_PRICE) AS total_revenue FROM orders'
        ),
        "vq_segments" AS (
            QUESTION 'What are the top market segments by number of customers?'
            SQL 'SELECT MARKET_SEGMENT, COUNT(*) AS customer_count FROM customers GROUP BY MARKET_SEGMENT ORDER BY customer_count DESC'
        ),
        "vq_status" AS (
            QUESTION 'What is the order count and revenue by status?'
            SQL 'SELECT ORDER_STATUS, COUNT(*) AS order_count, SUM(TOTAL_PRICE) AS revenue FROM orders GROUP BY ORDER_STATUS'
        )
    );

-- ============================================================================
-- VERIFY
-- ============================================================================

SELECT 'ORDERS'    AS table_name, COUNT(*) AS row_count FROM RETAIL_ANALYTICS.RAW_DATA.ORDERS
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM RETAIL_ANALYTICS.RAW_DATA.CUSTOMERS
UNION ALL
SELECT 'PRODUCTS',  COUNT(*) FROM RETAIL_ANALYTICS.RAW_DATA.PRODUCTS;

DESCRIBE SEMANTIC VIEW RETAIL_ANALYTICS.RAW_DATA.RETAIL_SV;

-- ============================================================================
-- NEXT: Execute sql/01c_deploy_agent.sql
-- ============================================================================
