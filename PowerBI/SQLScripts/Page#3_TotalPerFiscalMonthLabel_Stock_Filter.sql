--ALTER DATABASE [PowerBIHyperScaleDemo_v1] SET QUERY_STORE CLEAR;
--ALTER DATABASE [PowerBIHyperScaleDemo] SET QUERY_STORE CLEAR;

----
-- Clean Buffer pool and proc cache
-----
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
-----------------------------
SELECT 
TOP (1000001) *
FROM 
(

SELECT [t3].[Fiscal Month Label] AS [c43],[t5].[Stock Item] AS [c59],SUM(
CAST([t6].[Quantity] as BIGINT)
)
 AS [a0]
FROM 
(
((
select [$Table].[Sale Key] as [Sale Key],
    [$Table].[City Key] as [City Key],
    [$Table].[Customer Key] as [Customer Key],
    [$Table].[Bill To Customer Key] as [Bill To Customer Key],
    [$Table].[Stock Item Key] as [Stock Item Key],
    [$Table].[Invoice Date Key] as [Invoice Date Key],
    [$Table].[Delivery Date Key] as [Delivery Date Key],
    [$Table].[Salesperson Key] as [Salesperson Key],
    [$Table].[WWI Invoice ID] as [WWI Invoice ID],
    [$Table].[Description] as [Description],
    [$Table].[Package] as [Package],
    [$Table].[Quantity] as [Quantity],
    [$Table].[Unit Price] as [Unit Price],
    [$Table].[Tax Rate] as [Tax Rate],
    [$Table].[Total Excluding Tax] as [Total Excluding Tax],
    [$Table].[Tax Amount] as [Tax Amount],
    [$Table].[Profit] as [Profit],
    [$Table].[Total Including Tax] as [Total Including Tax],
    [$Table].[Total Dry Items] as [Total Dry Items],
    [$Table].[Total Chiller Items] as [Total Chiller Items],
    [$Table].[Lineage Key] as [Lineage Key]
from [Fact].[Sale] as [$Table]
) AS [t6]

 LEFT OUTER JOIN 

(
select [$Table].[Date] as [Date],
    [$Table].[Day Number] as [Day Number],
    [$Table].[Day] as [Day],
    [$Table].[Month] as [Month],
    [$Table].[Short Month] as [Short Month],
    [$Table].[Calendar Month Number] as [Calendar Month Number],
    [$Table].[Calendar Month Label] as [Calendar Month Label],
    [$Table].[Calendar Year] as [Calendar Year],
    [$Table].[Calendar Year Label] as [Calendar Year Label],
    [$Table].[Fiscal Month Number] as [Fiscal Month Number],
    [$Table].[Fiscal Month Label] as [Fiscal Month Label],
    [$Table].[Fiscal Year] as [Fiscal Year],
    [$Table].[Fiscal Year Label] as [Fiscal Year Label],
    [$Table].[ISO Week Number] as [ISO Week Number]
from [Dimension].[Date] as [$Table]
) AS [t3] on 
(
[t6].[Delivery Date Key] = [t3].[Date]
)
)


 INNER JOIN 

(
select [$Table].[Stock Item Key] as [Stock Item Key],
    [$Table].[WWI Stock Item ID] as [WWI Stock Item ID],
    [$Table].[Stock Item] as [Stock Item],
    [$Table].[Color] as [Color],
    [$Table].[Selling Package] as [Selling Package],
    [$Table].[Buying Package] as [Buying Package],
    [$Table].[Brand] as [Brand],
    [$Table].[Size] as [Size],
    [$Table].[Lead Time Days] as [Lead Time Days],
    [$Table].[Quantity Per Outer] as [Quantity Per Outer],
    [$Table].[Is Chiller Stock] as [Is Chiller Stock],
    [$Table].[Barcode] as [Barcode],
    [$Table].[Tax Rate] as [Tax Rate],
    [$Table].[Unit Price] as [Unit Price],
    [$Table].[Recommended Retail Price] as [Recommended Retail Price],
    [$Table].[Typical Weight Per Unit] as [Typical Weight Per Unit],
    [$Table].[Photo] as [Photo],
    [$Table].[Valid From] as [Valid From],
    [$Table].[Valid To] as [Valid To],
    [$Table].[Lineage Key] as [Lineage Key]
from [Dimension].[Stock Item] as [$Table]
) AS [t5] on 
(
[t6].[Stock Item Key] = [t5].[Stock Item Key]
)
)

WHERE 
(
([t3].[Fiscal Month Label] IN (N'FY2013-Aug',N'FY2014-Aug',N'FY2015-Aug'))
)

GROUP BY [t3].[Fiscal Month Label],[t5].[Stock Item]
)
 AS [MainTable]
WHERE 
(

NOT(
(
[a0] IS NULL 
)
)

)
 