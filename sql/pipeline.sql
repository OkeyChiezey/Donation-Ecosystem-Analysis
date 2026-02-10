-- =============================================
-- PHASE 1: THE REPORTING LAYER (CLEANING)
-- =============================================
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

-- =============================================
-- PHASE 2: DEEP AGGREGATION (BENCHMARKING)
-- =============================================
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
FROM "DonorStats" AS "ds"
ORDER BY "lifetime_value" DESC;

-- =============================================
-- PHASE 3: COMPARATIVE ANALYSIS (GOALS)
-- =============================================
CREATE TABLE IF NOT EXISTS "campaign_goals" (
    "campaign_id" VARCHAR(50) PRIMARY KEY,
    "campaign_name" VARCHAR(100),
    "goal_amount" NUMERIC(12, 2)
);

-- Note: Ensure these IDs match your decembertransactions "Form Id"
INSERT INTO "campaign_goals" ("campaign_id", "campaign_name", "goal_amount")
VALUES 
('44833', 'Uganda Mattresses', 10000.00),
('39380', 'General Fund', 50000.00)
ON CONFLICT DO NOTHING;

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
