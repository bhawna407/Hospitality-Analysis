**Hospitality Operations Analysis: Guest Experience & Revenue Performance**

1. **PROJECT BACKGROUND**
AtliQ Grands is a luxury business hotel chain operating across major Indian cities. The management team required a unified analytics view to monitor occupancy, revenue performance, booking channels, cancellations, and guest ratings. The objective of this project was to design an interactive Power BI dashboard enabling stakeholders to track hospitality KPIs, diagnose performance gaps, and support data-driven operational and pricing decisions.

2. **KEY INSIGHTS**
**Occupancy Performance**: The dashboard indicates an overall occupancy of 57.9%, suggesting underutilized room capacity across properties.

**Revenue Metrics**: Despite a stable ADR (~14.92K), RevPAR (~0.01) remains low, implying revenue inefficiencies driven by occupancy rather than pricing.

**City-Level Contribution**: Mumbai leads total revenue generation, while other cities trail, highlighting uneven property performance.

**Booking Platform Mix**: A noticeable share of revenue is driven by third-party platforms, signaling potential commission cost pressures.

**Cancellation Rate**: The overall cancellation rate (~24.83%) points toward revenue volatility and forecasting challenges.

**Weekend vs Weekday Trends**: Weekend occupancy (62.6%) exceeds weekday levels (56.0%), revealing demand concentration patterns.

**Room Class Revenue**: Elite and Premium categories generate higher revenue but may show occupancy gaps compared to Standard rooms.

**Guest Ratings Signal**: Properties with lower average ratings (~3.2–3.8) may reflect service or experience inconsistencies.

3. **RECOMMENDATIONS**
**Occupancy Optimization**: Introduce targeted weekday demand strategies (corporate packages, dynamic offers).

**Channel Strategy Adjustment**: Encourage direct bookings via loyalty incentives to reduce OTA dependency.

**Cancellation Management**: Refine cancellation policies or introduce partial prepayments to stabilize revenue.

**Experience Improvement**: Investigate lower-rated properties for operational/service enhancements.

**Pricing Calibration**: Reassess premium room category pricing vs perceived value.

**KPI Monitoring**: Use the dashboard for continuous tracking of Occupancy %, ADR, RevPAR, Realisation %, and Cancellations.

An interactive Power BI Dashboard (as shown in the screenshots) can be downloaded HERE.

