USE healthcare_analytics;

-- View 1: Patient Utilization Analysis

CREATE OR REPLACE VIEW vw_patient_utilization AS
SELECT
    p.id AS patient_id,
    CONCAT(p.first, ' ', p.last) AS patient_name,
    COUNT(e.id) AS total_encounters,
    ROUND(SUM(e.total_claim_cost), 2) AS total_claim_cost,
    ROUND(
        SUM(
            TIMESTAMPDIFF(HOUR, e.start, e.stop)
        ),
        2
    ) AS total_duration_hours
FROM patients p
JOIN encounters e
    ON p.id = e.patient
WHERE e.start IS NOT NULL
  AND e.stop IS NOT NULL
GROUP BY
    p.id,
    p.first,
    p.last;
    
-- Validate View 1

SELECT *
FROM vw_patient_utilization
LIMIT 10;



USE healthcare_analytics;

-- View 2: Payer Performance Analysis

CREATE OR REPLACE VIEW vw_payer_performance AS
SELECT
    p.id AS payer_id,
    p.name AS payer_name,
    COUNT(e.id) AS total_encounters,
    ROUND(SUM(e.total_claim_cost), 2) AS total_claim_cost,
    ROUND(SUM(e.payer_coverage), 2) AS total_payer_coverage,
    ROUND(
        SUM(e.total_claim_cost) - SUM(e.payer_coverage),
        2
    ) AS uncovered_amount,
    ROUND(
        SUM(e.payer_coverage)
        / NULLIF(SUM(e.total_claim_cost), 0) * 100,
        2
    ) AS coverage_percentage,
    ROUND(AVG(e.total_claim_cost), 2) AS avg_claim_cost
FROM payers p
JOIN encounters e
    ON p.id = e.payer
GROUP BY
    p.id,
    p.name;
    
    
-- Validate View 2

SELECT *
FROM vw_payer_performance
ORDER BY total_claim_cost DESC;


USE healthcare_analytics;

-- View 3: Procedure Performance Analysis

CREATE OR REPLACE VIEW vw_procedure_performance AS
SELECT
    description AS procedure_name,
    COUNT(*) AS procedure_count,
    COUNT(DISTINCT encounter) AS unique_encounters,
    ROUND(SUM(base_cost), 2) AS total_procedure_cost,
    ROUND(AVG(base_cost), 2) AS avg_procedure_cost
FROM procedures
GROUP BY description;

-- Validate View 3

SELECT *
FROM vw_procedure_performance
ORDER BY total_procedure_cost DESC
LIMIT 10;



USE healthcare_analytics;

-- View 4: Monthly Healthcare Trends

CREATE OR REPLACE VIEW vw_monthly_healthcare_trends AS
WITH monthly_data AS
(
    SELECT
        DATE_FORMAT(start, '%Y-%m') AS month,
        COUNT(*) AS total_encounters,
        SUM(total_claim_cost) AS total_claim_cost,
        AVG(total_claim_cost) AS avg_claim_cost
    FROM encounters
    GROUP BY DATE_FORMAT(start, '%Y-%m')
),
monthly_comparison AS
(
    SELECT
        month,
        total_encounters,
        total_claim_cost,
        avg_claim_cost,
        LAG(total_claim_cost) OVER (ORDER BY month) AS previous_month_cost
    FROM monthly_data
)
SELECT
    month,
    total_encounters,
    ROUND(total_claim_cost, 2) AS total_claim_cost,
    ROUND(avg_claim_cost, 2) AS avg_claim_cost,
    ROUND(previous_month_cost, 2) AS previous_month_cost,
    ROUND(
        total_claim_cost - previous_month_cost,
        2
    ) AS cost_change
FROM monthly_comparison;

-- Validate View 4

SELECT *
FROM vw_monthly_healthcare_trends
ORDER BY month;


USE healthcare_analytics;

-- View 5: Encounter Analysis

CREATE OR REPLACE VIEW vw_encounter_analysis AS
SELECT
    encounterclass,
    COUNT(*) AS total_encounters,
    ROUND(SUM(total_claim_cost), 2) AS total_claim_cost,
    ROUND(AVG(total_claim_cost), 2) AS avg_claim_cost,
    ROUND(
        AVG(TIMESTAMPDIFF(HOUR, start, stop)),
        2
    ) AS avg_duration_hours
FROM encounters
WHERE start IS NOT NULL
  AND stop IS NOT NULL
GROUP BY encounterclass;

-- Validate View 5

SELECT *
FROM vw_encounter_analysis
ORDER BY total_claim_cost DESC;


USE healthcare_analytics;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';