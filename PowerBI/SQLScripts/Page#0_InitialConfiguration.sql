SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    max(CASE i.type WHEN 5 THEN si.rowcnt ELSE p.rows END) AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN      
    sysindexes si ON t.OBJECT_ID = si.id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
	and s.name = 'Dimension' or s.name = 'Fact' 
GROUP BY 
    t.Name, s.Name
ORDER BY 
    t.Name, s.Name
