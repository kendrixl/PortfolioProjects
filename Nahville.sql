-- standardised date format:
-- this creates a new column called new_date_column of type DATE
ALTER TABLE nashville_housing ADD new_date_column DATE;
-- updates the new column with the converted dates
UPDATE nashville_housing SET new_date_column = STR_TO_DATE(SaleDate, '%M %e, %Y');
-- drops the old column
ALTER TABLE nashville_housing DROP COLUMN new_date_column;
-- renames the column
ALTER TABLE nashville_housing CHANGE new_date_column SaleDate DATE;

-- populate property address
UPDATE nashville_housing SET PropertyAddress = NULLIF(PropertyAddress, ''); -- the PA column was initally an empty string, so had to replace with NULL.

SELECT *
FROM nashville_housing
-- WHERE PropertyAddress IS NULL;
ORDER BY ParcelID;

SELECT a.ParcelID, 
	   a.PropertyAddress,
       b.ParcelID,
       b.PropertyAddress,
       COALESCE (a.PropertyAddress, b.PropertyAddress) AS updatedPA  -- use COALESCE instead of ISNULL as The COALESCE() function takes multiple arguments and returns the first non-NULL value.
FROM nashville_housing a
JOIN nashville_housing b
	 ON a.ParcelID = b.ParcelID
     AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;
-- this code basically takes the null values in a.PropertyAddress and will be replaced witht the values in b.PropertyAddress. The result is put in a new column called updatedPA.

UPDATE nashville_housing a 
JOIN nashville_housing b
	 ON a.ParcelID = b.ParcelID
     AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE (a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Breaking out Address into individual columns (Address, City, State)
-- there is a delimiter between state and city

SELECT PropertyAddress
FROM nashville_housing;
-- WHERE PropertyAddress IS NULL;
-- ORDER BY ParcelID;

SELECT
	 SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS Address,
     SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress)) AS Address2
FROM nashville_housing;

ALTER TABLE nashville_housing ADD PropertySplitAddress NVARCHAR(255);

UPDATE nashville_housing 
	   SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

ALTER TABLE nashville_housing ADD PropertyCity NVARCHAR(255);

UPDATE nashville_housing 
	   SET PropertyCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress));
       
SELECT *
FROM nashville_housing;

SELECT OwnerAddress
FROM nashville_housing;

SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) AS address,
	   SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS city,
       SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) AS state
FROM nashville_housing;

ALTER TABLE nashville_housing ADD OwnerSplitAddress NVARCHAR(255);

UPDATE nashville_housing 
	   SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashville_housing ADD Ownersplitcity NVARCHAR(255);

UPDATE nashville_housing 
	   SET Ownersplitcity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1); 

ALTER TABLE nashville_housing ADD OwnerSplitState NVARCHAR(255);

UPDATE nashville_housing 
	   SET OwnerSplitState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) ;
       
-- Change Y and N to Yes and No in "Sold as vacant" field

SELECT DISTINCT(SoldAsVacant), count(SoldAsVacant)
FROM nashville_housing
group by SoldAsVacant
order by SoldAsVacant;

SELECT SoldAsVacant,
       CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
       END AS UpdatedSoldAsVacant
FROM nashville_housing;

Update nashville_housing
	   SET SoldAsVacant = CASE 
            WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
       END;
-------------------------------------------------------------------------------------------------------------------------------------------
-- removing duplicates

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM nashville_housing
)
DELETE
FROM RowNumCTE
WHERE row_num >1
-- ORDER BY PropertyAddress
