/*
					SQL Project Name : Blood Bank Management System
							    Trainee Name : MD. Jahidul Islam Riyad
						    	  Trainee ID : 1278865      
									Batch ID : WADA/PNTL-A/56/01


*/

--USE DATABASE
USE BloodBank_DB
GO


-- Insert data by specifying column name
INSERT INTO BloodDonor (FirstName, LastName, BloodGroup, Age, Gender, ContactNumber, Address) VALUES
('Rakib', 'Anam', 'A+', 30, 'Male', '01711111111', '123 Main St'),
('HABIB', 'RAHMAN', 'B-', 30, 'Male', '01700000000', '123 SIDE St')
go

INSERT INTO BloodRecipient (FirstName, LastName, BloodGroup, ContactNumber) VALUES
('RONY','AHMED', 'A+', '01722222222'),
('BOBY','DEOL', 'AB+', '01111111111')
GO

INSERT INTO BloodDonation (DonationDate,QuantityInMl) VALUES
('2022-03-01', 9),
('2022-03-12', 5)
GO

INSERT INTO Product(ProductName) VALUES
('SMALL Bandage'),
('SERGERI BLADE')
GO

INSERT INTO StockTransaction(ProductID,TransactionType, Quantity, TransactionDate) VALUES
(1,'SERGERI', 2, GETDATE()),
(2, 'BLDTRANSFE', 4, GETDATE())
GO

-- INSERT DATA THROUGH STORED PROCEDURE
EXEC InsertBloodDonor
		@FirstName = 'Anik',
		@LastName = 'Islam',
		@BloodGroup = 'AB+',
		@Age = 40,
		@Gender = 'Male',
		@ContactNumber = '01311111111',
		@Address = '789 side St';
go

-- INSERT DATA THROUGH STORED PROCEDURE WITH AN OUTPUT PARAMETER
DECLARE @NewDonorID INT;
EXEC InsertBloodDonorWithOutput
		@FirstName = 'Habiba',
		@LastName = 'Islam',
		@BloodGroup = 'O+',
		@Age = 28,
		@Gender = 'Female',
		@ContactNumber = '01900000000',
		@Address = '321 Maple St',
		@DonorID = @NewDonorID OUTPUT;
PRINT 'New Donor ID: ' + CAST(@NewDonorID AS VARCHAR(10));
go

--Test update data USING STORED PROCEDURE
EXEC UpdateBloodDonorAge 1, 32
go

-- Test DELETE DATA USING STORED PROCEDURE
EXEC DeleteBloodDonor @DonorID = 2;
go

--SELECT DATA
SELECT * FROM BloodDonor
GO

-- SELECT INTO
SELECT *
INTO BloodDonorMale
FROM BloodDonor
WHERE Gender = 'Male';
go

--Using Waitfor
select * from BloodDonor
WAITFOR DELAY '00:00:02';
select * from BloodDonation
go

-- INSERT DATA USING SEQUENCE VALUE
INSERT INTO Product (ProductName, StockQuantity, UnitPrice)
VALUES ('Blood Bag', NEXT VALUE FOR BloodDonorIDSequence, 20.99);
go

-- UPDATE DATA through view
UPDATE BloodDonorView
SET Age = 36
WHERE DonorID = 1;
go

-- DELETE DATA through view
DELETE FROM BloodDonorView
WHERE DonorID = 3;
go

-- INSERT DATA ON tblProduct For Infrastructure TABLE and AUTOMATICALLY UPDATE STOCK IN Product TABLE
INSERT INTO Product (ProductName, StockQuantity)
VALUES ('Bandage', 50);
go

-- INNER JOIN WITH GROUP BY CLAUSE
SELECT D.BloodGroup, COUNT(*) AS DonationCount
FROM BloodDonor AS D
INNER JOIN BloodDonation AS DN ON D.DonorID = DN.DonorID
GROUP BY D.BloodGroup;
go

-- OUTER JOIN
SELECT D.FirstName, DN.DonationID
FROM BloodDonor AS D
LEFT JOIN BloodDonation AS DN ON D.DonorID = DN.DonorID;
go

-- CROSS JOIN
SELECT D.FirstName, P.ProductName
FROM BloodDonor AS D
CROSS JOIN Product AS P;
go

-- TOP CLAUSE WITH TIES
SELECT TOP 5 WITH TIES ProductName, UnitPrice
FROM Product
ORDER BY UnitPrice DESC;
go

-- DISTINCT
SELECT DISTINCT BloodGroup
FROM BloodDonor;
GO

--CTE
WITH BloodDonationSummary AS (
    SELECT BloodGroup, SUM(QuantityInMl) AS TotalQuantity
    FROM BloodDonation BD JOIN BloodDonor BDON
	ON BD.DonorID = BDON.DonorID
    GROUP BY BloodGroup
)
SELECT * FROM BloodDonationSummary;
GO

--Merge
MERGE BloodDonor t
USING BloodDonation s
ON s.DonorID = t.DonorID
WHEN MATCHED
    THEN UPDATE SET 
		t.DonorID = s.DonorID
WHEN NOT MATCHED BY TARGET 
    THEN INSERT (DonorID, BloodGroup, Age)
         VALUES (s.DonorID, s.QuantityInMl)
WHEN NOT MATCHED BY SOURCE 
    THEN DELETE;
go

-- COMPARISON, LOGICAL (AND, OR, NOT), & BETWEEN OPERATOR
SELECT *
FROM BloodDonor
WHERE Age BETWEEN 18 AND 40 AND BloodGroup IN ('A+', 'B+')
AND Gender = 'Male' OR LastName LIKE 'S%';
go

