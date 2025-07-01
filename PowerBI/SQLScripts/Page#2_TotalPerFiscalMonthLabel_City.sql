--ALTER DATABASE [PowerBIHyperScaleDemo_v1] SET QUERY_STORE CLEAR;
--ALTER DATABASE [PowerBIHyperScaleDemo] SET QUERY_STORE CLEAR;

----
-- Clean Buffer pool and proc cache
-----
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
-----------------------------------------

SELECT 
TOP (1000001) *
FROM 
(

SELECT [t1].[City] AS [c8],[t3].[Fiscal Month Label] AS [c43],SUM([t6].[Total Excluding Tax])
 AS [a0],SUM([t6].[Total Including Tax])
 AS [a1]
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

 INNER JOIN 

(
select [$Table].[City Key] as [City Key],
    [$Table].[WWI City ID] as [WWI City ID],
    [$Table].[City] as [City],
    [$Table].[State Province] as [State Province],
    [$Table].[Country] as [Country],
    [$Table].[Continent] as [Continent],
    [$Table].[Sales Territory] as [Sales Territory],
    [$Table].[Region] as [Region],
    [$Table].[Subregion] as [Subregion],
    convert(nvarchar(max), [$Table].[Location]) as [Location],
    [$Table].[Latest Recorded Population] as [Latest Recorded Population],
    [$Table].[Valid From] as [Valid From],
    [$Table].[Valid To] as [Valid To],
    [$Table].[Lineage Key] as [Lineage Key]
from [Dimension].[City] as [$Table]
) AS [t1] on 
(
[t6].[City Key] = [t1].[City Key]
)
)


 INNER JOIN 

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
[t6].[Invoice Date Key] = [t3].[Date]
)
)

GROUP BY [t1].[City],[t3].[Fiscal Month Label]
)
 AS [MainTable]
WHERE 
(

NOT(
(
[a0] IS NULL 
)
)
 OR 
NOT(
(
[a1] IS NULL 
)
)

)
 