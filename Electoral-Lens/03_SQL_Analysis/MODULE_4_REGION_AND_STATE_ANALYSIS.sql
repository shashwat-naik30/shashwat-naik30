/*=========================================================
MODULE_4_REGION_AND_STATE_ANALYSIS
=========================================================*/

/*---------------------------------------------------------
Query 36 : Winning Alliance in Every Government of India Region

Business Question:
Which alliance won the maximum number of Lok Sabha seats in each Government of India region?
---------------------------------------------------------*/

WITH regional_alliance AS
(
    SELECT
        rg.region_id,
        rg.region_name,
        p.alliance_name,
        COUNT(*) AS seats_won,
        ROW_NUMBER() OVER
        (
            PARTITION BY rg.region_id
            ORDER BY COUNT(*) DESC
        ) AS ranking
    FROM winner_summary w
    JOIN constituency c
        ON w.constituency_id = c.constituency_id
    JOIN state s
        ON c.state_id = s.state_id
    JOIN region rg
        ON s.region_id = rg.region_id
    JOIN party p
        ON w.winner_party_id = p.party_id
    GROUP BY
        rg.region_id,
        rg.region_name,
        p.alliance_name
)
SELECT
    region_name,
    alliance_name,
    seats_won
FROM regional_alliance
WHERE ranking = 1
ORDER BY region_id;


/*---------------------------------------------------------
Query 37 : Top Three Political Parties Within Every Alliance

Business Question:
Which three political parties contributed the highest number of Lok Sabha seats within every alliance?
---------------------------------------------------------*/

WITH ranked_parties AS
(
    SELECT
        p.alliance_name,
        p.party_name,
        COUNT(*) AS seats_won,
        ROW_NUMBER() OVER
        (
            PARTITION BY p.alliance_name
            ORDER BY COUNT(*) DESC
        ) AS ranking
    FROM winner_summary w
    JOIN party p
        ON w.winner_party_id = p.party_id
    GROUP BY
        p.alliance_name,
        p.party_name
)

SELECT
    alliance_name,
    party_name,
    seats_won
FROM ranked_parties
WHERE ranking <= 3
ORDER BY
    alliance_name,
    ranking;


/*---------------------------------------------------------
Query 38 : Largest Political Party in Every Region

Business Question:
Which political party won the highest number of Lok Sabha seats in each Government of India region?
---------------------------------------------------------*/

WITH regional_party AS
(
    SELECT
        rg.region_id,
        rg.region_name,
        p.party_name,
        COUNT(*) AS seats_won,
        ROW_NUMBER() OVER
        (
            PARTITION BY rg.region_id
            ORDER BY COUNT(*) DESC
        ) AS ranking
    FROM winner_summary w
    JOIN constituency c
        ON w.constituency_id = c.constituency_id
    JOIN state s
        ON c.state_id = s.state_id
    JOIN region rg
        ON s.region_id = rg.region_id
    JOIN party p
        ON w.winner_party_id = p.party_id
    GROUP BY
        rg.region_id,
        rg.region_name,
        p.party_name
)

SELECT
    region_name,
    party_name,
    seats_won
FROM regional_party
WHERE ranking = 1
ORDER BY region_id;


/*---------------------------------------------------------
Query 39 : Top Five Political Parties in Every Region

Business Question:
Which are the five strongest political parties in every Government of India region based on Lok Sabha seats won?
---------------------------------------------------------*/

WITH regional_party AS
(
    SELECT
        rg.region_id,
        rg.region_name,
        p.party_name,
        COUNT(*) AS seats_won,
        ROW_NUMBER() OVER
        (
            PARTITION BY rg.region_id
            ORDER BY COUNT(*) DESC
        ) AS ranking
    FROM winner_summary w
    JOIN constituency c
        ON w.constituency_id = c.constituency_id
    JOIN state s
        ON c.state_id = s.state_id
    JOIN region rg
        ON s.region_id = rg.region_id
    JOIN party p
        ON w.winner_party_id = p.party_id
    GROUP BY
        rg.region_id,
        rg.region_name,
        p.party_name
)

SELECT
    region_name,
    party_name,
    seats_won
FROM regional_party
WHERE ranking <= 5
ORDER BY
    region_id,
    ranking;


/*---------------------------------------------------------
Query 40 : Alliance Vote Share Across Regions

Business Question:
How did each alliance perform in terms of total votes across every Government of India region?
---------------------------------------------------------*/

SELECT
    rg.region_name,
    p.alliance_name,
    SUM(r.total_votes) AS total_votes,
    ROUND(
        SUM(r.total_votes) * 100.0 /
        SUM(SUM(r.total_votes)) OVER (PARTITION BY rg.region_id),
        2
    ) AS regional_vote_share
