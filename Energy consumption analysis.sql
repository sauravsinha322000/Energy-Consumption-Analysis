CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;
-- 1. country table
CREATE TABLE country_3 (
CID VARCHAR(10) PRIMARY KEY,
Country VARCHAR(100) UNIQUE
);
SELECT * FROM COUNTRY_3;


-- 2. emission_3 table
CREATE TABLE emission_3 (
country VARCHAR(100),
energy_type VARCHAR(50),
year INT,
emission INT,
per_capita_emission DOUBLE,
FOREIGN KEY (country) REFERENCES country(Country)
);
SELECT * FROM EMISSION_3;




-- 3. population table
CREATE TABLE population_3 (
countries VARCHAR(100),
year INT,
Value DOUBLE,
FOREIGN KEY (countries) REFERENCES country(Country)
);
SELECT * FROM POPULATION_3;




-- 4. production table
CREATE TABLE production_3 (
country VARCHAR(100),
energy VARCHAR(50),
year INT,
production INT,
FOREIGN KEY (country) REFERENCES country(Country)
);
SELECT * FROM PRODUCTION_3;



-- 5. gdp_3 table
CREATE TABLE gdp_3 (
Country VARCHAR(100),
year INT,
Value DOUBLE,
FOREIGN KEY (Country) REFERENCES country(Country)
);
SELECT * FROM GDP_3;




-- 6. consumption table
CREATE TABLE consum_3 (
country VARCHAR(100),
energy VARCHAR(50),
year INT,
consumption INT,
FOREIGN KEY (country) REFERENCES country(Country)
);
SELECT * FROM CONSUM_3;



# Data Analysis Questions
## General & Comparative Analysis
-- What is the total emission per country for the most recent year available?
select country,year,sum(emission) as total_emission from emission_3 where year=(select max(year) from emission_3) group by country,year order by total_emission desc;

-- What are the top 5 countries by GDP in the most recent year?
select country,year,sum(value) as gdp_value from gdp_3 where year=(select max(year) from gdp_3) group by country,year order by gdp_value desc limit 5;


-- Compare energy production and consumption by country and year.
select c.country,c.year,sum(c.consumption) as total_consumption,sum(p.production) as total_production from consum_3 c inner join production_3 p  on c.country=p.country and c.year=p.year group by c.country,c.year order by c.country,c.year desc;

-- Which energy types contribute most to emissions across all countries?
select energy_type,sum(emission) as total_emissions, round(sum(emission)*100/ (select sum(emission) from emission_3),2) as global_percent from emission_3 group by energy_type order by total_emissions desc;

## Trend Analysis Over Time
-- How have global emissions changed year over year?
with yearlytotals as (select year,sum(emission) as total_emission from emission_3 group by year) select year,total_emission,
total_emission-lag(total_emission) over(order by year) as absolute_change,round(total_emission-lag(total_emission) over(order by year)*100/lag(total_emission) over(order by year),2) as yoy_growth_percentage
from yearlytotals order by year desc;

-- What is the trend in GDP for each country over the given years?
with yeartotal as(select country,year,sum(value) as total_value from gdp_3 group by country,year) select country,year,total_value,
total_value-lag(total_value) over(order by year) as absolute_change_value,round(total_value-lag(total_value) over(order by year)*100/lag(total_value) over(order by year),2)
as yoy_global_percent from yeartotal order by year desc;

-- How has population growth affected total emissions in each count?
with combinedata as(select e.country,e.year,max(p.value) as total_population,sum(e.emission) as total_emission from emission_3 e inner join population_3 p on e.country=p.country and e.year=p.year group by p.country,p.year),
trendanalysis as(select country,year,total_emission,total_population,round(total_emission/total_population),6 as emission_per_capita,
lag(total_emission) over(partition by country order by year) as prev_emission, lag(total_population) over(partition by country order by year) as prev_population
from combinedata)select country,year,total_emission,total_population,emission_per_capita,
round(((total_population-prev_population)*100)/prev_population,2)as population_growth_percent,
round(((total_emission-prev_emission)*100)/prev_emission,2)as emission_growth_percent from trendanalysis where prev_population is not null order by country,year desc;

