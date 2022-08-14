-- checking for exiting view and dropping it for ease and repeated usage
DROP VIEW IF EXISTS forestation;
-- Creating view called 'forestation'
CREATE VIEW forestation AS
SELECT f.country_code AS country_code,
       f.country_name AS country_name,
       f.year,
       f.forest_area_sqkm AS forest_area_sq_km,
       l.total_area_sq_mi*2.59 AS land_area_sq_km,
       r.region,
       r.income_group,
       (f.forest_area_sqkm*100)/(l.total_area_sq_mi*2.59) AS per_forest_area_sqkm
FROM forest_area f
JOIN land_area l ON f.country_code = l.country_code
AND f.year = l.year
JOIN regions r ON r.country_code = f.country_code;

-----1)GLOBAL SITUATION------------------------------------------------------------ 
/*a) What was the total forest area (in sq km) of the world in 1990? Please keep in
mind that you can use the
 country record denoted as “World" in the region table.*/
SELECT forest_table.forest_area_sq_km
FROM forestation forest_table
WHERE forest_table.year = 1990 AND forest_table.country_name = 'World';


/*b) What was the total forest area (in sq km) of the world in 2016? Please keep in
mind that you can use the country record in the table is denoted as “World.”*/
SELECT forest_table.forest_area_sq_km
FROM forestation forest_table
WHERE forest_table.year = 2016 AND forest_table.country_name = 'World';

/*c) What was the change (in sq km) in the forest area of the world from 1990 to
2016?*/
SELECT MIN(
             (SELECT SUM(forest_area_sq_km)/2
              FROM forestation
              WHERE YEAR = 1990) -
             (SELECT SUM(forest_area_sq_km)/2
              FROM forestation
              WHERE YEAR = 2016)) AS change_in_area
FROM forestation;
              
/*d) What was the percent change in forest area of the world between 1990 and 2016?*/
WITH forest_area_1990 AS
  (SELECT SUM(forest_table.forest_area_sq_km)
   FROM forestation forest_table
   WHERE forest_table.year = 1990),
                                                                  change_in_forest_area AS
  (SELECT MIN(
                (SELECT SUM(forest_area_sq_km)
                 FROM forestation
                 WHERE YEAR = 1990) -
                (SELECT SUM(forest_area_sq_km)
                 FROM forestation
                 WHERE YEAR = 2016)) AS per_of_change_in_area
   FROM forestation)
SELECT MIN(
             (SELECT *
              FROM change_in_forest_area)*100/
             (SELECT *
              FROM forest_area_1990)) AS per_of_change_in_area
FROM forestation;
              
/*e) If you compare the amount of forest area lost between 1990 and 2016, to which
country's total area in 2016 is it closest to?*/
WITH change_in_forest_area AS
  (SELECT MIN(
                (SELECT SUM(forest_area_sq_km)
                 FROM forestation
                 WHERE YEAR = 1990) -
                (SELECT SUM(forest_area_sq_km)
                 FROM forestation
                 WHERE YEAR = 2016)) AS per_of_change_in_area
   FROM forestation)
SELECT *
FROM forestation f
WHERE YEAR = 2016
ORDER BY ABS(f.land_area_sq_km -
               (SELECT *
                FROM change_in_forest_area))
LIMIT 1;
------ 2) REGIONAL OUTLOOK--------------               
/*a) What was the percent forest of the entire world in 2016? Which region had the
HIGHEST percent forest in 2016,
 and which had the LOWEST, to 2 decimal places?*/
SELECT SUM(forest_area_sq_km*100)/(SUM(land_area_sq_km)) AS percent_of_forest
FROM forestation f
WHERE YEAR = 2016;

SELECT region,
       AVG(per_forest_area_sqkm) AS forest_area
FROM forestation
WHERE YEAR = 2016
  AND per_forest_area_sqkm IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

/*b) What was the percent forest of the entire world in 1990? Which region had the
 HIGHEST percent forest in 1990,
 and which had the LOWEST, to 2 decimal places?
 */




SELECT round((SUM(forest_area_sq_km*100)/(SUM(land_area_sq_km)))::numeric, 2) AS percent_of_forest
--IMP : Round() takes only numeric input expression, double precision NOT allowed, There's no implicit cast from double precision to numeric, so you'll have to use an explicit cast as above
--SUM(forest_area_sq_km*100)/(SUM(land_area_sq_km)) AS percent_of_forest
--ROUND(SUM(forest_area_sq_km*100)/(SUM(land_area_sq_km))::numeric, 2)AS percent_of_forest