-- LIKE
SELECT *
FROM BloodDonor
WHERE Address LIKE '%St';
go

-- IN
SELECT *
FROM Product
WHERE ProductID IN (1, 2, 3);
go

-- NOT IN
SELECT *
FROM Product
WHERE ProductID NOT IN (1, 2, 3);
go

-- OPERATOR & IS NULL CLAUSE
SELECT *
FROM Product
WHERE UnitPrice > 50 OR StockQuantity IS NULL;
go

-- OFFSET FETCH
SELECT *
FROM Product
ORDER BY UnitPrice
OFFSET 1 ROWS FETCH NEXT 2 ROWS ONLY;
go

-- UNION
SELECT FirstName, LastName FROM BloodDonor
UNION
SELECT FirstName, LastName FROM BloodRecipient;
go

-- EXCEPT
SELECT FirstName, LastName FROM BloodDonor
EXCEPT
SELECT FirstName, LastName FROM BloodRecipient;
go

-- INTERSECT
SELECT FirstName, LastName FROM BloodDonor
INTERSECT
SELECT FirstName, LastName FROM BloodRecipient;
go

-- AGGREGATE FUNCTION
SELECT COUNT(*) AS TotalDonors
FROM BloodDonor;
go

-- AGGREGATE FUNCTION WITH GROUP BY & HAVING CLAUSE
SELECT BloodGroup, COUNT(*) AS DonationCount
FROM BloodDonor
GROUP BY BloodGroup
HAVING COUNT(*) > 3;
go

-- ROLL UP & CUBE OPERATOR --
--ROLL UP
SELECT BloodGroup, Age, COUNT(*) AS DonationCount
FROM BloodDonor
GROUP BY ROLLUP(BloodGroup, Age);
GO

--CUBE
SELECT BloodGroup, Age, COUNT(*) AS DonationCount
FROM BloodDonor
GROUP BY CUBE(BloodGroup, Age);
GO

-- GROUPING SETS
SELECT BloodGroup, Age, COUNT(*) AS DonationCount
FROM BloodDonor
GROUP BY GROUPING SETS((BloodGroup), (Age));
go

-- INNER SUB-QUERIES
SELECT ProductName, UnitPrice
FROM Product
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Product);
go

-- Correlated Subquery
SELECT FirstName, LastName
FROM BloodDonor D
WHERE Age > (SELECT AVG(Age) FROM BloodDonor WHERE BloodGroup = D.BloodGroup);
go

-- EXISTS
SELECT FirstName, LastName
FROM BloodDonor D
WHERE EXISTS (SELECT 1 FROM BloodDonation DN WHERE DN.DonorID = D.DonorID);
go

-- CASE
SELECT ProductName, UnitPrice,
    CASE
        WHEN UnitPrice >= 50 THEN 'Expensive'
        WHEN UnitPrice >= 30 THEN 'Moderate'
        ELSE 'Affordable'
    END AS PriceCategory
FROM Product;
go

-- IIF
SELECT ProductName, UnitPrice,
    IIF(UnitPrice >= 50, 'Expensive', 'Affordable') AS PriceCategory
FROM Product;
go

-- COALESCE & IS NULL
SELECT FirstName, LastName, COALESCE(Address, 'No ADDRESS Provided') AS ADDRESS
FROM BloodDonor;
go

-- WHILE LOOP
DECLARE @Counter INT = 1;
WHILE @Counter <= 10
	BEGIN
		PRINT 'Counter Value: ' + CONVERT(VARCHAR(2), @Counter);
		SET @Counter = @Counter + 1;
	END;
go

-- GROUPING FUNCTION
SELECT BloodGroup, GROUPING(BloodGroup) AS IsGrouped, COUNT(*) AS DonationCount
FROM BloodDonor
GROUP BY BloodGroup WITH ROLLUP;
go

-- RANKING FUNCTION
SELECT ProductName, UnitPrice, RANK() OVER (ORDER BY UnitPrice DESC) AS Ranking
FROM Product;
go

-- IF ELSE & PRINT
DECLARE @Condition INT = 1;
IF @Condition = 1
    PRINT 'Condition is true.';
ELSE
    PRINT 'Condition is false.';
go

-- Test Trigger
INSERT INTO BloodDonation (DonorID, RecipientID, DonationDate, QuantityInMl)
VALUES (1, 1, GETDATE(), 200);

SELECT * FROM Product;
go

--Test View
SELECT *
FROM BloodDonorView;
go

-- Test scalar function
DECLARE @ProductIDToTest INT = 1;

DECLARE @UnitPrice DECIMAL(10, 2);
SET @UnitPrice = dbo.GetProductUnitPrice(@ProductIDToTest);

SELECT @UnitPrice AS UnitPrice;
go

-- GOTO 
DECLARE @Counter INT = 1;
LOOP:
    IF @Counter > 10
        GOTO END_LOOP;
    PRINT 'Counter Value: ' + CAST(@Counter AS VARCHAR(2));
    SET @Counter = @Counter + 1;
    GOTO LOOP;
END_LOOP:
PRINT 'Loop ends.';
go

-- TRY_CATCH
BEGIN TRY
	SELECT 100/0 AS 'DIVISION';
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS 'ERROR MESSAGE', ERROR_LINE() AS 'ERROR LINE'
END CATCH
go

--==============================================================================================================================

