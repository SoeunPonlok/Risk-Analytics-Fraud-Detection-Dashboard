
-- Insert Value to Dim_TrxType --

INSERT INTO Dim_TransactionType
(
    TransactionType
)
SELECT DISTINCT
       type
FROM Stg_Transactions;

-- Insert Value to Dim_Customer --

INSERT INTO Dim_Customer (CustomerID)
SELECT nameOrig
FROM Stg_Transactions

UNION

SELECT nameDest
FROM Stg_Transactions;

-- Insert Value to Dim_Date --

INSERT INTO Dim_Date
(
    DateKey,
    StepNumber,
    FullDateTime,
    YearNumber,
    MonthNumber,
    DayNumber,
    HourNumber
)
SELECT DISTINCT
       step,
       step,
       DATEADD(HOUR, step, '2025-01-01'),
       YEAR(DATEADD(HOUR, step, '2025-01-01')),
       MONTH(DATEADD(HOUR, step, '2025-01-01')),
       DAY(DATEADD(HOUR, step, '2025-01-01')),
       DATEPART(HOUR, DATEADD(HOUR, step, '2025-01-01'))
FROM Stg_Transactions;



SELECT COUNT(*)
FROM Dim_Customer;


SELECT COUNT(DISTINCT nameDest) AS ReceiverCount
FROM Stg_Transactions;

SELECT COUNT(DISTINCT CustomerID) AS SenderCount
FROM Dim_Customer;

SELECT *
FROM Dim_TransactionType;

-- Insesrt to Fact_Table --

INSERT INTO Fact_Transactions
(
    SenderCustomerKey,
    ReceiverCustomerKey,
    TransactionTypeKey,
    DateKey,

    Amount,

    OldBalanceOrigin,
    NewBalanceOrigin,

    OldBalanceDestination,
    NewBalanceDestination,

    FraudFlag,
    FlaggedFraud
)
SELECT
    Sender.CustomerKey,
    Receiver.CustomerKey,

    TT.TransactionTypeKey,

    D.DateKey,

    S.amount,

    S.oldbalanceOrg,
    S.newbalanceOrig,

    S.oldbalanceDest,
    S.newbalanceDest,

    S.isFraud,
    S.isFlaggedFraud

FROM Stg_Transactions S

INNER JOIN Dim_Customer Sender
    ON S.nameOrig = Sender.CustomerID

INNER JOIN Dim_Customer Receiver
    ON S.nameDest = Receiver.CustomerID

INNER JOIN Dim_TransactionType TT
    ON S.type = TT.TransactionType

INNER JOIN Dim_Date D
    ON S.step = D.StepNumber;
