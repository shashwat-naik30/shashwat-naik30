USE healthcare_analytics;

-- Query 1: Total number of patients

SELECT COUNT(*) AS total_patients
FROM patients;

-- Query 2: Total number of encounters

SELECT COUNT(*) AS total_encounters
FROM encounters;

-- Query 3: Total number of procedures

SELECT COUNT(*) AS total_procedures
FROM procedures;

-- Query 4: Total number of organizations

SELECT COUNT(*) AS total_organizations
FROM organizations;

-- Query 5: Total number of payers

SELECT COUNT(*) AS total_payers
FROM payers;

-- Query 6: Number of encounters by encounter class
SELECT encounterclass, COUNT(*) AS total_encounters
FROM encounters
GROUP BY encounterclass
ORDER BY total_encounters DESC;


-- Query 7: Patient count by gender
SELECT gender, COUNT(*) AS total_patients
FROM patients
GROUP BY gender
ORDER BY total_patients DESC;

-- Query 8: Number of encounters by payer
SELECT p.name AS payer_name,
       COUNT(*) AS total_encounters
FROM encounters e
JOIN payers p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY total_encounters DESC;


-- Query 9: Patient count by state
SELECT state, COUNT(*) AS total_patients
FROM patients
GROUP BY state
ORDER BY total_patients DESC;

-- Query 10: Average claim cost by encounter class

SELECT encounterclass,
       ROUND(AVG(total_claim_cost), 2) AS avg_claim_cost
FROM encounters
GROUP BY encounterclass
ORDER BY avg_claim_cost DESC;


-- Query 11: Average payer coverage by payer

SELECT p.name AS payer_name,
       ROUND(AVG(e.payer_coverage), 2) AS avg_payer_coverage
FROM encounters e
JOIN payers p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY avg_payer_coverage DESC;


-- Query 12: Total claim cost by payer

SELECT p.name AS payer_name,
       ROUND(SUM(e.total_claim_cost), 2) AS total_claim_cost
FROM encounters e
JOIN payers p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY total_claim_cost DESC;


-- Query 13: Average encounter cost by payer

SELECT p.name AS payer_name,
       ROUND(AVG(e.total_claim_cost), 2) AS avg_encounter_cost
FROM encounters e
JOIN payers p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY avg_encounter_cost DESC;


-- Query 14: Most frequently performed procedures

SELECT description,
       COUNT(*) AS procedure_count
FROM procedures
GROUP BY description
ORDER BY procedure_count DESC
LIMIT 10;

-- Query 15: Most expensive procedures by average base cost

SELECT description,
       ROUND(AVG(base_cost), 2) AS avg_procedure_cost
FROM procedures
GROUP BY description
ORDER BY avg_procedure_cost DESC
LIMIT 10;


-- Query 16: Patients with the highest number of encounters

SELECT patient,
       COUNT(*) AS total_encounters
FROM encounters
GROUP BY patient
ORDER BY total_encounters DESC
LIMIT 10;




-- Query 17: Number of encounters by month

SELECT DATE_FORMAT(start, '%Y-%m') AS month,
       COUNT(*) AS total_encounters
FROM encounters
GROUP BY DATE_FORMAT(start, '%Y-%m')
ORDER BY month;


-- Query 18: Total claim cost by month

SELECT DATE_FORMAT(start, '%Y-%m') AS month,
       ROUND(SUM(total_claim_cost), 2) AS total_claim_cost
FROM encounters
GROUP BY DATE_FORMAT(start, '%Y-%m')
ORDER BY month;


-- Query 19: Average claim cost by month

SELECT DATE_FORMAT(start, '%Y-%m') AS month,
       ROUND(AVG(total_claim_cost), 2) AS avg_claim_cost
FROM encounters
GROUP BY DATE_FORMAT(start, '%Y-%m')
ORDER BY month;

-- Query 20: Total claim cost by patient
SELECT 
    patient,
    ROUND(SUM(total_claim_cost), 2) AS total_claim_cost
FROM encounters
GROUP BY patient
ORDER BY total_claim_cost DESC;


-- Query 21: Average length of an encounter by encounter class
SELECT
    encounterclass,
    ROUND(
        AVG(TIMESTAMPDIFF(HOUR, start, stop)),
        2
    ) AS avg_duration_hours
FROM encounters
WHERE start IS NOT NULL
  AND stop IS NOT NULL
GROUP BY encounterclass
ORDER BY avg_duration_hours DESC;


-- Query 22: Total claim cost by encounter class
SELECT 
    encounterclass,
    ROUND(SUM(total_claim_cost), 2) AS total_claim_cost
FROM encounters
GROUP BY encounterclass
ORDER BY total_claim_cost DESC;


-- Query 23: Patients with the longest total healthcare duration
SELECT
    p.id AS patient_id,
    CONCAT(p.first, ' ', p.last) AS patient_name,
    ROUND(
        SUM(TIMESTAMPDIFF(HOUR, e.start, e.stop)),
        2
    ) AS total_duration_hours
