ALTER DATABASE OptimizacionWebinar
SET QUERY_STORE = ON;
GO

ALTER DATABASE OptimizacionWebinar 
SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
GO

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


--DMVs (Dynamic Management Views)
    SELECT 
    r.session_id,
    r.status,
    r.start_time,
    t.text,
    r.cpu_time,
    r.logical_reads
FROM 
    sys.dm_exec_requests r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) t
WHERE 
    r.session_id <> @@SPID;


--ULTIMAS 100 CONSULTAS
SELECT TOP 100
    s.creation_time,
    s.last_execution_time,
    r.status,
    r.start_time,
    t.text AS query_text,
    s.execution_count,
    s.total_elapsed_time / s.execution_count AS avg_elapsed_time_ms,
    s.total_worker_time / s.execution_count AS avg_cpu_time_ms,
    s.total_logical_reads / s.execution_count AS avg_logical_reads,
    qp.query_plan
FROM 
    sys.dm_exec_query_stats s
CROSS APPLY 
    sys.dm_exec_sql_text(s.sql_handle) t
CROSS APPLY 
    sys.dm_exec_query_plan(s.plan_handle) qp
LEFT JOIN 
    sys.dm_exec_requests r ON s.plan_handle = r.plan_handle
ORDER BY 
    s.last_execution_time DESC;

    /*
| Columna                 | Descripción                                 |
| ----------------------- | ------------------------------------------- |
| `creation_time`         | Cuándo se compiló el plan por primera vez   |
| `last_execution_time`   | Última vez que se ejecutó la consulta       |
| `status` / `start_time` | Si sigue en ejecución (de ser el caso)      |
| `query_text`            | Texto SQL de la consulta                    |
| `avg_elapsed_time_ms`   | Tiempo promedio de ejecución (milisegundos) |
| `avg_cpu_time_ms`       | CPU promedio usada por ejecución            |
| `avg_logical_reads`     | Lecturas lógicas promedio                   |
| `query_plan`            | Plan de ejecución XML                       |
*/


