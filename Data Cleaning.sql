/* Data Cleaning */

-- Checking if two columns are always the same
WITH checker AS
(
SELECT CASE WHEN host_listings_count = host_total_listings_count
            THEN 1
            ELSE 0
       END AS is_check_true
FROM listings
)

SELECT COUNT(is_check_true)
FROM checker;

-- Dropping unnecessary columns
ALTER TABLE listings
DROP COLUMN neighbourhood
DROP COLUMN scrape_id,
DROP COLUMN last_scraped,
DROP COLUMN picture_url,
DROP COLUMN host_thumbnail_url,
DROP COLUMN host_picture_url,
DROP COLUMN host_neighbourhood,
DROP COLUMN host_total_listings_count,
DROP COLUMN neighbourhood_group_cleansed,
DROP COLUMN bathrooms,
DROP COLUMN calendar_updated,
DROP COLUMN calendar_last_scraped,
DROP COLUMN license;

ALTER TABLE calendar
DROP COLUMN adjusted_price;

-- Checking neighbourhoods included in the data
SELECT DISTINCT neighbourhood_cleansed, count(id)
FROM listings
GROUP BY neighbourhood_cleansed
ORDER BY count(id) DESC;

-- Deleting listings located outside of Napoli's historic centre
DELETE FROM listings
WHERE neighbourhood_cleansed IN ('Porto','Arenella','Zona Industriale','Fuorigrotta','Bagnoli','Poggioreale','San Giovanni a Teduccio','Chiaiano','Ponticelli','San Pietro a Patierno','Secondigliano','Barra','Pianura','Piscinola','Soccavo','Miano');

-- Turning the PRICE column to a DOUBLE (for listings and calendar tables)
UPDATE listings
SET price = RIGHT(price,(LENGTH(price)-1));

UPDATE listings
SET price = CAST(price AS DOUBLE);

UPDATE calendar
SET price = RIGHT(price,(LENGTH(price)-1));

UPDATE calendar
SET price = CAST(price AS DOUBLE);

-- Turning the Date fields into DATE types

UPDATE listings
SET host_since = STR_TO_DATE(host_since, '%d/%m/%Y');

UPDATE listings
SET first_review = STR_TO_DATE(first_review, '%d/%m/%Y')
WHERE first_review <> '';

UPDATE listings
SET last_review = STR_TO_DATE(last_review, '%d/%m/%Y')
WHERE last_review <> '';

UPDATE calendar
SET date = STR_TO_DATE(date, '%Y-%m-%d');

UPDATE reviews
SET date = STR_TO_DATE(date, '%Y-%m-%d');

