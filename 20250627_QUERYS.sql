-- Crear base de datos de ejemplo
CREATE DATABASE OptimizacionWebinar;
GO
USE OptimizacionWebinar;

-- Tabla de ventas con 1 millón de registros
CREATE TABLE Ventas (
    Id INT IDENTITY PRIMARY KEY,
    FechaVenta DATE,
    ClienteId INT,
    ProductoId INT,
    Monto DECIMAL(10,2)
);

-- Insertar data aleatoria
DECLARE @i INT = 0;
WHILE @i < 1000000
BEGIN
    INSERT INTO Ventas (FechaVenta, ClienteId, ProductoId, Monto)
    VALUES (
        DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 1000), GETDATE()),
        ABS(CHECKSUM(NEWID()) % 10000),
        ABS(CHECKSUM(NEWID()) % 500),
        ROUND(RAND() * 1000, 2)
    );
    SET @i += 1;
END

/*
INSERT INTO Ventas (FechaVenta ,    ClienteId ,    ProductoId ,    Monto)
SELECT TOP 2000000 FechaVenta ,    ClienteId ,    ProductoId ,    Monto FROM Ventas
*/

SET STATISTICS TIME ON

SELECT * FROM Ventas


-- Habilitar el plan de ejecución (SSMS: Ctrl+M)
SELECT COUNT(*),SUM(Monto)--,MIN(ProductoId),MAX(ProductoId)
FROM Ventas A
WHERE ClienteId = 1234 AND FechaVenta BETWEEN '2022-01-01' AND '2024-12-31';

   --CPU time = 0 ms, elapsed time = 1 ms.
   --CPU time = 16 ms,  elapsed time = 42 ms.
   --CPU time = 967 ms,  elapsed time = 275 ms.

--Crear indice

DROP INDEX IF EXISTS IX_Ventas_Cliente_Fecha ON Ventas
CREATE NONCLUSTERED INDEX  IX_Ventas_Cliente_Fecha
ON Ventas (ClienteId, FechaVenta) --CPU time = 0 ms,  elapsed time = 4 ms.
INCLUDE (Monto); --CPU time = 0 ms,  elapsed time = 0 ms.

    --CPU time = 1718 ms,  elapsed time = 344 ms.

--Diferencia entre índice clusterizado y no clusterizado

-- Actualizar estadísticas
UPDATE STATISTICS Ventas;

-- Forzar uso de índice (en casos muy controlados)
SELECT SUM(Monto)
FROM Ventas WITH (INDEX(IX_Ventas_Cliente_Fecha))
WHERE ClienteId = 1234 AND FechaVenta BETWEEN '2022-01-01' AND '2024-12-31';

SET STATISTICS TIME ON

--Índice Columnstore Híbrido
SELECT ClienteId, SUM(Monto) AS Total
FROM Ventas
GROUP BY ClienteId;

--CPU time = 2782 ms,  elapsed time = 587 ms.

-- Crear copia de tabla para no mezclar con índices normales
CREATE TABLE Ventas_CS (
    Id INT,
    FechaVenta DATE,
    ClienteId INT,
    ProductoId INT,
    Monto DECIMAL(10,2)
);

INSERT INTO Ventas_CS
SELECT * FROM Ventas;

-- Agregar índice columnstore
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Ventas ON Ventas_CS;

--Índice Columnstore Híbrido
SELECT ProductoId, SUM(Monto) AS Total
FROM Ventas_CS
GROUP BY ProductoId;


--CPU time = 531 ms,  elapsed time = 209 ms.
--CPU time = 4188 ms,  elapsed time = 850 ms.

318.883 GB RAW
31.8 GB INDEX

318.883 MB
253.234 MB INDEX
275.641 MB INDEX (22MB)

SELECT DATEPART(YEAR,FechaVenta) Año,COUNT(*)Registros FROM Ventas
GROUP BY DATEPART(YEAR,FechaVenta)
ORDER BY 1 DESC
;


MAX 10% 


--FILTERED INDEX
CREATE NONCLUSTERED INDEX IX_Ventas_Recientes
ON Ventas (FechaVenta)
WHERE FechaVenta >= '2025-01-01';


SELECT COUNT(*),SUM(Monto)--,MIN(ProductoId),MAX(ProductoId)
FROM Ventas
WHERE FechaVenta BETWEEN '2024-01-01' AND '2024-12-31';

--CPU time = 1108 ms,  elapsed time = 231 ms.


SELECT COUNT(*),SUM(Monto)--,MIN(ProductoId),MAX(ProductoId)
FROM Ventas
WHERE FechaVenta BETWEEN '2025-01-01' AND '2025-12-31';


SELECT * FROM Ventas 
WHERE FechaVenta BETWEEN '2024-01-01' AND '2024-12-31'
AND ClienteId = 2000  --CTRL + "L" (planeamiento)
--CTRL + M -> F5


