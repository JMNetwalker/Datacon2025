CREATE OR ALTER VIEW DameTotalFiscalMonthLabel
with schemabinding
as
SELECT [Fiscal Month Label] ,SUM([Total Including Tax]) AS [a0],SUM([Total Excluding Tax]) AS [a1], COUNT_BIG(*) AS Total
from [Fact].[Sale] 
inner join [Dimension].[Date] on [Fact].[Sale].[Delivery Date Key] = [Dimension].[Date].[Date]
GROUP BY [Fiscal Month Label]


CREATE UNIQUE CLUSTERED INDEX DameTotalFiscalMonthLabel_X1 ON DameTotalFiscalMonthLabel([Fiscal Month Label])

CREATE INDEX FactSaleByInvoiceDay_X1
ON Fact.Sale
(
	[Delivery Date Key]
)
