--Question 1
SELECT DATE_PART('year', join_datetime) AS join_year, COUNT(*) AS user_count
FROM users
WHERE DATE_PART('year', join_datetime) >= 2010
GROUP BY join_year
ORDER BY join_year;

--Question 2
SELECT elite_year, COUNT(DISTINCT user_id) AS elite_user_count
FROM usereliteyears
WHERE elite_year BETWEEN 2012 AND 2021
GROUP BY elite_year
ORDER BY elite_year;

--Question 3
WITH TopUser AS (
    SELECT u.name, u.join_datetime, u.fans_count,
           u.funny_votes_sent, u.useful_votes_sent, u.cool_votes_sent,
           r.review_text, r.review_datetime
    FROM users u
    JOIN reviews r ON u.user_id = r.user_id
    WHERE r.stars = 5.0
    ORDER BY u.review_count DESC
    LIMIT 1
), RecentReviews AS (
    SELECT review_text, review_datetime
    FROM reviews
    WHERE user_id = (SELECT user_id FROM TopUser)
    AND stars = 5.0
    ORDER BY review_datetime DESC
    LIMIT 5
)
SELECT *, 
       (SELECT name FROM TopUser) AS user_name,
       (SELECT join_datetime FROM TopUser) AS join_date,
       (SELECT fans_count FROM TopUser) AS fan_count,
       (SELECT funny_votes_sent FROM TopUser) AS funny_votes,
       (SELECT useful_votes_sent FROM TopUser) AS useful_votes,
       (SELECT cool_votes_sent FROM TopUser) AS cool_votes
FROM RecentReviews;

--Question 4
SELECT b.business_id, bc.category, 
       SUM(EXTRACT(EPOCH FROM (bh.closing_time - bh.opening_time)) / 3600) AS total_hours_per_week
FROM businesses b
JOIN businesscategories bc ON b.business_id = bc.business_id
JOIN businesshours bh ON b.business_id = bh.business_id
GROUP BY b.business_id, bc.category;

--Question 5
SELECT state, COUNT(*) AS business_count
FROM businesses
GROUP BY state
ORDER BY business_count DESC
LIMIT 11; --because the 10th state is a canadian province and we want US states

--Question 6
SELECT category, COUNT(*) AS business_count
FROM businesscategories
GROUP BY category
ORDER BY business_count DESC
LIMIT 10;

--Question 7
SELECT bc.category, AVG(b.stars) AS average_rating
FROM businesses b
JOIN businesscategories bc ON b.business_id = bc.business_id
WHERE bc.category IN (SELECT category FROM businesscategories ORDER BY COUNT(*) DESC LIMIT 10)
GROUP BY bc.category;

--Question 8 has 3 parts
-- Part 1: Get the 5 funniest restaurant reviews
SELECT r.review_text, r.funny_count
FROM reviews r
JOIN businesses b ON r.business_id = b.business_id
JOIN businesscategories bc ON b.business_id = bc.business_id
WHERE bc.category LIKE '%Restaurants%'
ORDER BY r.funny_count DESC
LIMIT 5;

-- Part 2: Get the 5 least funny restaurant reviews
SELECT r.review_text, r.funny_count
FROM reviews r
JOIN businesses b ON r.business_id = b.business_id
JOIN businesscategories bc ON b.business_id = bc.business_id
WHERE bc.category LIKE '%Restaurants%'
  AND r.funny_count > 0
ORDER BY r.funny_count ASC
LIMIT 5;

--Part 3: Analysis the common words in the funniest reviews

SELECT r.review_text, r.funny_count
FROM reviews r
JOIN businesses b ON r.business_id = b.business_id
JOIN businesscategories bc ON b.business_id = bc.business_id
WHERE bc.category LIKE '%Restaurants%'
ORDER BY r.funny_count DESC
LIMIT 1000;

--Question 9
WITH MostComplimented AS (
    SELECT tip_text, LENGTH(tip_text) AS text_length
    FROM tips
    ORDER BY compliments_count DESC
    LIMIT 100
),
LeastComplimented AS (
    SELECT tip_text, LENGTH(tip_text) AS text_length
    FROM tips
    ORDER BY compliments_count ASC
    LIMIT 100
)
SELECT 
    (SELECT AVG(text_length) FROM MostComplimented) AS avg_length_most_complimented,
    (SELECT AVG(text_length) FROM LeastComplimented) AS avg_length_least_complimented;

--Question 10
SELECT b.business_id,
       b.name AS business_name,
       bc.category AS business_category,
       AVG(EXTRACT(EPOCH FROM (bh.closing_time - bh.opening_time)) / 3600) AS avg_hours_per_week,
       ARRAY_AGG(DISTINCT bh.day_of_week ORDER BY bh.day_of_week) AS days_open,
       COUNT(DISTINCT r.review_id) AS num_reviews
FROM businesses b
JOIN businesscategories bc ON b.business_id = bc.business_id
JOIN businesshours bh ON b.business_id = bh.business_id
LEFT JOIN reviews r ON b.business_id = r.business_id
WHERE bc.category = 'Restaurants'
GROUP BY b.business_id, b.name, bc.category
LIMIT 10;

-- Extra Credit question 1 (average review length)
SELECT 
    bc.category AS business_category,
    AVG(LENGTH(r.review_text)) AS average_review_length
FROM 
    reviews r
JOIN 
    businesses b ON r.business_id = b.business_id
JOIN 
    businesscategories bc ON b.business_id = bc.business_id
GROUP BY 
    bc.category
	ORDER BY average_review_length DESC
	LIMIT 10;
--Extra credit question 2 (closed on weekends vs closed on weekdays)
SELECT 
    (SELECT COUNT(*) FROM businesses) AS total_businesses,
    
    (SELECT COUNT(*) FROM businesses b 
     WHERE NOT EXISTS (
            SELECT 1
            FROM businesshours bh
            WHERE b.business_id = bh.business_id
            AND bh.day_of_week IN ('Saturday', 'Sunday')
        )) AS num_closed_on_weekends,
        
    (SELECT COUNT(*) FROM businesses b 
     WHERE NOT EXISTS (
            SELECT 1
            FROM businesshours bh
            WHERE b.business_id = bh.business_id
            AND bh.day_of_week NOT IN ('Saturday', 'Sunday')
        )) AS num_closed_on_weekdays;

