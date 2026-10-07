TRUNCATE TABLE recommendations;


SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT app_id) AS games_in_sample,
    COUNT(DISTINCT user_id) AS users_in_sample
FROM recommendations;


SELECT
    g.title,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM recommendations),
        2
    ) AS sample_percentage
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
GROUP BY g.title
ORDER BY review_count DESC
LIMIT 20;


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
GROUP BY playtime_segment
ORDER BY
    CASE playtime_segment
        WHEN 'Under 2 Hours' THEN 1
        WHEN '2-10 Hours' THEN 2
        WHEN '10-50 Hours' THEN 3
        WHEN '50-100 Hours' THEN 4
        WHEN '100+ Hours' THEN 5
    END;


CREATE INDEX idx_recommendations_app_id
ON recommendations(app_id);

CREATE INDEX idx_recommendations_user_id
ON recommendations(user_id);


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
GROUP BY price_segment
ORDER BY
    CASE price_segment
        WHEN 'Free' THEN 1
        WHEN 'Under $10' THEN 2
        WHEN '$10-$19.99' THEN 3
        WHEN '$20-$39.99' THEN 4
        WHEN '$40-$59.99' THEN 5
        WHEN '$60+' THEN 6
    END;


WITH game_metrics AS (
    SELECT
        g.app_id,
        g.title,
        g.price_final,
        COUNT(*) AS review_count,
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
        g.price_final
)
SELECT
    title,
    price_final,
    review_count,
    avg_hours,
    recommendation_rate
FROM game_metrics
WHERE review_count >= 100
ORDER BY recommendation_rate DESC, avg_hours DESC
LIMIT 20;


WITH game_metrics AS (
    SELECT
        g.app_id,
        g.title,
        g.price_final,
        COUNT(*) AS review_count,
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
        g.price_final
    HAVING COUNT(*) >= 100
),
ranked_games AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY avg_hours) AS engagement_quartile,
        NTILE(4) OVER (ORDER BY recommendation_rate) AS satisfaction_quartile
    FROM game_metrics
)
SELECT
    title,
    price_final,
    review_count,
    avg_hours,
    recommendation_rate
FROM ranked_games
WHERE engagement_quartile = 4
  AND satisfaction_quartile = 4
ORDER BY recommendation_rate DESC, avg_hours DESC;


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
GROUP BY library_segment
ORDER BY
    CASE library_segment
        WHEN 'Under 20 Products' THEN 1
        WHEN '20-99 Products' THEN 2
        WHEN '100-299 Products' THEN 3
        WHEN '300+ Products' THEN 4
    END;


SELECT
    EXTRACT(YEAR FROM g.date_release) AS release_year,
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
GROUP BY EXTRACT(YEAR FROM g.date_release)
HAVING COUNT(*) >= 1000
ORDER BY release_year;


SELECT
    COUNT(*) AS reviews_before_release
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
WHERE r.date < g.date_release;


SELECT
    g.title,
    g.date_release,
    r.date AS review_date,
    r.hours,
    r.is_recommended
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
WHERE r.date < g.date_release
ORDER BY g.date_release DESC
LIMIT 25;


SELECT
    EXTRACT(YEAR FROM g.date_release) AS release_year,
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
  AND r.date >= g.date_release
GROUP BY EXTRACT(YEAR FROM g.date_release)
HAVING COUNT(*) >= 1000
   AND COUNT(DISTINCT g.app_id) >= 100
ORDER BY release_year;


SELECT
    COUNT(DISTINCT r.app_id) AS affected_games,
    MIN(g.date_release - r.date) AS smallest_gap_days,
    MAX(g.date_release - r.date) AS largest_gap_days,
    ROUND(AVG(g.date_release - r.date), 2) AS avg_gap_days
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
WHERE r.date < g.date_release;


SELECT
    g.title,
    g.date_release,
    COUNT(*) AS reviews_before_release,
    MIN(r.date) AS earliest_review,
    MAX(r.date) AS latest_review_before_release
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
WHERE r.date < g.date_release
GROUP BY
    g.app_id,
    g.title,
    g.date_release
ORDER BY reviews_before_release DESC
LIMIT 25;


SELECT
    EXTRACT(YEAR FROM g.date_release) AS release_year,
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
   AND COUNT(DISTINCT g.app_id) >= 100
ORDER BY release_year;


SELECT
    COUNT(*) AS early_access_or_pre_release_reviews,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM recommendations),
        2
    ) AS percentage_of_sample,
    COUNT(DISTINCT r.app_id) AS affected_games
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
WHERE r.date < g.date_release;
