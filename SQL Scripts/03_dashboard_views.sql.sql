-- Steam Player Engagement Analysis
-- Script 03: Dashboard Views
-- Creates cleaned summary views for Power BI

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

SELECT *
FROM vw_game_performance
ORDER BY sampled_reviews DESC
LIMIT 20;


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
    ) AS recommendation_rate
FROM playtime_data
GROUP BY playtime_segment;

SELECT *
FROM vw_playtime_segments
ORDER BY
    CASE playtime_segment
        WHEN 'Under 2 Hours' THEN 1
        WHEN '2-10 Hours' THEN 2
        WHEN '10-50 Hours' THEN 3
        WHEN '50-100 Hours' THEN 4
        WHEN '100+ Hours' THEN 5
    END;


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
    ) AS recommendation_rate
FROM price_data
GROUP BY price_segment;

SELECT *
FROM vw_price_segments
ORDER BY
    CASE price_segment
        WHEN 'Free' THEN 1
        WHEN 'Under $10' THEN 2
        WHEN '$10-$19.99' THEN 3
        WHEN '$20-$39.99' THEN 4
        WHEN '$40-$59.99' THEN 5
        WHEN '$60+' THEN 6
    END;


CREATE OR REPLACE VIEW vw_player_segments AS
WITH player_data AS (
    SELECT
        CASE
            WHEN u.products < 20 THEN 'Under 20 Products'
            WHEN u.products < 100 THEN '20-99 Products'
            WHEN u.products < 300 THEN '100-299 Products'
            ELSE '300+ Products'
        END AS library_segment,
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
    ) AS recommendation_rate
FROM player_data
GROUP BY library_segment;

SELECT *
FROM vw_player_segments
ORDER BY
    CASE library_segment
        WHEN 'Under 20 Products' THEN 1
        WHEN '20-99 Products' THEN 2
        WHEN '100-299 Products' THEN 3
        WHEN '300+ Products' THEN 4
    END;


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
GROUP BY EXTRACT(YEAR FROM g.date_release)
HAVING COUNT(*) >= 1000
   AND COUNT(DISTINCT g.app_id) >= 100;

SELECT *
FROM vw_release_year
ORDER BY release_year;


SELECT 'vw_game_performance' AS view_name, COUNT(*) AS row_count
FROM vw_game_performance
UNION ALL
SELECT 'vw_playtime_segments', COUNT(*)
FROM vw_playtime_segments
UNION ALL
SELECT 'vw_price_segments', COUNT(*)
FROM vw_price_segments
UNION ALL
SELECT 'vw_player_segments', COUNT(*)
FROM vw_player_segments
UNION ALL
SELECT 'vw_release_year', COUNT(*)
FROM vw_release_year;