-- =============================================================================
-- OYO HOTELS — DEEP ANALYSIS SQL QUERIES
-- Derived from: OYO_STAKEHOLDER_PROJ.pbix
-- Schema inferred from DataModel + Report/Layout
--
-- TABLES IDENTIFIED:
--   dim_Date        → date, mmm_yyy, week_no, Day_type, Month
--   Dim_Hotels      → property_id, property_name, city, category
--   Dim_Rooms       → room_id, property_id, room_class
--   Fact_Bookings   → booking_id, property_id, room_id, date_id,
--                     booking_platform, revenue_generated,
--                     booking_status (Checked Out / Cancelled / No Show)
--
-- NOTES:
--   • No INSERT/CREATE TABLE statements — data loaded via Power BI Import Mode.
--   • All queries written in standard SQL (compatible with SQL Server / PostgreSQL).
--   • Column aliases match the Power BI display names exactly.
--   • Metrics used in visuals (ADR, RevPar, Occupancy %, etc.) are
--     re-derived here from raw Fact_Bookings columns for analytical depth.
--   • "Realisation %" = URN / SRN  (Successfully realised bookings ratio).
--   • Day_type in dim_Date = 'Weekday' or 'Weekend'.
-- =============================================================================


-- =============================================================================
-- SECTION 1: REVENUE ANALYSIS
-- =============================================================================

-- ── Q1. Monthly Revenue Trend with MoM Growth % ─────────────────────────────
-- Business Question: Which months show revenue dips? Is growth consistent?
-- Problem Solving : Identifies seasonal patterns & revenue momentum for
--                   pricing/inventory strategy.
SELECT
    d.mmm_yyy                                             AS [Month],
    ROUND(SUM(f.revenue_generated), 0)                    AS [Total Revenue],
    LAG(ROUND(SUM(f.revenue_generated), 0))
        OVER (ORDER BY MIN(d.date))                       AS [Prev Month Revenue],
    ROUND(
        (SUM(f.revenue_generated)
         - LAG(SUM(f.revenue_generated)) OVER (ORDER BY MIN(d.date)))
        / NULLIF(LAG(SUM(f.revenue_generated)) OVER (ORDER BY MIN(d.date)), 0)
        * 100, 2)                                         AS [MoM Growth %]
FROM Fact_Bookings f
JOIN dim_Date d ON f.date_id = d.date_id
GROUP BY d.mmm_yyy
ORDER BY MIN(d.date);


-- ── Q2. Revenue by City — Share of Total ─────────────────────────────────────
-- Business Question: Which cities drive the most revenue?
-- Problem Solving : Supports budget allocation and regional expansion decisions.
SELECT
    h.city,
    ROUND(SUM(f.revenue_generated), 0)                   AS [City Revenue],
    ROUND(
        SUM(f.revenue_generated)
        / SUM(SUM(f.revenue_generated)) OVER () * 100, 2) AS [Revenue Share %]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
WHERE f.booking_status = 'Checked Out'
GROUP BY h.city
ORDER BY [City Revenue] DESC;


-- ── Q3. Revenue by Room Class ─────────────────────────────────────────────────
-- Business Question: Do premium room classes justify their inventory allocation?
SELECT
    r.room_class,
    COUNT(f.booking_id)                                   AS [Total Bookings],
    ROUND(SUM(f.revenue_generated), 0)                    AS [Revenue],
    ROUND(AVG(f.revenue_generated), 2)                    AS [Avg Revenue per Booking],
    ROUND(
        SUM(f.revenue_generated)
        / SUM(SUM(f.revenue_generated)) OVER () * 100, 2) AS [Revenue Share %]
FROM Fact_Bookings f
JOIN Dim_Rooms r ON f.room_id = r.room_id
WHERE f.booking_status = 'Checked Out'
GROUP BY r.room_class
ORDER BY [Revenue] DESC;


-- ── Q4. Revenue by Booking Platform ──────────────────────────────────────────
-- Business Question: Is direct booking (website) outperforming OTAs?
-- Problem Solving : Informs commission cost vs. platform dependency trade-off.
SELECT
    f.booking_platform,
    COUNT(f.booking_id)                                   AS [Total Bookings],
    ROUND(SUM(f.revenue_generated), 0)                    AS [Revenue],
    ROUND(AVG(f.revenue_generated), 2)                    AS [ADR],
    ROUND(
        SUM(f.revenue_generated)
        / SUM(SUM(f.revenue_generated)) OVER () * 100, 2) AS [Revenue Share %]
