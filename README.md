# COVID-19 SQL Data Exploration

Nine SQL queries on COVID-19 data in SQL Server (SSMS). I first followed Alex The Analyst's tutorial ["Data Analyst Portfolio Project | SQL Data Exploration | Project 1/4"](https://youtu.be/qfyynHBFOsM), then wrote my own questions as a self-test. All queries are in `PPQ2_practice.sql`.

## Dataset
- [CovidDeaths.xlsx](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidDeaths.xlsx)
- [CovidVaccinations.xlsx](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidVaccinations.xlsx)
- Provided by the tutorial author. Coverage: 1 Jan 2020 to 30 Apr 2021, so everything below describes the first 16 months of the pandemic only.

## Skills practiced
Joins, CTEs, window functions (`DENSE_RANK`, `LAG`, rolling averages), `CASE`, date functions, aggregation, `CREATE VIEW`.

## Questions
1. Top 10 countries by death rate (deaths / cases) on each country's latest date, minimum 10,000 cases
2. Peak month of new cases per continent
3. Countries with under 1% of population infected
4. Days between first case and peak daily cases, per country
5. 7-day rolling average and sum of new cases in India
6. Top 3 countries by total deaths per continent
7. Days from first case to 50% of population with at least one dose
8. Country summary with a death-rate band
9. Sharpest month-over-month increases in new cases (previous month at least 1,000)

Not solved: consecutive weeks of rising deaths. I attempted it and could not finish it.

## Findings
- **Reported death rate:** Among countries with at least 10,000 cases, Mexico is highest at 9.25% (216,907 deaths / 2.34M cases), followed by Syria (7.0%), Sudan (6.9%), Egypt (5.9%) and Somalia (5.1%). The rest of the top 10 sit between 4.3% and 4.9%. This is reported deaths over reported cases, so countries with little testing look worse than they may be. The cutoff also matters: Yemen's rate is 19.4%, but with 6,317 cases it falls under the 10,000 threshold.
- **Raw deaths follow population:** The US (576,232) and Brazil (403,781) lead, then Mexico (216,907) and India (211,853). Mexico recorded about as many deaths as India with roughly a tenth of its population, so a per-million ranking would look very different.
- **Fastest monthly growth:** The five biggest month-over-month jumps in new cases (previous month at least 1,000) were Italy (+9,195%, from 1,126 to 104,664), Russia (+4,361%), Peru (+3,272%), India (+2,301%) and Mexico (+1,387%). All come from the first wave in spring 2020. Percent change rewards a low starting point, so this mostly shows when each outbreak took off.
- **Death-rate bands:** Six countries fall in the HIGH band (death rate of 5% or more): Yemen, Somalia, Egypt, Mexico, Sudan and Syria. 34 are LOW, more than 110 are MEDIUM, and 53 could not be rated because they have under 5,000 cases or no case data. That last group includes New Zealand (2,613 cases), Taiwan (1,128) and Vietnam (2,928).
- **Vaccination data is incomplete:** Gibraltar shows 111% (more people vaccinated than its recorded population). China and Saudi Arabia show NULL even though both ran large vaccination programs, so NULL means missing data, not zero vaccination. For comparison: Israel 62%, UK 50%, US 44%, India 9%.

## Limitations
- Data ends 30 Apr 2021, before later waves. In query 7, only countries that reached 50% vaccination inside this window appear.
- Cases and deaths are as reported. A low infection rate or a high death rate can reflect testing and reporting, not the real situation.
- Query 6 ranks by raw deaths, so large populations dominate. Deaths per million would be a fairer comparison.
- The thresholds (10,000 cases in query 1, 1,000 prior-month cases in query 9, 5,000 cases and the 1% / 5% bands in the summary view) are my own choices.
- The summary band is a simple death-rate label, not a real risk assessment.

## How I worked, and what went wrong
I wrote the first version of every query myself. I looked up `LAG` syntax (then redid that query on my own) and `CASE` syntax. I then reviewed the file with an AI assistant (Claude) and fixed these bugs:
- Month-over-month change divided by the previous month twice, giving wrong percentages.
- Two joins matched on `location` only, not `location` and `date`, so rows multiplied.
- The 50% vaccination query summed total doses instead of using people with a first dose.
- The monthly peak query ignored the year and included world and income-group rows.

I checked fixes by comparing results across queries. Totals for the same country (for example Mexico at 216,907 deaths) matched in three separately written queries.

## What I learned
- One small mistake, like not excluding continent and aggregate rows, can make a whole query useless.
- CTEs and window functions make complex logic easier to build and read.
- `MIN` and `MAX` answer a lot of useful questions on cumulative columns.
- A query that runs without errors is not necessarily correct. Checking results against raw rows is part of the work.

## How to run
Import both files into a SQL Server database named `portfolio_project` as `CovidDeaths` and `CovidVaccinations`, then run `PPQ2_practice.sql`. 
