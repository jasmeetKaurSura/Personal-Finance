--Number of records 
SELECT Count(*) 'Number of records in Budget Table' FROM [Personal finance].dbo.Budget
SELECT Count(*) 'Number of records in Personal Transaction Table'FROM [Personal finance].dbo.personal_transactions


-- Total transactions by month


SELECT Month(date) Month, 
	SUM(CASE WHEN YEAR(date) ='2018' THEN 1   END) as 'total number of Transactions (2018)',
	SUM(CASE WHEN YEAR(date) ='2019' THEN 1  END) as 'total number of Transactions (2019)'
FROM[Personal finance].[dbo].[personal_transactions]
WHERE Transaction_Type = 'debit' 
GROUP BY Month(date)



-- Finding total number of categories 
SELECT DISTINCT 
	P. [Category], B.[Category]
FROM [Personal finance].[dbo].[personal_transactions] P
inner join [Personal finance].[dbo].[Budget] B
On   P. [Category]= B.[Category]

SELECT  Year(date) year, 
	SUM(amount) 'total money spent '
FROM[Personal finance].[dbo].[personal_transactions]
WHERE Transaction_Type = 'debit' 
GROUP BY Year(date)

--Descriptive Analysis
SELECT Category,max(amount) maxval,
	min(Amount) minval,
	STDEV(amount) ' standard deviation' , 
	Var(amount) Variance
FROM [Personal finance].[dbo].[personal_transactions]
WHERE Transaction_Type = 'debit' 
GROUP BY category
ORDER BY STDEV(amount) DESC

-- Printing Budget
SELECT * FROM [Personal finance].[dbo].[Budget]

SELECT SUM(Budget) AS 'Spending allowed' 
FROM [Personal finance].[dbo].[Budget] 
WHERE Budget.Category != 'Paycheck' 

SELECT SUM(Budget) AS 'Income'
FROM [Personal finance].[dbo].[Budget]
WHERE Budget.Category = 'Paycheck' 

--Top Five Spending categories 

SELECT Top(5) Category, 
	Amount, 
	Year(Date) AS 'Year', 
	Month(Date) AS 'Month'
FROM [Personal finance].[dbo].[personal_transactions]
WHERE Transaction_Type = 'debit' AND Category != 'Credit Card Payment'
ORDER BY Amount DESC



-- Spending by month 

SELECT Month(date) As 'month',
	SUM(CASE WHEN YEAR(DATE) ='2018' THEN Amount END) 'Spending By Month(2018)', 
	SUM(CASE WHEN YEAR(DATE) ='2019' THEN Amount END) 'Spending By Month(2019)'
FROM [Personal finance].[dbo].[personal_transactions] 
WHERE Transaction_Type = 'debit' And Account_Name ='checking' 
GROUP BY Month(date)
ORDER BY Month(date)

--Spending by card type

SELECT  Account_Name,
		SUM(Amount) 'Spending By Account'
FROM [Personal finance].[dbo].[personal_transactions] 
WHERE Transaction_Type = 'debit'  
GROUP BY Account_Name
-- Income versus spending by month

SELECT Month(date) As 'month',
		Year(date) AS 'Year',
		SUM(CASE 
			WHEN Transaction_Type = 'debit' THEN Amount 
			ELSE 0 END) As 'Spending By Month', 
		SUM(CASE 
			WHEN Category = 'Paycheck' THEN Amount 
			ELSE 0 END) As 'Income',
		SUM(CASE 
			WHEN Transaction_Type = 'debit' THEN Amount 
			ELSE 0 END)/ SUM(CASE 
			WHEN Category = 'Paycheck' THEN Amount 
			ELSE 0 END) *100 AS 'Percentage of income spent'
FROM [Personal finance].[dbo].[personal_transactions] 
WHERE Account_Name ='checking' 
GROUP BY Month(date), YEAR(Date)
ORDER BY YEAR(Date), Month(date)

-- Spending by Category  

SELECT SUM(Amount) 'Spending By Category', 
	Category, 
	YEAR(Date) AS Year
FROM [Personal finance].[dbo].[personal_transactions] 
WHERE Transaction_Type = 'debit'
GROUP BY Category, YEAR(date)
ORDER BY YEAR(date), SUM(Amount) DESC

--Top Five most spent on categories 

SELECT TOP(5) Category, 
	SUM(Amount) 'Spending By Category' 
FROM [Personal finance].[dbo].[personal_transactions] 
WHERE Transaction_Type = 'debit'
GROUP BY Category
ORDER BY SUM(Amount) DESC

-- category wise monthly Spending compared to the budget 

SELECT A.*,
	b.maxval,
	b.minval,
	sum(A.[Spending By Category]) over (Partition by A.Category Order by A.Year , A.Month) 'Running Total'
FROM
	(
	SELECT P.Category,
		MONTH(Date) AS Month,
		YEAR(Date) AS Year,
		SUM(P.Amount) 'Spending By Category',
		COUNT(*) 'total transactions', B.Budget, 
		(SUM(P.Amount)/B.Budget)*100 'Percentage of Budget used'
	FROM [Personal finance].[dbo].[personal_transactions] As P
	Inner JOIN   [Personal finance].[dbo].[Budget] AS B
	ON P.Category = B.Category 
	WHERE Transaction_Type = 'debit' AND P.Category != 'Credit Card Payment'
	GROUP BY P.Category, Month(date), Year(date),  B.Budget
	)A
	inner join (
	SELECT max(amount) maxval, 
			min(Amount) minval,Category
	FROM [Personal finance].[dbo].[personal_transactions]
	GROUP BY category)b 
ON a.Category =b.Category
WHERE A.[Percentage of Budget Used]>100
ORDER BY YEAR, Month, Budget Desc


--Categories that have outspent budget

SELECT Z.Category,
	COUNT(*) 'Number of times outspent' , 
	MAX(Z.[Spending By Category])'Maximum Spent', 
	Max(Z.Budget)Budget
FROM
(
SELECT A.*,b.maxval,b.minval,
	sum(A.[Spending By Category]) over (Partition by A.Category Order by A.Year , A.Month) 'Running Total',
	Row_Number() OVER (Partition by a.Category ORDER BY a.[Spending By Category] DESC) AS Rank
FROM
(
SELECT P.Category,
	MONTH(Date) AS Month,
	YEAR(Date) AS Year,
	SUM(P.Amount) 'Spending By Category',
	COUNT(*) 'total transactions', B.Budget, 
	(SUM(P.Amount)/B.Budget)*100 'Percentage of Budget used'
FROM [Personal finance].[dbo].[personal_transactions] As P
Inner JOIN   [Personal finance].[dbo].[Budget] AS B
ON P.Category = B.Category 
WHERE Transaction_Type = 'debit' AND P.Category != 'Credit Card Payment'
GROUP BY P.Category, Month(date), Year(date),  B.Budget
)A
inner join (SELECT max(amount) maxval, min(Amount) minval,Category
			FROM [Personal finance].[dbo].[personal_transactions]
			GROUP BY category)b 
ON a.Category =b.Category
)z
WHERE  Z.[Percentage of Budget used]>100
GROUP BY Z.Category
Order BY  COUNT(*)DESC

