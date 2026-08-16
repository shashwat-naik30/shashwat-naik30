/*=========================================================
MODULE_3_ALLIANCE_ANALYSIS
=========================================================*/

/*---------------------------------------------------------
Query 21 : Alliance-wise Seat Distribution

Business Question:
Which alliance won the highest number of Lok Sabha seats?
---------------------------------------------------------*/

SELECT
    p.alliance_name,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY p.alliance_name
ORDER BY seats_won DESC;


/*---------------------------------------------------------
Query 22 : Alliance-wise National Vote Share

Business Question:
Which alliance received the highest total votes across India?
---------------------------------------------------------*/

SELECT
    p.alliance_name,
    SUM(r.total_votes) AS total_votes,
    ROUND(
        SUM(r.total_votes) * 100.0 /
        (SELECT SUM(total_votes) FROM result),
        2
    ) AS vote_share_percentage
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY p.alliance_name
ORDER BY total_votes DESC;


/*---------------------------------------------------------
Query 23 : Alliance Strike Rate

Business Question:
Which alliance converted contested seats into victories more efficiently?
---------------------------------------------------------*/

SELECT
    p.alliance_name,

    COUNT(DISTINCT w.constituency_id) AS seats_won,

    COUNT(DISTINCT r.constituency_id) AS seats_contested,

    ROUND(
        COUNT(DISTINCT w.constituency_id) * 100.0 /
        COUNT(DISTINCT r.constituency_id),
        2
    ) AS strike_rate

FROM result r

JOIN party p
ON r.party_id = p.party_id

LEFT JOIN winner_summary w
ON r.party_id = w.winner_party_id
AND r.constituency_id = w.constituency_id

GROUP BY p.alliance_name
ORDER BY strike_rate DESC;


/*---------------------------------------------------------
Query 24 : Alliance Dominance by State

Business Question:
Which alliance dominated each state based on the number of Lok Sabha seats won?
---------------------------------------------------------*/

SELECT
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
    s.state_name,
    p.alliance_name

ORDER BY
    s.state_name,
    seats_won DESC;


/*---------------------------------------------------------
Query 25 : States Completely Swept by a Single Alliance

Business Question:
Which states were completely swept by a single alliance?
---------------------------------------------------------*/

SELECT
    s.state_name,
    p.alliance_name,
    COUNT(*) AS seats_won,
    total.total_seats
FROM winner_summary w

JOIN constituency c
ON w.constituency_id = c.constituency_id

JOIN state s
ON c.state_id = s.state_id

JOIN party p
ON w.winner_party_id = p.party_id

JOIN (
    SELECT
        state_id,
        COUNT(*) AS total_seats
    FROM constituency
    GROUP BY state_id
) AS total
ON c.state_id = total.state_id

GROUP BY
    s.state_name,
    p.alliance_name,
    total.total_seats

HAVING seats_won = total.total_seats;


/*---------------------------------------------------------
Query 26 : Top 20 Closest Electoral Contests

Business Question:
Which were the Top 20 closest contests in the entire election?
---------------------------------------------------------*/

SELECT
    c.constituency_name,
    s.state_name,
    w.winner_candidate,
    pw.party_name AS winner_party,
    w.runner_up_candidate,
    pr.party_name AS runner_up_party,
    w.margin_votes
FROM winner_summary w
JOIN constituency c
    ON w.constituency_id = c.constituency_id
JOIN state s
    ON c.state_id = s.state_id
JOIN party pw
    ON w.winner_party_id = pw.party_id
JOIN party pr
    ON w.runner_up_party_id = pr.party_id
WHERE w.margin_votes IS NOT NULL
ORDER BY w.margin_votes ASC
LIMIT 20;


/*---------------------------------------------------------
Query 27 : Largest Victory Margins

Business Question:
Which candidates won by overwhelming victory margins?
---------------------------------------------------------*/

SELECT
    s.state_name,
    c.constituency_name,
    w.winner_candidate,
    pw.party_name AS winner_party,
    w.margin_votes
FROM winner_summary w
JOIN constituency c
    ON w.constituency_id = c.constituency_id
JOIN state s
    ON c.state_id = s.state_id
JOIN party pw
    ON w.winner_party_id = pw.party_id
WHERE w.margin_votes IS NOT NULL
ORDER BY w.margin_votes DESC
LIMIT 20;


/*---------------------------------------------------------
Query 28 : Most Competitive States

Business Question:
Which states had the most competitive Lok Sabha elections based on average victory margin?
---------------------------------------------------------*/

SELECT
    s.state_name,
    ROUND(AVG(w.margin_votes),0) AS average_margin
FROM winner_summary w
JOIN constituency c
    ON w.constituency_id = c.constituency_id
JOIN state s
    ON c.state_id = s.state_id
WHERE w.margin_votes IS NOT NULL
GROUP BY s.state_name
ORDER BY average_margin;

