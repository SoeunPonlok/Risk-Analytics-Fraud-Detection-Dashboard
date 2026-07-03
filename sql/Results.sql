
TRUNCATE TABLE Dim_Customer;

SELECT COUNT(*)
FROM Dim_Customer;

DROP TABLE IF EXISTS Fact_Transactions;
GO


SELECT COUNT(*)
FROM Dim_Date;

SELECT TOP 5 *
FROM Dim_Date;


SELECT COUNT(*)
FROM Fact_Transactions;

SELECT COUNT(*) FROM Fact_Transactions;

SELECT TOP 5 *
FROM Fact_Transactions;

SELECT TOP 5
       FT.TransactionKey,
       FT.Amount,
       FT.OldBalanceOrigin,
       FT.NewBalanceOrigin,
       TT.TransactionType
FROM Fact_Transactions FT
JOIN Dim_TransactionType TT
    ON FT.TransactionTypeKey = TT.TransactionTypeKey;


SELECT
    RiskLevel,
    COUNT(*) AS TotalTransactions
FROM Fact_Transactions
GROUP BY RiskLevel
ORDER BY TotalTransactions DESC;


SELECT TOP 20
       TransactionKey,
       Amount,
       RiskScore,
       RiskLevel,
       FraudFlag
FROM Fact_Transactions
ORDER BY RiskScore DESC;


-- Measure Rule Effectiveness --

SELECT
    RiskLevel,
    COUNT(*) AS TotalTransactions,
    SUM(CAST(FraudFlag AS INT)) AS FraudTransactions
FROM Fact_Transactions
GROUP BY RiskLevel
ORDER BY RiskLevel;


-- Fraud Detection Rate --

SELECT
    COUNT(*) AS TotalFraudCases
FROM Fact_Transactions
WHERE FraudFlag = 1;


SELECT
    COUNT(*) AS HighRiskFraudCases
FROM Fact_Transactions
WHERE FraudFlag = 1
AND RiskLevel = 'High Risk';


-- Find Customers Generating Most High-Risk Alerts --

SELECT TOP 20
       C.CustomerID,
       COUNT(*) AS HighRiskTransactions,
       SUM(FT.Amount) AS TotalAmount
FROM Fact_Transactions FT
JOIN Dim_Customer C
    ON FT.SenderCustomerKey = C.CustomerKey
WHERE FT.RiskLevel = 'High Risk'
GROUP BY C.CustomerID
ORDER BY HighRiskTransactions DESC;


-- Find Customers Associated With Fraud --

SELECT TOP 20
       C.CustomerID,
       COUNT(*) AS FraudTransactions,
       SUM(FT.Amount) AS FraudAmount
FROM Fact_Transactions FT
JOIN Dim_Customer C
    ON FT.SenderCustomerKey = C.CustomerKey
WHERE FT.FraudFlag = 1
GROUP BY C.CustomerID
ORDER BY FraudTransactions DESC;


-- Risk by Transaction Type --

SELECT
       TT.TransactionType,
       COUNT(*) AS TotalTransactions,
       SUM(CAST(FT.FraudFlag AS INT)) AS FraudTransactions,
       ROUND(
            100.0 * SUM(CAST(FT.FraudFlag AS INT))
            / COUNT(*),
            2
       ) AS FraudRate
FROM Fact_Transactions FT
JOIN Dim_TransactionType TT
    ON FT.TransactionTypeKey = TT.TransactionTypeKey
GROUP BY TT.TransactionType
ORDER BY FraudRate DESC;