FROM Fact_Bookings f
WHERE f.booking_status = 'Checked Out'
GROUP BY f.booking_platform
ORDER BY [Revenue] DESC;


-- =============================================================================
-- SECTION 2: OCCUPANCY & CAPACITY ANALYSIS
-- =============================================================================

-- ── Q5. Occupancy % by Property (Top & Bottom 5) ────────────────────────────
-- Business Question: Which hotels are underperforming on occupancy?
-- Problem Solving : Triggers targeted promotions or pricing reductions for
--                   low-occupancy properties.
WITH OccupancyBase AS (
    SELECT
        h.property_name,
        h.city,
        COUNT(f.booking_id)                              AS [Total Bookings],
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN 1 ELSE 0 END)                     AS [Checked Out],
        -- Occupancy % = Checked Out / Total Capacity (approximated as total bookings)
        ROUND(
            SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
            * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2) AS [Occupancy %]
    FROM Fact_Bookings f
    JOIN Dim_Hotels h ON f.property_id = h.property_id
    GROUP BY h.property_name, h.city
)
SELECT property_name, city, [Total Bookings], [Checked Out], [Occupancy %], [Rank Group]
FROM (
    SELECT TOP 5 property_name, city, [Total Bookings], [Checked Out], [Occupancy %],
           'Top 5'    AS [Rank Group]
    FROM OccupancyBase
    ORDER BY [Occupancy %] DESC
) AS Top5
UNION ALL
SELECT property_name, city, [Total Bookings], [Checked Out], [Occupancy %], [Rank Group]
FROM (
    SELECT TOP 5 property_name, city, [Total Bookings], [Checked Out], [Occupancy %],
           'Bottom 5' AS [Rank Group]
    FROM OccupancyBase
    ORDER BY [Occupancy %] ASC
) AS Bottom5;


-- ── Q6. Weekday vs Weekend Occupancy & ADR Comparison ───────────────────────
-- Business Question: Does weekend demand support premium pricing?
-- Problem Solving : Guides dynamic pricing strategy (yield management).
SELECT
    d.Day_type,
    COUNT(f.booking_id)                                  AS [Total Bookings],
    SUM(CASE WHEN f.booking_status = 'Checked Out'
             THEN 1 ELSE 0 END)                         AS [Checked Out],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)   AS [Occupancy %],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN f.revenue_generated ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                          THEN 1 ELSE 0 END), 0), 2)   AS [ADR]
FROM Fact_Bookings f
JOIN dim_Date d ON f.date_id = d.date_id
GROUP BY d.Day_type;


-- ── Q7. Weekly Occupancy Trend ────────────────────────────────────────────────
-- Business Question: Are there specific weeks with demand troughs?
SELECT
    d.week_no                                            AS [Week No],
    COUNT(f.booking_id)                                  AS [Total Bookings],
    SUM(CASE WHEN f.booking_status = 'Checked Out'
             THEN 1 ELSE 0 END)                         AS [Checked Out],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)   AS [Occupancy %]
FROM Fact_Bookings f
JOIN dim_Date d ON f.date_id = d.date_id
GROUP BY d.week_no
ORDER BY d.week_no;


-- =============================================================================
-- SECTION 3: CANCELLATION & NO-SHOW ANALYSIS
-- =============================================================================

-- ── Q8. Cancellation Rate by Booking Platform ────────────────────────────────
-- Business Question: Which platforms bring the most cancellations?
-- Problem Solving : Helps renegotiate OTA contracts or add cancellation
--                   penalties for high-churn channels.
SELECT
    f.booking_platform,
    COUNT(f.booking_id)                                  AS [Total Bookings],
    SUM(CASE WHEN f.booking_status = 'Cancelled'
             THEN 1 ELSE 0 END)                         AS [Cancelled],
    SUM(CASE WHEN f.booking_status = 'No Show'
             THEN 1 ELSE 0 END)                         AS [No Show],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)   AS [Cancellation %],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'No Show' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)   AS [No Show %]
FROM Fact_Bookings f
GROUP BY f.booking_platform
ORDER BY [Cancellation %] DESC;


-- ── Q9. Cancellation Rate by Room Class ──────────────────────────────────────
-- Business Question: Are premium rooms more vulnerable to cancellations?
SELECT
    r.room_class,
    COUNT(f.booking_id)                                  AS [Total Bookings],
    SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS [Cancelled],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)   AS [Cancellation %]
FROM Fact_Bookings f
JOIN Dim_Rooms r ON f.room_id = r.room_id
GROUP BY r.room_class
ORDER BY [Cancellation %] DESC;


