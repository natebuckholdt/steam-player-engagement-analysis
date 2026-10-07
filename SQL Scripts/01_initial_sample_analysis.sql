CREATE TABLE games (
    app_id INTEGER PRIMARY KEY,
    title TEXT,
    date_release DATE,
    win BOOLEAN,
    mac BOOLEAN,
    linux BOOLEAN,
    rating TEXT,
    positive_ratio NUMERIC(5,2),
    user_reviews INTEGER,
    price_final NUMERIC(10,2),
    price_original NUMERIC(10,2),
    discount NUMERIC(5,2),
    steam_deck BOOLEAN
);


SELECT COUNT(*)
FROM games;

SELECT
    title,
    price_final,
    positive_ratio,
    user_reviews
FROM games
ORDER BY user_reviews DESC
LIMIT 10;


CREATE TABLE users (
    user_id BIGINT PRIMARY KEY,
    products INTEGER,
    reviews INTEGER
);



SELECT *
FROM users
LIMIT 10;

SELECT COUNT(*)
FROM users;


SELECT
    COUNT(*) AS total_games,
    AVG(price_final) AS avg_price,
    AVG(positive_ratio) AS avg_positive_ratio
FROM games;


SELECT
    COUNT(*) AS total_users,
    AVG(products) AS avg_products_owned,
    AVG(reviews) AS avg_reviews_written
FROM users;



SELECT COUNT(*) FROM games;
SELECT COUNT(*) FROM users;


CREATE TABLE recommendations (
    app_id INTEGER,
    helpful INTEGER,
    funny INTEGER,
    date DATE,
    is_recommended BOOLEAN,
    hours NUMERIC(10,2),
    user_id BIGINT,
    review_id BIGINT PRIMARY KEY
);


SELECT COUNT(*)
FROM recommendations;

SELECT *
FROM recommendations
LIMIT 10;

SELECT COUNT(*) AS matching_recommendations
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id;

SELECT COUNT(*) AS matching_users
FROM recommendations r
JOIN users u
    ON r.user_id = u.user_id;


SELECT
    g.title,
    r.hours,
    r.is_recommended,
    u.products,
    u.reviews
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
JOIN users u
    ON r.user_id = u.user_id
LIMIT 20;



SELECT
    g.title,
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
GROUP BY g.app_id, g.title
HAVING COUNT(*) >= 100
ORDER BY review_count DESC
LIMIT 20;



SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_reviews,
    COUNT(DISTINCT app_id) AS unique_games,
    COUNT(DISTINCT user_id) AS unique_users
FROM recommendations;

SELECT
    COUNT(*) FILTER (WHERE app_id IS NULL) AS missing_app_id,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS missing_user_id,
    COUNT(*) FILTER (WHERE hours IS NULL) AS missing_hours,
    COUNT(*) FILTER (WHERE is_recommended IS NULL) AS missing_recommendation
FROM recommendations;

SELECT
    MIN(hours) AS min_hours,
    MAX(hours) AS max_hours,
    ROUND(AVG(hours), 2) AS avg_hours
FROM recommendations;

SELECT
    g.title,
    COUNT(*) AS review_count,
    ROUND(AVG(r.hours), 2) AS avg_hours
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
GROUP BY g.title
HAVING COUNT(*) >= 100
ORDER BY avg_hours DESC
LIMIT 20;


SELECT
    g.title,
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
GROUP BY g.title
HAVING COUNT(*) >= 100
ORDER BY avg_hours DESC
LIMIT 20;



SELECT
    MIN(date) AS earliest_review,
    MAX(date) AS latest_review,
    COUNT(DISTINCT date) AS unique_dates
FROM recommendations;


SELECT
    CASE
        WHEN hours < 2 THEN 'Under 2 Hours'
        WHEN hours < 10 THEN '2-10 Hours'
        WHEN hours < 50 THEN '10-50 Hours'
        WHEN hours < 100 THEN '50-100 Hours'
        ELSE '100+ Hours'
    END AS playtime_segment,
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
FROM recommendations
GROUP BY playtime_segment;



SELECT
    COUNT(DISTINCT app_id) AS games_in_sample,
    COUNT(DISTINCT user_id) AS users_in_sample
FROM recommendations;


SELECT
    EXTRACT(YEAR FROM date) AS review_year,
    COUNT(*) AS review_count,
    ROUND(
        AVG(
            CASE
                WHEN is_recommended = TRUE THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS recommendation_rate
FROM recommendations
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY review_year;


SELECT
    g.title,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100.0 / 1000000, 2) AS sample_percentage
FROM recommendations r
JOIN games g
    ON r.app_id = g.app_id
GROUP BY g.title
ORDER BY review_count DESC
LIMIT 20;
