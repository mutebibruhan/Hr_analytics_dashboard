SELECT * FROM hr_dataset;

--- Create new table
CREATE TABLE hr_copy AS
SELECT * FROM hr_dataset;

SELECT * FROM hr_copy;

-- Check and remove duplicates

SELECT EmployeeID, count(*) AS count FROM hr_copy
GROUP BY EmployeeID
HAVING count > 1;

SELECT *,
ROW_NUMBER() OVER(PARTITION BY EmployeeID ORDER BY EmployeeID) AS rn
FROM hr_copy;

CREATE TABLE hr_copy2 AS 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY EmployeeID ORDER BY EmployeeID) AS rn
FROM hr_copy;

SELECT * FROM hr_copy2;

DELETE FROM hr_copy2
WHERE rn > 1;

SELECT * FROM hr_copy2;

-- Formating FullName
SELECT Email,
group_concat(distinct FullName separator '|') AS Variants FROM hr_copy2
GROUP BY Email
HAVING COUNT(DISTINCT FullNAme) > 1;

SELECT EmployeeID, FullName
FROM hr_copy2
WHERE Email = '' OR Email IS NULL;

UPDATE hr_copy2
SET FullName = TRIM(FullName);

SELECT FullName FROM hr_copy2;

UPDATE hr_copy2
SET FullName = UPPER(FullName);

SELECT FullName FROM hr_copy2
WHERE FullName Like '%@%';


UPDATE hr_copy2
SET FullName = REPLACE(FullName, '@', 'A')
WHERE FullName Like '%@%';

-- Formatt emaills/replace Null with no mail format

UPDATE hr_copy2
SET Email = LOWER(CONCAT(REPLACE(FullName,'','.'), '@nomail.com'))
WHERE Email = '' OR Email IS NULL;

SELECT * FROM hr_copy2;

-- Format Phone column
SELECT Phone FROM hr_copy2;

SELECT DISTINCT Phone
FROM hr_copy2
WHERE Phone IS NOT NULL AND TRIM(Phone) !=''
ORDER BY Phone;

CREATE TABLE hr_copy2_backup_phones_final AS
SELECT EmployeeID, Phone FROM hr_copy2;

UPDATE hr_copy2
SET Phone = CONCAT('+971', RIGHT(REGEXP_REPLACE(Phone, '[^0-9]', ''), 9))
WHERE Phone IS NOT NULL AND TRIM(Phone) != '';

SELECT COUNT(*) AS bad_rows
FROM hr_copy2
WHERE Phone IS NOT NULL AND CHAR_LENGTH(Phone) != 13;

SELECT * FROM hr_copy2;

-- Standardize Gender 
SELECT DIstinct Gender FROM hr_copy2;

UPDATE hr_copy2
SET Gender = CASE
                 WHEN TRIM(GEnder) = '' THEN null
                 ELSE CONCAT(UPPER(LEFT(Gender,1)),LOWER(SUBSTRING(Gender,2)))
END;

-- Standadize JobTitle
SELECT JobTitle, count(*) FROM hr_copy2
group by JobTitle;

UPDATE hr_copy2
SET JobTitle = CASE
    WHEN LOWER(TRIM(JobTitle)) IN ('it', 'i.t.') THEN 'IT'
    WHEN LOWER(TRIM(JobTitle)) IN ('i.t. support', 'it support') THEN 'IT Support'
    WHEN LOWER(TRIM(JobTitle)) IN ('software engineer', 's/w engineer') THEN 'Software Engineer'
    WHEN LOWER(TRIM(JobTitle)) = 'hr manager' THEN 'HR Manager'
    ELSE CONCAT(UPPER(LEFT(JobTitle,1)), LOWER(SUBSTRING(JobTitle,2)))
END;
SELECT * FROM hr_copy2;

-- Standize Department
SELECT Department, count(*) FROM hr_copy2
group by Department;

UPDATE hr_copy2
SET Department = CASE
    WHEN LOWER(TRIM(Department)) IN ('it', 'i.t.') THEN 'IT'
    WHEN LOWER(TRIM(Department)) IN ('hr', 'human resources') THEN 'Human Resources'
    WHEN LOWER(TRIM(Department)) = 'admin' THEN 'Admin'
    ELSE CONCAT(UPPER(LEFT(Department,1)), LOWER(SUBSTRING(Department,2)))
END;
SELECT * FROM hr_copy2;

-- Format HireDate
SELECT HireDate FROM hr_copy2;

ALTER TABLE hr_copy2 ADD COLUMN HireDate_Clean DATE;

UPDATE hr_copy2
SET HireDate_Clean = CASE
    WHEN HireDate REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(HireDate, '%Y-%m-%d')           -- 2025-01-25
   
    WHEN HireDate REGEXP '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$'
        THEN STR_TO_DATE(HireDate, '%d-%b-%Y')           -- 11-Oct-2024
   
    WHEN HireDate REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
        THEN STR_TO_DATE(HireDate, '%d/%m/%Y')           -- 19/03/2026
   
    WHEN HireDate REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
        THEN STR_TO_DATE(HireDate, '%m-%d-%Y')           -- 11-13-2025
END;

