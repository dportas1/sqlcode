/*

	DatabaseStaticAnalysis01.sql
	Some simple static analysis queries for Microsoft SQL Server (2005, 2008, 2012)

	by dportas @ acm.org
	v1.02 2011-05-14

	These queries perform some very basic checks for commonly encountered problems in SQL Server table designs and index implementation.
	Each query identifies a different type of issue - no rows returned = no problem found.

	Public domain. No warranty given or implied.

*/

DECLARE	@TableName NVARCHAR(128);
SET		@TableName = N'%'; -- Table name mask

-- [Q1] No index
-- This query identifies tables without any indexes at all. Every table ought to have at least one index
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'no index' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
		(	SELECT	*
			FROM	sys.indexes i
			WHERE	i.object_id = o.object_id AND type>0)
ORDER	BY SchemaName, TableName;

-- [Q2] No unique index
-- Returns tables without a unique index. No unique index means no keys, no way to guarantee uniqueness
-- and/or potentially sub-obtimal query plans (if a theoretically unique index wasn't declared as such)
-- Tables without an index at all (already reported by [Q1]) are excluded.
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'no unique index' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
		(	SELECT	*
			FROM	sys.indexes i
			WHERE	i.object_id = o.object_id
			AND		i.is_unique = 1)
EXCEPT
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'no unique index' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
		(	SELECT	*
			FROM	sys.indexes i
			WHERE	i.object_id = o.object_id
			AND		i.type>0)
ORDER	BY SchemaName, TableName;

-- [Q3] No clustered index
-- This query returns any heap tables - tables without a clustered index.
-- As a general rule tables should be clustered unless there's a good reason to make them heaps.
-- Tables without an index at all (already reported by [Q1]) are excluded.
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'no clustered index' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
		(	SELECT *
			FROM	sys.indexes i
			WHERE	i.object_id = o.object_id
			AND		i.type=1)
EXCEPT
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'no clustered index' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
		(	SELECT	*
			FROM	sys.indexes i
			WHERE	i.object_id = o.object_id
			AND		i.type>0)
ORDER	BY SchemaName, TableName;

-- [Q4] Unique index on IDENTITY only
-- Identifies tables whose only unique index is on an IDENTITY column.
-- IDENTITY is typically (though not always) reserved for surrogate keys, in which case there should generally exist some
-- alternate key (the domain/natural key) for that table as well. Not necessarily an absolute rule but definitely worth a
-- second look if a table has no key other than an IDENTITY column.
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'unique index on identity only' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
(
SELECT	1
FROM	sys.indexes i
JOIN	sys.index_columns ic
ON		i.object_id = ic.object_id
AND		i.index_id = ic.index_id
JOIN	sys.columns c
ON		ic.object_id = c.object_id
AND		ic.column_id = c.column_id
WHERE	i.is_unique=1 AND i.object_id = o.object_id
GROUP	BY i.object_id, i.index_id
HAVING	MAX(CASE c.is_identity WHEN 1 THEN 1 ELSE 0 END)=0
)
EXCEPT
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, N'unique index on identity only' txt
FROM	sys.objects o WHERE type = N'U' AND o.name LIKE @TableName AND NOT EXISTS
		(	SELECT *
			FROM sys.indexes i
			WHERE i.object_id = o.object_id
			AND i.is_unique = 1)
ORDER	BY SchemaName, TableName;


-- [Q5] IDENTITY without unique index
-- Usually an IDENTITY column is supposed to be a key, or sometimes part of a key. The IDENTITY property on its own does not
-- guarantee uniqueness. This query checks for potentially non-unique IDENTITY columns, i.e. those without a unique index.
SELECT	SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, i.name ColumnName, N'IDENTITY without unique index' txt
FROM	sys.objects o
JOIN	sys.identity_columns i
ON		o.object_id = i.object_id
AND		o.name LIKE @TableName
WHERE	o.type = N'U' AND NOT EXISTS
(
SELECT	1
FROM	sys.indexes i
JOIN	sys.index_columns ic
ON		i.object_id = ic.object_id
AND		i.index_id = ic.index_id
JOIN	sys.columns c
ON		ic.object_id = c.object_id
AND		ic.column_id = c.column_id
WHERE	i.is_unique=1 AND i.object_id = o.object_id
GROUP	BY i.object_id, i.index_id
HAVING	COUNT(NULLIF(c.is_identity,0))=1
);

-- [Q6] Nullable unique index
-- Returns the name of any unique index containing a nullable column.
-- Nullable "unique" indexes are not often a wise implementation choice. Their behaviour and interpretation is highly
-- inconsistent between different software and tools and is frequently misunderstood by users and developers alike.
-- Very commonly nullable unique indexes are created in error - the unique index being added without anyone noticing a
-- nullable column.
-- Definitely worth reviewing any cases returned by this query.
SELECT	DISTINCT SCHEMA_NAME(MAX(o.schema_id)) SchemaName, MAX(o.name) TableName, MAX(i.name) IndexName, N'nullable unique index' txt
FROM	sys.objects o
JOIN	sys.indexes i
ON		o.object_id = i.object_id
JOIN	sys.index_columns ic
ON		i.object_id = ic.object_id
AND		i.index_id = ic.index_id
JOIN	sys.columns c
ON		ic.object_id = c.object_id
AND		ic.column_id = c.column_id
WHERE	o.type = N'U' AND o.name LIKE @TableName AND i.is_unique=1
GROUP	BY o.object_id, i.index_id
HAVING	MAX(CASE is_nullable WHEN 1 THEN 1 ELSE 0 END)=1;

-- [Q7] Nullable foreign keys
-- Returns any foreign key constraint that includes a nullable column.
-- Similar remarks apply here as to Q6.
SELECT	SCHEMA_NAME(MAX(o.schema_id)) SchemaName, o.name TableName,
		OBJECT_NAME(fkc.constraint_object_id) ConstraintName,
		MIN(CASE WHEN c.is_nullable = 1 THEN c.name END) ColumnName,
		N'nullable foreign key' txt
FROM	sys.foreign_key_columns fkc
JOIN	sys.columns c
ON		fkc.parent_object_id = c.object_id
AND		fkc.parent_column_id = c.column_id
JOIN	sys.objects o
ON		o.object_id = fkc.parent_object_id
AND		o.name LIKE @TableName
AND		c.is_nullable = 1
GROUP	BY o.schema_id, o.name, fkc.constraint_object_id;

-- [Q8] Unindexed foreign keys
-- Foreign keys are usually a good candidate for indexes. This query returns the name of any foreign key constraint that
-- doesn't have a matching index.
SELECT	SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName,
		OBJECT_NAME(fkc.constraint_object_id) ConstraintName,
		MIN(CASE WHEN ic.object_id IS NULL THEN c.name END) ColumnName,
		N'unindexed foreign key' txt
FROM	sys.foreign_key_columns fkc
JOIN	sys.objects o
ON		fkc.parent_object_id = o.object_id
JOIN	sys.columns c
ON		fkc.parent_object_id = c.object_id
AND		fkc.parent_column_id = c.column_id
LEFT	JOIN sys.index_columns ic
ON		fkc.parent_object_id = ic.object_id
AND		fkc.parent_column_id = ic.column_id
WHERE	o.name LIKE @TableName
GROUP	BY o.schema_id, o.name, fkc.constraint_object_id
HAVING	COUNT(ic.object_id)<COUNT(*);

-- [Q9] Untrusted constraints
-- Looks for constraints marked as untrusted meaning they may have been violated and won't be considered by the optimiser.
-- The fix is to re-evaluate them using the WITH CHECK clause, e.g.: ALTER TABLE tablename WITH CHECK CHECK CONSTRAINT ALL;
SELECT	DISTINCT SCHEMA_NAME(o.schema_id) SchemaName, o.name TableName, c.name ConstraintName, N'untrusted constraint' txt
FROM	sys.objects c
JOIN	sys.objects o
ON		c.parent_object_id = o.object_id
WHERE	OBJECTPROPERTY(c.object_id,'CnstIsNotTrusted')=1
AND		o.name LIKE @TableName;

-- [Q10] System-named constraints
-- It's good practice to specify a name for every constraint (including defaults, which in SQL Server terms are known
-- as "constraints"). This query attempts to spot constraints that have no user-defined name. The query doesn't rely
-- only on the is_system_named property because if constraints have been scripted and recreated then that property may
-- not be retained.
SELECT	SchemaName, TableName, ConstraintName, N'system-named constraint' txt
FROM
(
SELECT	s.name SchemaName, o.name TableName, c.name ConstraintName
FROM	sys.key_constraints c
JOIN	sys.objects o
ON		c.parent_object_id = o.object_id
JOIN	sys.schemas s
ON		o.schema_id = s.schema_id
WHERE	c.is_system_named = 1 OR LEFT(RIGHT(c.name,10),2)=N'__' AND RIGHT(c.name,8) LIKE N'%[0123456789]%[0123456789]%'
UNION
SELECT	s.name SchemaName, o.name TableName, c.name ConstraintName
FROM	sys.default_constraints c
JOIN	sys.objects o
ON		c.parent_object_id = o.object_id
JOIN	sys.schemas s
ON		o.schema_id = s.schema_id
WHERE	c.is_system_named = 1 OR LEFT(RIGHT(c.name,10),2)=N'__' AND RIGHT(c.name,8) LIKE N'%[0123456789]%[0123456789]%'
UNION
SELECT	s.name SchemaName, o.name TableName, c.name ConstraintName
FROM	sys.foreign_keys c
JOIN	sys.objects o
ON		c.parent_object_id = o.object_id
JOIN	sys.schemas s
ON		o.schema_id = s.schema_id
WHERE	c.is_system_named = 1 OR LEFT(RIGHT(c.name,10),2)=N'__' AND RIGHT(c.name,8) LIKE N'%[0123456789]%[0123456789]%'
UNION
SELECT	s.name SchemaName, o.name TableName, c.name ConstraintName
FROM	sys.check_constraints c
JOIN	sys.objects o
ON		c.parent_object_id = o.object_id
JOIN	sys.schemas s
ON		o.schema_id = s.schema_id
WHERE	c.is_system_named = 1 OR LEFT(RIGHT(c.name,10),2)=N'__' AND RIGHT(c.name,8) LIKE N'%[0123456789]%[0123456789]%'
) c
WHERE	c.TableName LIKE @TableName
ORDER	BY SchemaName, TableName, ConstraintName;