FROM result r
JOIN party p
    ON r.party_id = p.party_id
JOIN constituency c
    ON r.constituency_id = c.constituency_id
JOIN state s
    ON c.state_id = s.state_id
JOIN region rg
    ON s.region_id = rg.region_id
GROUP BY
    rg.region_id,
    rg.region_name,
    p.alliance_name
ORDER BY
    rg.region_id,
    regional_vote_share DESC;
    
    /*---------------------------------------------------------
Query 41 : Top Three Political Parties in Every State

Business Question:
Which are the top three political parties in every state based on Lok Sabha seats won?
---------------------------------------------------------*/

WITH ranked_parties AS
(
SELECT
    s.state_id,
    s.state_name,
    p.party_name,
    COUNT(*) AS seats_won,
    ROW_NUMBER() OVER
    (
        PARTITION BY s.state_id
        ORDER BY COUNT(*) DESC
    ) AS ranking
FROM winner_summary w
JOIN constituency c
ON w.constituency_id=c.constituency_id
JOIN state s
ON c.state_id=s.state_id
JOIN party p
ON w.winner_party_id=p.party_id
GROUP BY
    s.state_id,
    s.state_name,
    p.party_name
)

SELECT
    state_name,
    party_name,
    seats_won
FROM ranked_parties
WHERE ranking<=3
ORDER BY
    state_name,
    ranking;


/*---------------------------------------------------------
Query 42 : States Without a Majority Alliance

Business Question:
Which states did not have a single alliance winning more than 50% of the Lok Sabha seats?
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
),

total_seats AS
(
SELECT
    state_id,
    COUNT(*) AS total_seats
FROM constituency
GROUP BY state_id
),

majority_check AS
(
SELECT
    a.state_id,
    a.state_name,
    MAX(a.seats_won) AS highest_seats
FROM alliance_seats a
GROUP BY
    a.state_id,
    a.state_name
)

SELECT
    m.state_name,
    m.highest_seats,
    t.total_seats
FROM majority_check m
JOIN total_seats t
ON m.state_id = t.state_id
WHERE m.highest_seats <= t.total_seats / 2
ORDER BY t.total_seats DESC;


/*---------------------------------------------------------
Query 43 : States Electing the Highest Number of Different Political Parties

Business Question:
Which states elected the highest number of different political parties?
---------------------------------------------------------*/

SELECT
    s.state_name,
    COUNT(DISTINCT p.party_name) AS parties_won,
    COUNT(*) AS total_seats
FROM winner_summary w
JOIN constituency c
ON w.constituency_id=c.constituency_id
JOIN state s
ON c.state_id=s.state_id
JOIN party p
ON w.winner_party_id=p.party_id
GROUP BY
    s.state_id,
    s.state_name
ORDER BY
    parties_won DESC,
    total_seats DESC;


/*---------------------------------------------------------
Query 44 : Region with the Highest Political Diversity

Business Question:
Which Government of India region had the highest political diversity based on winning political parties?
---------------------------------------------------------*/

SELECT
    rg.region_name,
    COUNT(DISTINCT p.party_name) AS parties_won,
    COUNT(*) AS total_seats
FROM winner_summary w
JOIN constituency c
ON w.constituency_id=c.constituency_id
JOIN state s
ON c.state_id=s.state_id
JOIN region rg
ON s.region_id=rg.region_id
JOIN party p
ON w.winner_party_id=p.party_id
GROUP BY
    rg.region_id,
    rg.region_name
ORDER BY
    parties_won DESC;


/*---------------------------------------------------------
Query 45 : Alliance Dependency on Its Largest Political Party

Business Question:
How dependent is each political alliance on its largest political party for winning Lok Sabha seats?
---------------------------------------------------------*/

WITH alliance_stats AS
(
SELECT
    p.alliance_name,
    p.party_name,
    COUNT(*) AS seats_won,
    ROW_NUMBER() OVER
    (
        PARTITION BY p.alliance_name
        ORDER BY COUNT(*) DESC
    ) AS ranking,
    SUM(COUNT(*)) OVER
    (
        PARTITION BY p.alliance_name
    ) AS alliance_total
FROM winner_summary w
JOIN party p
ON w.winner_party_id=p.party_id
GROUP BY
    p.alliance_name,
    p.party_name
)

SELECT
    alliance_name,
    party_name,
    seats_won,
    alliance_total,
    ROUND(seats_won*100.0/alliance_total,2) AS dependency_percentage
FROM alliance_stats
WHERE ranking=1;