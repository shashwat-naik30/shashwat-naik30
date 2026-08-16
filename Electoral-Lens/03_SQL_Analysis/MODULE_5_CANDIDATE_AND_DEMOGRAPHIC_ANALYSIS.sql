/*=========================================================
MODULE_5_CANDIDATE_AND_DEMOGRAPHIC_ANALYSIS
=========================================================*/

/*---------------------------------------------------------
Query 46 : Youngest Elected Members of Parliament

Business Question:
Who were the youngest candidates elected to the Lok Sabha in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    w.winner_candidate,
    p.party_name,
    p.alliance_name,
    s.state_name,
    c.constituency_name,
    a.age
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN party p
ON w.winner_party_id = p.party_id
WHERE a.age IS NOT NULL
ORDER BY a.age ASC
LIMIT 10;


/*---------------------------------------------------------
Query 47 : Oldest Elected Members of Parliament

Business Question:
Who were the oldest candidates elected to the Lok Sabha in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    w.winner_candidate,
    p.party_name,
    p.alliance_name,
    s.state_name,
    c.constituency_name,
    a.age
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN party p
ON w.winner_party_id = p.party_id
WHERE a.age IS NOT NULL
ORDER BY a.age DESC
LIMIT 10;


/*---------------------------------------------------------
Query 48 : Average Age of Winners by Political Party

Business Question:
What is the average age of elected MPs in each political party?
---------------------------------------------------------*/

SELECT
    p.party_name,
    p.alliance_name,
    COUNT(*) AS total_winners,
    ROUND(AVG(a.age),2) AS average_age
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
JOIN party p
ON w.winner_party_id = p.party_id
WHERE a.age IS NOT NULL
GROUP BY
    p.party_id,
    p.party_name,
    p.alliance_name
HAVING COUNT(*) >= 2
ORDER BY
    average_age ASC;


/*---------------------------------------------------------
Query 49 : Winners by Age Group

Business Question:
How are elected MPs distributed across different age groups?
---------------------------------------------------------*/

SELECT
CASE
    WHEN a.age < 35 THEN 'Below 35'
    WHEN a.age BETWEEN 35 AND 50 THEN '35-50'
    WHEN a.age BETWEEN 51 AND 65 THEN '51-65'
    ELSE 'Above 65'
END AS age_group,
COUNT(*) AS winners
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
WHERE a.age IS NOT NULL
GROUP BY age_group
ORDER BY winners DESC;


/*---------------------------------------------------------
Query 50 : Youngest MP from Every Government of India Region

Business Question:
Who is the youngest elected MP from each Government of India region?
---------------------------------------------------------*/

WITH ranked_age AS
(
SELECT
    rg.region_name,
    w.winner_candidate,
    p.party_name,
    a.age,
    ROW_NUMBER() OVER
    (
        PARTITION BY rg.region_name
        ORDER BY a.age ASC
    ) AS ranking
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN region rg
ON s.region_id = rg.region_id
JOIN party p
ON w.winner_party_id = p.party_id
WHERE a.age IS NOT NULL
)

SELECT
    region_name,
    winner_candidate,
    party_name,
    age
FROM ranked_age
WHERE ranking = 1
ORDER BY region_name;

/*---------------------------------------------------------
Query 51 : Female Candidate Strike Rate by Political Party

Business Question:
Which political parties had the highest success rate among their female candidates?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(DISTINCT a.candidate_name) AS female_candidates,
    COUNT(DISTINCT w.winner_candidate) AS female_winners,
    ROUND(
        COUNT(DISTINCT w.winner_candidate) * 100.0 /
        COUNT(DISTINCT a.candidate_name),
        2
    ) AS strike_rate
FROM application a
JOIN party p
ON a.party_id = p.party_id
LEFT JOIN winner_summary w
ON a.candidate_name = w.winner_candidate
AND a.constituency_id = w.constituency_id
WHERE a.gender = 'Female'
GROUP BY
    p.party_id,
    p.party_name
HAVING female_candidates >= 2
ORDER BY strike_rate DESC;


/*---------------------------------------------------------
Query 52 : Women MPs by Alliance

Business Question:
How many women MPs were elected from each political alliance?
---------------------------------------------------------*/

SELECT
    p.alliance_name,
    COUNT(*) AS women_mps
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
AND w.constituency_id = a.constituency_id
JOIN party p
ON w.winner_party_id = p.party_id
WHERE a.gender = 'Female'
GROUP BY
    p.alliance_name
ORDER BY women_mps DESC;


/*---------------------------------------------------------
Query 53 : Women MPs by Government of India Region

Business Question:
Which Government of India region elected the highest number of women MPs?
---------------------------------------------------------*/

SELECT
    rg.region_name,
    COUNT(*) AS women_mps
FROM winner_summary w
JOIN application a
ON w.winner_candidate = a.candidate_name
AND w.constituency_id = a.constituency_id
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN region rg
ON s.region_id = rg.region_id
WHERE a.gender = 'Female'
GROUP BY
    rg.region_id,
    rg.region_name
ORDER BY women_mps DESC;


/*---------------------------------------------------------
Query 54 : Success Rate of Independent Candidates

Business Question:
How successful were Independent candidates in the 2024 Lok Sabha Elections?
---------------------------------------------------------*/

SELECT
    COUNT(DISTINCT a.candidate_name) AS total_candidates,
    COUNT(DISTINCT w.winner_candidate) AS winners,
    ROUND(
        COUNT(DISTINCT w.winner_candidate) * 100.0 /
        COUNT(DISTINCT a.candidate_name),
        2
    ) AS strike_rate
FROM application a
JOIN party p
ON a.party_id = p.party_id
LEFT JOIN winner_summary w
ON a.candidate_name = w.winner_candidate
AND a.constituency_id = w.constituency_id
WHERE p.party_name = 'Independent';


/*---------------------------------------------------------
Query 55 : National Parties vs Regional / Other Parties

Business Question:
How many Lok Sabha seats were won by National Parties compared to Regional / Other Parties?
---------------------------------------------------------*/

SELECT
    CASE
        WHEN p.party_name IN
        (
            'Bharatiya Janata Party',
            'Indian National Congress',
            'Aam Aadmi Party',
            'Bahujan Samaj Party',
            'Communist Party of India  (Marxist)',
            'National People''s Party'
        )
        THEN 'National Party'
        ELSE 'Regional / Other Party'
    END AS party_category,

    COUNT(*) AS seats_won

FROM winner_summary w

JOIN party p
ON w.winner_party_id = p.party_id

GROUP BY party_category

ORDER BY seats_won DESC;


/*---------------------------------------------------------
Query 56 : States with the Closest NDA vs INDIA Contest

Business Question:
Which states witnessed the closest contest between the NDA and INDIA alliances based on seats won?
---------------------------------------------------------*/

WITH alliance_seats AS
(
SELECT
    s.state_id,
    s.state_name,
    p.alliance_name,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY
    s.state_id,
    s.state_name,
    p.alliance_name
)

SELECT
    state_name,
    MAX(CASE WHEN alliance_name='NDA' THEN seats_won ELSE 0 END) AS NDA_Seats,
    MAX(CASE WHEN alliance_name='INDIA' THEN seats_won ELSE 0 END) AS INDIA_Seats,
    ABS(
        MAX(CASE WHEN alliance_name='NDA' THEN seats_won ELSE 0 END) -
        MAX(CASE WHEN alliance_name='INDIA' THEN seats_won ELSE 0 END)
    ) AS Seat_Difference
FROM alliance_seats
GROUP BY
    state_id,
    state_name
ORDER BY Seat_Difference ASC;