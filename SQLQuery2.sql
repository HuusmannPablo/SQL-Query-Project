/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--SELECT * FROM PortfolioProject..CovidDeaths


-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, CAST((CAST(total_deaths AS FLOAT)/total_cases)*100 AS DECIMAL(5,2)) as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Argentina'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rates at any point compared to Population

SELECT 
	Location, 
	Population, 
	MAX(CAST(total_cases as FLOAT)) as HIghestInfectionCount, 
	MAX((CAST(total_cases as FLOAT)/population))*100 as PopulationInfectedPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY 4 desc


-- Showing Countries with Highest Death Count per Population

SELECT 
	Location, 
	MAX(CAST(total_deaths as FLOAT)) as HighestDeathsCount
	--MAX((CAST(total_deaths as FLOAT)/population))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY 2 desc

--Total in the world

SELECT 
	SUM(new_cases) as total_cases,	
	SUM(CAST(new_deaths as float)) as total_deaths, 
	SUM(CAST(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

--SELECT *
SELECT 
	deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccinations.new_vaccinations,
	SUM(CONVERT(int, vaccinations.new_vaccinations)) OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.date) as RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
WHERE deaths.continent is not null
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopulationVsVaccinations (Continent, Location, Date, Population, new_vaccinations, RollingCountPeopleVaccinated)
AS (
SELECT 
	deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccinations.new_vaccinations,
	SUM(CONVERT(int, vaccinations.new_vaccinations)) OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.date) as RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
WHERE deaths.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingCountPeopleVaccinated/Population)*100 AS 'In Percentage'
FROM PopulationVsVaccinations


-- Using Temp Table to perform Calculation on Partition By in previous query

IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCountPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccinations.new_vaccinations,
	SUM(CONVERT(int, vaccinations.new_vaccinations)) OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.date) as RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
WHERE deaths.continent is not null
--ORDER BY 2,3

SELECT *, (RollingCountPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualization

IF OBJECT_ID('dbo.PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW dbo.PercentPopulationVaccinated;
GO
CREATE VIEW dbo.PercentPopulationVaccinated as
SELECT 
	deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccinations.new_vaccinations,
	SUM(CAST(ISNULL(vaccinations.new_vaccinations, 0) AS INT)) 
		OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.date) as RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
WHERE deaths.continent is not null