-- Replacing empty text with Nulls - empty cells were skewing aggregated functions
UPDATE listings
SET id = NULL WHERE id = '',
SET listing_url = NULL WHERE listing_url = '',
SET name = NULL WHERE name = '',
SET description = NULL WHERE description = '',
SET neighborhood_overview = NULL WHERE neighborhood_overview = '',
SET host_id = NULL WHERE host_id = '',
SET host_url = NULL WHERE host_url = '',
SET host_name = NULL WHERE host_name = '',
SET host_since = NULL WHERE host_since = '',
SET host_location = NULL WHERE host_location = '',
SET host_about = NULL WHERE host_about = '',
SET host_response_time = NULL WHERE host_response_time = '',
SET host_response_rate = NULL WHERE host_response_rate = '',
SET host_acceptance_rate = NULL WHERE host_acceptance_rate = '',
SET host_is_superhost = NULL WHERE host_is_superhost = '',
SET host_listings_count = NULL WHERE host_listings_count = '',
SET host_verifications = NULL WHERE host_verifications = '',
SET host_has_profile_pic = NULL WHERE host_has_profile_pic = '',
SET host_identity_verified = NULL WHERE host_identity_verified = '',
SET neighbourhood_cleansed = NULL WHERE neighbourhood_cleansed = '',
SET latitude = NULL WHERE latitude = '',
SET longitude = NULL WHERE longitude = '',
SET property_type = NULL WHERE property_type = '',
SET room_type = NULL WHERE room_type = '',
SET accommodates = NULL WHERE accommodates = '',
SET bathrooms_text = NULL WHERE bathrooms_text = '',
SET bedrooms = NULL WHERE bedrooms = '',
SET beds = NULL WHERE beds = '',
SET amenities = NULL WHERE amenities = '',
SET price = NULL WHERE price = '',
SET minimum_nights = NULL WHERE minimum_nights = '',
SET maximum_nights = NULL WHERE maximum_nights = '',
SET minimum_minimum_nights = NULL WHERE minimum_minimum_nights = '',
SET maximum_minimum_nights = NULL WHERE maximum_minimum_nights = '',
SET minimum_maximum_nights = NULL WHERE minimum_maximum_nights = '',
SET maximum_maximum_nights = NULL WHERE maximum_maximum_nights = '',
SET minimum_nights_avg_ntm = NULL WHERE minimum_nights_avg_ntm = '',
SET maximum_nights_avg_ntm = NULL WHERE maximum_nights_avg_ntm = '',
SET has_availability = NULL WHERE has_availability = '',
SET availability_30 = NULL WHERE availability_30 = '',
SET availability_60 = NULL WHERE availability_60 = '',
SET availability_90 = NULL WHERE availability_90 = '',
SET availability_365 = NULL WHERE availability_365 = '',
SET number_of_reviews = NULL WHERE number_of_reviews = '',
SET number_of_reviews_ltm = NULL WHERE number_of_reviews_ltm = '',
SET number_of_reviews_l30d = NULL WHERE number_of_reviews_l30d = '',
SET first_review = NULL WHERE first_review = '',
SET last_review = NULL WHERE last_review = '',
SET review_scores_rating = NULL WHERE review_scores_rating = '',
SET review_scores_accuracy = NULL WHERE review_scores_accuracy = '',
SET review_scores_cleanliness = NULL WHERE review_scores_cleanliness = '',
SET review_scores_checkin = NULL WHERE review_scores_checkin = '',
SET review_scores_communication = NULL WHERE review_scores_communication = '',
SET review_scores_location = NULL WHERE review_scores_location = '',
SET review_scores_value = NULL WHERE review_scores_value = '',
SET instant_bookable = NULL WHERE instant_bookable = '',
SET calculated_host_listings_count = NULL WHERE calculated_host_listings_count = '',
SET calculated_host_listings_count_entire_homes = NULL WHERE calculated_host_listings_count_entire_homes = '',
SET calculated_host_listings_count_private_rooms = NULL WHERE calculated_host_listings_count_private_rooms = '',
SET calculated_host_listings_count_shared_rooms = NULL WHERE calculated_host_listings_count_shared_rooms = '',
SET reviews_per_month = NULL WHERE reviews_per_month = '';


-- Removing the % from Response and Acceptance Rates to allow for calculations
UPDATE listings
SET host_response_rate = CAST(LEFT(host_response_rate,(LENGTH(host_response_rate)-1)) AS DOUBLE)
WHERE host_response_rate <> 'N/A'

UPDATE listings
SET host_response_rate = NULL
WHERE host_response_rate = 'N/A'

UPDATE listings
SET host_acceptance_rate = CAST(LEFT(host_acceptance_rate,(LENGTH(host_acceptance_rate)-1)) AS DOUBLE)
WHERE host_acceptance_rate <> 'N/A'

UPDATE listings
SET host_acceptance_rate = NULL
WHERE host_acceptance_rate = 'N/A'

-- Adding Active Listings (reviewed in the 6 months before the data scrape) into a table:
CREATE TABLE ActiveListings
SELECT * FROM listings
WHERE last_review > '2021-06-15' -- Total: 3067 listings

-- Adding FocusListings (1 bed flats, 2 bed flats and private rooms): constitute 85% of the Active Listings and other room_types skewed the numbers.
CREATE TABLE FocusListings
SELECT * FROM listings
WHERE (last_review > '2021-06-15') AND ((room_type = 'Entire home/apt' AND bedrooms = 1) OR (room_type = 'Entire home/apt' AND bedrooms = 2) OR ((room_type = 'Private room' AND bedrooms = 1)))
-- Total: 2588 listings