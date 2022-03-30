/* Overview: an overall picture of the Airbnb environment in Napoli */

-- Total number of listings: 6087
SELECT COUNT(DISTINCT id)
FROM listings;

-- Total number of Active Listings (those that received a review in the 6 months prior to the data scrape): 3067 out of 6087 (50%)
SELECT COUNT(DISTINCT id)
FROM listings
WHERE last_review > '2021-06-15';

-- Number of unique hosts: 3453
SELECT COUNT(DISTINCT host_id)
FROM listings;

-- Number of unique Active hosts (those that received a review in the 6 months prior to the data scrape): 1972 out of 3453 (57%)
SELECT COUNT(DISTINCT host_id)
FROM listings
WHERE last_review > '2021-06-15';

-- Oldest and newest host: the first host entered in 2009, the last one only 4 days before the data scrape
SELECT MIN(host_since), MAX(host_since)
FROM listings;

-- Number of new hosts by year: a huge wave of new hosts entered Airbnb in Napoli between 2015 - 2019. The pandemic slowed down this trend.
SELECT YEAR(host_since), COUNT(host_id)
FROM listings
GROUP BY YEAR(host_since)
ORDER BY YEAR(host_since) DESC;

/* Considering half of the listings in the original data set hadn't received a review in the 6 months prior to data scrape and the recent shift brought by the pandemic, I decided to narrow down the analysis to Active Listings only in order to get a more recent picture of the Airbnb environment */

-- Price by size of property (entire flats only): one-bedroom and two-bedroom flats have similar prices. For the bigger properties, there's a huge jump with every single additional bedroom.
SELECT bedrooms, ROUND(AVG(price),2) AS Avg_Price
FROM ActiveListings
WHERE room_type = 'Entire home/apt'
GROUP BY bedrooms
ORDER BY bedrooms ASC;

-- Null bedrooms appeared on the data, what are they?: 111 listings varying from different types of properties for which the host didn't include bedroom information.
SELECT * FROM ActiveListings
WHERE bedrooms IS NULL AND room_type = 'Entire home/apt';

-- Price by size of property (shared rooms - including hostels, hotel rooms and private rooms): Hotel rooms and private rooms go for a higher average price than 1 bed flats.
SELECT room_type, ROUND(AVG(price),2) AS Avg_Price
FROM listings
WHERE room_type <> "Entire home/apt"
GROUP BY room_type
ORDER BY ROUND(AVG(price),2) ASC;

-- Proportion of types of property: 1 bed flats, 2 bed flats and private rooms comprise 84% of the listings.
SELECT room_type, bedrooms, COUNT(id) AS Number_Listings, ROUND((COUNT(id)/(SELECT COUNT(id) FROM Listings WHERE last_review > '2021-06-15'))*100,0) AS Perc
FROM ActiveListings
GROUP BY room_type, bedrooms
ORDER BY COUNT(id) DESC

/* Based on the average prices and proportion of types of properties, I decided to focus the analysis on Active one-bedroom flats, two-bedroom flats and single rooms. These amount to 84% of Active Listings and bigger properties skew the numbers with their variance in price */

-- Number of listings and average price per neighbourhood (monolocale): Most listings are concentrate in the very epicentre of the centro storico which also features similar prices. Properties in Posillipo and Vomero show higher prices.
SELECT neighbourhood_cleansed, COUNT(id) AS NumberListings, ROUND(AVG(price),0) AS Avg_Price
FROM FocusListings
WHERE room_type = "Entire home/apt" and bedrooms = 1
GROUP BY neighbourhood_cleansed
ORDER BY ROUND(AVG(price),0) DESC

-- Number of listings and average price per neighbourhood (rooms): for the single rooms, a specific part of the centro storico shows higher prices. Vomero and Posillipo show similar prices to the rest of the areas.
SELECT neighbourhood_cleansed, COUNT(id) AS NumberListings, ROUND(AVG(price),0) AS Avg_Price
FROM FocusListings
WHERE room_type = 'Private room' AND bedrooms = 1
GROUP BY neighbourhood_cleansed
ORDER BY ROUND(AVG(price),0) DESC

-- Types of property per neighbourhood: Looking at the drivers for average price in each neighbourhood to give some context for the above.
SELECT neighbourhood_cleansed, property_type, bedrooms, COUNT(id), ROUND(AVG(price),2)
FROM FocusListings
GROUP BY neighbourhood_cleansed, property_type, bedrooms
ORDER BY neighbourhood_cleansed