-- ── Q10. Revenue Lost Due to Cancellations & No Shows ───────────────────────
-- Business Question: What is the financial impact of failed bookings?
-- Problem Solving : Quantifies revenue leakage; justifies stricter
--                   cancellation policy or overbooking buffer.
SELECT
    h.city,
    h.property_name,
    ROUND(SUM(CASE WHEN f.booking_status = 'Checked Out'
                   THEN f.revenue_generated ELSE 0 END), 0)  AS [Revenue Realised],
    ROUND(SUM(CASE WHEN f.booking_status IN ('Cancelled', 'No Show')
                   THEN f.revenue_generated ELSE 0 END), 0)  AS [Revenue Lost (Est.)],
    ROUND(
        SUM(CASE WHEN f.booking_status IN ('Cancelled', 'No Show')
                 THEN f.revenue_generated ELSE 0 END)
        * 100.0
        / NULLIF(SUM(f.revenue_generated), 0), 2)           AS [Revenue Loss %]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.city, h.property_name
ORDER BY [Revenue Lost (Est.)] DESC;


-- =============================================================================
-- SECTION 4: KEY HOSPITALITY METRICS (ADR, RevPAR, Realisation %)
-- =============================================================================

-- ── Q11. ADR (Average Daily Rate) by City & Month ────────────────────────────
-- Business Question: Are cities maintaining pricing discipline over time?
SELECT
    h.city,
    d.mmm_yyy                                            AS [Month],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN f.revenue_generated ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                          THEN 1 ELSE 0 END), 0), 2)   AS [ADR]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
JOIN dim_Date d ON f.date_id = d.date_id
GROUP BY h.city, d.mmm_yyy
ORDER BY h.city, MIN(d.date);


-- ── Q12. RevPAR Analysis by Property ─────────────────────────────────────────
-- Business Question: Which properties generate the most revenue per available room?
-- RevPAR = ADR × Occupancy % = Total Revenue / Total Available Rooms
-- (Approximated as Total Revenue / Total Bookings since capacity data not explicit)
SELECT
    h.property_name,
    h.city,
    h.category,
    COUNT(f.booking_id)                                  AS [Total Bookings],
    ROUND(SUM(f.revenue_generated), 0)                   AS [Total Revenue],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN f.revenue_generated ELSE 0 END)
        / NULLIF(COUNT(f.booking_id), 0), 2)            AS [RevPAR (Approx)]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.property_name, h.city, h.category
ORDER BY [RevPAR (Approx)] DESC;


-- ── Q13. Realisation % by Booking Platform ────────────────────────────────────
-- Business Question: Which platforms actually convert bookings to stays?
-- Realisation % = Checked Out Bookings / Total Bookings (URN / SRN proxy)
SELECT
    f.booking_platform,
    COUNT(f.booking_id)                                  AS [Total Bookings (SRN)],
    SUM(CASE WHEN f.booking_status = 'Checked Out'
             THEN 1 ELSE 0 END)                         AS [Realised Bookings (URN)],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)   AS [Realisation %]
FROM Fact_Bookings f
GROUP BY f.booking_platform
ORDER BY [Realisation %] DESC;


-- =============================================================================
-- SECTION 5: PROPERTY PERFORMANCE BENCHMARKING
-- =============================================================================

-- ── Q14. Full Property Scorecard ─────────────────────────────────────────────
-- Business Question: How does each property rank across all KPIs simultaneously?
-- Problem Solving : One-stop view for GM performance reviews and
--                   underperformer identification.
SELECT
    h.property_name,
    h.city,
    h.category,
    COUNT(f.booking_id)                                                AS [Total Bookings],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Total Revenue],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Occupancy %],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN f.revenue_generated ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                          THEN 1 ELSE 0 END), 0), 2)                  AS [ADR],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Cancellation %],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Realisation %]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.property_name, h.city, h.category
ORDER BY [Total Revenue] DESC;


-- ── Q15. Luxury vs Business Category Comparison ──────────────────────────────
-- Business Question: Does the Luxury segment deliver proportionally higher ADR?
SELECT
    h.category,
    COUNT(DISTINCT h.property_id)                                      AS [Properties],
    COUNT(f.booking_id)                                                AS [Total Bookings],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Total Revenue],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN f.revenue_generated ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                          THEN 1 ELSE 0 END), 0), 2)                  AS [ADR],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Occupancy %],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Cancellation %]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.category;


