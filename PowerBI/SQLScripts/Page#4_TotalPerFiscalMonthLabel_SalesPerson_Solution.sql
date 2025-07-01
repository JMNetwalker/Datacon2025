CREATE NONCLUSTERED INDEX [FACT_Sale_SalesPerson_Key]
ON [Fact].[Sale] ([Salesperson Key])

CREATE NONCLUSTERED INDEX [FACT_Sale_City_Key]
ON [Fact].[Sale] ([City Key])

CREATE NONCLUSTERED INDEX [FACT_Sale_Customer_Key]
ON [Fact].[Sale] ([Customer Key])

CREATE NONCLUSTERED INDEX [FACT_Sale_Stock_Item_key]
ON [Fact].[Sale] ([Stock Item Key])

CREATE NONCLUSTERED INDEX Dimension_Employee_ix1
    ON Dimension.Employee ([Employee Key])
    WHERE [is Salesperson] = 1;