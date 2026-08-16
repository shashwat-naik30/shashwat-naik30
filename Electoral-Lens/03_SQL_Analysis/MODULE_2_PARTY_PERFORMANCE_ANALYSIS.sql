/*=========================================================
MODULE_2_PARTY_PERFORMANCE_ANALYSIS
=========================================================*/

/*---------------------------------------------------------
Query 6 : Seat Distribution Among Political Parties

Business Question:
Which political party won the highest number of Lok Sabha seats?
What is the final seat distribution among all political parties?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(*) AS seats_won
FROM winner_summary w
INNER JOIN party p
    ON w.winner_party_id = p.party_id
GROUP BY p.party_name
ORDER BY seats_won DESC;


/*---------------------------------------------------------
Query 7 : Top 10 Political Parties by Seats Won

Business Question:
Which are the Top 10 political parties by seats won?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
ON w.winner_party_id=p.party_id
GROUP BY p.party_name
ORDER BY seats_won DESC
LIMIT 10;


/*---------------------------------------------------------
Query 8 : Seats Won by Independent Candidates

Business Question:
How many seats did Independent candidates win?
---------------------------------------------------------*/

SELECT COUNT(*) AS independent_wins
FROM winner_summary w
JOIN party p
ON w.winner_party_id=p.party_id
WHERE p.party_name='Independent';


/*---------------------------------------------------------
Query 9 : Political Parties That Failed to Win Any Seat

Business Question:
Which political parties failed to win even a single Lok Sabha seat?
---------------------------------------------------------*/

SELECT
    p.party_name
FROM party p
LEFT JOIN winner_summary w
ON p.party_id=w.winner_party_id
WHERE w.winner_party_id IS NULL;


/*---------------------------------------------------------
Query 10 : Political Parties Receiving the Highest Total Votes

Business Question:
Which political parties secured the highest total votes across India?
---------------------------------------------------------*/

SELECT
    p.party_name,
    CASE
        WHEN SUM(r.total_votes) >= 10000000
            THEN CONCAT(ROUND(SUM(r.total_votes)/10000000,2),' Cr')
        WHEN SUM(r.total_votes) >= 100000
            THEN CONCAT(ROUND(SUM(r.total_votes)/100000,2),' Lakh')
        WHEN SUM(r.total_votes) >= 1000
            THEN CONCAT(ROUND(SUM(r.total_votes)/1000,2),' Thousand')
        ELSE SUM(r.total_votes)
    END AS total_votes
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY p.party_name
ORDER BY SUM(r.total_votes) DESC;


/*---------------------------------------------------------
Query 11 : Political Parties Contesting the Highest Number of Constituencies

Business Question:
Which political parties contested the highest number of Lok Sabha constituencies?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(DISTINCT r.constituency_id) AS constituencies_contested
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY p.party_name
ORDER BY constituencies_contested DESC;


/*---------------------------------------------------------
Query 12 : Political Party with the Highest Average Vote Share

Business Question:
Which political party had the highest average vote share per candidate?
---------------------------------------------------------*/

SELECT
    p.party_name,
    ROUND(AVG(r.vote_share),2) AS average_vote_share
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY p.party_name
ORDER BY average_vote_share DESC;

/*---------------------------------------------------------
Query 13 : Political Parties Receiving More Than 10 Lakh Votes

Business Question:
Which political parties received more than 10 lakh total votes across India?
---------------------------------------------------------*/

SELECT
    p.party_name,
    SUM(r.total_votes) AS total_votes
FROM result r
JOIN party p
ON r.party_id=p.party_id
GROUP BY p.party_name
HAVING SUM(r.total_votes)>1000000
ORDER BY total_votes DESC;


/*---------------------------------------------------------
Query 14 : Political Party with the Highest Strike Rate

Business Question:
Which political party had the highest strike rate in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(w.summary_id) AS seats_won,
    COUNT(DISTINCT r.constituency_id) AS seats_contested,
    ROUND(
        COUNT(w.summary_id)*100.0/
        COUNT(DISTINCT r.constituency_id),
        2
    ) AS strike_rate
FROM party p
JOIN result r
ON p.party_id=r.party_id
LEFT JOIN winner_summary w
ON p.party_id=w.winner_party_id
AND r.constituency_id=w.constituency_id
GROUP BY p.party_name
HAVING COUNT(DISTINCT r.constituency_id)>0
ORDER BY strike_rate DESC;


/*---------------------------------------------------------
Query 16 : Political Parties with the Highest Seat Share

Business Question:
Which political party won the highest percentage of total Lok Sabha seats?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(*) AS seats_won,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM winner_summary),
        2
    ) AS seat_percentage
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY p.party_name
ORDER BY seat_percentage DESC;


/*---------------------------------------------------------
Query 17 : Political Parties Winning Exactly One Seat

Business Question:
Which political parties won only one Lok Sabha seat?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(*) AS seats_won
FROM winner_summary w
JOIN party p
ON w.winner_party_id = p.party_id
GROUP BY p.party_name
HAVING COUNT(*) = 1
ORDER BY p.party_name;


/*---------------------------------------------------------
Query 18 : Political Parties Crossing 5% National Vote Share

Business Question:
Which political parties received more than 5% of the total votes polled nationwide?
---------------------------------------------------------*/

SELECT
    p.party_name,
    SUM(r.total_votes) AS total_votes,
    ROUND(
        SUM(r.total_votes) * 100.0 /
        (SELECT SUM(total_votes) FROM result),
        2
    ) AS national_vote_share
FROM result r
JOIN party p
ON r.party_id = p.party_id
GROUP BY p.party_name
HAVING national_vote_share > 5
ORDER BY national_vote_share DESC;


/*---------------------------------------------------------
Query 19 : Political Parties Contesting but Winning Zero Seats

Business Question:
Which political parties contested Lok Sabha seats but failed to win even one?
---------------------------------------------------------*/

SELECT
    p.party_name,
    COUNT(DISTINCT r.constituency_id) AS seats_contested
FROM result r
JOIN party p
ON r.party_id = p.party_id
LEFT JOIN winner_summary w
ON r.party_id = w.winner_party_id
AND r.constituency_id = w.constituency_id
GROUP BY p.party_name
HAVING COUNT(w.summary_id)=0
ORDER BY seats_contested DESC;


/*---------------------------------------------------------
Query 20 : Vote Share vs Seat Share Analysis

Business Question:
Which political parties had the largest gap between their national vote share and Lok Sabha seat share?
---------------------------------------------------------*/

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
    ) AS seat_share,
    ROUND(
        (
            SUM(r.total_votes) * 100.0 /
            (SELECT SUM(total_votes) FROM result)
        )
        -
        (
            COUNT(DISTINCT w.constituency_id) *100.0/
            (SELECT COUNT(*) FROM winner_summary)
        ),
        2
    ) AS difference
FROM party p
JOIN result r
ON p.party_id=r.party_id
LEFT JOIN winner_summary w
ON p.party_id=w.winner_party_id
AND r.constituency_id=w.constituency_id
GROUP BY p.party_name
ORDER BY ABS(difference) DESC;