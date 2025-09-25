-- ## Prescribers Database

-- For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	prescr.npi, 
	SUM(rx.total_claim_count)
FROM 
	prescriber AS prescr
LEFT JOIN 
	prescription AS rx
ON 
	prescr.npi = rx.npi
WHERE 
	rx.total_claim_count IS NOT NULL
GROUP BY 
	prescr.npi
ORDER BY 
	SUM(rx.total_claim_count) DESC;

--answer: The prescriber NPI with the highest total of claims: 1881634483, 99,707 claims
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	prescr.nppes_provider_first_name, 
	prescr.nppes_provider_last_org_name, 
	prescr.specialty_description, 
	SUM(rx.total_claim_count) AS sum_of_clm_amt
FROM 
	prescriber AS prescr
LEFT JOIN 
	prescription AS rx
ON 
	prescr.npi = rx.npi
WHERE 
	rx.total_claim_count IS NOT NULL
GROUP BY
	prescr.nppes_provider_first_name, 
	prescr.nppes_provider_last_org_name, 
	prescr.specialty_description
ORDER BY 
	SUM(rx.total_claim_count) DESC;

--answer: Highest prescriber name: Bruce Pendley, Family Practice. Total CLaims: 99,707

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
	prescr.specialty_description, 
	SUM(rx.total_claim_count)
FROM 
	prescriber AS prescr 
LEFT JOIN 
	prescription AS rx
ON 
	prescr.npi = rx.npi
WHERE 
	rx.total_claim_count IS NOT NULL
GROUP BY 
	prescr.specialty_description
ORDER BY 
	SUM(rx.total_claim_count) DESC;

--answer: Family Practice, 9,752,347


--     b. Which specialty had the most total number of claims for opioids?

SELECT 
	prescr.specialty_description, 
	drug.opioid_drug_flag, 
	SUM(rx.total_claim_count)
FROM 
	prescriber AS prescr
LEFT JOIN 
	prescription AS rx
ON 
	prescr.npi = rx.npi
LEFT JOIN 
	drug
ON 
	drug.drug_name = rx.drug_name
WHERE 
	rx.total_claim_count IS NOT NULL AND 
	drug.opioid_drug_flag = 'Y'
GROUP BY 
	prescr.specialty_description, 
	drug.opioid_drug_flag
ORDER BY SUM(rx.total_claim_count) DESC;

--answer: Nurse Practitioner, 900,845

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT
	specialty_description
FROM 
	 prescriber AS prescr
WHERE	
	prescr.specialty_description NOT IN 
	(SELECT specialty_description 
	FROM prescriber
	INNER JOIN prescription
	USING(npi))
ORDER BY
	specialty_description ASC;

	

--answer: yes, 15 different specialties with no prescription

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT
	specialty_description,
	COUNT(drug.opioid_drug_flag = 'Y') AS sum_opi,
	SUM(rx.total_claim_count) AS total_clm,
	((COUNT(drug.opioid_drug_flag = 'Y')) / (SUM(rx.total_claim_count)) * 100) AS percentage
FROM 
	prescriber AS prescr
LEFT JOIN 
	prescription AS rx
ON 
	prescr.npi = rx.npi
LEFT JOIN 
	drug
ON 
	drug.drug_name = rx.drug_name
GROUP BY 
	specialty_description;


SELECT 
	specialty_description,
	SUM(total_claim_count),
	(SELECT COUNT(opioid_drug_flag = 'Y') FROM drug) AS opi
FROM prescriber AS prescr 
LEFT JOIN prescription
USING(npi)
LEFT JOIN drug
USING(drug_name)
GROUP BY
	specialty_description
ORDER BY
	specialty_description;




--answer: Highest percentage of Opioids per claims filed is 9.09%, a tie between Thoracic Surgery, Psychologists, and Colon& Rectal Surgery
-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT 
	d.generic_name, 
	SUM(total_drug_cost) AS sum_of_cost
FROM 
	prescription AS p
LEFT JOIN 
	drug AS d
USING(drug_name)
GROUP BY d.generic_name
ORDER BY sum_of_cost DESC;

