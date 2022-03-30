/* New Years Eve in Napoli - analysis of behaviour of segments

Looking at how each type of listing (those managed by Airbnb Management Companies - AMC, those from hosts who own multiple properties - MP and those from hosts who only own 1 property - SP)
behaved in terms of price and occupancy over the New Years Period. 

This period was divided in to 3 stages - defined after analysis of price variance:
December Minus NYE: from 15/12/2021 (data scrape date) to 29/12/2021
NYE: 30/12/2021 to 02/01/2022
January: 03/01/2022 to 31/01/2022

The group of listings here is limited to those included in the Earnings table:
Active listings only: those that received a review in the last 6 months.
Focus listings only: one-bed flats, two-bed flats and private rooms (see Overview for more details on the rationale behind this group)
Listings with genuine occupancy only: listings that had their calendary unavailable for most of the year were excluded (see Host Analysis for more details on the rationale behind this group)
Booked nights only: only the nights that were actually booked. This ensures that only prices paid by guests are included in the analysis, as hosts can set their prices to whatever they want.
*/

-- All properties of the group of listings: looking at the price variance in general and total number of listings occupied during each period (in average).
WITH CTE AS (
SELECT a.date, ROUND(AVG(a.price),0) AS AvgPrice, COUNT(a.available) AS OccupiedListings, CASE 
	WHEN a.date BETWEEN '2021-12-15' AND '2021-12-29' THEN 'December minus NYE'
    WHEN a.date BETWEEN '2021-12-30' AND '2022-01-02' THEN 'NYE'
	WHEN a.date BETWEEN '2022-01-03' AND '2022-01-31' THEN 'January'
    END AS Season
FROM calendar a
JOIN FocusListings b ON a.listing_id = b.id
WHERE b.host_id IN (SELECT host_id FROM Earnings) AND a.available = 'f'
GROUP BY a.date
ORDER BY a.date )

SELECT Season, ROUND(AVG(AvgPrice),0) AS AvgPrice, ROUND(AVG(OccupiedListings),0) AS AvgOccupiedListings
FROM CTE
GROUP BY Season

-- Listings managed by AMCs: a much higher hike in price than the average over NYE.
WITH CTE AS (
SELECT a.date, ROUND(AVG(a.price),0) AS AvgPrice, COUNT(a.available) AS OccupiedListings, (SELECT SUM(NumberListings) FROM Earnings WHERE Segment = 'AMC') AS TotalListings, CASE 
	WHEN a.date BETWEEN '2021-12-15' AND '2021-12-29' THEN 'December minus NYE'
    WHEN a.date BETWEEN '2021-12-30' AND '2022-01-02' THEN 'NYE'
	WHEN a.date BETWEEN '2022-01-03' AND '2022-01-31' THEN 'January'
    END AS Season
FROM calendar a
LEFT JOIN FocusListings b ON a.listing_id = b.id
LEFT JOIN Earnings c ON b.host_id = c.host_id
WHERE c.Segment = 'AMC' AND a.available = 'f'
GROUP BY a.date
ORDER BY a.date )

SELECT Season, ROUND(AVG(AvgPrice),0) AS AvgPrice, ROUND((AVG(OccupiedListings)/AVG(TotalListings)*100),0) AS PercOccupancy
FROM CTE
GROUP BY Season


-- Multiple Properties: a hike in NYE is seen but smaller than AMCs. Prices for the other periods are in line with the average.
WITH CTE AS (
SELECT a.date, ROUND(AVG(a.price),0) AS AvgPrice, COUNT(a.available) AS OccupiedListings, (SELECT SUM(NumberListings) FROM Earnings WHERE Segment = 'Multiple Properties') AS TotalListings, CASE 
	WHEN a.date BETWEEN '2021-12-15' AND '2021-12-29' THEN 'December minus NYE'
    WHEN a.date BETWEEN '2021-12-30' AND '2022-01-02' THEN 'NYE'
	WHEN a.date BETWEEN '2022-01-03' AND '2022-01-31' THEN 'January'
    END AS Season
FROM calendar a
LEFT JOIN FocusListings b ON a.listing_id = b.id
LEFT JOIN Earnings c ON b.host_id = c.host_id
WHERE c.Segment = 'Multiple Properties' AND a.available = 'f'
GROUP BY a.date
ORDER BY a.date )

