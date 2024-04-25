/*

cleaning the data in sql queries

*/

select * from [Portifolio(covid_cases)]..[Nashville Housing Data ]
--------------------------------------------------------------------------------

--Standardize data format(converting data type of saledate to datetime to date)


select SaleDate,CONVERT(date,SaleDate) from [Portifolio(covid_cases)]..[Nashville Housing Data ]


alter table [Nashville Housing Data ]
add SaleDateConverted Date;


update [Nashville Housing Data ] 
set SaleDateConverted=CONVERT(date,SaleDate);

---------------------------------------------------------------------------------------

--populate Property Adress data

--(so to fix the null value in property address we are looking for parcel id we find out that if parcel id are same they goes to same property adress
---( so for that we are repalcaing the null with already presenred parcel id property adress but keeping in mind that not taking similar parcel id at a time we used unique id <> unique id in self join on  the table.

select PropertyAddress from [Nashville Housing Data ]
where PropertyAddress is null

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,ISNULL(a.PropertyAddress,b.PropertyAddress)
from [Nashville Housing Data ] a
join [Nashville Housing Data ] b
   on a.ParcelID=b.ParcelID
   and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

update a 
set PropertyAddress=ISNULL(a.PropertyAddress,b.PropertyAddress)
from [Nashville Housing Data ] a
join [Nashville Housing Data ] b
   on a.ParcelID=b.ParcelID
   and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

----------------------------------------------------------------------------------

--breaking out the address into individual columns(address,city,state)

select PropertyAddress from [Nashville Housing Data ]

select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address ,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , len(PropertyAddress)) as City from [Nashville Housing Data ]

alter table [Nashville Housing Data ] 
add PropertySplitAddress Nvarchar(255);

update [Nashville Housing Data ]
set PropertySplitAddress= SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

alter table [Nashville Housing Data ]
add PropertySplitCity Nvarchar(255);

update [Nashville Housing Data ]
set PropertySplitCity=SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , len(PropertyAddress))


--- chaning owner adress
-- so we are using parsname in place of substring which is simple but it only breaks the string in containg period(.) so we are replacing commas with period to work with parsname at the same time parsname works backwords

select OwnerAddress from [Nashville Housing Data ]

select 
PARSENAME(Replace(OwnerAddress,',', '.'),3),
PARSENAME(Replace(OwnerAddress,',', '.'),2) ,
PARSENAME(Replace(OwnerAddress,',', '.'),1) 
from [Nashville Housing Data ]

alter table [Nashville Housing Data ] 
add OwnerSplitAddress Nvarchar(255);

update [Nashville Housing Data ]
set OwnerSplitAddress= PARSENAME(Replace(OwnerAddress,',', '.'),3)

alter table [Nashville Housing Data ]
add OwnerSplitCity Nvarchar(255);

update [Nashville Housing Data ]
set OwnerSplitCity=PARSENAME(Replace(OwnerAddress,',', '.'),2)

alter table [Nashville Housing Data ]
add OwnerSplitState Nvarchar(255);

update [Nashville Housing Data ]
set OwnerSplitState=PARSENAME(Replace(OwnerAddress,',', '.'),1) 

----------------------------------------------------------------------------------

-- change Y and N to yes and no in Sold as vacant field

select distinct(SoldAsVacant),COUNT(SoldAsVacant) from [Nashville Housing Data ]
group by SoldAsVacant
order by 2

select SoldAsVacant
, CASE WHEN SoldAsVacant='Y'	THEN 'Yes'
     WHEN SoldAsVacant='N'  THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM [Nashville Housing Data ]

update [Nashville Housing Data ]
set SoldAsVacant=CASE WHEN SoldAsVacant='Y'	THEN 'Yes'
     WHEN SoldAsVacant='N'  THEN 'No'
	 ELSE SoldAsVacant
	 END

----------------------------------------------------------------------------------------

--Remove Duplicates
use [Portifolio(covid_cases)]

WITH RowNumCTE AS(
Select*,
      ROW_NUMBER() OVER (
             PARTITION BY   ParcelID,
							PropertyAddress,
							SalePrice,
							SaleDate,
							LegalReference
             order by  UniqueID) row_num
From [Nashville Housing Data ])
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

-------------------------------------------------------

-- Delete unused columns
Alter table [Nashville Housing Data ]
drop column OwnerAddress,TaxDistrict,PropertyAddress

Alter table [Nashville Housing Data ]
Drop column SaleDate

select * from [Nashville Housing Data ]