The SQL Queries utilized for inspection and validation can be found HERE.
[HERE](https://github.com/bhawna407/Hospitality-Analysis/blob/main/AtliQ%20Grands%20Hospitality%20Analysis.sql)

SQL Queries used for cleaning and transformation can be found HERE.

Targeted SQL Queries for deeper analysis can be found HERE.

**Data Structure & Initial Checks**
AtliQ Grands’ database structure, as illustrated in the model view, consists of 6 tables: Dim_Hotels, Fact_Bookings, Dim_Date, Dim_Rooms, Fact_Aggregated_Bookings, Dim_Customers, with a total row count of 508,627 records.

![Dashboard](https://github.com/bhawna407/Hospitality-Analysis/blob/main/OYO%20DATAMODEL.png)

Prior to the beginning of the analysis, a variety of chechks were conducted for quality control & familizarization with the datasets. The SQL Queries utilized to inspect & perform quality checks can be found here.

**Executive Summary**

**Overview of Findings**

![Dashboard](https://github.com/bhawna407/Hospitality-Analysis/blob/main/OYO%20.png)

AtliQ Grands’ performance analysis highlights operational and revenue optimization opportunities critical for sustaining profitability and enhancing guest experience. The portfolio-wide occupancy stands at 57.9%, signaling underutilized room capacity despite a stable ADR (~14.92K). Consequently, RevPAR (~0.01) remains below potential, indicating that revenue constraints are driven primarily by occupancy inefficiencies rather than pricing. The dashboard further reveals a cancellation rate of 24.83%, contributing to revenue volatility and forecasting challenges. Demand patterns show stronger weekend occupancy (62.6%) compared to weekday performance (56.0%), suggesting uneven business demand distribution. Additionally, reliance on third-party booking platforms may be exerting margin pressure through commission costs. Variations in average guest ratings (≈3.2–3.8) across properties point toward inconsistencies in service or stay experience. To improve overall performance, AtliQ Grands should prioritize weekday demand stimulation, reduce OTA dependency through direct booking incentives, refine cancellation controls, and address experience gaps in lower-rated properties.

Below is the overview page from the Power BI dashboard, and more examples are included throughout the report. The entire interactive dashboard can be downloaded HERE.

**OCCUPANCY & CAPACITY UTILIZATION**
This section evaluates how effectively AtliQ Grands is utilizing its available room inventory across properties and time periods.

**Occupancy Analysis**: The overall Occupancy Rate of **57.9%** indicates that a significant portion of room capacity remains unsold, directly limiting revenue potential.

**Demand Imbalance**: The noticeable variation between **Weekend Occupancy (62.6%)** and **Weekday Occupancy (56.0%)** suggests uneven demand distribution, pointing toward weaker corporate/business travel during weekdays.

**Utilization Efficiency**: Consistently moderate occupancy levels imply that pricing alone is not the constraint; rather, demand stimulation and channel optimization are required.

**Operational Implication**: Underutilized rooms represent fixed-cost inefficiencies, as operational expenses continue regardless of occupancy.

**REVENUE PERFORMANCE (ADR & RevPAR DYNAMICS)**
This section examines how pricing strategy and room sales efficiency translate into revenue generation.

**ADR Stability**: The Average Daily Rate **(~14.92K)** remains relatively stable, indicating that the brand’s pricing power is intact.

**RevPAR Underperformance**: Despite stable ADR, **RevPAR (~0.01)** remains low, signaling that revenue inefficiencies stem primarily from occupancy gaps rather than pricing weaknesses.

**Monetization Gap**: The disparity between room rates and realized revenue highlights missed opportunities in maximizing revenue per available room.

**Strategic Insight**: Improving occupancy will yield stronger RevPAR gains than aggressive price adjustments.

**BOOKING CHANNELS & REALISATION PERFORMANCE**
This section focuses on revenue sources and how efficiently potential revenue is converted into realized revenue.

**Platform Contribution**: Revenue share from **third-party booking** platforms suggests reliance on OTAs, which may compress margins through commission payouts.

**Realisation % Variance**: Fluctuations in Realisation % indicate inconsistencies between theoretical revenue potential and actual revenue capture.

**Channel Efficiency**: **Higher OTA** dependency may reflect **weaker direct booking engagement or loyalty** program leverage.

**Business Impact**: Channel mix optimization can improve profitability without requiring occupancy growth.

**CANCELLATIONS & GUEST EXPERIENCE SIGNALS**
This section assesses factors affecting revenue stability and customer satisfaction.

**Cancellation Pressure**: The Cancellation Rate (24.83%) introduces revenue volatility, reduces forecast accuracy, and disrupts operational planning.

**Guest Satisfaction Trends**: Properties with lower **average ratings (~3.2–3.8)** suggest experience inconsistencies potentially tied to service quality or room comfort.

**Emotional Insight**: Frequent cancellations and lower ratings may indicate unmet guest expectations or value-perception gaps.

**Strategic Risk**: Experience-related dissatisfaction can affect repeat bookings, brand trust, and long-term occupancy performance.

**RECOMMENDATIONS**
Based on the uncovered insights, the following priority actions are recommended:

**Weekday Demand Stimulation**: Address weekday occupancy gaps by introducing **corporate tie-ups, business travel packages, and targeted weekday offers** to stabilize capacity utilization.

**Dynamic Pricing Optimization**: With stable ADR but weak RevPAR, implement **occupancy-linked pricing strategies** to improve room fill without eroding rate positioning.

**Direct Booking Enhancement**: Reduce OTA dependency and commission costs by strengthening **loyalty benefits, member-exclusive rates, and website-only incentives**.

**Cancellation Control Measures**: Mitigate revenue volatility by adopting **tiered cancellation policies and partial prepayment mechanisms** to improve booking reliability.

