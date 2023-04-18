  --- Viewing the dataset
  SELECT *
  FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

--- Checking for duplicates using columns that should be unique
  SELECT ID, Name,
     COUNT(*) AS "Count"
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]
  GROUP BY ID, Name
  HAVING COUNT(*) > 1
  ORDER BY ID;

---Players' Name
--- viewing the Name, LongName, and playerUrl fields
SELECT Name, LongName, playerUrl
FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

--- Add new name column 'Player_Name'
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ADD Player_Name Varchar(100);

--update/extract from playerUrl based on forward slash ("/") delimeters
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Player_Name = SUBSTRING(playerUrl,CHARINDEX('/',PlayerURL)+24,
          (LEN(playerUrl)- CHARINDEX('/',PlayerURL)-2));

SELECT playerUrl, Player_Name --- to check progress of the extraction process
FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

--- Further extraction to remove delimiters
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Player_Name = REPLACE(LEFT(Player_Name,LEN(Player_Name)-8),'/',' ');

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Player_Name = REPLACE(Player_Name,'-',' ') --- hyphens should be replaced with spaces to create a more readable and consistent format for the player's name.

 --- Removing Numeric characters
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Player_Name = TRIM(TRANSLATE(Player_Name,'0123456789','          '));

--- Checking that it worked
SELECT playerUrl,Player_Name
FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

--- creating custom function for Proper case 
CREATE OR 
ALTER FUNCTION [dbo].[PROPER](@Text VARCHAR(5000)) RETURNS VARCHAR(5000) AS BEGIN
	DECLARE @Index INT;
	DECLARE @FirstChar CHAR(1);
	DECLARE @LastChar CHAR(1);
	DECLARE @String VARCHAR(5000);
		SET @String = LOWER(@Text);
		SET @Index = 1;
		WHILE @Index <= LEN(@Text)
BEGIN
	SET @FirstChar = SUBSTRING(@Text, @Index, 1);
	SET @LastChar = CASE WHEN @Index = 1
		THEN ' ' ELSE SUBSTRING(@Text, @Index - 1, 1)
	END;
	IF @LastChar IN(' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(', '#', '*', '$', '@')
BEGIN
IF @FirstChar != ''''
OR UPPER(@FirstChar) != 'S'
SET @String = STUFF(@String, @Index, 1, UPPER(@FirstChar));
	END;
SET @Index = @Index + 1;
	END;
RETURN @String;
END;
GO

--- Using created custom function to change column to Proper case
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Player_Name = [Project_FIFA 21].[dbo].[PROPER](Player_Name);

---confirming it worked
SELECT Player_Name
FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

---removing name and LongName columns
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
DROP COLUMN Name, LongName;

--- Club Column
--- checking for presence of special/numeric characters
SELECT Club
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]
  WHERE Club LIKE '%[@,#,$,%,*]%' OR Club LIKE '%1%';

--- Removing the '1.' from the club column
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Club = TRIM(REPLACE(Club,'1.',' '));

---Height Column
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ADD Height_CM smallint --- Adding New column

--- Standardize the height column to same unit of measurement for uniformity
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Height_CM = 
    CASE WHEN height LIKE '%''%"' 
THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, 1, CHARINDEX('''', height)-1))*30.48 + 
 TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, CHARINDEX('''', height)+1, LEN(height)-CHARINDEX('''', height)-1))*2.54 
        WHEN height LIKE '%"' THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, 1, LEN(height) - 2)) * 2.54 
        ELSE TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, 1, LEN(height) - 2)) 
    END;

---removing the messy Height Column 
 ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
DROP COLUMN Height;

---Weight Column
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Weight_Kg = 
       CASE 
        WHEN Weight LIKE '%kg' THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(Weight, 1, LEN(Weight) - 2))
        WHEN Weight LIKE '%lbs' THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(Weight, 1, LEN(Weight) - 3)) * 0.45359237
        ELSE TRY_CONVERT(DECIMAL(10,2), SUBSTRING(Weight, 1, LEN(Weight) - 2)) 
    END;

