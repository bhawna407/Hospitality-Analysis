
-- Hospitality Domain (Marketing or Revenue ) ---
USE CODEBASICS;

-- Table Calendar DIM--

CREATE TABLE hotel_calendar (
    booking_date DATE,
    mmm_yy VARCHAR(7),
    week_no VARCHAR(10),
    day_type VARCHAR(10)
);

SELECT * FROM hotel_calendar;

-- Table Hotels DIM --

CREATE TABLE Hotels (
    property_id INT PRIMARY KEY,
    property_name VARCHAR(100),
    category VARCHAR(50),
    city VARCHAR(50)
);

SELECT * FROM Hotels;

-- Table Rooms DIM --

CREATE TABLE Rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    room_class VARCHAR(50)
);

SELECT * FROM Rooms;

-- Table FACT Aggregated Bookings --

CREATE TABLE FACT_Aggregated_Bookings (
    property_id INT,
    check_in_date DATE,
    room_category VARCHAR(10),
    successful_bookings INT,
    capacity INT
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_aggregated_bookings.csv'
INTO TABLE FACT_Aggregated_Bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM FACT_Aggregated_Bookings;


-- Table Bookings FACT --

CREATE TABLE FACT_Bookings (
    booking_id VARCHAR(50),
    property_id INT,
    booking_date DATE,
    check_in_date DATE,
    checkout_date DATE,
    no_guests INT,
    room_category VARCHAR(10),
    booking_platform VARCHAR(50),
    ratings_given INT,
    booking_status VARCHAR(20),
    revenue_generated DECIMAL(10,2),
    revenue_realized DECIMAL(10,2)
);

LOAD DATA INFILE 
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_bookings.csv'
INTO TABLE FACT_Bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE FACT_Bookings
ADD primary key(booking_id);

SELECT * FROM FACT_Bookings;


-- UNDERSTANDING DATA --
-- Checking Data Types --

DESCRIBE hotel_calendar;
DESCRIBE hotels;
DESCRIBE rooms;
DESCRIBE FACT_Bookings;
DESCRIBE Fact_Aggregated_Bookings;

-- DATA CLEANING --

-- 1 Removing Null Values --

UPDATE hotel_calendar
SET booking_date = (
    SELECT booking_date
    FROM (
        SELECT booking_date
        FROM hotel_calendar
        WHERE booking_date IS NOT NULL
        GROUP BY booking_date
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS t
)
WHERE booking_date IS NULL;

SET SQL_SAFE_UPDATES = 0;

SELECT *
FROM FACT_bookings;

SELECT *
FROM FACT_bookings;

-- IQR -- 

SELECT MAX(revenue_realized) - MIN(revenue_generated)AS IQR
FROM FACT_bookings;

-- Q1 AND Q3 ---
WITH ordered AS (
    SELECT 
        revenue_realized,
        ROW_NUMBER() OVER (ORDER BY revenue_realized) AS rn,
        COUNT(*) OVER () AS total_count
    FROM fact_bookings
),
Quartiles AS  (
SELECT  MAX(revenue_realized) - MIN(revenue_generated)AS IQR,
    MAX(CASE WHEN rn = FLOOR(total_count*0.25) THEN revenue_realized END) AS Q1,
    MAX(CASE WHEN rn = FLOOR(total_count*0.75) THEN revenue_realized END) AS Q3
FROM ordered )

-- FINDING OUTLIERS --

SELECT Q1-1.5*(IQR)
FROM Quartiles;	


-- HOTEL ANALYSIS --

-- Total Revenue --
SELECT SUM(revenue_realized) AS total_revenue
FROM fact_bookings;

-- Total Bookings --
SELECT COUNT(booking_id) AS total_bookings
FROM fact_bookings;

-- Total Capacity --
SELECT SUM(capacity) AS total_capacity
FROM fact_aggregated_bookings;

-- Occupancy % --
SELECT 
ROUND(SUM(successful_bookings)/SUM(capacity)*100,2) AS occupancy_pct
FROM fact_aggregated_bookings;

-- Avg Rating --
SELECT ROUND(AVG(ratings_given),2) AS avg_rating
FROM fact_bookings
WHERE ratings_given IS NOT NULL;

-- Total Cancelled Bookings --
SELECT COUNT(*) AS cancelled_bookings
FROM fact_bookings
WHERE booking_status = 'Cancelled';

-- Cancellation % --
SELECT 
ROUND(
COUNT(CASE WHEN booking_status='Cancelled' THEN 1 END)
/COUNT(*)*100,2) AS cancellation_pct
FROM fact_bookings;

-- Total Checked Out --
SELECT COUNT(*) AS checked_out
FROM fact_bookings
WHERE booking_status = 'Checked Out';

-- Total No Show --
SELECT COUNT(*) AS no_show
FROM fact_bookings
WHERE booking_status = 'No show';


-- RevpAR--  -- MAYBE REMOVE IT -- ? 
SELECT 
ROUND(SUM(revenue_realized)/SUM(capacity),2) AS RevPAR
FROM fact_aggregated_bookings f
JOIN fact_bookings b
ON f.property_id=b.property_id
AND f.check_in_date=b.check_in_date;

-- Daily Booked Room Nights --
SELECT 
ROUND(COUNT(*)/COUNT(DISTINCT check_in_date),2) AS DBRN
FROM fact_bookings
WHERE booking_status='Checked Out';

-- Daily Sellable Room Nights --
SELECT 
ROUND(SUM(capacity)/COUNT(DISTINCT check_in_date),2) AS DSRN
FROM fact_aggregated_bookings;

-- Daily Utilized Room NIghts ---
SELECT 
ROUND(SUM(successful_bookings)/COUNT(DISTINCT check_in_date),2) AS DURN
FROM fact_aggregated_bookings;

-- TREND BASED ANALYSIS ---

-- Revnue WoW% ---
WITH weekly_rev AS (
SELECT d.week_no, SUM(b.revenue_realized) revenue
FROM fact_bookings b
JOIN hotel_calendar d ON b.booking_date=d.booking_date
GROUP BY d.week_no
)
SELECT week_no,
ROUND((revenue-LAG(revenue) OVER())/LAG(revenue) OVER()*100,2) AS wow_revenue_pct
FROM weekly_rev;

SELECT * FROM hotel_Calendar;
SELECT * FROM FACT_bookings;
SELECT * FROM FACT_aggregated_bookings;

-- Occupancy Wow% ---
WITH weekly_occ AS (
SELECT d.week_no,
SUM(f.successful_bookings)/SUM(f.capacity) occ
FROM fact_aggregated_bookings f
JOIN hotel_Calendar d ON f.check_in_date=d.booking_date
GROUP BY d.week_no
)
SELECT week_no,
ROUND((occ-LAG(occ) OVER())/LAG(occ) OVER()*100,2) AS wow_occupancy_pct
FROM weekly_occ;

-- Bookings WoW% ---

SELECT 
    week_no,
    COUNT(b.booking_id) AS total_bookings,
    ROUND(
        (COUNT(b.booking_id) - LAG(COUNT(b.booking_id)) OVER (ORDER BY week_no)) 
        * 100.0 / LAG(COUNT(b.booking_id)) OVER (ORDER BY week_no),
        2
    ) AS booking_wow_percentage
FROM fact_bookings b
JOIN hotel_calendar d
    ON b.booking_date = d.booking_date
GROUP BY week_no
ORDER BY week_no;


-- Total Booking & Revenue (WEEKEND V/S WEEKDAY) ---

SELECT day_type,SUM(revenue_generated)as Total_revenue,COUNT(*)AS Total_Bookings
FROM hotel_Calendar C
Join FACT_bookings B
ON C.booking_date = B.booking_date
GROUP BY day_type;


-- Total Occupancy % (WEEKEND V/S WEEKDAY) ---

SELECT 
    d.day_type,
    ROUND(
        SUM(f.successful_bookings) * 100.0 / 
        SUM(f.capacity),
        2
    ) AS occupancy_percentage
FROM fact_aggregated_bookings f
JOIN hotel_Calendar d
    ON f.check_in_date = d.booking_date
GROUP BY d.day_type
ORDER BY occupancy_percentage DESC;


-- WEEKDAY V/S WEEKEDN Cancelaltion % --

SELECT 
    d.day_type,
    ROUND(
        SUM(CASE 
                WHEN b.booking_status = 'Cancelled' THEN 1 
                ELSE 0 
            END) * 100.0 / COUNT(b.booking_id),
        2
    ) AS cancellation_percentage
FROM fact_bookings b
JOIN hotel_calendar d
    ON b.booking_date = d.booking_date
GROUP BY d.day_type
ORDER BY cancellation_percentage DESC;


-- WEEKDAYS BASED REVENUE ---

SELECT DAYNAME(B.booking_date)AS DAYS,SUM(revenue_generated)as Total_revenue
FROM hotel_Calendar C
Join FACT_bookings B
ON C.booking_date = B.booking_date
GROUP BY DAYS;

-- CITY BASED REVENUE % --

SELECT 
    h.city,
    ROUND(
        SUM(b.revenue_realized) * 100.0 / 
        (SELECT SUM(revenue_realized) FROM fact_bookings),
        2
    ) AS revenue_percentage
FROM fact_bookings b
JOIN hotels h
    ON b.property_id = h.property_id
GROUP BY h.city
ORDER BY revenue_percentage DESC;


-- Hotel category  BASED REVENUE % --

SELECT 
    h.category,
    ROUND(
        SUM(b.revenue_realized) * 100.0 / 
        (SELECT SUM(revenue_realized) FROM fact_bookings),
        2
    ) AS revenue_percentage
FROM fact_bookings b
JOIN hotels h
    ON b.property_id = h.property_id
GROUP BY h.category
ORDER BY revenue_percentage DESC;


-- Revenue % per room_class ---

SELECT 
    r.room_class,
    ROUND(
        SUM(b.revenue_realized) * 100.0 / 
        (SELECT SUM(revenue_realized) FROM fact_bookings),
        2
    ) AS revenue_percentage
FROM rooms r
JOIN fact_bookings b
    ON r.room_id = b.room_category
GROUP BY r.room_class
ORDER BY revenue_percentage DESC;


-- revenue as per Property name ---

SELECT 
    h.property_name,
    ROUND(
        SUM(b.revenue_realized) * 100.0 / 
        (SELECT SUM(revenue_realized) FROM fact_bookings),
        2
    ) AS revenue_percentage
FROM fact_bookings b
JOIN hotels h
    ON b.property_id = h.property_id
GROUP BY h.property_name
ORDER BY revenue_percentage DESC;


-- revenue % by platform type ---

SELECT 
    b.booking_platform,
    ROUND(
        SUM(b.revenue_realized) * 100.0 / 
        (SELECT SUM(revenue_realized) FROM fact_bookings),
        2
    ) AS revenue_percentage
FROM fact_bookings b
GROUP BY b.booking_platform
ORDER BY revenue_percentage DESC;


-- ANALYSIS BASED ON property name ---

-- Total Capacity per property_name --

SELECT property_name,
SUM(capacity)as Total_Capacity
FROM Hotels H
JOIN FACT_aggregated_bookings B
ON H.property_id = B.property_id
GROUP BY property_name;

-- Total Bookings per property_name --

SELECT property_name,COUNT(booking_id)AS Total_bookings
FROM hotels H
JOIN FACT_bookings B
ON H.property_id = B.property_id
GROUP BY property_name;

-- Occupancy % by property_name --

SELECT 
    h.property_name,
    ROUND(
        SUM(f.successful_bookings) * 100.0 / 
        SUM(f.capacity),
        2
    ) AS occupancy_percentage
FROM fact_aggregated_bookings f
JOIN hotels h
    ON f.property_id = h.property_id
GROUP BY h.property_name
ORDER BY occupancy_percentage DESC;


-- Cancellation rate % by property name --

SELECT 
    h.property_name,
    ROUND(
        SUM(CASE 
                WHEN b.booking_status = 'Cancelled' THEN 1 
                ELSE 0 
            END) * 100.0 / COUNT(b.booking_id),
        2
    ) AS cancellation_percentage
FROM fact_bookings b
JOIN hotels h
    ON b.property_id = h.property_id
GROUP BY h.property_name
ORDER BY cancellation_percentage DESC;



-- Average rating per property_name --

SELECT property_name,AVG(ratings_given)AS Avg_ratings
FROM Hotels H
JOIN FACT_bookings B
ON H.property_id = B.property_id
GROUP BY property_name;


-- Total Booking % by Room_catgeory ---

SELECT 
    r.room_class,
    ROUND(
        COUNT(b.booking_id) * 100.0 /
        (SELECT COUNT(*) FROM fact_bookings),
        2
    ) AS bookings_percentage
FROM fact_bookings b
JOIN rooms r
    ON b.room_category = r.room_id
GROUP BY r.room_class
ORDER BY bookings_percentage DESC;


-- CITY BASED ANALYSIS --

-- Total Revenue per city ---

SELECT city,SUM(Revenue_generated)as Total_Revenue
FROM Hotels H
JOIN FACT_bookings B
ON H.property_id = B.property_id
GROUP BY City;


-- Occupancy % by city --

SELECT 
    h.city,
    ROUND(
        SUM(f.successful_bookings) * 100.0 /
        SUM(f.capacity),
        2
    ) AS occupancy_percentage
FROM fact_aggregated_bookings f
JOIN hotels h
    ON f.property_id = h.property_id
GROUP BY h.city
ORDER BY occupancy_percentage DESC;


-- Cancellation % by city --

SELECT city,ROUND(
COUNT(CASE WHEN booking_status = "cancelled" THEN 1 END)*100.0/COUNT(*),2)AS Cancellation
FROM Hotels H
JOIN FACT_bookings B
ON H.property_id = B.property_id
GROUP BY city;


-- Room Class Based ANALYSIS --

-- Total Rvenue per Room class --

SELECT 
    r.room_class,
    SUM(b.revenue_realized) AS total_revenue
FROM rooms r
JOIN fact_bookings b
    ON r.room_id = b.room_category
GROUP BY r.room_class
ORDER BY total_revenue DESC;


-- Total occupancy % per room class --

SELECT 
    r.room_class,
    ROUND(
        SUM(f.successful_bookings) * 100.0 / 
        SUM(f.capacity),
        2
    ) AS occupancy_percentage
FROM rooms r
JOIN fact_aggregated_bookings f
    ON r.room_id = f.room_category
GROUP BY r.room_class
ORDER BY occupancy_percentage DESC;

-- Cancellation % per room class --

SELECT 
    r.room_class,
    ROUND(
        SUM(CASE 
                WHEN b.booking_status = 'Cancelled' THEN 1 
                ELSE 0 
            END) * 100.0 / COUNT(b.booking_id),
        2
    ) AS cancellation_percentage
FROM rooms r
JOIN fact_bookings b
    ON r.room_id = b.room_category
GROUP BY r.room_class
ORDER BY cancellation_percentage DESC;



SELECT * FROM Hotels;
SELECT * FROM rooms;
SELECT * FROM FACT_bookings;
SELECT * FROM FACT_aggregated_bookings;
SELECT * FROM hotel_calendar;