-- Has energy consumption increased or decreased over the years for major economies?
with energy_consumption as(select country,year,sum(emission) as total_emission from emission_3 group by country,year) select country,year,total_emission,
total_emission-lag(total_emission) over(partition by country order by year) as old_emission,round(total_emission-lag(total_emission) over(partition by country order by year)*100/
lag(total_emission) over(partition by country order by year),2) as change_energy_consumption from energy_consumption order by year desc;

-- What is the average yearly change in emissions per capita for each country?
WITH PerCapitaBase AS (SELECT e.country,e.year,SUM(e.emission) / MAX(p.value) AS emissions_per_capita FROM emission_3 e INNER JOIN population_3 p ON e.country = p.country AND e.year = p.year
GROUP BY e.country, e.year),YearlyDifferences AS (SELECT country,year,emissions_per_capita,emissions_per_capita - LAG(emissions_per_capita) OVER (PARTITION BY country ORDER BY year) AS yearly_change FROM 
PerCapitaBase)SELECT country,COUNT(yearly_change) AS years_tracked,ROUND(AVG(yearly_change), 6) AS avg_yearly_per_capita_change FROM YearlyDifferences WHERE yearly_change IS NOT NULL
GROUP BY country ORDER BY avg_yearly_per_capita_change ASC;


## Ratio & Per Capita Analysis
-- What is the emission-to-GDP ratio for each country by year?
select e.country,e.year,sum(e.emission),g.value,round(sum(e.emission)/g.value,6) as gdp_ratio from emission_3 e inner join gdp_3 g on e.country=g.country and e.year=g.year group by e.country,
e.year,g.value order by gdp_ratio asc; 

-- What is the energy consumption per capita for each country over the last decade?
SET @max_year = (SELECT MAX(year) FROM consum_3);
select c.country,c.year,sum(c.consumption),max(p.value) as population,round(sum(c.consumption)/max(p.value),6) as consumption_per_capita from consum_3 c inner join population_3 p 
on c.country=p.country and c.year=p.year where c.year >= (@max_year - 10)  group by c.country,c.year order by c.country asc,c.year desc; 


-- How does energy production per capita vary across countries?
select p.country,p.year,sum(p.production) as production_energy,max(pop.value) as population,round(sum(p.production)/max(pop.value),6) as production_per_capita from production_3 p 
inner join population_3 pop on p.country=pop.country and p.year=pop.year where p.year>=2020 group by p.country,p.year order by p.country asc,
pop.year desc; 
-- Which countries have the highest energy consumption relative to GDP?
SELECT c.country,c.year,SUM(c.consumption) AS total_consumption,g.value AS gdp_value,ROUND(SUM(c.consumption) / g.value, 6) AS energy_to_gdp_ratio FROM consum_3 c INNER JOIN 
gdp_3 g ON c.country = g.country AND c.year = g.year WHERE c.year >= 2015 AND g.value > 0 GROUP BY c.country,c.year,g.value ORDER BY c.country ASC, c.year DESC;

-- What is the correlation between GDP growth and energy production growth?
SELECT growth_data.country,COUNT(*) AS tracking_years,ROUND((COUNT(*) * SUM(growth_data.gdp_growth * growth_data.prod_growth) - SUM(growth_data.gdp_growth) * SUM(growth_data.prod_growth)) / 
SQRT((COUNT(*) * SUM(POW(growth_data.gdp_growth, 2)) - POW(SUM(growth_data.gdp_growth), 2)) * (COUNT(*) * SUM(POW(growth_data.prod_growth, 2)) - POW(SUM(growth_data.prod_growth), 2))), 4
) AS growth_correlation_coefficient FROM (SELECT curr.country,curr.year,((curr.total_gdp - prev.total_gdp) * 100.0 / prev.total_gdp) AS gdp_growth,((curr.total_production - prev.total_production) * 100.0 / prev.total_production) AS prod_growth
FROM (SELECT p.country, p.year, SUM(p.energy) AS total_production, MAX(g.value) AS total_gdp FROM production_3 p INNER JOIN gdp_3 g ON p.country = g.country AND p.year = g.year
GROUP BY p.country, p.year) curr INNER JOIN (SELECT p.country, p.year, SUM(p.energy) AS total_production, MAX(g.value) AS total_gdp FROM production_3 p INNER JOIN gdp_3 g ON p.country = g.country AND p.year = g.year
GROUP BY p.country, p.year) prev ON curr.country = prev.country AND curr.year = prev.year + 1 WHERE prev.total_gdp > 0 AND prev.total_production > 0) growth_data GROUP BY growth_data.country
HAVING tracking_years >= 5 ORDER BY growth_correlation_coefficient DESC;



