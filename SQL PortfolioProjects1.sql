SELECT *
FROM PortfolioProjects..coviddeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProjects..vaccinations
--ORDER BY 3,4

--Select Data that we are going ot be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..coviddeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths,
	CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases), 0)*100
	AS DeathPercentage
FROM PortfolioProjects..coviddeaths
WHERE Location like 'United_States'
ORDER BY 1,2

--2nd way

SELECT Location, date, total_cases, total_deaths,
	CAST(total_deaths AS FLOAT)/ISNULL(CAST(total_cases AS FLOAT), 0)*100 
	AS DeathPercentage
FROM PortfolioProjects..coviddeaths
WHERE Location like 'United_States'
ORDER BY 1,2




--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT Location, date, population, total_cases, 
	(total_cases/population)*100
	AS PercentagePopulationInfected
FROM PortfolioProjects..coviddeaths
WHERE Location like 'United_States'
ORDER BY 1,2

--Looking at Country with highest infection rate compared to Population

SELECT Location, population, 
	MAX(CAST(total_cases AS Int)) AS HighestInfectionCount,
	MAX(CAST(total_cases AS Int)/population)*100 AS PercentagePopulationInfected
FROM PortfolioProjects..coviddeaths
--WHERE Location like 'United_States'
GROUP BY Location, population
ORDER BY PercentagePopulationInfected DESC

--Showing Countries with Highest Death Count per Population

SELECT Location,
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProjects..coviddeaths
--WHERE Location like 'United_States'
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC



SELECT Location,
	SUM(cast(new_deaths as INT)) AS NewDeathCount
FROM PortfolioProjects..coviddeaths
--WHERE Location like 'United_States'
WHERE continent is null
	and Location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY Location
ORDER BY NewDeathCount DESC


--Let's break things down by Continent

-- Showing contintents with the highest death count per population

SELECT continent,
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProjects..coviddeaths
--WHERE Location like 'United_States'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC






--GLOBAL NUMBERS


SELECT 
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths
	, SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProjects..coviddeaths
--WHERE Location like 'United_States'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vaccinations

SELECT coviddeaths.continent, coviddeaths.location, coviddeaths.date, coviddeaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(float, vaccinations.new_vaccinations)) 
OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date)
AS RollingPeopleVaccinated
FROM PortfolioProjects..coviddeaths
Join PortfolioProjects..vaccinations 
	ON vaccinations.location = coviddeaths.location
	and vaccinations.date = coviddeaths.date
WHERE coviddeaths.continent is not null
ORDER BY 2,3



----USE CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT coviddeaths.continent, coviddeaths.location, coviddeaths.date, coviddeaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(float, vaccinations.new_vaccinations)) 
OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date)
AS RollingPeopleVaccinated
FROM PortfolioProjects..coviddeaths
Join PortfolioProjects..vaccinations 
	ON vaccinations.location = coviddeaths.location
	and vaccinations.date = coviddeaths.date
WHERE coviddeaths.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac


--------TEMP TABLE to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
( Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric )


INSERT INTO #PercentPopulationVaccinated
SELECT coviddeaths.continent, coviddeaths.location, coviddeaths.date, coviddeaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(float, vaccinations.new_vaccinations)) 
OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date)
AS RollingPeopleVaccinated
FROM PortfolioProjects..coviddeaths
Join PortfolioProjects..vaccinations 
	ON vaccinations.location = coviddeaths.location
	and vaccinations.date = coviddeaths.date
--WHERE coviddeaths.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

CREATE VIEW [PercentPopulationVaccinated] AS
SELECT coviddeaths.continent, coviddeaths.location, coviddeaths.date, coviddeaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(float, vaccinations.new_vaccinations)) 
OVER (PARTITION BY coviddeaths.location ORDER BY coviddeaths.location, coviddeaths.date)
AS RollingPeopleVaccinated
FROM PortfolioProjects..coviddeaths
Join PortfolioProjects..vaccinations 
	ON vaccinations.location = coviddeaths.location
	and vaccinations.date = coviddeaths.date
WHERE coviddeaths.continent is not null


CREATE VIEW [Covid19DeathRate] AS 
SELECT 
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths
	, SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProjects..coviddeaths
--WHERE Location like 'United_States'
WHERE continent is not null
--GROUP BY date
--ORDER BY 1,2


CREATE VIEW [PercentPopulationInfected] AS
SELECT Location, population, 
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM PortfolioProjects..coviddeaths
WHERE Location like 'United_States'
GROUP BY Location, population
--ORDER BY PercentagePopulationInfected DESC
