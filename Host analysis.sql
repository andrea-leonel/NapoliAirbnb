/* An analysis of Active hosts in Napoli */

-- Number of listings per host
SELECT DISTINCT host_id, host_name, COUNT(host_id) AS NumberListings, AVG(host_response_rate) AS Avg_RR, AVG(host_acceptance_rate) AS Avg_AR, ROUND(AVG(review_scores_rating),1) AS Avg_review, ROUND((AVG(90-availability_90)/90)*100,0) AS Avg_occupancy_90d
FROM FocusListings
GROUP BY host_id, host_name
ORDER BY COUNT(host_id) DESC;

-- Looking into some of the hosts who has the highest number of properties:
SELECT * FROM FocusListings
WHERE id = '19229935';

-- Earnings per Host: average price here takes into consideration the price variance with seasonality. The definition of Occupancy are booked nights but also nights the host has made unavailale.

CREATE TEMPORARY TABLE Occupancy
SELECT a.host_id, a.host_name, b.listing_id, COUNT(b.available) AS Occupancy
FROM FocusListings a
LEFT JOIN calendar b ON a.id = b.listing_id
WHERE b.available = 'f'
GROUP BY a.host_id, a.host_name, b.listing_id
ORDER BY COUNT(b.available) DESC;

WITH CTE AS (
SELECT a.host_id, a.host_name, AVG(b.Occupancy) AS AvgOccupancy
FROM FocusListings a
LEFT JOIN Occupancy b ON a.host_id = b.host_id
GROUP BY a.host_id, a.host_name
ORDER BY AVG(b.Occupancy) ASC
)

SELECT a.host_id, a.host_name, COUNT(DISTINCT b.listing_id) AS NumberListings, ROUND(AVG(b.price),0) AS AvgPrice, ROUND((AVG(c.AvgOccupancy)/369)*100,0) AS IndexOccupancy, SUM(b.price) AS Earnings
FROM FocusListings a
LEFT JOIN calendar b ON a.id = b.listing_id
LEFT JOIN CTE c ON a.host_id = c.host_id
WHERE b.available = 'f'
GROUP BY a.host_id, a.host_name
ORDER BY SUM(b.price) DESC

/* Some hosts were showing an average occupancy of over 70% for the whole year of 2022 which seems unlikely. Numbers could be skewed by nights made unavailable by the host. For that reason, I decided to re-run the analysis applying a threshold of Occcupancy to try to remove blocked nights from the data. */

SELECT AVG(Occupancy) FROM Occupancy -- On average, the properties are showing 120 unavailable days per year.

-- Applying the threshold to the CTE and re-running the analysis: made it into a table to allow for calculations

CREATE TABLE Earnings
WITH CTE AS (
SELECT a.host_id, a.host_name, AVG(b.Occupancy) AS AvgOccupancy
FROM FocusListings a
LEFT JOIN Occupancy b ON a.host_id = b.host_id
WHERE b.Occupancy <= 120
GROUP BY a.host_id, a.host_name
ORDER BY AVG(b.Occupancy) ASC
)

SELECT a.host_id, a.host_name, COUNT(DISTINCT b.listing_id) AS NumberListings, ROUND(AVG(b.price),0) AS AvgPrice, ROUND((AVG(c.AvgOccupancy)/369)*100,0) AS IndexOccupancy, SUM(b.price) AS Earnings
FROM FocusListings a
LEFT JOIN calendar b ON a.id = b.listing_id
RIGHT JOIN CTE c ON a.host_id = c.host_id
WHERE b.available = 'f'
GROUP BY a.host_id, a.host_name
ORDER BY SUM(b.price) DESC

-- Final Earnings table considering a threshold of Occupancy to attempt to remove block nights by the host from the data and putting final Earnings into a % to give an idea of the proportion of earnings, since the asbolute number isn't relevant here.

SELECT host_id, host_name, NumberListings, AvgPrice, IndexOccupancy, ROUND((Earnings/(SELECT SUM(Earnings) FROM Earnings))*100,2) AS PercEarnings
FROM Earnings
ORDER BY ROUND((Earnings/(SELECT SUM(Earnings) FROM Earnings))*100,0) DESC

-- Adding the segmentation column:
ALTER TABLE Earnings
ADD COLUMN Segment text

UPDATE Earnings
SET Segment = CASE 
	WHEN NumberListings = 1 THEN 'Single'
	WHEN host_id IN ('40457249', '13036400', '96122546', '128841116') THEN 'AMC'
	ELSE 'Multiple Properties'
END

/* Segmentations were created based on:
AMC (Airbnb Management Company): The 4 main AMCs in terms of Earnings. There may be other smaller AMCs within Multiple Properties, but it'd be impossible to pull them out individually and they're not making relevant earnings.
Multiple Properties: hosts who are managaing multiple properties, including hotels and individuals. As mentioned previously, there could be a small number of AMCs here but they're not relevant to the data and it'd be difficult to pull them out individually.
Single: hosts who manage a single property.
*/

-- Understanding the % of earnings going to each segment.
SELECT Segment, COUNT(host_id) AS NumberHosts, SUM(NumberListings) AS NumberListings,ROUND(SUM(ROUND((Earnings/(SELECT SUM(Earnings) FROM Earnings))*100,2)),0) AS PercEarning
FROM Earnings
GROUP BY Segment

/* Proportion of earnings through Airbnb in Napoli:
Single property hosts: 26% (730 hosts - 730 listings)
Main Airbnb management companies: 26% (4 companies - 124 listings)
Other multiple-property hosts: 48% (309 hosts - 823 listings)

Conclusions: In the Napoli environment, if you have an additional property and you feel like earning some money for it, you're better off putting it in the hands of
an Airbnb Management company. This type of experience is very far away from what Airbnb inteded to provide. Airbnb is becoming a business and no longer a place
for those who want to make some money from an extra property.

From a rental perspective, these companies make it very convenient for hosts in and outside of Napoli to acquire properties and turn them into Airbnbs as it's
profitable and easy to manage.
Massification of Airbnb
*/