## Global Comparisons
-- What are the top 10 countries by population and how do their emissions compare?
SET @latest_year = (SELECT MAX(year) FROM population_3);
SELECT pop.country,pop.year,MAX(pop.value) AS total_population,SUM(e.emission) AS total_emissions,ROUND(SUM(e.emission) / MAX(pop.value), 6) AS emissions_per_capita FROM population_3 pop
INNER JOIN emission_3 e ON pop.country = e.country AND pop.year = e.year WHERE pop.year = @latest_year GROUP BY pop.country,pop.year ORDER BY total_population DESC   -- Isolate the largest countries first
LIMIT 10;                  


-- Which countries have improved (reduced) their per capita emissions the most over the last decade?
SELECT recent.country,ROUND(prior.co2_per_capita, 4) AS footprint_10_years_ago,ROUND(recent.co2_per_capita, 4) AS recent_footprint,ROUND(recent.co2_per_capita - prior.co2_per_capita, 4) AS absolute_change,
ROUND(((recent.co2_per_capita - prior.co2_per_capita) / prior.co2_per_capita) * 100.0, 2) AS percentage_change FROM (SELECT e.country, e.year, SUM(e.emission) / MAX(pop.value) AS co2_per_capita
FROM emission_3 e INNER JOIN population_3 pop ON e.country = pop.country AND e.year = pop.year WHERE e.year = (SELECT MAX(year) FROM emission_3) GROUP BY e.country, e.year) recent
INNER JOIN (SELECT e.country, e.year, SUM(e.emission) / MAX(pop.value) AS co2_per_capita FROM emission_3 e INNER JOIN population_3 pop ON e.country = pop.country AND e.year = pop.year
WHERE e.year = (SELECT MAX(year) FROM emission_3) - 10 GROUP BY e.country, e.year) prior ON recent.country = prior.country WHERE prior.co2_per_capita > 0 -- Safe filter to prevent any potential Division-by-Zero faults
AND (recent.co2_per_capita - prior.co2_per_capita) < 0 ORDER BY absolute_change ASC LIMIT 10;

-- What is the global share (%) of emissions by country?
SELECT e.country,SUM(e.emission) AS total_emissions,ROUND(SUM(e.emission) * 100.0 / global_total.grand_sum, 2) AS global_percentage_share FROM emission_3 e CROSS JOIN (SELECT SUM(emission) AS grand_sum 
FROM emission_3 WHERE year = (SELECT MAX(year) FROM emission_3)) global_total WHERE e.year = (SELECT MAX(year) FROM emission_3)GROUP BY e.country,global_total.grand_sum ORDER BY 
global_percentage_share DESC;

-- What is the global average GDP, emission, and population by year?
SELECT gdp_totals.year,ROUND(AVG(gdp_totals.country_gdp), 2) AS global_avg_gdp,ROUND(AVG(emission_totals.country_emissions), 2) AS global_avg_emission,ROUND(AVG(pop_totals.country_population), 2) AS global_avg_population
FROM (SELECT country, year, MAX(value) AS country_gdp FROM gdp_3 GROUP BY country, year) gdp_totals INNER JOIN (SELECT country, year, SUM(emission) AS country_emissions FROM emission_3 
GROUP BY country, year) emission_totals ON gdp_totals.country = emission_totals.country AND gdp_totals.year = emission_totals.year INNER JOIN (SELECT country, year, MAX(value) AS country_population FROM population_3 
GROUP BY country, year) pop_totals ON gdp_totals.country = pop_totals.country AND gdp_totals.year = pop_totals.year GROUP BY gdp_totals.year ORDER BY gdp_totals.year DESC;