-- [Q11] Inconsistent names / types
-- This query is based on the assumption that a column of any given name represents the same attribute in any table.
-- The query looks for columns with the same name but different datatypes in different tables - possible indication
-- that the naming isn't consistent or that the wrong type was used.
SELECT	s.name AS SchemaName,
		o.name AS TableName,
		c.name AS ColumnName,
		t.name AS TypeName,
		c.max_length AS MaxLength,
		c.precision,
		c.scale,
		'inconsistent name / type' AS txt
FROM	sys.objects o
JOIN	sys.schemas s
ON		o.schema_id = s.schema_id
JOIN	sys.columns c
ON		o.object_id = c.object_id
JOIN	sys.types t
ON		c.user_type_id = t.user_type_id
WHERE	OBJECTPROPERTY(o.object_id,'IsUserTable')=1
AND		c.name IN
(
		SELECT	name
		FROM
		(
			SELECT DISTINCT c.name, t.name typename, c.max_length, c.precision, c.scale
			FROM   sys.columns c
			JOIN   sys.types t
			ON		c.user_type_id = t.user_type_id
			WHERE  OBJECTPROPERTY(c.object_id,'IsUserTable')=1
		) t
		GROUP	BY name
		HAVING	COUNT(*)>1
)
AND		o.name LIKE @TableName
ORDER	BY ColumnName, SchemaName, TableName;