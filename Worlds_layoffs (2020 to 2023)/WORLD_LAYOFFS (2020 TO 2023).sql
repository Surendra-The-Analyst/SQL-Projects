USE WORLDS_LAYOFFS;

--   DATA CLEANING PROJECT-------------------------------------

SELECT * FROM LAYOFFS;

-- CREATING COPY OF THE DATA

CREATE TABLE LAYOFFS_DUPLICATE LIKE LAYOFFS; 

INSERT  LAYOFFS_DUPLICATE  SELECT * FROM LAYOFFS;
----------------------------------------------------------------------------------

-- ASSIGNING UNIQUE ROW NUMBER TO IDENTIFY DUPLICATES WITH THE USE OF ROW_NUMBER WINDOW FUNCTION USING CTE.

select * from LAYOFFS_DUPLICATE;

with remove_duplicate_CTE AS
(
select *,
row_number() over(
partition by  company,location,industry,total_laid_off,'date',
stage,country,funds_raised_millions) as row_num
from LAYOFFS_DUPLICATE
)
select * from remove_duplicate_CTE
where row_num >1;

-- CREATING ANOTHER TABLE TO REMOVE THE DUPLICATES FROM CTE TABLE
CREATE TABLE `layoffs_duplicate2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
   `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs_duplicate2;

insert into layoffs_duplicate2
select *,
row_number() over(
partition by  company,location,industry,total_laid_off,'date',
stage,country,funds_raised_millions) as row_num
from LAYOFFS_DUPLICATE;

select * 
from layoffs_duplicate2
where row_num>1;

delete  
from layoffs_duplicate2
where row_num>1;

-- STANDARDIZING THE DATA (MAKING SURE OF NOT HAVING ANY TYPOS OR UNWANTED SPACES.)

select company, trim(company)from layoffs_duplicate2;

update layoffs_duplicate2
set company=trim(company);

select distinct(industry) from layoffs_duplicate2
order by industry;

select * from layoffs_duplicate2
where industry like 'Crypto%';

update layoffs_duplicate2
set industry= 'Crypto'
where industry like 'Crypto%';

select distinct(country),trim(trailing '.' from country) from layoffs_duplicate2
order by 1;

update layoffs_duplicate2
set country = trim(trailing '.' from country)
where country like 'United States%';

-- MODIFYING DATA TYPE OF A DATE COLUMN

select `date` from layoffs_duplicate2;

update layoffs_duplicate2
set `date`= str_to_date(`date`, '%m/%d/%Y');


alter table layoffs_duplicate2
modify column `date` date;

--  WORKING WITH THE BLANKS AND FINDING PATTERNS TO FILL THE BLANKS.

select * from layoffs_duplicate2
where total_laid_off is null
and percentage_laid_off is null;


select * from layoffs_duplicate2
where industry is null or industry like '';

select * from layoffs_duplicate2
where company='Airbnb';

update layoffs_duplicate2
set industry= NULL
where industry like '';

select t1.industry,t2.industry from layoffs_duplicate2 t1
join layoffs_duplicate2 t2 
on  t1.company=t2.company 
where (t1.industry is null or t1.industry like '') and
t2.industry is not null;

update layoffs_duplicate2 t1
join layoffs_duplicate2 t2 
   on  t1.company=t2.company 
set t1.industry=t2.industry
where t1.industry is null  and
t2.industry is not null;

select * from layoffs_duplicate2
where company like'Bally%';

Delete from layoffs_duplicate2
where percentage_laid_off is null and
total_laid_off is null;

alter table layoffs_duplicate2
drop column row_num;


--  EXPLORATORY DATA ANALYSIS
-- THEME IS TO FIND OUT WHAT ARE THE TOP 5 COMPANIES THAT LAID OF MOST IN THE RESPECTIVE YEARS(2020,2021,2023) 

select max(total_laid_off),max(percentage_laid_off) from layoffs_duplicate2;

select * from layoffs_duplicate2
where percentage_laid_off=1
order by total_laid_off desc;

select * from layoffs_duplicate2
where percentage_laid_off=1
order by funds_raised_millions desc;

select company,sum(total_laid_off) from layoffs_duplicate2
group by company
order by 2 desc;

select min(`date`),max(`date`) from layoffs_duplicate2;

select industry,sum(total_laid_off) from layoffs_duplicate2
group by industry
order by 2 desc;

select country,sum(total_laid_off) from layoffs_duplicate2
group by country
order by 2 desc;

select year(`date`),sum(total_laid_off) from layoffs_duplicate2
group by year(`date`)
order by 1 desc;

select stage,sum(total_laid_off) from layoffs_duplicate2
group by stage
order by 2 desc;

select substring(`date`,1,7) as 'month',sum(total_laid_off)
from layoffs_duplicate2
where substring(`date`,1,7) is not null
group by substring(`date`,1,7)
order by 1 ASC;

with rolling_total as (
select substring(`date`,1,7) as monthly ,sum(total_laid_off) as total_off
from layoffs_duplicate2
where substring(`date`,1,7) is not null
group by substring(`date`,1,7)
order by 1 ASC
)
select monthly,total_off, sum(total_off) over(order by monthly) as roll_total
from rolling_total;


select company,year(`date`),sum(total_laid_off) from layoffs_duplicate2
group by company,year(`date`)
order by 3 desc;

with Company_Year(company,years,total_laid_off) as 
(
select company,year(`date`),sum(total_laid_off) from layoffs_duplicate2
group by company,year(`date`)
order by 3 desc
), Company_year_rank as 
(
select *,
dense_rank() over(partition by years order by total_laid_off desc) as Company_ranking
from Company_Year
where years is not null
)

select * from Company_year_rank
where Company_ranking<=5;




































