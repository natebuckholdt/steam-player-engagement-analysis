-- Steam Player Engagement & Satisfaction Analysis
-- Script 03: Dashboard Views
-- Creates cleaned summary views for the Power BI dashboard


-- ============================================================
-- 1. GAME PERFORMANCE VIEW
-- One row per game with engagement and recommendation metrics
-- ============================================================

CREATE OR REPLACE VIEW vw_game_performance AS
SELECT
    g.app_id,
    g.title,
    g.date_release,
    EXTRACT(YEAR FROM g.date_release) AS release_year,
    g.price_final,
    g.positive_ratio,
    g.user_reviews,
    g.rating,
    g.steam_deck,
    COUNT(*) AS sampled_reviews,
    ROUND(AVG(r.hours), 2) AS avg_hours,
    ROUND(
        AVG(
            CASE
                WHEN r.is_recommended = TRUE THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS recommendation_rate
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
GROUP BY
    g.app_id,
    g.title,
    g.date_release,
    g.price_final,
    g.positive_ratio,
    g.user_reviews,
    g.rating,
    g.steam_deck;


-- Test game performance view

SELECT *
FROM vw_game_performance
ORDER BY sampled_reviews DESC
LIMIT 20;



-- ============================================================
-- 2. PLAYTIME SEGMENT VIEW
-- Groups recommendation records by player engagement level
-- ============================================================

CREATE OR REPLACE VIEW vw_playtime_segments AS
WITH playtime_data AS (
    SELECT
        CASE
            WHEN hours < 2 THEN 'Under 2 Hours'
            WHEN hours < 10 THEN '2-10 Hours'
            WHEN hours < 50 THEN '10-50 Hours'
            WHEN hours < 100 THEN '50-100 Hours'
            ELSE '100+ Hours'
        END AS playtime_segment,

        CASE
            WHEN hours < 2 THEN 1
            WHEN hours < 10 THEN 2
            WHEN hours < 50 THEN 3
            WHEN hours < 100 THEN 4
            ELSE 5
        END AS playtime_sort,

        hours,
        is_recommended
    FROM recommendations
)

SELECT
    playtime_segment,
    COUNT(*) AS review_count,
    ROUND(AVG(hours), 2) AS avg_hours,
    ROUND(
        AVG(
            CASE
                WHEN is_recommended = TRUE THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS recommendation_rate,
    playtime_sort
FROM playtime_data
GROUP BY
    playtime_segment,
    playtime_sort;


-- Test playtime segment view

SELECT *
FROM vw_playtime_segments
ORDER BY playtime_sort;



-- ============================================================
-- 3. PRICE SEGMENT VIEW
-- Groups games by price and measures recommendation behavior
-- ============================================================

CREATE OR REPLACE VIEW vw_price_segments AS
WITH price_data AS (
    SELECT
        CASE
            WHEN g.price_final = 0 THEN 'Free'
            WHEN g.price_final < 10 THEN 'Under $10'
            WHEN g.price_final < 20 THEN '$10-$19.99'
            WHEN g.price_final < 40 THEN '$20-$39.99'
            WHEN g.price_final < 60 THEN '$40-$59.99'
            ELSE '$60+'
        END AS price_segment,

        CASE
            WHEN g.price_final = 0 THEN 1
            WHEN g.price_final < 10 THEN 2
            WHEN g.price_final < 20 THEN 3
            WHEN g.price_final < 40 THEN 4
            WHEN g.price_final < 60 THEN 5
            ELSE 6
        END AS price_sort,

        r.hours,
        r.is_recommended
    FROM recommendations r
    JOIN games g
        ON r.app_id = g.app_id
)

SELECT
    price_segment,
    COUNT(*) AS review_count,
    ROUND(AVG(hours), 2) AS avg_hours,
    ROUND(
        AVG(
            CASE
                WHEN is_recommended = TRUE THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS recommendation_rate,
    price_sort
FROM price_data
GROUP BY
    price_segment,
    price_sort;


-- Test price segment view

SELECT *
FROM vw_price_segments
ORDER BY price_sort;



-- ============================================================
-- 4. PLAYER LIBRARY SEGMENT VIEW
-- Compares behavior based on the size of a user's Steam library
-- Uses recommendations, users, and games tables
-- ============================================================

CREATE OR REPLACE VIEW vw_player_segments AS
WITH player_data AS (
    SELECT
        CASE
            WHEN u.products < 20 THEN 'Under 20 Products'
            WHEN u.products < 100 THEN '20-99 Products'
            WHEN u.products < 300 THEN '100-299 Products'
            ELSE '300+ Products'
        END AS library_segment,

        CASE
            WHEN u.products < 20 THEN 1
            WHEN u.products < 100 THEN 2
            WHEN u.products < 300 THEN 3
            ELSE 4
        END AS library_sort,

        u.user_id,
        r.hours,
        r.is_recommended,
        g.price_final
    FROM recommendations r
    JOIN users u
        ON r.user_id = u.user_id
    JOIN games g
        ON r.app_id = g.app_id
)

SELECT
    library_segment,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) AS review_count,
    ROUND(AVG(hours), 2) AS avg_hours,
    ROUND(AVG(price_final), 2) AS avg_game_price,
    ROUND(
        AVG(
            CASE
                WHEN is_recommended = TRUE THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS recommendation_rate,
    library_sort
FROM player_data
GROUP BY
    library_segment,
    library_sort;


-- Test player segment view

SELECT *
FROM vw_player_segments
ORDER BY library_sort;



-- ============================================================
-- 5. RELEASE YEAR VIEW
-- Analyzes recommendation behavior by listed release year
-- Limited to release years through 2022
-- Requires sufficient review and game representation
-- ============================================================

CREATE OR REPLACE VIEW vw_release_year AS
SELECT
    EXTRACT(YEAR FROM g.date_release)::INT AS release_year,
    COUNT(*) AS review_count,
    COUNT(DISTINCT g.app_id) AS games_reviewed,
    ROUND(AVG(r.hours), 2) AS avg_hours,
    ROUND(
        AVG(
            CASE
                WHEN r.is_recommended = TRUE THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS recommendation_rate
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
WHERE g.date_release IS NOT NULL
  AND EXTRACT(YEAR FROM g.date_release) <= 2022
GROUP BY
    EXTRACT(YEAR FROM g.date_release)
HAVING COUNT(*) >= 1000
   AND COUNT(DISTINCT g.app_id) >= 100;


-- Test release year view

SELECT *
FROM vw_release_year
ORDER BY release_year;



-- ============================================================
-- 6. FINAL VIEW VALIDATION
-- Confirms that all five Power BI views were created successfully
-- ============================================================

SELECT
    'vw_game_performance' AS view_name,
    COUNT(*) AS row_count
FROM vw_game_performance

UNION ALL

SELECT
    'vw_playtime_segments',
    COUNT(*)
FROM vw_playtime_segments

UNION ALL

SELECT
    'vw_price_segments',
    COUNT(*)
FROM vw_price_segments

UNION ALL

SELECT
    'vw_player_segments',
    COUNT(*)
FROM vw_player_segments

UNION ALL

SELECT
    'vw_release_year',
    COUNT(*)
FROM vw_release_year;
