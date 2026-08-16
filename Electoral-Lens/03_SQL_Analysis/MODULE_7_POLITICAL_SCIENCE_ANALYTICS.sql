/*=========================================================
MODULE_7_POLITICAL_SCIENCE_ANALYTICS
=========================================================*/

/*---------------------------------------------------------
Query 62 : Effective Number of Political Parties (ENPV)

Business Question:
How fragmented was the party system in the 2024 General Election based on vote share?
---------------------------------------------------------*/

WITH vote_share AS
(
SELECT
    p.party_name,
    SUM(CAST(r.total_votes AS UNSIGNED)) /
    (SELECT SUM(CAST(total_votes AS UNSIGNED)) FROM result) AS vote_fraction
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY
    p.party_id,
    p.party_name
)

SELECT
    ROUND(
        1 / SUM(POWER(vote_fraction,2)),
        2
    ) AS effective_number_of_parties
FROM vote_share;


/*---------------------------------------------------------
Query 63 : Bipolar vs Multipolar States

Business Question:
Which states experienced bipolar contests and which had multiparty competition?
---------------------------------------------------------*/

SELECT
    s.state_name,
    COUNT(DISTINCT p.party_id) AS winning_parties,

    CASE
        WHEN COUNT(DISTINCT p.party_id) = 1 THEN 'Single Party Dominance'
        WHEN COUNT(DISTINCT p.party_id) = 2 THEN 'Bipolar'
        WHEN COUNT(DISTINCT p.party_id) BETWEEN 3 AND 4 THEN 'Competitive'
        ELSE 'Multipolar'
    END AS political_system
FROM winner_summary w
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY
    s.state_id,
    s.state_name
ORDER BY
    winning_parties DESC;


/*---------------------------------------------------------
Query 64 : Alliance Diversity Index

Business Question:
How many different political parties contributed to each alliance's Lok Sabha tally?
---------------------------------------------------------*/

SELECT
    alliance_name,
    COUNT(DISTINCT party_id) AS contributing_parties,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY
    alliance_name
ORDER BY
    contributing_parties DESC;


/*---------------------------------------------------------
Query 65 : Region-wise Alliance Strongholds

Business Question:
Which alliance dominated each Government of India region in terms of Lok Sabha seats?
---------------------------------------------------------*/

WITH alliance_region AS
(
SELECT
    rg.region_name,
    p.alliance_name,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN region rg
ON s.region_id = rg.region_id
GROUP BY
    rg.region_name,
    p.alliance_name
)

SELECT
    region_name,
    alliance_name,
    seats_won,
    DENSE_RANK() OVER
    (
        PARTITION BY region_name
        ORDER BY seats_won DESC
    ) AS alliance_rank
FROM alliance_region
ORDER BY
    region_name,
    alliance_rank;


/*---------------------------------------------------------
Query 66 : State-wise Contribution to Alliances

Business Question:
Which states contributed the highest number of Lok Sabha seats to each political alliance?
---------------------------------------------------------*/

WITH alliance_state AS
(
SELECT
    p.alliance_name,
    s.state_name,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
GROUP BY
    p.alliance_name,
    s.state_name
)

SELECT
    alliance_name,
    state_name,
    seats_won,
    DENSE_RANK() OVER
    (
        PARTITION BY alliance_name
        ORDER BY seats_won DESC
    ) AS state_rank
FROM alliance_state
ORDER BY
    alliance_name,
    state_rank;