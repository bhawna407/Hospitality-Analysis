Hotel Revenue & Booking Analysis README
1️⃣ Data Structure Description

Tables & Columns:

dim_date – Dates

date, mmm yy, week no, day_type (Weekday/Weekend)

dim_hotels – Hotels

property_id, property_name, category (Luxury/Business), city

dim_rooms – Rooms

room_id, room_class (Standard, Elite, Premium, Presidential)

fact_aggregated_bookings – Aggregated bookings

property_id, check_in_date, room_category, successful_bookings, capacity

fact_bookings – Individual bookings

booking_id, property_id, booking_date, check_in_date, check_out_date, no_guests, room_category, booking_platform, ratings_given, booking_status, revenue_generated, revenue_realized

2️⃣ Data Cleaning Steps

Removed duplicate records and standardized date formats.

Handled missing/null values in key columns (revenue_realized, successful_bookings, capacity).

Ensured room_category → room_id mapping was correct.

Filtered cancelled bookings for relevant metrics.

Checked for consistency across dimension and fact tables.

3️⃣ Executive Summary

The analysis evaluates hotel performance in revenue, occupancy, bookings, and cancellations to identify key drivers and optimization opportunities.

Revenue: Concentrated in a few cities and premium hotels → prioritize marketing & resources.

Occupancy: Premium rooms are highly occupied; Standard/Elite rooms underutilized → promotions and dynamic pricing needed.

Booking Trends: Weekend bookings dominate; WoW fluctuations suggest staffing and inventory adjustments.

Cancellations: Higher on weekdays and lower-tier rooms → policy improvements needed.

Platform Insights: OTAs drive most revenue but higher cancellations → platform-specific retention strategies.

4️⃣ Subpoints & Detailed Analysis

Revenue Contribution

City-wise: Top cities drive ~70% revenue → focus marketing efforts.

Property-wise: Top 3 hotels contribute ~50% revenue → monitor underperformers.

Hotel Category: Luxury hotels ~60% of revenue → premium pricing effective.

Room Class: Presidential & Premium ~55% revenue → optimize availability.

Booking Platform: OTAs ~65% revenue → negotiate commission rates.

Occupancy & Utilization

Room-wise: Standard & Elite rooms lower occupancy → consider promotions.

Property-wise: Some hotels underutilized → operational review needed.

City-wise: High occupancy in top revenue cities → maintain service standards.

Weekday vs Weekend: Occupancy higher on weekends → dynamic pricing recommended.

Room Class: Premium rooms highest occupancy → align pricing with demand.

Booking & Cancellation Trends

Booking %: Majority in top cities & hotels → focus retention strategies.

Cancellation %: Weekday cancellations ~15% higher → revisit policy.

Room Class: Standard rooms show higher cancellations → booking incentives recommended.

Platform: OTA bookings higher cancellations → retention strategies needed.

WoW Analysis: Week-over-week bookings fluctuate 10–20% → plan staffing & inventory accordingly.

5️⃣ Recommendations & Why

Dynamic Pricing: Adjust rates by weekday/weekend & room class → maximize revenue.

Focus on Top Cities & Hotels: Prioritize marketing & loyalty programs → drives higher revenue.

Promote Underutilized Rooms: Standard & Elite rooms → increase occupancy.

Improve Cancellation Policy: Incentives or penalties → reduce revenue leakage.

Optimize Platform Strategy: Negotiate OTA commissions & improve direct bookings → better margins.
