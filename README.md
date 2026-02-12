
# 🕊️ Love Peace Harmony: Donation Ecosystem Analysis

**A Data Engineering & Strategic Analytics Framework**

> **The Mission:** Transforming 1,900+ rows of raw, unstructured donation data into an executive dashboard to drive donor retention and campaign ROI.

---

## 📂 1. Project Framework & Strategy

The goal of this project was to move beyond "basic reporting" and into **Strategic Intelligence**. We achieved this by building a pipeline that prioritizes data integrity and executive clarity.

* **Goal:** Identifying high-value donor behaviors to optimize fundraising efforts.
* **Reasoning:** Raw donation exports are often "noisy" (null values, inconsistent booleans). By building a structured SQL staging layer, we ensure that every chart in our final dashboard is based on a "Single Source of Truth."

---

## 📑 2. Exec-Driven Questions

Before touching the code, we defined the metrics that actually matter to stakeholders:

1. **Retention:** Which donors are committed to recurring (Monthly) giving?
2. **Benchmark:** Who are our "Star Donors" exceeding the organizational average?
3. **Accountability:** Which specific campaigns are hitting their fiscal targets?

---

## 🛠️ 3. The Analytical Framework (SQL Pipeline)

### Phase 1: The Reporting Layer (Cleaning & Segmentation)

**Goal:** Standardize messy raw data into a human-readable format.

**Reasoning:** SQL can be a diva about case sensitivity and data types. By using a **View**, we protect the raw data while fixing "t/f" booleans and creating donor "Buckets" (Major vs. Small-Dollar) for easier analysis.

```sql
DROP VIEW IF EXISTS "staging_donations";

CREATE VIEW "staging_donations" AS
SELECT 
    "Name" AS "transaction_id",
    "First Name" || ' ' || "Last Name" AS "donor_name",
    "Email",
    "Form Id" AS "campaign_id",
    "Amount",
    CASE WHEN "Recurring" = 't' THEN 'Monthly' ELSE 'One-Time' END AS "status",
    COALESCE("Frequency", 'One-Time') AS "donation_type",
    CASE 
        WHEN "Amount" >= 500 THEN 'Major Donor'
        WHEN "Amount" >= 100 THEN 'Mid-Tier'
        ELSE 'Small-Dollar'
    END AS "donor_segment"
FROM "decembertransactions";

```

### Phase 2: Deep Aggregation (The LTV Benchmark)

**Goal:** Calculate Lifetime Value (LTV) and establish a global average.

**Reasoning:** A single donation doesn't tell a story; the total history does. Using a **CTE (Common Table Expression)**, we calculated the organizational mean to identify "High-Potential" donors.

```sql
WITH "DonorStats" AS (
    SELECT 
        "Email",
        SUM("Amount") AS "lifetime_value"
    FROM "staging_donations"
    GROUP BY "Email"
)
SELECT 
    "ds".*,
    (SELECT AVG("lifetime_value") FROM "DonorStats") AS "avg_org_ltv"
FROM "DonorStats" AS "ds";

```

### Phase 3: Comparative Analysis (The Performance Join)

**Goal:** Match actual revenue against campaign goals.

**Reasoning:** Since goals aren't in the raw data, we architected a metadata table. We utilized **Explicit Type Casting (`::VARCHAR`)** to resolve data type mismatches between the two tables.

```sql
SELECT 
    "staging_donations"."campaign_id",
    "campaign_goals"."campaign_name",
    SUM("staging_donations"."Amount") AS "total_raised",
    "campaign_goals"."goal_amount",
    (SUM("staging_donations"."Amount") / "campaign_goals"."goal_amount") * 100 AS "percent_to_goal"
FROM "staging_donations"
JOIN "campaign_goals" 
    ON "staging_donations"."campaign_id"::VARCHAR = "campaign_goals"."campaign_id"
GROUP BY 1, 2, 4;

```

---

## 📊 4. Data Visualization & Segmentation

We don't export "everything" to Excel—we export **answers**. Below is the visualization plan for the final dashboard:

| Dashboard Component | Data Source | The Strategic "Why" |
| --- | --- | --- |
| **Donor Mix (Donut)** | `donor_segment` | Shows if the org is too reliant on a few "Major Donors." |
| **Cohort Quality (Bar)** | `status` (Monthly) | Proves the long-term ROI of recurring giving vs. one-time gifts. |
| **Goal Progress (Gauge)** | `percent_to_goal` | Provides real-time "win/loss" data for current campaigns. |
| **Star Donor List** | `avg_org_ltv` | A "hit list" for the outreach team based on benchmark performance. |

---

## 💡 5. Best Practices & Impact

* **Technical Rigor:** Implemented a "Drop and Recreate" deployment pattern to ensure schema updates were cleanly applied.
* **Scalability:** Designed the SQL layer to handle future CSV imports without manual recoding.
* **Actionable Insights:** Discovered that the **Uganda Mattress Campaign** had the highest conversion rate, suggesting stakeholders should pivot marketing focus to tangible, project-based appeals.

---

### **How to Explore This Project**

1. Navigate to the `/sql` folder to view the full pipeline scripts.
2. Review the `/data` folder for the metadata schema requirements.
3. Open the `/docs` folder for the full Excel visualization guide.
