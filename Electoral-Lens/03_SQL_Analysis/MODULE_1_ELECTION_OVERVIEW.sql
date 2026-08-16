/*=========================================================
MODULE 1 : ELECTION OVERVIEW
=========================================================*/

/*---------------------------------------------------------
Query 1 : Total States and Union Territories Participated

Business Question:
How many States and Union Territories participated in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    COUNT(*) AS total_states
FROM state;


/*---------------------------------------------------------
Query 2 : Total Political Parties Participated

Business Question:
How many political parties participated in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    COUNT(*) AS total_parties
FROM party;


/*---------------------------------------------------------
Query 3 : Total Election Phases Conducted

Business Question:
How many election phases were conducted during the 2024 General Election?
---------------------------------------------------------*/

SELECT
    COUNT(*) AS total_phases
FROM phase;


/*---------------------------------------------------------
Query 4 : Total Lok Sabha Constituencies Contested

Business Question:
How many Lok Sabha constituencies were contested in the 2024 General Election?
---------------------------------------------------------*/

SELECT
    COUNT(*) AS total_constituencies
FROM constituency;


/*---------------------------------------------------------
Query 5 : Total Accepted Candidate Applications

Business Question:
How many candidate applications were accepted for the 2024 General Election?
---------------------------------------------------------*/

SELECT
    COUNT(*) AS total_applications
FROM application
WHERE application_status = 'Accepted';