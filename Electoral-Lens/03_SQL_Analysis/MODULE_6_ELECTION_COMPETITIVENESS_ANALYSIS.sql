/*=========================================================
MODULE_6_ELECTION_COMPETITIVENESS_ANALYSIS
=========================================================*/

/*---------------------------------------------------------
Query 57 : Deposit Forfeiture Analysis

Business Question:
Which political parties had the highest deposit forfeiture rate in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(*) AS total_candidates,
    SUM(
        CASE
            WHEN CAST(r.vote_share AS DECIMAL(5,2)) < 16.67
            THEN 1
            ELSE 0
        END
    ) AS deposits_forfeited,
    ROUND(
        SUM(
            CASE
                WHEN CAST(r.vote_share AS DECIMAL(5,2)) < 16.67
                THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS forfeiture_rate
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY
    p.party_id,
    p.party_name
HAVING total_candidates >= 5
ORDER BY forfeiture_rate DESC;


/*---------------------------------------------------------
Query 58 : Constituency Competitiveness Classification

Business Question:
How competitive was each constituency based on the victory margin?
---------------------------------------------------------*/

SELECT
    s.state_name,
    c.constituency_name,
    w.winner_candidate,
    p.party_name,
    w.margin_votes,

    CASE
        WHEN w.margin_votes < 1000 THEN 'Photo Finish'
        WHEN w.margin_votes < 5000 THEN 'Highly Competitive'
        WHEN w.margin_votes < 20000 THEN 'Competitive'
        WHEN w.margin_votes < 50000 THEN 'Comfortable'
        ELSE 'Landslide'
    END AS competition_level

FROM winner_summary w

JOIN constituency c
ON w.constituency_id = c.constituency_id

JOIN state s
ON c.state_id = s.state_id

JOIN party p
ON w.winner_party_id = p.party_id

WHERE w.result_status <> 'Unopposed'

ORDER BY
    w.margin_votes;


/*---------------------------------------------------------
Query 59 : NOTA Impact Analysis

Business Question:
In which constituencies was the NOTA vote greater than the victory margin?
---------------------------------------------------------*/

SELECT
    s.state_name,
    c.constituency_name,
    nota.total_votes AS nota_votes,
    w.margin_votes
FROM winner_summary w
JOIN constituency c
ON w.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
JOIN result nota
ON w.constituency_id = nota.constituency_id
WHERE nota.candidate_name='NOTA'
AND CAST(nota.total_votes AS UNSIGNED) > w.margin_votes
ORDER BY
CAST(nota.total_votes AS UNSIGNED) - w.margin_votes DESC;


/*---------------------------------------------------------
Query 60 : State-wise Ranking of Political Parties

Business Question:
How did each political party rank within every state based on the number of Lok Sabha seats won?
---------------------------------------------------------*/

WITH party_seats AS
(
SELECT
    s.state_name,
    p.party_name,
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
    p.party_id,
    p.party_name,
    p.alliance_name
)

SELECT
    state_name,
    party_name,
    alliance_name,
    seats_won,
    DENSE_RANK() OVER
    (
        PARTITION BY state_name
        ORDER BY seats_won DESC
    ) AS party_rank
FROM party_seats
ORDER BY
    state_name,
    party_rank;


/*---------------------------------------------------------
Query 61 : Constituencies Where NOTA Finished Runner-up

Business Question:
Which constituencies had NOTA as the runner-up candidate?
---------------------------------------------------------*/

WITH ranked_votes AS
(
SELECT
    s.state_name,
    c.constituency_name,
    r.candidate_name,
    p.party_name,
    CAST(r.total_votes AS UNSIGNED) AS total_votes,
    DENSE_RANK() OVER
    (
        PARTITION BY r.constituency_id
        ORDER BY CAST(r.total_votes AS UNSIGNED) DESC
    ) AS vote_rank
FROM result r
JOIN constituency c
ON r.constituency_id = c.constituency_id
JOIN state s
ON c.state_id = s.state_id
LEFT JOIN party p
ON r.party_id = p.party_id
)

SELECT
    state_name,
    constituency_name,
    candidate_name,
    total_votes
FROM ranked_votes
WHERE
    vote_rank = 2
    AND candidate_name = 'NOTA'
ORDER BY
    state_name,
    constituency_name;