---removing the messy Weight Column 
 ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
DROP COLUMN Weight;

--- JOINED
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ADD Joined_Club Date; --- Add a new column for club joining date

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Joined_Club = CONVERT(Date,Joined); 
 
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
DROP COLUMN Joined; --- Remove the Joined column

---contract
SELECT Contract
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]
WHERE Contract LIKE '%[@,#,$,%,*]%'; ---checking  for presence of special characters.

--- updating contract column delimeter from '~' to '-'
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Contract = TRIM(REPLACE(Contract,'~','-'))

 --- Create new columns to extract contract details for better analysis
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ADD Contract_Start_year smallint, Contract_End_year smallint, Contract_Status Varchar(30);

--- updating the new columns 
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Contract_Start_year = CASE WHEN Contract LIKE '%-%' THEN SUBSTRING(Contract,1,4)
				WHEN Contract LIKE '%Loan%' THEN SUBSTRING(Contract,9,4)
			    ELSE NULL 
				END;

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Contract_End_year = TRIM(CASE WHEN Contract LIKE '%-%' THEN SUBSTRING(Contract,7,6)
				         WHEN Contract LIKE '%Loan%' THEN SUBSTRING(Contract,9,4)
				ELSE NULL END)

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Contract_Status = CASE WHEN Contract LIKE '%-%' THEN 'Active'
			        WHEN Contract LIKE '%Loan%' THEN 'On Loan'
		               ELSE 'Free' END;

---Checking it worked
SELECT Contract,Loan_Date_End,Contract_Start_year, Contract_End_year,Contract_Status
FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

---removing the Loan_date_end and contract column
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
DROP COLUMN Contract,Loan_Date_End;

---Value, Wage, Release_Clause
--- viewing the columns
SELECT Value, Wage, Release_Clause
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]

--- updating the columns
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Value = CASE
    WHEN Value LIKE '€%' AND Value LIKE '%M' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Value, '€', ''), 'M', '')) * 1000000
    WHEN Value LIKE '€%' AND Value LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Value, '€', ''), 'K', '')) * 1000
    WHEN Value LIKE '€%' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(Value, '€', ''))
    ELSE Value
END;

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Wage = CASE
    WHEN Wage LIKE '€%' AND Wage LIKE '%M' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Wage, '€', ''), 'M', '')) * 1000000
    WHEN Wage LIKE '€%' AND Wage LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Wage, '€', ''), 'K', '')) * 1000
    WHEN Wage LIKE '€%' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(Wage, '€', ''))
    ELSE Wage
END;

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Release_Clause = CASE
    WHEN Release_Clause LIKE '€%' AND Release_Clause LIKE '%M' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Release_Clause, '€', ''), 'M', '')) * 1000000
    WHEN Release_Clause LIKE '€%' AND Release_Clause LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Release_Clause, '€', ''), 'K', '')) * 1000
    WHEN Release_Clause LIKE '€%' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(Release_Clause, '€', ''))
    ELSE Release_Clause
END;

--- removing the decimals
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Value = CONVERT(INT, CONVERT(FLOAT, Value));

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Wage = CONVERT(INT, CONVERT(FLOAT, Wage));

UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Release_Clause = CONVERT(INT, CONVERT(FLOAT, Release_Clause));

--- confirming solution
SELECT Value, Wage, Release_Clause
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]

--- Changing column data types to appropriate one
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Value int;

ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Wage int;

ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Release_Clause int;

--- Renaming the Columns
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].Value', 'Value(€)', 'COLUMN';
GO

USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].Wage', 'Wage(€)', 'COLUMN';
GO

USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].Release_Clause', 'Release_Clause(€)', 'COLUMN';
GO


 ---W_F, SM, IR
SELECT W_F, SM, IR
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]

--- removing the '*' character
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET W_F = LEFT(W_F,1),
	SM = LEFT(SM,1),
    IR = LEFT(IR,1);

--- Renaming the Columns
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].W_F', 'Weak_foot_ability', 'COLUMN';
GO

USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].SM', 'Skill_moves', 'COLUMN';
GO

USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].IR', 'Injury_rating', 'COLUMN';
GO

--- Changing the datatype
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Weak_foot_ability smallint

ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Skill_moves smallint

ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Injury_rating smallint;

---HITS
--- viewing the hits column
SELECT Hits
FROM [Project_FIFA 21].[dbo].[FIFA_21 data]
WHERE Hits LIKE '%.%K'

--- removing the 'k' suffix
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Hits = CASE WHEN Hits LIKE '%k' 
            THEN CAST(LEFT(Hits, LEN(Hits)-1) AS float) * 1000 
			ELSE Hits 
		END 
			WHERE Hits LIKE '%k';

--- Changing the column datatype to 'Integer'
ALTER TABLE [Project_FIFA 21].[dbo].[FIFA_21 data]
ALTER COLUMN Hits int;
--- confirming solution
SELECT Hits
FROM [Project_FIFA 21].[dbo].[FIFA_21 data];

---Rename Abbreviated columns
--- Rename 'OVA' to 'Overall_rating'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].OVA', 'Overall_rating', 'COLUMN';
GO
--- Rename 'POT' to 'Potential_rating'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].POT', 'Potential_rating', 'COLUMN';
GO
--- Rename 'BOV' to 'Best_Overall_rating'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].BOV', 'Best_Overall_rating', 'COLUMN';
GO
--- Rename ‘A_W’ to 'Attacking_workrate'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].A_W', 'Attacking_workrate', 'COLUMN';
GO
---Rename D_W to 'Defensive_workrate', 
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].D_W', 'Defensive_workrate', 'COLUMN';
GO
--- Rename PAC to 'Pace'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].PAC', 'Pace', 'COLUMN';
GO
--- Rename SHO to Shooting_ability'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].SHO', 'Shooting_ability', 'COLUMN';
GO
--- Rename PAS to 'Passing_ability'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].PAS', 'Passing_ability', 'COLUMN';
GO
--- Rename DRI to 'Dribbling_ability'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].DRI', 'Dribbling_ability', 'COLUMN';
GO
--- Rename DEF to ‘Defensive_ability'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].DEF', 'Defensive_ability', 'COLUMN';
GO
--- Rename PHY to 'Physical_strength'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].PHY', 'Physical_strength', 'COLUMN';
GO
--- Rename Goalkeeping to 'Goalkeeping(GK)'
USE [Project_FIFA 21]
GO
EXEC sp_rename '[Project_FIFA 21].[dbo].[FIFA_21 data].Goalkeeping', 'Goalkeeping(GK)', 'COLUMN';
GO

--- Query to generate a table that shows the name of each column that contains a newline character and the number of rows that contain the character.
DECLARE @tableName VARCHAR(100) = '[Project_FIFA 21].[dbo].[FIFA_21 data]';
DECLARE @query NVARCHAR(MAX) = '';

SELECT @query += 'SELECT ''' + c.name + ''' AS ColumnName, COUNT(*) AS NumRows
                  FROM ' + @tableName + '
                  WHERE CHARINDEX(CHAR(10), [' + c.name + ']) > 0 OR CHARINDEX(CHAR(13), [' + c.name + ']) > 0
                  UNION '
FROM sys.columns c
WHERE object_id = OBJECT_ID(@tableName);

SET @query = LEFT(@query, LEN(@query) - 6);

EXEC(@query);

---Newline/Carriage Return Characters Checks/Resolution
--- Query to remove newline characters:
UPDATE [Project_FIFA 21].[dbo].[FIFA_21 data]
SET Club = REPLACE(REPLACE(Club, CHAR(10), ''), CHAR(13), '')
WHERE CHARINDEX(CHAR(10), Club) > 0 OR CHARINDEX(CHAR(13), Club) > 0;

---Display clean DataSet
  --- Viewing the dataset
  SELECT *
  FROM [Project_FIFA 21].[dbo].[FIFA_21 data];