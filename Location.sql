/* Analysis of listings per building

For this analysis, we revert back to the group of Active Listings - those in the historical centre that received a review in the 6 months prior to the data scrape -
regardless of the size of property.

I used latitude and longitude information to check if there're are buildings in Napoli occupied mostly by Airbnbs and cross-checked the analysis
with my the building I live in - which I know to have at least 4 listings in it.

Unfortunately, I was not able to reach any conclusions. The buildings in Napoli tend to be wide and deep which means that at times two apartments in the same 
building will have different latitudes and longitudes.

For example, these are the latitudes and longitudes of two listings which I know to be in the same building:
Listing1: 40.85396 14.24928
Listing2: 40.85324 14.24831

Even if I ran the analysis using only 3 decimals, this would encompass a large area and results wouldn't be conclusive.
 */

-- Checking the amount of unique latitude and longitude: 2947 (from ActiveListings)
SELECT COUNT(DISTINCT(CONCAT_WS(' ',latitude, longitude)))
FROM ActiveListings

-- How many listings per location:

ALTER TABLE ActiveListings
ADD COLUMN LocationConcat TEXT

UPDATE ActiveListings
SET LocationConcat = CONCAT_WS(' ',latitude, longitude)

CREATE TEMPORARY TABLE Buildings
SELECT LocationConcat, COUNT(LocationConcat) OVER(PARTITION BY LocationConcat) AS Building
FROM ActiveListings

ALTER TABLE ActiveListings
ADD COlUMN Building INT

UPDATE ActiveListings b
JOIN Buildings a ON a.LocationConcat = b.LocationConcat
SET b.Building = a.Building


-- Looking into the listings in locations with more than 1 listing:
CREATE TEMPORARY TABLE MultListBuild
SELECT * FROM ActiveListings
WHERE Building > 1

-- Looking into the listings in locations with more than 1 listing: 203 listings, from 97 unique hosts and 83 unique buildings
SELECT COUNT(DISTINCT id) AS NumberListings, COUNT(DISTINCT host_id) AS NumberHosts, COUNT(DISTINCT LocationConcat) AS NumberBuildings  FROM MultListBuild

-- How many buildings we have with 2 listings, 3 listings, 4 listings and 5 listings: Majority of buildings with more than 1 listings has only 2 listings in it.
SELECT DISTINCT Building, COUNT(Building) AS Occurrences
FROM MultListBuild
GROUP BY Building

-- How many hosts are in each building: at most, a building will have 3 unique hosts.
SELECT DISTINCT LocationConcat, COUNT(DISTINCT host_id) AS UniqueHosts, ROUND(AVG(Building),0) AS Building FROM MultListBuild
WHERE Building > 1
GROUP BY LocationConcat
ORDER BY COUNT(DISTINCT host_id) DESC

-- Looking into specific buildings and listings
SELECT * FROM MultListBuild
WHERE LocationConcat = '40.84798 14.26173'

SELECT * FROM ActiveListings
WHERE id = '4421923'