-- SUM(forest_area_sq_km*100)/(SUM(land_area_sq_km))
-- AS percent_of_forest
FROM forestation f
WHERE YEAR = 1990;
                                          
/*c) Based on the table you created, which regions of the world DECREASED in forest
area from 1990 to 2016?*/
SELECT region,
       (SUM(forest_area_sq_km)*100)/(SUM(land_area_sq_km)) AS percent_of_forest
FROM forestation f
WHERE YEAR = 2016
  AND per_forest_area_sqkm IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

------3) COUNTRY-LEVEL DETAIL-------------

/*a) Which 5 countries saw the largest amount decrease in forest area from 1990 to
 2016?
What was the difference in forest area for each?*/
WITH forest_1990 AS
  (SELECT country_code,
          YEAR,
          country_name,
          forest_area_sq_km
   FROM forestation
   WHERE YEAR = 1990),
     forest_2016 AS
  (SELECT country_code,
          YEAR,
          country_name,
          forest_area_sq_km
   FROM forestation
   WHERE YEAR = 2016)
SELECT f16.country_code,
       f16.country_name,
       f90.year AS year_1990,
       f16.year AS year_2016,
       f90.forest_area_sq_km AS forest_1990,
       f16.forest_area_sq_km AS forest_2016,
       (f16.forest_area_sq_km - f90.forest_area_sq_km) AS change_in_forest_area,
        (f16.forest_area_sq_km - f90.forest_area_sq_km)*100/f90.forest_area_sq_km AS per_change_in_forest_area                                 
FROM forest_1990 f90
JOIN forest_2016 f16 ON f90.country_code = f16.country_code
AND f90.country_name = f16.country_name
WHERE (f90.forest_area_sq_km IS NOT NULL)
  AND (f16.forest_area_sq_km IS NOT NULL)
  AND (f16.country_name != 'World')
ORDER BY 8 DESC;
                                      
/*b) Which 5 countries saw the largest percent decrease in forest area from 1990 to
 2016?
  What was the percent change to 2 decimal places for each?*/
   WITH forest_1990 AS
  (SELECT country_code,
          YEAR,
          country_name,
          forest_area_sq_km
   FROM forestation
   WHERE YEAR = 1990),
   forest_2016 AS
  (SELECT country_code,
          YEAR,
          country_name,
          forest_area_sq_km
   FROM forestation
   WHERE YEAR = 2016)
SELECT f16.country_code,
       f16.country_name,
       f90.year AS year_1990,
       f16.year AS year_2016,
       f90.forest_area_sq_km AS forest_1990,
       f16.forest_area_sq_km AS forest_2016,
       (f16.forest_area_sq_km - f90.forest_area_sq_km) AS change_in_forest_area,
       (f16.forest_area_sq_km - f90.forest_area_sq_km)*100/(f90.forest_area_sq_km) AS per_change_in_forest_area_sqkm
FROM forest_1990 f90
JOIN forest_2016 f16 ON f90.country_code = f16.country_code
AND f90.country_name = f16.country_name
WHERE (f90.forest_area_sq_km IS NOT NULL)
  AND (f16.forest_area_sq_km IS NOT NULL)
  AND (f16.country_name != 'World')
ORDER BY 8
LIMIT 5;
                                 
/*c) If countries were grouped by percent forestation in quartiles, which group had
the most countries in it in 2016?*/
SELECT DISTINCT(quartiles),
       COUNT(country_name) OVER (PARTITION BY quartiles)
FROM
  (SELECT country_name,
          CASE
              WHEN per_forest_area_sqkm <= 25 THEN 1
              WHEN per_forest_area_sqkm > 25
                   AND per_forest_area_sqkm <= 50 THEN 2
              WHEN per_forest_area_sqkm > 50
                   AND per_forest_area_sqkm <= 75 THEN 3
              ELSE 4
          END AS quartiles
   FROM forestation
   WHERE YEAR = 2016
     AND (per_forest_area_sqkm IS NOT NULL)) t1
ORDER BY 2;
          
/*d) List all of the countries that were in the 4th quartile (percent forest > 75%)
in 2016.*/
SELECT country_name,
       per_forest_area_sqkm,
       region
FROM forestation
WHERE YEAR = 2016
  AND (per_forest_area_sqkm IS NOT NULL)
  AND (per_forest_area_sqkm > 75)
ORDER BY 2 DESC;
          