FROM patients p
JOIN encounters e
    ON p.id = e.patient
WHERE e.start IS NOT NULL
  AND e.stop IS NOT NULL
GROUP BY p.id, p.first, p.last
ORDER BY total_duration_hours DESC
LIMIT 10;





-- Query 24: Procedures performed across different encounters
SELECT
    description,
    COUNT(DISTINCT encounter) AS unique_encounters,
    COUNT(*) AS total_procedures
FROM procedures
GROUP BY description
ORDER BY unique_encounters DESC
LIMIT 10;


-- Query 25: Uncovered claim amount by payer

SELECT
    p.name AS payer_name,
    ROUND(SUM(e.total_claim_cost), 2) AS total_claim_cost,
    ROUND(SUM(e.payer_coverage), 2) AS total_payer_coverage,
    ROUND(
        SUM(e.total_claim_cost) - SUM(e.payer_coverage),
        2
    ) AS uncovered_amount
FROM encounters e
JOIN payers p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY uncovered_amount DESC;


-- Query 26: Monthly encounter growth compared with previous month
WITH monthly_encounters AS
(
    SELECT
        DATE_FORMAT(start, '%Y-%m') AS month,
        COUNT(*) AS total_encounters
    FROM encounters
    GROUP BY DATE_FORMAT(start, '%Y-%m')
)
SELECT
    month,
    total_encounters,
    LAG(total_encounters) OVER (ORDER BY month) AS previous_month_encounters,
    total_encounters -
        LAG(total_encounters) OVER (ORDER BY month) AS encounter_change
FROM monthly_encounters
ORDER BY month;

-- Query 27: Patients whose total claim cost is above the average patient cost
SELECT
    patient,
    ROUND(SUM(total_claim_cost), 2) AS total_claim_cost
FROM encounters
GROUP BY patient
HAVING SUM(total_claim_cost) >
(
    SELECT AVG(patient_cost)
    FROM
    (
        SELECT SUM(total_claim_cost) AS patient_cost
        FROM encounters
        GROUP BY patient
    ) AS patient_totals
)
ORDER BY total_claim_cost DESC;


-- Query 28: Percentage of total claim cost covered by each payer
SELECT
    p.name AS payer_name,
    ROUND(SUM(e.payer_coverage), 2) AS total_coverage,
    ROUND(SUM(e.total_claim_cost), 2) AS total_claim_cost,
    ROUND(
        SUM(e.payer_coverage) / NULLIF(SUM(e.total_claim_cost), 0) * 100,
        2
    ) AS coverage_percentage
FROM encounters e
JOIN payers p
    ON e.payer = p.id
GROUP BY p.name
ORDER BY coverage_percentage DESC;




-- Query 29: Top 10 procedures by total spending
SELECT
    description,
    ROUND(SUM(base_cost), 2) AS total_procedure_cost,
    COUNT(*) AS procedure_count
FROM procedures
GROUP BY description
ORDER BY total_procedure_cost DESC
LIMIT 10;




-- Query 30: Monthly claim cost compared with previous month
WITH monthly_cost AS
(
    SELECT
        DATE_FORMAT(start, '%Y-%m') AS month,
        SUM(total_claim_cost) AS total_claim_cost
    FROM encounters
    GROUP BY DATE_FORMAT(start, '%Y-%m')
)
SELECT
    month,
    ROUND(total_claim_cost, 2) AS total_claim_cost,
    ROUND(
        LAG(total_claim_cost) OVER (ORDER BY month),
        2
    ) AS previous_month_cost,
    ROUND(
        total_claim_cost -
        LAG(total_claim_cost) OVER (ORDER BY month),
        2
    ) AS cost_change
FROM monthly_cost
ORDER BY month;


-- Query 31: High-utilization and high-cost patients
WITH patient_summary AS
(
    SELECT
        patient,
        COUNT(*) AS total_encounters,
        SUM(total_claim_cost) AS total_claim_cost
    FROM encounters
    GROUP BY patient
),
thresholds AS
(
    SELECT
        AVG(total_encounters) AS avg_encounters,
        AVG(total_claim_cost) AS avg_cost
    FROM patient_summary
)
SELECT
    ps.patient,
    ps.total_encounters,
    ROUND(ps.total_claim_cost, 2) AS total_claim_cost,
    CASE
        WHEN ps.total_encounters > t.avg_encounters
         AND ps.total_claim_cost > t.avg_cost
        THEN 'High Utilization & High Cost'
        ELSE 'Other'
    END AS patient_category
FROM patient_summary ps
CROSS JOIN thresholds t
WHERE ps.total_encounters > t.avg_encounters
  AND ps.total_claim_cost > t.avg_cost
ORDER BY ps.total_claim_cost DESC;