-- ── Q16. City-wise Property Count & Revenue per Property ─────────────────────
-- Business Question: Are cities with more properties generating proportional revenue?
SELECT
    h.city,
    COUNT(DISTINCT h.property_id)                                      AS [Properties],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Total Revenue],
    ROUND(SUM(f.revenue_generated)
          / NULLIF(COUNT(DISTINCT h.property_id), 0), 0)              AS [Revenue per Property],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Avg Occupancy %]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.city
ORDER BY [Revenue per Property] DESC;


-- =============================================================================
-- SECTION 6: BOOKING PLATFORM DEEP DIVE
-- =============================================================================

-- ── Q17. Platform Performance Matrix ─────────────────────────────────────────
-- Business Question: Which platforms bring high volume but low value (or vice versa)?
-- Problem Solving : Informs channel strategy — invest vs deprioritise platforms.
SELECT
    f.booking_platform,
    COUNT(f.booking_id)                                                AS [Total Bookings],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Total Revenue],
    ROUND(AVG(f.revenue_generated), 2)                                 AS [Avg Booking Value],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out'
                 THEN f.revenue_generated ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                          THEN 1 ELSE 0 END), 0), 2)                  AS [ADR],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Realisation %],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Cancellation %]
FROM Fact_Bookings f
GROUP BY f.booking_platform
ORDER BY [Total Revenue] DESC;


-- ── Q18. Platform Preference by Room Class ───────────────────────────────────
-- Business Question: Do luxury room bookers prefer certain platforms?
SELECT
    f.booking_platform,
    r.room_class,
    COUNT(f.booking_id)                                                AS [Bookings],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Revenue]
FROM Fact_Bookings f
JOIN Dim_Rooms r ON f.room_id = r.room_id
GROUP BY f.booking_platform, r.room_class
ORDER BY f.booking_platform, [Bookings] DESC;


-- =============================================================================
-- SECTION 7: ADVANCED / PROBLEM-SOLVING QUERIES
-- =============================================================================

-- ── Q19. Revenue Concentration Risk (80/20 Analysis) ─────────────────────────
-- Business Question: Are 20% of properties generating 80% of revenue?
-- Problem Solving : Identifies over-reliance on a few properties — a business risk.
WITH PropertyRevenue AS (
    SELECT
        h.property_name,
        h.city,
        ROUND(SUM(f.revenue_generated), 0)                             AS [Revenue],
        ROUND(SUM(f.revenue_generated)
              / SUM(SUM(f.revenue_generated)) OVER () * 100, 2)       AS [Revenue Share %],
        ROUND(SUM(SUM(f.revenue_generated))
              OVER (ORDER BY SUM(f.revenue_generated) DESC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
              / SUM(SUM(f.revenue_generated)) OVER () * 100, 2)       AS [Cumulative Revenue %]
    FROM Fact_Bookings f
    JOIN Dim_Hotels h ON f.property_id = h.property_id
    GROUP BY h.property_name, h.city
)
SELECT *,
    CASE WHEN [Cumulative Revenue %] <= 80 THEN 'Top 80% Contributors'
         ELSE 'Tail' END                                               AS [Segment]
FROM PropertyRevenue
ORDER BY [Revenue] DESC;


-- ── Q20. Month-over-Month Cancellation Spike Detection ───────────────────────
-- Business Question: Did cancellation rates spike in any month? What triggered it?
-- Problem Solving : Early warning system for demand shocks or policy issues.
SELECT
    d.mmm_yyy                                                          AS [Month],
    COUNT(f.booking_id)                                                AS [Total Bookings],
    SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)   AS [Cancellations],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Cancellation %],
    LAG(ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2))
        OVER (ORDER BY MIN(d.date))                                    AS [Prev Month Cancel %],
    ROUND(
        ROUND(
          SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)
        - LAG(ROUND(
            SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
            * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2))
          OVER (ORDER BY MIN(d.date)), 2)                              AS [MoM Change (pp)]
FROM Fact_Bookings f
JOIN dim_Date d ON f.date_id = d.date_id
GROUP BY d.mmm_yyy
ORDER BY MIN(d.date);