--CPU time = 952 ms,  elapsed time = 200 ms.

--LECTURA DE UN PLAN DE EJECUCCIÓN

/*
| Operador                 | ¿Qué hace?                                   | 🧠 Interpretación común                  |
| ------------------------ | -------------------------------------------- | ---------------------------------------- |
| **Table Scan**           | Lee toda la tabla                            | ⚠️ No hay índice útil, puede ser costoso |
| **Clustered Index Scan** | Recorre todo el índice clustered             | Puede estar bien si la tabla es pequeña  |
| **Index Seek**           | Búsqueda eficiente en un índice              | ✅ Ideal, buen uso de índice              |
| **Key Lookup**           | Va al índice clustered a buscar más columnas | ⚠️ Costo extra, evalúa `INCLUDE`         |
| **RID Lookup**           | Como `Key Lookup` pero sin clustered index   | ⚠️ Muy costoso, considera crear índice   |
| **Nested Loops**         | Ciclo anidado entre dos tablas               | ✅ Bueno si la tabla externa es pequeña   |
| **Hash Match**           | Unión o agregación basada en hash            | Costoso en RAM, evalúa índices           |
| **Sort**                 | Ordenamiento de datos                        | ⚠️ Evitable con índice ordenado          |
| **Compute Scalar**       | Calcula una expresión                        | Normal, bajo costo                       |
| **Filter**               | Filtra filas tras otras operaciones          | Normal, pero evalúa mover filtros antes  |
*/



SELECT 
    qs.query_id,
    qs.last_execution_time,
    qt.query_sql_text,
    p.query_plan
FROM 
    sys.query_store_query qs
JOIN 
    sys.query_store_query_text qt ON qs.query_text_id = qt.query_text_id
JOIN 
    sys.query_store_plan p ON qs.query_id = p.query_id
ORDER BY 
    qs.last_execution_time DESC;

    <ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.564" Build="16.0.1135.2"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM Ventas" StatementId="1" StatementCompId="1" StatementType="SELECT" StatementSqlHandle="0x0900EE5FE4A4CFB09EB2CEB26C7475FD7CAF0000000000000000000000000000000000000000000000000000" DatabaseContextSettingsId="1" ParentObjectId="0" StatementParameterizationType="0" RetrievedFromCache="true" StatementSubTreeCost="41.2374" StatementEstRows="1e+07" SecurityPolicyApplied="false" StatementOptmLevel="FULL" QueryHash="0xCE7889EEEA0039AF" QueryPlanHash="0xEC6BB79462856159" CardinalityEstimationModelVersion="160"><StatementSetOptions QUOTED_IDENTIFIER="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" NUMERIC_ROUNDABORT="false"></StatementSetOptions><QueryPlan CachedPlanSize="16" CompileTime="0" CompileCPU="0" CompileMemory="128"><MemoryGrantInfo SerialRequiredMemory="0" SerialDesiredMemory="0" GrantedMemory="0" MaxUsedMemory="0"></MemoryGrantInfo><OptimizerHardwareDependentProperties EstimatedAvailableMemoryGrant="104857" EstimatedPagesCached="104857" EstimatedAvailableDegreeOfParallelism="6" MaxCompileMemory="1216712"></OptimizerHardwareDependentProperties><RelOp NodeId="0" PhysicalOp="Clustered Index Scan" LogicalOp="Clustered Index Scan" EstimateRows="1e+07" EstimatedRowsRead="1e+07" EstimateIO="30.2372" EstimateCPU="11.0002" AvgRowSize="31" EstimatedTotalSubtreeCost="41.2374" TableCardinality="1e+07" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row"><OutputList><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="Id"></ColumnReference><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="FechaVenta"></ColumnReference><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="ClienteId"></ColumnReference><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="ProductoId"></ColumnReference><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="Monto"></ColumnReference></OutputList><IndexScan Ordered="0" ForcedIndex="0" ForceScan="0" NoExpandHint="0" Storage="RowStore"><DefinedValues><DefinedValue><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="Id"></ColumnReference></DefinedValue><DefinedValue><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="FechaVenta"></ColumnReference></DefinedValue><DefinedValue><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="ClienteId"></ColumnReference></DefinedValue><DefinedValue><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="ProductoId"></ColumnReference></DefinedValue><DefinedValue><ColumnReference Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Column="Monto"></ColumnReference></DefinedValue></DefinedValues><Object Database="[OptimizacionWebinar]" Schema="[dbo]" Table="[Ventas]" Index="[PK__Ventas__3214EC0707F98975]" IndexKind="Clustered" Storage="RowStore"></Object></IndexScan></RelOp></QueryPlan></StmtSimple></Statements></Batch></BatchSequence></ShowPlanXML>