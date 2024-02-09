--project num 2
--Q1
SELECT DISTINCT p.ProductID, 
				Name AS ProductName ,
				Color, 
				ListPrice, 
				Size
FROM Production.Product p LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID=
			sod.ProductID
WHERE sod.ProductID IS NULL
ORDER BY 1

--Q2
SELECT CustomerID, 
	   ISNULL(LastName, 'Unknown') AS LastName, 
	   ISNULL(FirstName, 'Unknown') AS FirstName
FROM Sales.Customer c LEFT JOIN Person.Person p ON c.CustomerID=p.BusinessEntityID
WHERE c.PersonID IS NULL
ORDER BY 1

--Q3
SELECT TOP 10 c.CustomerID, 
			  FirstName, 
			  LastName ,
			  COUNT(*) AS CountOfOrders
FROM Sales.Customer c INNER JOIN Sales.SalesOrderHeader soh ON c.CustomerID=soh.CustomerID
	 INNER JOIN Person.Person p ON p.BusinessEntityID=c.PersonID
GROUP BY c.CustomerID, FirstName, LastName
ORDER BY 4 DESC

--Q4
SELECT FirstName ,
	   LastName, 
	   JobTitle, 
	   HireDate,
		COUNT(e.BusinessEntityID) OVER(PARTITION BY e.JobTitle) AS CountOfTitle
FROM HumanResources.Employee e INNER JOIN Person.Person p ON e.BusinessEntityID=p.BusinessEntityID
GROUP BY FirstName, LastName, JobTitle, HireDate, e.BusinessEntityID

--Q5
SELECT soi AS SalesOrderID, 
		cid AS CustomerID, 
		p.LastName, 
		p.FirstName,maxod AS LastOrder, 
		minod AS PreviousOrder
FROM (
	  SELECT c.CustomerID AS cid,
	  soh.SalesOrderID AS soi,
	  soh.OrderDate AS sod, 
	  c.PersonID AS pid,
	  MAX(soh.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY c.CustomerID ) maxod,
	  LAG(soh.OrderDate,1) OVER (ORDER BY c.CustomerID, soh.OrderDate ) minod
	  FROM Sales.SalesOrderHeader soh
	  INNER JOIN sales.Customer c
	  ON soh.CustomerID = c.CustomerID) AS t1
	INNER JOIN person.person p ON p.BusinessEntityID=t1.pid
	WHERE t1.sod = t1.maxod
ORDER BY 2

--Q6
SELECT y AS "Year", 
	   oid AS SalesOrderID, 
	   p.LastName, 
	   p.FirstName, 
	   FORMAT(total,'#,#.0') AS Total
FROM		(
			SELECT year(OrderDate) AS y, 
			soh.SalesOrderID AS oid, 
			SUM(UnitPrice*(1-UnitPriceDiscount)*OrderQty) AS total,
			soh.CustomerID AS cid,
			ROW_NUMBER() OVER (PARTITION BY year(OrderDate) ORDER BY SUM(UnitPrice*(1-UnitPriceDiscount)*OrderQty) DESC) RN
			FROM Sales.SalesOrderHeader soh INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID=sod.SalesOrderID
			GROUP BY year(OrderDate), soh.SalesOrderID, soh.CustomerID
			) AS t1
INNER JOIN Sales.Customer c ON c.CustomerID=t1.cid INNER JOIN Person.Person p ON p.BusinessEntityID=
		c.PersonID
WHERE RN = 1

--Q7
SELECT Month, [2011],[2012],[2013],[2014]
FROM
		(SELECT SalesOrderID, YEAR(OrderDate) AS y, MONTH(OrderDate) AS "Month", COUNT(SalesOrderID) 
				AS CountOrders
		 FROM Sales.SalesOrderHeader
		 GROUP BY SalesOrderID, OrderDate) AS o
		 PIVOT (COUNT(SalesOrderID) for y in ([2011],[2012],[2013],[2014])) PIV
ORDER BY 1

--Q8
WITH sumprice
as		(
		SELECT YEAR(ModifiedDate) "Year", 
			   MONTH(ModifiedDate) "Month", 
			   CAST(SUM(UnitPrice*(1-UnitPriceDiscount)) AS DECIMAL (15,2)) Sum_Price
		FROM Sales.SalesOrderDetail
		GROUP BY YEAR(ModifiedDate), MONTH(ModifiedDate)
		)
SELECT Year, 
	   cast(Month as nvarchar) "Month", 
	   Sum_Price, SUM(Sum_Price) OVER(PARTITION BY year ORDER BY month) as CumSum
FROM sumprice
UNION
SELECT Year, 'grand_total', null, SUM(Sum_Price)
FROM sumprice
GROUP BY year
ORDER BY 1,4

--Q9
SELECT 
		d.Name AS DepartmentName, 
		e.BusinessEntityID AS EmployeesID, 
		FirstName+' '+LastName AS EmployeesFullName, 
		HireDate,
		DATEDIFF(MM,HireDate,GETDATE()) AS Seniority,
		LAG(FirstName+' '+LastName,1) OVER(PARTITION BY d.name ORDER BY hiredate) AS PreviusEmpName,
		LAG(HireDate,1) OVER(PARTITION BY d.name ORDER BY hiredate) AS PreviusEmpHDate,
		DATEDIFF(DD,LAG(HireDate,1) OVER(PARTITION BY d.name ORDER BY hiredate),HireDate) AS DiffDays
FROM HumanResources.Employee e INNER JOIN Person.Person p ON e.BusinessEntityID =
	  p.BusinessEntityID
	  INNER JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = 
	  edh.BusinessEntityID
	  INNER JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID
ORDER BY 1, 4 DESC

--Q10
SELECT DISTINCT HireDate, 
				DepartmentID, 
				TeamEmployees 
FROM(
			SELECT DISTINCT HireDate, 
							DepartmentID ,
							STUFF((SELECT DISTINCT ', '+ CAST(p.BusinessEntityID AS NVARCHAR)+' '+ LastName+' '+ FirstName
								   FROM Person.Person p INNER JOIN HumanResources.Employee e 
								        ON p.BusinessEntityID = e.BusinessEntityID INNER JOIN 
								        HumanResources.EmployeeDepartmentHistory h
								        ON e.BusinessEntityID = h.BusinessEntityID
								   WHERE e.HireDate = e2.HireDate AND h.DepartmentID = h2.DepartmentID
								   FOR XML PATH ('')),1,1,'') TeamEmployees,
							ROW_NUMBER() OVER(PARTITION BY HireDate ORDER BY HireDate DESC) AS rn
			FROM HumanResources.Employee e2 INNER JOIN HumanResources.EmployeeDepartmentHistory h2 
					ON e2.BusinessEntityID = h2.BusinessEntityID
			WHERE H2.EndDate IS NULL
			GROUP BY HireDate, DepartmentID) AS t
ORDER BY 1 DESC
