/****** Object:  Table [Fact].[Sale]    Script Date: 22/11/2022 19:27:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE Fact.[SaleColumnStoreIndex]

CREATE TABLE [Fact].[SaleColumnStoreIndex](
	[Sale Key] [bigint] IDENTITY(1,1) NOT NULL,
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Bill To Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Invoice Date Key] [date] NOT NULL,
	[Delivery Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[WWI Invoice ID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[Package] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Tax Rate] [decimal](18, 3) NOT NULL,
	[Total Excluding Tax] [decimal](18, 2) NOT NULL,
	[Tax Amount] [decimal](18, 2) NOT NULL,
	[Profit] [decimal](18, 2) NOT NULL,
	[Total Including Tax] [decimal](18, 2) NOT NULL,
	[Total Dry Items] [int] NOT NULL,
	[Total Chiller Items] [int] NOT NULL,
	[Lineage Key] [int] NOT NULL,
	 index [SaleColumnStoreIndex_CC] CLUSTERED COLUMNSTORE
) ON myPartitionScheme([Delivery Date Key])

GO

CREATE PARTITION FUNCTION myDateRangePF (date)
AS RANGE RIGHT FOR VALUES ('2013-01-01','2014-01-01','2015-01-01','2016-01-01')
GO

CREATE PARTITION SCHEME myPartitionScheme 
AS PARTITION myDateRangePF ALL TO ([PRIMARY]) 
GO

INSERT INTO [Fact].[SaleColumnStoreIndex]
           ([City Key]
           ,[Customer Key]
           ,[Bill To Customer Key]
           ,[Stock Item Key]
           ,[Invoice Date Key]
           ,[Delivery Date Key]
           ,[Salesperson Key]
           ,[WWI Invoice ID]
           ,[Description]
           ,[Package]
           ,[Quantity]
           ,[Unit Price]
           ,[Tax Rate]
           ,[Total Excluding Tax]
           ,[Tax Amount]
           ,[Profit]
           ,[Total Including Tax]
           ,[Total Dry Items]
           ,[Total Chiller Items]
           ,[Lineage Key])
     SELECT 
           [City Key]
           ,[Customer Key]
           ,[Bill To Customer Key]
           ,[Stock Item Key]
           ,[Invoice Date Key]
           ,[Delivery Date Key]
           ,[Salesperson Key]
           ,[WWI Invoice ID]
           ,[Description]
           ,[Package]
           ,[Quantity]
           ,[Unit Price]
           ,[Tax Rate]
           ,[Total Excluding Tax]
           ,[Tax Amount]
           ,[Profit]
           ,[Total Including Tax]
           ,[Total Dry Items]
           ,[Total Chiller Items]
           ,[Lineage Key]
		   FROM [FACT].[Sale]
GO

CREATE INDEX SaleColumnStoreIndex_City
ON Fact.SaleColumnStoreIndex
(
	[City Key]
)

CREATE INDEX SaleColumnStoreIndex_Date
ON Fact.SaleColumnStoreIndex
(
	[Delivery Date Key]
)

CREATE INDEX SaleColumnStoreIndex_Stock_Item_key
ON Fact.SaleColumnStoreIndex
(
	[Stock Item Key]
)

CREATE INDEX SaleColumnStoreIndex_Customer_key
ON Fact.SaleColumnStoreIndex
(
	[Customer Key]
)

CREATE INDEX SaleColumnStoreIndex_SalesPerson_Key
ON Fact.SaleColumnStoreIndex
(
	[SalesPerson Key]
)