ALTER TABLE hr_copy2 DROP COLUMN HireDate;
ALTER TABLE hr_copy2 CHANGE HireDate_Clean HireDate DATE;

SELECT * FROM hr_copy2;

-- Standardize Salary
SELECT SalaryAED FROM hr_copy2;

UPDATE hr_copy2
SET SalaryAED = REPLACE(SalaryAED, ',000', '')
WHERE SalaryAED LIKE '%,000';

UPDATE hr_copy2
SET Salary_Clean = CAST(
    REPLACE(REPLACE(UPPER(TRIM(SalaryAED)), 'AED', ''), ' ', '')
AS DECIMAL(10,2));

SELECT MIN(Salary_Clean), MAX(Salary_Clean), AVG(Salary_Clean) FROM hr_copy2;


ALTER TABLE hr_copy2 DROP COLUMN SalaryAED;
ALTER TABLE hr_copy2 CHANGE COLUMN `Salary_Clean` `SalaryAED` DECIMAL(10,2);

SELECT * FROM hr_copy2;
-- Standardize LeaveDaysTaken

SELECT LeaveDaysTaken FROM hr_copy2
order by LeaveDaysTaken desc;

ALTER TABLE hr_copy2  ADD COLUMN
LeaveDaysTaken_Clean INT;

UPDATE hr_copy2 
SET LeaveDaysTaken_Clean = 
     CASE 
         WHEN LeaveDaysTAken BETWEEN 0 AND 
35 THEN LeaveDaysTAken
         ELSE null
	 END;
     
ALTER TABLE hr_copy2 DROP COLUMN LeaveDaysTaken;
ALTER TABLE hr_copy2 CHANGE COLUMN `LeaveDaysTaken_Clean` `LeaveDaysTaken` INT;

SELECT LeaveDaysTaken FROM hr_copy2
order by LeaveDaysTaken asc;

-- Standardize Performance rating
SELECT PerformanceRating, count(PerformanceRating) FROM hr_copy
group by PerformanceRating
order by PerformanceRating ASC;

ALTER TABLE hr_copy2 ADD COLUMN PerformanceRating_Clean INT;

UPDATE hr_copy2
SET PerformanceRating_Clean =
    CASE
        WHEN LOWER(TRIM(PerformanceRating)) = 'three' THEN 3
        WHEN PerformanceRating REGEXP '^[1-5]$' THEN CAST(PerformanceRating AS UNSIGNED)
        ELSE NULL
    END;
    
    SELECT AVG(PerformanceRating_Clean) AS avg_rating
FROM hr_copy2
WHERE PerformanceRating_Clean IS NOT NULL;

UPDATE hr_copy2
SET PerformanceRating_Clean = 3
WHERE PerformanceRating_Clean IS NULL;


ALTER TABLE hr_copy2 DROP COLUMN PerformanceRating;
ALTER TABLE hr_copy2 CHANGE COLUMN PerformanceRating_Clean PerformanceRating INT;


SELECT PerformanceRating FROM hr_copy2
ORDER BY PerformanceRating DESC;

SELECT * FROM hr_copy2;

describe hr_copy2;

ALTER TABLE hr_copy2
MODIFY COLUMN EmployeeID varchar(20),
MODIFY COLUMN ManagerID varchar(20);

ALTER TABLE hr_copy2
MODIFY COLUMN FullName VARCHAR(100),
MODIFY COLUMN Email VARCHAR(150),
MODIFY COLUMN Phone VARCHAR(20),
MODIFY COLUMN Gender VARCHAR(20),
MODIFY COLUMN Nationality VARCHAR(50),
MODIFY COLUMN JobTitle VARCHAR(100),
MODIFY COLUMN Department VARCHAR(50),
MODIFY COLUMN BranchCity VARCHAR(50),
MODIFY COLUMN EmploymentType VARCHAR(30);

describe hr_copy2;

-- Ready for Power BI visual

SELECT * FROM hr_copy2;

-- Business Questions
-- 1.What is the headcount by department and branch city?

SELECT Department, BranchCity, count(EmployeeID) AS HeadCount
FROM hr_copy2
GROUP BY Department,BranchCity
order by BranchCity;

-- 2. Which departments have the highest average salaries?
SELECT Department, round(avg(SalaryAED)) AS AvgSalary
FROM hr_copy2
group by Department
ORDER BY AvgSalary DESC;

-- 3. What are the hiring trends from 2024 to 2026?
SELECT YEAR(HireDate), count(EmployeeID)
FROM hr_copy2
WHERE Year(HireDate) between 2024 and 2026
group by YEAR(HireDate);

-- 4. Is there a relationship between leave days taken and performance ratings?
SELECT LeaveDaysTaken, Count(*) AS Employees, Round(Avg(PerformanceRating), 2) AS AvgRating
FROM hr_copy2
group by LeaveDaysTaken
order by LeaveDaysTaken;

-- 5. Which branch has the highest concentration of contract employees?
SELECT BranchCity, count(EmployeeID) AS TotalEmployee
FROM hr_copy2
WHERE EmploymentType = 'Contract'
GROUP BY BranchCity;

-- 7. Which managers oversee the largest number of employees?
SELECT ManagerID, count(EmployeeID) AS Employees
FROM hr_copy2
group by ManagerID
order by Employees DESC