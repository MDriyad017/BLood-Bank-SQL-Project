/*
					SQL Project Name : Blood Bank Management System
							    Trainee Name : MD. Jahidul Islam Riyad
						    	  Trainee ID : 1278865      
									Batch ID : WADA/PNTL-A/56/01


*/

use master
go
--************************************* CREATE AND USE DATABASE ***************************************--
create database BloodBank_DB on (
	name = 'BloodBank_DB_data',
	filename = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\BloodBank_DB_data.mdf',
	size = 2mb,
	maxsize = 50mb,
	filegrowth = 10%
)
log on (
	name = 'BloodBank_DB_log',
	filename = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\BloodBank_DB_log.ldf',
	size = 2mb,
	maxsize = 50mb,
	filegrowth = 10%
)
go

USE BloodBank_DB
GO

-- **********************************  Create BloodDonor table ***************************************--
CREATE TABLE BloodDonor (
    DonorID INT IDENTITY PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    BloodGroup VARCHAR(3) NOT NULL,
    Age INT,
    Gender VARCHAR(10),
    ContactNumber VARCHAR(15) NOT NULL,
    Address VARCHAR(100),
    LastDonationDate DATE,
    CONSTRAINT CK_BloodGroup CHECK (BloodGroup IN ('A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'))
);
GO

-- ********************************** Create BloodRecipient table **********************************--
CREATE TABLE BloodRecipient (
    RecipientID INT  IDENTITY PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    BloodGroup VARCHAR(3) NOT NULL,
    Age INT,
    Gender VARCHAR(10),
    ContactNumber VARCHAR(15) NOT NULL,
    Address VARCHAR(100)
);
GO

--********************** Create BloodDonation table with Foreign Key constraint *************************--
CREATE TABLE BloodDonation (
    DonationID INT IDENTITY PRIMARY KEY,
    DonorID INT REFERENCES BloodDonor(DonorID),
	RecipientID INT REFERENCES BloodRecipient(RecipientID),
    DonationDate DATE NOT NULL,
    QuantityInMl INT NOT NULL
);
GO

--******************************* Create Product table with Default constraint **********************************--
CREATE TABLE Product (
    ProductID INT IDENTITY PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    StockQuantity INT DEFAULT 0,
    UnitPrice DECIMAL(10, 2) DEFAULT 0.00
);
GO