SELECT Season, ROUND(AVG(AvgPrice),0) AS AvgPrice, ROUND((AVG(OccupiedListings)/AVG(TotalListings)*100),0) AS PercOccupancy
FROM CTE
GROUP BY Season

-- Single Property: similar average prices to MPs but a much smaller hike during NYE. Prices for the other periods are in line with the average.
WITH CTE AS (
SELECT a.date, ROUND(AVG(a.price),0) AS AvgPrice, COUNT(a.available) AS OccupiedListings, (SELECT SUM(NumberListings) FROM Earnings WHERE Segment = 'Single') AS TotalListings, CASE 
	WHEN a.date BETWEEN '2021-12-15' AND '2021-12-29' THEN 'December minus NYE'
    WHEN a.date BETWEEN '2021-12-30' AND '2022-01-02' THEN 'NYE'
	WHEN a.date BETWEEN '2022-01-03' AND '2022-01-31' THEN 'January'
    END AS Season
FROM calendar a
LEFT JOIN FocusListings b ON a.listing_id = b.id
LEFT JOIN Earnings c ON b.host_id = c.host_id
WHERE c.Segment = 'Single' AND a.available = 'f'
GROUP BY a.date
ORDER BY a.date )

SELECT Season, ROUND(AVG(AvgPrice),0) AS AvgPrice, ROUND((AVG(OccupiedListings)/AVG(TotalListings)*100),0) AS PercOccupancy
FROM CTE
GROUP BY Season

/* All types of hosts naturally increase the price of their listings over NYE. However, AMCs can afford to charge higher prices in general 
and increase the prices more than average during NYE. MPs remain in the average while SPs stay below the average price, for both low and high seasons.
WIth those prices, AMCs still get to occupy a good amount of their properties (60% during NYE) but the other hosts show a better proportion of occupancy (80%).
Therefore, AMCs are driving the average price up in the Napoli environment and even though they get to occupy less of their properties with this approach, the end result is still good as we've seen in the Host Analysis (25% of earnings go to them even though they have only 174 listings).
*/

-- Review Score: how the different segments perform in terms of review score. Look into the different factors.

SELECT b.Segment,
ROUND(AVG(a.review_scores_rating),1) AS AvgOverall, 
ROUND(AVG(a.review_scores_accuracy),1) AS AvgAccuracy, 
ROUND(AVG(a.review_scores_cleanliness),1) AS AvgCleanliness, 
ROUND(AVG(a.review_scores_checkin),1) AS AvgCheckin, 
ROUND(AVG(a.review_scores_communication),1) AS AvgCommunication, 
ROUND(AVG(a.review_scores_location),1) AS AvgLocation, 
ROUND(AVG(a.review_scores_value),1) AS AvgValue
FROM FocusListings a
RIGHT JOIN Earnings b ON a.host_id = b.host_id 
GROUP BY b.Segment
ORDER BY b.Segment

/* Listings managed by AMCs show worse performance in the reviews overall and across all the sub-factors. 
Check-in, Communication and Location are less affected - because this is where they excel.
But levels of Accuracy, Cleanliness and Value are well below the other hosts.
MPs and Singles show similar review values.
*/

/*
AMCs are bringing unbalance to the AirBnb environment offering experiences that are not as good as other hosts but still taking a good portion of
the earnings. Airbnb prides itself as a peer-to-peer platform but the businesses are the ones fairing well in the platform even if they're offering
the best experiences. 

Surprisingly, the MP hosts are performing very similarly to Single Hosts - except for a slightly higher hike in prices. But this shows that these
hosts affect the Airbnb envirnoment in a similar way to Single Hosts and doesn't seem to be driving price up or offering poor experiences.

The AMCs are the issue for the Airbnb environment. It creates an unfair competition within the platform and allow for a mass production of Airbnb
listings thanks to the ease of managing the profiles. The property owner can even be abroad and they'll be at their best chance to make money on Airbnb
with the AMC. If they weren't allowed on the platform, MPs and Singles would still exist but price would be more under control and it would limit a
host's capacity of managing multiple profiles and making a bigger impact on the housing market. It would make being an Airbnb host less attractive
and improve the experience of those using Airbnb. 


