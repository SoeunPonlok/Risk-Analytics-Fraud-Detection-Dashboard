
-- Create DataBase --

CREATE DATABASE RiskAnalyticsDW;

GO

-- Create Stagging Table --

USE RiskAnalyticsDW;
GO

CREATE TABLE dbo.Stg_Transactions
(
    StagingID BIGINT IDENTITY(1,1),

    step INT,
    type VARCHAR(20),
    amount DECIMAL(18,2),

    nameOrig VARCHAR(50),
    oldbalanceOrg DECIMAL(18,2),
    newbalanceOrig DECIMAL(18,2),

    nameDest VARCHAR(50),
    oldbalanceDest DECIMAL(18,2),
    newbalanceDest DECIMAL(18,2),

    isFraud BIT,
    isFlaggedFraud BIT
);
GO

-- Create Dimension Tables --

-- Dim_TransactionType --

USE RiskAnalyticsDW;
GO

CREATE TABLE Dim_TransactionType
(
    TransactionTypeKey INT IDENTITY(1,1) PRIMARY KEY,
    TransactionType VARCHAR(50)
);

-- Dim_Customer --

USE RiskAnalyticsDW;
GO

CREATE TABLE Dim_Customer
(
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID VARCHAR(50)
);

-- Dim_Date --

USE RiskAnalyticsDW;
GO

CREATE TABLE Dim_Date
(
    DateKey INT PRIMARY KEY,
    StepNumber INT,
    FullDateTime DATETIME,
    YearNumber INT,
    MonthNumber INT,
    DayNumber INT,
    HourNumber INT
);
GO

-- Create Fact Table --

USE RiskAnalyticsDW;
GO

CREATE TABLE Fact_Transactions
(
    TransactionKey BIGINT IDENTITY(1,1) PRIMARY KEY,

    SenderCustomerKey INT,
    ReceiverCustomerKey INT,

    TransactionTypeKey INT,
    DateKey INT,

    Amount DECIMAL(18,2),

    OldBalanceOrigin DECIMAL(18,2),
    NewBalanceOrigin DECIMAL(18,2),

    OldBalanceDestination DECIMAL(18,2),
    NewBalanceDestination DECIMAL(18,2),

    FraudFlag BIT,
    FlaggedFraud BIT,

    RiskScore INT NULL,
    RiskLevel VARCHAR(20) NULL,

    FOREIGN KEY (SenderCustomerKey)
        REFERENCES Dim_Customer(CustomerKey),

    FOREIGN KEY (ReceiverCustomerKey)
        REFERENCES Dim_Customer(CustomerKey),

    FOREIGN KEY (TransactionTypeKey)
        REFERENCES Dim_TransactionType(TransactionTypeKey),

    FOREIGN KEY (DateKey)
        REFERENCES Dim_Date(DateKey)
);
GO

-- Update Table -- 

UPDATE FT
SET RiskScore =
(
    CASE
        WHEN Amount > 200000 THEN 30
        ELSE 0
    END

    +

    CASE
        WHEN NewBalanceOrigin = 0
             AND Amount > 100000
        THEN 25
        ELSE 0
    END

    +

    CASE
        WHEN TT.TransactionType = 'TRANSFER'
        THEN 15
        ELSE 0
    END

    +

    CASE
        WHEN TT.TransactionType = 'CASH_OUT'
        THEN 15
        ELSE 0
    END
)
FROM Fact_Transactions FT
JOIN Dim_TransactionType TT
    ON FT.TransactionTypeKey = TT.TransactionTypeKey;


-- Update Fact Table --

UPDATE Fact_Transactions
SET RiskLevel =
CASE
    WHEN RiskScore >= 51 THEN 'High Risk'
    WHEN RiskScore >= 21 THEN 'Medium Risk'
    ELSE 'Low Risk'
END;


-- Create Summury View --

CREATE VIEW vw_RiskAnalyticsDashboard
AS
SELECT
    FT.TransactionKey,
    D.FullDateTime,
    Sender.CustomerID AS SenderID,
    Receiver.CustomerID AS ReceiverID,
    TT.TransactionType,
    FT.Amount,
    FT.FraudFlag,
    FT.FlaggedFraud,
    FT.RiskScore,
    FT.RiskLevel
FROM Fact_Transactions FT
JOIN Dim_Customer Sender
    ON FT.SenderCustomerKey = Sender.CustomerKey
JOIN Dim_Customer Receiver
    ON FT.ReceiverCustomerKey = Receiver.CustomerKey
JOIN Dim_TransactionType TT
    ON FT.TransactionTypeKey = TT.TransactionTypeKey
JOIN Dim_Date D
    ON FT.DateKey = D.DateKey;