--answer: INSULIN

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**



SELECT
	d.generic_name, 
	ROUND((SUM(total_drug_cost)/SUM(p.total_day_supply)),2) AS cost_per_day
FROM 
	prescription as p
FULL JOIN 
	drug AS d
USING(drug_name)
WHERE 
	total_drug_cost > 0
	AND
	p.total_day_supply > 0
GROUP BY 1
ORDER BY
	cost_per_day DESC;



--answer: Highest Cost per day is C1 ESTERASE INHIBITOR at $3,495.22 per day

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT 
	drug_name,
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'OPIOID'
		WHEN antibiotic_drug_flag = 'Y' THEN 'ANTIBIOTIC'
		ELSE 'Neither'
	END drug_type
FROM 
	drug;


--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'OPIOID'
		WHEN antibiotic_drug_flag = 'Y' THEN 'ANTIBIOTIC'
		ELSE 'Neither'
	END drug_type,
	TO_CHAR(SUM(p.total_drug_cost), 'FM$999,999,999,990.00') AS total
FROM 
	drug AS d
LEFT JOIN 
	prescription AS p
USING(drug_name)
GROUP BY
	drug_type
ORDER BY 
	total DESC;

--answer: OPIOIDS have the highest Total Drug Cost at $105,080,626.37

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT 
	COUNT(state)
FROM
	CBSA
LEFT JOIN
	fips_county
USING(fipscounty)
WHERE 
	state = 'TN';



--answer: Tennessee has 42 CBSAs

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT	
	c.cbsaname,
	SUM(p.population)
FROM
	CBSA c
LEFT JOIN
	population p
USING(fipscounty)
WHERE	
	p.population IS NOT NULL
GROUP BY 
	c.cbsaname
ORDER BY
	SUM(p.population) DESC;


--answer: CBSA 34980 Nashville-Davidson-Murf-Franklin, TN has the largest combined population of 1,830,410     
--CBSA 34100 Morristown, TNhas the smallest combined population of 116,352
--note: not sure why only TN is showing

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT 
	f.county, 
	SUM(p.population) sum_of_pop
FROM 
	population p
LEFT JOIN 
	cbsa
USING(fipscounty)
LEFT JOIN 
	fips_county f
USING(fipscounty)
WHERE 
	p.fipscounty NOT IN (
		SELECT fipscounty 
		FROM cbsa)
GROUP BY 
	f.county
ORDER BY 
	sum_of_pop DESC;
-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT
	d.drug_name,
	total_claim_count
FROM 
	prescription p
LEFT JOIN
	drug d
USING(drug_name)
GROUP BY 
	d.drug_name,
	total_claim_count
HAVING 
	total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT
	d.drug_name,
	total_claim_count,
	opioid_drug_flag
FROM 
	prescription p
LEFT JOIN
	drug d
USING(drug_name)
GROUP BY 
	d.drug_name,
	total_claim_count,
	opioid_drug_flag
HAVING 
	total_claim_count >= 3000;

--     c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT	
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	d.drug_name,
	total_claim_count,
	opioid_drug_flag
FROM 
	prescription p
LEFT JOIN
	drug d
USING(drug_name)
LEFT JOIN 
	prescriber pre
ON
	p.npi = pre.npi
GROUP BY 
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	d.drug_name,
	total_claim_count,
	opioid_drug_flag
HAVING 
	total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.



SELECT	
	presc.npi,
	d.drug_name
FROM
	prescriber presc
CROSS JOIN
	drug d
WHERE
	nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
	AND opioid_drug_flag = 'Y';


--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT	
	npi,
	drug_name,
	total_claim_count
FROM
	prescriber
CROSS JOIN
	drug
LEFT JOIN prescription 
USING(npi, drug_name)
WHERE
	nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
	AND opioid_drug_flag = 'Y';
	
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT	
	npi,
	drug_name,
	COALESCE(total_claim_count,0)
FROM
	prescriber
CROSS JOIN
	drug
LEFT JOIN prescription 
USING(drug_name, npi)
WHERE
	nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
	AND opioid_drug_flag = 'Y';