CREATE NONCLUSTERED INDEX [Fact_Sale_Invoice Date Key]
ON [Fact].[Sale] ([Invoice Date Key]) 
INCLUDE ([City Key],[Total Excluding Tax],[Total Including Tax])

update statistics Fact.Sale([_WA_Sys_00000002_05A3D694]) with fullscan