--********************************** Create StockTransaction table **********************************--
CREATE TABLE StockTransaction (
    TransactionID INT IDENTITY PRIMARY KEY,
    ProductID INT NOT NULL,
    TransactionType VARCHAR(10) NOT NULL,
    Quantity INT NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_StockTransaction_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
GO

--********************************** Create BloodBankUser table **********************************--
CREATE TABLE BloodBankUser (
    UserID INT IDENTITY PRIMARY KEY,
    UserName VARCHAR(50) NOT NULL,
    PasswordHash VARBINARY(64) NOT NULL
);
GO
--********************************** CREATE COMMENT TABLE **********************************--
create table comment (
	cmntID int,
	comment varchar(80)
)

create table bloodStatus (
	statusID int,
	Status varchar (50), -- good or bad blood
	StatusTopic varchar(50)
)


--***************************** ADD CHECK CONSTRAINT with existing name **********************************--

alter table BloodDonor
add constraint ck_phoneNum check (ContactNumber like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')

--********************************** drop object **********************************--
alter table bloodStatus
drop column statusTopic

--********************************** Create Clustered and Non-clustered indexes **********************************
CREATE CLUSTERED INDEX ix_coment
ON comment
	(cmntID)
go

CREATE NONCLUSTERED INDEX IX_BloodRecipient_BloodGroup 
ON BloodRecipient
	(BloodGroup)
GO

--**********************************  Create sequence ********************************** 
CREATE SEQUENCE BloodDonorIDSequence
    AS INT
    START WITH 1000
    INCREMENT BY 1;
GO

--***************************** Create views WITH ENCRYPTION AND SCHEMABINDING ******************************--
CREATE VIEW BloodDonorView
WITH SCHEMABINDING
AS
    SELECT DonorID, FirstName, LastName, BloodGroup, Age, Gender, ContactNumber, Address
    FROM dbo.BloodDonor;
GO

CREATE VIEW EncryptedBloodDonorView
WITH ENCRYPTION, SCHEMABINDING
AS
    SELECT DonorID, FirstName, LastName, BloodGroup
    FROM dbo.BloodDonor;
GO

--***************************** Create stored procedures *****************************--
CREATE PROCEDURE InsertBloodDonor
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @BloodGroup VARCHAR(3),
    @Age INT,
    @Gender VARCHAR(10),
    @ContactNumber VARCHAR(15),
    @Address VARCHAR(100)
AS
BEGIN
    INSERT INTO BloodDonor (FirstName, LastName, BloodGroup, Age, Gender, ContactNumber, Address)
    VALUES (@FirstName, @LastName, @BloodGroup, @Age, @Gender, @ContactNumber, @Address);
END;
GO

CREATE PROCEDURE InsertBloodDonorWithOutput
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @BloodGroup VARCHAR(3),
    @Age INT,
    @Gender VARCHAR(10),
    @ContactNumber VARCHAR(15),
    @Address VARCHAR(100),
    @DonorID INT OUTPUT
AS
BEGIN
    INSERT INTO BloodDonor (FirstName, LastName, BloodGroup, Age, Gender, ContactNumber, Address)
    VALUES (@FirstName, @LastName, @BloodGroup, @Age, @Gender, @ContactNumber, @Address);

    SET @DonorID = SCOPE_IDENTITY();
END;
GO

--***************************** create store procedure for update data *****************************--
CREATE PROCEDURE UpdateBloodDonorAge
    @DonorID INT,
    @NewAge INT
AS
BEGIN
    UPDATE BloodDonor
    SET Age = @NewAge
    WHERE DonorID = @DonorID;
END;
go

--***************************** create store procedure for delete data *****************************--
CREATE PROCEDURE DeleteBloodDonor
    @DonorID INT
AS
BEGIN
    DELETE FROM BloodDonor
    WHERE DonorID = @DonorID;
END;
go

--***************************** Create triggers *****************************--
CREATE TRIGGER UpdateProductStockOnBloodDonation
ON BloodDonation
AFTER INSERT
AS
BEGIN
    DECLARE @DonorID INT, @QuantityInMl INT;

    SELECT @DonorID = DonorID, @QuantityInMl = QuantityInMl
    FROM inserted;

    UPDATE Product
    SET StockQuantity += @QuantityInMl
    WHERE ProductID = (SELECT ProductID FROM BloodDonor WHERE DonorID = @DonorID);
END;
GO

CREATE TRIGGER UpdateProductStockOnStockTransaction
ON StockTransaction
AFTER INSERT
AS
BEGIN
    DECLARE @ProductID INT, @Quantity INT, @TransactionType VARCHAR(10);

    SELECT @ProductID = ProductID, @Quantity = Quantity, @TransactionType = TransactionType
    FROM inserted;

    IF @TransactionType = 'In'
        UPDATE Product
        SET StockQuantity += @Quantity
        WHERE ProductID = @ProductID;
    ELSE IF @TransactionType = 'Out'
        UPDATE Product
        SET StockQuantity -= @Quantity
        WHERE ProductID = @ProductID;
END;
GO

--***************************** Create scalar function *****************************--
CREATE FUNCTION GetProductUnitPrice
(
    @ProductID INT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @UnitPrice DECIMAL(10, 2);

    SELECT @UnitPrice = UnitPrice
    FROM Product
    WHERE ProductID = @ProductID;

    RETURN @UnitPrice;
END;
GO


--***************************** Create inline table-valued function *****************************
CREATE FUNCTION GetBloodDonorsByBloodGroup
(
    @BloodGroup VARCHAR(3)
)
RETURNS TABLE
AS
RETURN
(
    SELECT DonorID, FirstName, LastName, Age, Gender, ContactNumber, Address
    FROM BloodDonor
    WHERE BloodGroup = @BloodGroup
);
GO

--************************ Create multi-statement table-valued function **************************--
CREATE FUNCTION GetBloodDonationsForDonor
(
    @DonorID INT
)
RETURNS @Donations TABLE
(
    DonationID INT,
    DonationDate DATE,
    QuantityInMl INT
)
AS
BEGIN
    INSERT INTO @Donations (DonationID, DonationDate, QuantityInMl)
    SELECT DonationID, DonationDate, QuantityInMl
    FROM BloodDonation
    WHERE DonorID = @DonorID;

    RETURN;
END;
GO
--
CREATE TRIGGER InsteadOfInsertOnBloodDonation
ON BloodDonation
INSTEAD OF INSERT
AS
	BEGIN
		INSERT INTO BloodDonation (DonorID, DonationDate, QuantityInMl)
		SELECT i.DonorID, i.DonationDate, i.QuantityInMl
		FROM inserted i
		INNER JOIN BloodDonor d ON i.DonorID = d.DonorID;
	END;
GO

--***************************** RAISERROR using trigger on view *****************************--
CREATE TRIGGER InsteadOfInsertOnBloodDonorView
ON BloodDonorView
INSTEAD OF INSERT
AS
BEGIN
    RAISERROR('Instead Of trigger on BloodDonorView is not allowed.', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

--***************************** Alter trigger *****************************--
ALTER TRIGGER UpdateProductStockOnStockTransaction
ON StockTransaction
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @ProductID INT, @Quantity INT, @TransactionType VARCHAR(10);

    SELECT @ProductID = ProductID, @Quantity = Quantity, @TransactionType = TransactionType
    FROM inserted;

    IF @TransactionType = 'In'
        UPDATE Product
        SET StockQuantity += @Quantity
        WHERE ProductID = @ProductID;
    ELSE IF @TransactionType = 'Out'
        UPDATE Product
        SET StockQuantity -= @Quantity
        WHERE ProductID = @ProductID;
END;
GO

--===================================================================================================================