-- ── Q21. Underperforming Properties: Low Occupancy + High Cancellation ────────
-- Business Question: Which properties need immediate intervention?
-- Problem Solving : Flags properties for operational review, targeted marketing,
--                   or contract renegotiation.
WITH PropertyStats AS (
    SELECT
        h.property_name,
        h.city,
        h.category,
        COUNT(f.booking_id)                                            AS [Total Bookings],
        ROUND(
            SUM(CASE WHEN f.booking_status = 'Checked Out' THEN 1 ELSE 0 END)
            * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)             AS [Occupancy %],
        ROUND(
            SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
            * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)             AS [Cancellation %],
        ROUND(SUM(f.revenue_generated), 0)                            AS [Revenue]
    FROM Fact_Bookings f
    JOIN Dim_Hotels h ON f.property_id = h.property_id
    GROUP BY h.property_name, h.city, h.category
),
Averages AS (
    SELECT
        AVG([Occupancy %])     AS [Avg Occupancy],
        AVG([Cancellation %])  AS [Avg Cancellation]
    FROM PropertyStats
)
SELECT
    ps.*,
    CASE
        WHEN ps.[Occupancy %] < a.[Avg Occupancy]
         AND ps.[Cancellation %] > a.[Avg Cancellation] THEN '🔴 Critical'
        WHEN ps.[Occupancy %] < a.[Avg Occupancy]       THEN '🟡 Low Occupancy'
        WHEN ps.[Cancellation %] > a.[Avg Cancellation] THEN '🟡 High Cancellation'
        ELSE '🟢 Healthy'
    END                                                                AS [Status Flag]
FROM PropertyStats ps, Averages a
ORDER BY [Status Flag], [Revenue];


-- ── Q22. Revenue Recovery: What If No-Shows Were Converted? ──────────────────
-- Business Question: How much revenue could be recovered with better no-show management?
-- Problem Solving : Quantifies the ROI of deposit policy / prepaid booking incentives.
SELECT
    h.city,
    SUM(CASE WHEN f.booking_status = 'No Show'
             THEN 1 ELSE 0 END)                                        AS [No Show Count],
    ROUND(SUM(CASE WHEN f.booking_status = 'No Show'
                   THEN f.revenue_generated ELSE 0 END), 0)           AS [Lost Revenue (No Shows)],
    ROUND(SUM(CASE WHEN f.booking_status = 'Checked Out'
                   THEN f.revenue_generated ELSE 0 END)
          / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                            THEN 1 ELSE 0 END), 0), 2)                AS [Avg ADR (Realised)],
    -- Recovery potential if 50% of no-shows converted at avg ADR
    ROUND(
        SUM(CASE WHEN f.booking_status = 'No Show' THEN 1 ELSE 0 END) * 0.5
        * (SUM(CASE WHEN f.booking_status = 'Checked Out'
                    THEN f.revenue_generated ELSE 0 END)
           / NULLIF(SUM(CASE WHEN f.booking_status = 'Checked Out'
                             THEN 1 ELSE 0 END), 0)), 0)              AS [Recovery Potential (50%)]
FROM Fact_Bookings f
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.city
ORDER BY [Lost Revenue (No Shows)] DESC;


-- ── Q23. Booking Lead Time Proxy — Weekday vs Weekend Booking Patterns ────────
-- Business Question: Do weekend bookings skew toward last-minute channels?
-- (Uses Day_type as proxy since explicit lead-time column not in schema)
SELECT
    d.Day_type,
    f.booking_platform,
    COUNT(f.booking_id)                                                AS [Bookings],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Revenue],
    ROUND(
        SUM(CASE WHEN f.booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(f.booking_id), 0), 2)                  AS [Cancellation %]
FROM Fact_Bookings f
JOIN dim_Date d ON f.date_id = d.date_id
GROUP BY d.Day_type, f.booking_platform
ORDER BY d.Day_type, [Bookings] DESC;


-- ── Q24. Rolling 4-Week Revenue Trend per City ───────────────────────────────
-- Business Question: Is city-level revenue trending up or down recently?
-- Problem Solving : Early detection of demand erosion in specific markets.
SELECT
    h.city,
    d.week_no                                                          AS [Week No],
    ROUND(SUM(f.revenue_generated), 0)                                 AS [Weekly Revenue],
    ROUND(AVG(SUM(f.revenue_generated))
          OVER (PARTITION BY h.city
                ORDER BY d.week_no
                ROWS BETWEEN 3 PRECEDING AND CURRENT ROW), 0)        AS [4-Week Rolling Avg Revenue]
FROM Fact_Bookings f
JOIN dim_Date d ON f.date_id = d.date_id
JOIN Dim_Hotels h ON f.property_id = h.property_id
GROUP BY h.city, d.week_no
ORDER BY h.city, d.week_no;


-- =============================================================================
-- END OF FILE
-- Total: 24 queries across 7 analytical sections
-- =============================================================================
