--SNIPPETS
SELECT 
    s.session_id,
    r.status,
    r.cpu_time,
    t.text AS query_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
WHERE r.status = 'running';

CTRL + ALT + "T"


--UBICAR OBJETOS
SELECT b.name schema_name,a.* FROM sys.objects a
left join sys.schemas b
on a.schema_id = b.schema_id
where a.name like '%score%'

select * from DTM.PESOS_SCORE

--BUSCAR PARTE DE CÓDIGO EN OTROS OBJETOS
SELECT SCHEMA_NAME(o.SCHEMA_ID), o.Name, o.[type]
FROM sys.sql_modules m
INNER JOIN sys.objects o
    ON o.object_id = m.object_id
WHERE m.definition like '%SCORE%'
GO


sp_helptext 'dbo.codigos_tipificacion'


--**ATAJOS**
--QUERY SHORCUTS

--CONFIGURAR NUMERO DE LINEA

--CONFIGURAR COLOR SEGUN SERVIDOR

--REGISTRAR SERVIDORES PARA ACCESO RAPIDO

