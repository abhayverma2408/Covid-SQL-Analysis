-- TOP 10 COUNTRIES WITH HIEGEST DEATH RATES 

SELECT TOP (10) location , date , total_deaths , total_cases , (CAST(total_deaths AS FLOAT)/total_cases)*100 AS Death_Rate
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
AND date = (SELECT MAX(date) FROM portfolio_project..CovidDeaths)
GROUP BY location , date , total_deaths , total_cases
HAVING total_cases > 10000
ORDER BY Death_Rate DESC 

-- MONTH WITH THE MOST NEW CASES FOR EACH CONTINENT

WITH max_cases 
AS 
(
SELECT location , DATEPART(MONTH , date) AS month , SUM(new_cases) AS total_new_cases
FROM portfolio_project..CovidDeaths
WHERE continent IS NULL 
GROUP BY DATEPART(MONTH , date) , location 
)
,final
AS
(
SELECT location , MAX(total_new_cases) AS max_month_cases
FROM max_cases
GROUP BY location 
)
SELECT MC.location , MC.month
FROM max_cases MC
JOIN final F
	ON MC.location = F.location
	AND MC.total_new_cases = F.max_month_cases

-- COUNTRIES WITH LESS THAN 1 PERCENT POPULATION INFECTED

SELECT location , population , MAX(total_cases) AS total_cases , (CAST(MAX(total_cases) AS FLOAT)/population)*100 AS InfectionRate
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location , population 
HAVING (CAST(MAX(total_cases) AS FLOAT)/population)*100 < 1
ORDER BY 1,2,3

-- 1st CASE AND PEAK CASES DATE DIFFERANCE

WITH FC AS
(
SELECT location , date , new_cases 
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
AND new_cases != 0
AND new_cases IS NOT NULL
GROUP BY location , date , new_cases
)
, FCD AS
(
SELECT location , MIN(date) AS first_case_date
FROM FC 
GROUP BY location 
)
, PC AS
(
SELECT location , MAX(new_cases) AS peak_cases
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
)
, PCD AS
(
SELECT CD.location , CD.date AS peak_case_date , CD.new_cases
FROM portfolio_project..CovidDeaths CD
JOIN PC 
	ON CD.location = PC.location
	AND CD.new_cases = PC.peak_cases 
)
SELECT FCD.location , FCD.first_case_date , PCD.peak_case_date , DATEDIFF(DAY , FCD.first_case_date , PCD.peak_case_date) AS DateDifference
FROM FCD 
JOIN PCD 
	ON FCD.location = PCD.location 
ORDER BY location 

-- 7 DAY ROLLING AVERAGE OF NEW CASES IN INDIA

SELECT location , date , new_cases ,
AVG(CAST(new_cases AS FLOAT)) OVER(PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW ) AS RollingAverage ,
SUM(CAST(new_cases AS FLOAT)) OVER(PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW ) AS RollingSum
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
AND location LIKE 'India'

-- COUNTRIES WITH MOST DEATH PER CONTINENT

WITH CTE AS
(
SELECT continent , location , MAX(total_deaths) AS total_deaths 
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent , location 
)
, RANKING AS 
(
SELECT continent , location , total_deaths , DENSE_RANK()  OVER(PARTITION BY continent ORDER BY total_deaths DESC) AS countries_rank
FROM CTE 
GROUP BY location , continent , total_deaths
)
SELECT *
FROM RANKING
WHERE countries_rank <= 3

-- 1ST CASE AND 50% POPULATION VACINATED WITH FIRST DOSE DATE DIFFERENCE

WITH ROLLING AS
(
SELECT location , date , total_vaccinations , people_vaccinated , new_vaccinations,
SUM(CAST(new_vaccinations AS FLOAT)) OVER(PARTITION BY location ORDER BY date) AS RollingSum
FROM portfolio_project..CovidVaccinations
WHERE continent IS NOT NULL
)
, FIFTYPERCENT AS
(
SELECT R.location , R.date
FROM ROLLING R
JOIN portfolio_project..CovidDeaths CD
ON R.location = CD.location
WHERE (CAST(R.RollingSum AS FLOAT)/CD.population)*100 >= 50
GROUP BY R.location , R.date
)
, FVD AS
(
SELECT location , MIN(DATE) AS fifty_date
FROM FIFTYPERCENT
GROUP BY location
)
, FC AS
(
SELECT location , date , new_cases 
FROM portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
AND new_cases != 0
AND new_cases IS NOT NULL
GROUP BY location , date , new_cases
)
, FCD AS
(
SELECT location , MIN(date) AS first_case_date
FROM FC 
GROUP BY location 
)
SELECT FVD.location , FVD.fifty_date , FCD.first_case_date , 
DATEDIFF(DAY , FCD.first_case_date , FVD.fifty_date) AS DateDifference
FROM FVD 
JOIN FCD 
	ON FVD.location = FCD.location
ORDER BY DateDifference , FVD.location 

-- SUMMARY TABLE FOR EACH COUNTRY

WITH ST AS 
(
SELECT CD.location , CD.population , MAX(CD.total_cases) AS total_cases , MAX(CD.total_deaths) AS total_deaths , 
(CAST(MAX(CD.total_deaths) AS FLOAT)/MAX(CD.total_cases))*100 AS DeathRate ,
(CAST(MAX(CV.people_vaccinated) AS FLOAT)/CD.population)*100 AS VaccinationRate
FROM portfolio_project..CovidDeaths CD
JOIN portfolio_project..CovidVaccinations CV
	ON CD.location = CV.location
WHERE CD.continent IS NOT NULL
GROUP BY CD.location , CD.population 
)
SELECT * ,
CASE 
WHEN DeathRate < 1 AND total_cases > 5000 THEN 'LOW'
WHEN DeathRate > 1 AND DeathRate < 5 AND total_cases > 5000 THEN 'MEDIUM'
WHEN DeathRate > 5 AND total_cases > 5000 THEN 'HIGH'
WHEN DeathRate IS NULL 
OR total_cases < 5000 THEN 'LOW'
END AS RISK_LABLE 
FROM ST 
ORDER BY RISK_LABLE , location 

-- MONTH-OVER-MONTH CHANGE IN NEW CASES

WITH MNC AS 
(
SELECT location , DATEPART(YEAR , date) AS year , DATEPART(MONTH , date) AS month , SUM(new_cases) AS monthly_new_cases
FROM portfolio_project..CovidDeaths 
GROUP BY location , DATEPART(MONTH , date) , DATEPART(YEAR , date)
)
, PMC AS 
(
SELECT * , LAG(monthly_new_cases , 1 , 0) OVER(PARTITION BY location ORDER BY YEAR , month) AS prev_month_cases
FROM MNC
)
SELECT TOP(5) location , month , ((monthly_new_cases - prev_month_cases)/prev_month_cases)*100 / NULLIF(prev_month_cases,0) AS pct_change
FROM PMC
WHERE prev_month_cases IS NOT NULL
AND prev_month_cases > 0
ORDER BY pct_change DESC 