/*---------------------------------------------------------
Query 29 : Alliance-wise Average Victory Margin

Business Question:
Which alliance generally won Lok Sabha seats with larger victory margins?
---------------------------------------------------------*/

SELECT
    p.alliance_name,
    ROUND(AVG(w.margin_votes),0) AS average_margin,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
    ON w.winner_party_id = p.party_id
WHERE w.margin_votes IS NOT NULL
GROUP BY p.alliance_name
ORDER BY average_margin DESC;


/*---------------------------------------------------------
Query 30 : Constituencies Decided by Fewer Than 1,000 Votes

Business Question:
Which Lok Sabha constituencies were decided by fewer than 1,000 votes?
---------------------------------------------------------*/

SELECT
    s.state_name,
    c.constituency_name,
    w.winner_candidate,
    pw.party_name,
    w.runner_up_candidate,
    w.margin_votes
FROM winner_summary w
JOIN constituency c
    ON w.constituency_id = c.constituency_id
JOIN state s
    ON c.state_id = s.state_id
JOIN party pw
    ON w.winner_party_id = pw.party_id
WHERE w.margin_votes < 1000
ORDER BY w.margin_votes ASC;


/*---------------------------------------------------------
Query 31 : Alliance-wise Seat Share Percentage

Business Question:
How many seats did each alliance win and what percentage of the Lok Sabha does it represent?
---------------------------------------------------------*/

SELECT
    p.alliance_name,
    COUNT(*) AS seats_won,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM winner_summary),
        2
    ) AS seat_share_percentage
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY p.alliance_name
ORDER BY seats_won DESC;


/*---------------------------------------------------------
Query 32 : National Vote Share of Every Alliance

Business Question:
What is the national vote share of every political alliance?
---------------------------------------------------------*/

SELECT
    p.alliance_name,
    SUM(r.total_votes) AS total_votes,
    ROUND(
        SUM(r.total_votes)*100.0/
        (
            SELECT SUM(total_votes)
            FROM result
        ),
        2
    ) AS vote_share
FROM result r
JOIN party p
ON r.party_id=p.party_id
GROUP BY p.alliance_name
ORDER BY total_votes DESC;


/*---------------------------------------------------------
Query 33 : Alliance Seat Efficiency

Business Question:
Which political alliance converted votes into Lok Sabha seats most efficiently?
---------------------------------------------------------*/

SELECT
    alliance_name,
    vote_share,
    seat_share,
    ROUND(
        seat_share/
        vote_share,
        2
    ) AS seat_efficiency
FROM
(
SELECT
p.alliance_name,
ROUND(
SUM(r.total_votes)*100/
(
SELECT SUM(total_votes)
FROM result
),2
) AS vote_share,
ROUND(
COUNT(DISTINCT w.constituency_id)*100/
(
SELECT COUNT(*)
FROM winner_summary
),2
) AS seat_share
FROM party p
JOIN result r
ON p.party_id=r.party_id
LEFT JOIN winner_summary w
ON p.party_id=w.winner_party_id
AND r.constituency_id=w.constituency_id
GROUP BY p.alliance_name
)t
ORDER BY seat_efficiency DESC;


/*---------------------------------------------------------
Query 34 : Vote Share vs Seat Share Representation Analysis

Business Question:
Which political parties are over-represented or under-represented in the Lok Sabha based on their vote share and seat share?
---------------------------------------------------------*/

SELECT
    party_name,
    vote_share,
    seat_share,
    ROUND(seat_share - vote_share, 2) AS representation_difference,

    CASE
        WHEN seat_share > vote_share THEN 'Over-represented'
        WHEN seat_share < vote_share THEN 'Under-represented'
        ELSE 'Proportionally Represented'
    END AS representation_status

FROM
(
    SELECT

        p.party_name,
        ROUND(
            SUM(r.total_votes) * 100.0 /
            (SELECT SUM(total_votes) FROM result),
            2
        ) AS vote_share,
        ROUND(
            COUNT(DISTINCT w.constituency_id) * 100.0 /
            (SELECT COUNT(*) FROM winner_summary),
            2
        ) AS seat_share
    FROM party p
    JOIN result r
        ON p.party_id = r.party_id
    LEFT JOIN winner_summary w
        ON p.party_id = w.winner_party_id
       AND r.constituency_id = w.constituency_id
    GROUP BY p.party_name
) AS party_analysis
ORDER BY representation_difference DESC;


/*---------------------------------------------------------
Query 35 : Region-wise Alliance Seat Distribution

Business Question:
How many Lok Sabha seats were won by each alliance in every region of India?
---------------------------------------------------------*/

SELECT
    rg.region_name,
    SUM(CASE WHEN p.alliance_name='NDA' THEN 1 ELSE 0 END) AS NDA,
    SUM(CASE WHEN p.alliance_name='INDIA' THEN 1 ELSE 0 END) AS INDIA,
    SUM(CASE WHEN p.alliance_name='Others' THEN 1 ELSE 0 END) AS Others
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
    rg.region_name
ORDER BY
    rg.region_id;