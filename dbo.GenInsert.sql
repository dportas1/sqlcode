/*

	geninsert.sql
	Generate Insert / Merge statements for SQL Server 2005, 2008/R2, 2012, 2014, 2016

	by dportas <AT> acm DOT org
	v2.30   2016-06-25

	Generates INSERT statements or MERGE statements from data in a table
	Tested on SQL Server 2005, 2008/R2, 2012, 2014, 2016

	Public domain. No warranties.


	Parameters:

			@schemaname		Table schema name

			@objname		Table name / view name / temp table name

			@script			Syntax of script to be produced:
							I = One INSERT statement per row (default option, supported by vs.2005,2008,2012,2014,2016)
							S = Single set-based INSERT for all rows (generated script will be valid for vs.2008 + later only)
							M = Merge (MERGE with INSERT,UPDATE,DELETE clauses - generated script will be valid for vs.2008 + later only)
							U = Upsert (MERGE with INSERT,UPDATE clauses - generated script will be valid for vs.2008 + later only)

			@mergekey		Specifies an alternative set of key columns on which to perform a merge. Relevant only when @script = 'M' or 'U'
							Delimit multiple columns with a comma
							By default the merge option will use a PRIMARY KEY, UNIQUE constraint/index or IDENTITY column unless the @mergekey option is specified

			@where			Optional WHERE clause specifying the data to be included

			@identity		0 = don't include IDENTITY
							1 = include IDENTITY column (if any) in the script using the IDENTITY_INSERT option (default option)

			@rowversion		0 = don't include ROWVERSION / TIMESTAMP (default option)
							1 = include ROWVERSION / TIMESTAMP columns (as VARBINARY)

			@filestream		0 = don't include FILESTREAM (default option)
							1 = include FILESTREAM columns

			@geo			0 = script spatial values as binary (default option)
							1 = script spatial values as strings

			@page			Maximum number of rows per statement


	Examples:

			EXEC dbo.geninsert @schemaname = 'dbo', @objname = 'tbl' ;
			EXEC dbo.geninsert @schemaname = 'dbo', @objname = 'tbl', @script = 'S' ;
			EXEC dbo.geninsert @schemaname = 'dbo', @objname = 'tbl', @script = 'M', @mergekey = 'keycol' ;
			EXEC dbo.geninsert @objname = '[dbo].[Contacts]', @script = 'M';


*/

CREATE PROC [dbo].[geninsert]
(
		@schemaname NVARCHAR(128) = N'',
		@objname    NVARCHAR(128) = N'',
		@script     CHAR(1) = 'I' /* I = Inserts, S = Single Insert, M = Merge, U = Upsert */,
		@mergekey   NVARCHAR(MAX) = N'',
		@where		NVARCHAR(MAX) = N'',
		@identity   BIT = 1,
		@rowversion BIT = 0,
		@filestream BIT = 0,
		@geo        BIT = 0,
		@page       INT = 0,
		@printsql   BIT = 0 -- Print dynamic SQL for debug only
)
AS
BEGIN;
		SET NOCOUNT ON;

		DECLARE	@object_id BIGINT,
				@tmp_object_id BIGINT,
				@fullobjectname NVARCHAR(300),
				@sql NVARCHAR(MAX),
				@ColumnList NVARCHAR(MAX),
				@SetList NVARCHAR(MAX),
				@KeyList NVARCHAR(MAX),
				@startrow NVARCHAR(MAX),
				@endrow NVARCHAR(10),
				@unqindex BIGINT,
				@rowcount INT,
				@nextid INT,
				@floatstyle NCHAR(1);

		/* Init variables */
		SELECT	@sql = N'',
				@ColumnList = N'',
				@SetList = N'',
				@KeyList = N'',
				@nextid = 1,
				@identity = ISNULL(@identity,1),
				@geo = ISNULL(@geo,0),
				@rowversion = ISNULL(@rowversion,0),
				@filestream = ISNULL(@filestream,0);

		IF		CAST(SERVERPROPERTY('ProductMajorVersion') AS SMALLINT) >= 13
				/* Style 3 improves the accuracy of float-string conversion in SQL Server 2016 */
				SET @floatstyle = N'3';
		ELSE
				SET @floatstyle = N'2';

		/* object in current database */
		SET		@object_id = OBJECT_ID(QUOTENAME(@schemaname)+N'.'+QUOTENAME(@objname));

		/* object in tempdb */
		IF		@object_id IS NULL AND @objname LIKE N'#%'
		SET		@tmp_object_id = OBJECT_ID(N'[tempdb]..'+QUOTENAME(@objname));

		/* two-part name in either schema or object parameter */
		IF		@object_id IS NULL
		AND		@tmp_object_id IS NULL
		AND		(@schemaname IS NULL OR @objname IS NULL OR @schemaname = N'' OR @objname = N'')
		SET		@object_id = COALESCE(OBJECT_ID(@schemaname),OBJECT_ID(@objname));

		/* Raiserror if table was not found */
		IF		@object_id IS NULL
		AND		@tmp_object_id IS NULL
		BEGIN	;
				RAISERROR('Specified object not found',16,1);
				RETURN -1;
		END;

		/* Raiserror if script option is invalid */
		IF		@script IS NULL
		OR		@script NOT IN ('I','S','M','U')
		BEGIN	;
				RAISERROR('Invalid @script option. Specify I,S,M or U. I = Inserts, S = Single Insert, M = Merge, U = Upsert',16,1);
				RETURN -1;
		END;

		/* Specified table object_id in current db */
		IF		@object_id IS NOT NULL
		SELECT	@fullobjectname = QUOTENAME(OBJECT_SCHEMA_NAME(@object_id))+N'.'+QUOTENAME(OBJECT_NAME(@object_id)),
				@identity =
				CASE WHEN @identity = 1 AND
				(		SELECT	TOP (1) 1
						FROM	sys.identity_columns i
						WHERE	i.object_id = @object_id) =1
				THEN	1 ELSE 0 END;

		/* Specified table object_id in tempdb */
		IF		@tmp_object_id IS NOT NULL
		SELECT	@fullobjectname = QUOTENAME(@objname),
				@identity =
				CASE WHEN @identity = 1 AND
				(		SELECT	TOP (1) 1
						FROM	tempdb.sys.identity_columns i
						WHERE	i.object_id = @tmp_object_id) =1
				THEN	1 ELSE 0 END;

		/* Default page size. 1000 = max allowed for a INSERT-SELECT row-value constructor, otherwise 100000 */
		IF		ISNULL(@page,0) < 1
		SET		@page = CASE @script WHEN 'S' THEN 1000 ELSE 100000 END;

		/* Identify MERGE key */
		IF		(@script = 'M' OR @script = 'U')
		AND		ISNULL(@mergekey,N'') = N''
		BEGIN	;

				/* Script type is MERGE and no key was specified so pick a suitable index to use as a merge key */

				IF		@object_id IS NOT NULL
				SELECT	TOP (1) @unqindex = i.index_id
				FROM	sys.indexes i
				LEFT	JOIN
				( /* Don't use unique indexes that contain excluded columns */
						SELECT	DISTINCT i.index_id
						FROM	sys.index_columns i
						JOIN	sys.columns c
						ON		i.object_id = c.object_id
						AND		i.column_id = c.column_id
						JOIN	sys.types t
						ON		c.user_type_id = t.user_type_id
						LEFT	JOIN sys.types st
						ON		c.system_type_id = st.user_type_id
						WHERE	i.object_id = @object_id
						AND		((c.is_filestream = 1
						AND		@filestream = 0)
						OR		c.is_computed = 1
						OR		(c.is_identity = 1
						AND		@identity = 0)
						OR		(st.name IN (N'timestamp',N'rowversion')
						AND		@rowversion = 0)
						OR		(st.name IS NULL AND t.name  IN (N'hierarchyid',N'geography',N'geometry')))
						AND		i.is_included_column = 0
				) x
				ON		i.index_id = x.index_id
				WHERE	i.object_id = @object_id
				AND		i.is_unique = 1
				AND		x.index_id IS NULL
				ORDER	BY i.is_primary_key DESC, i.is_unique_constraint DESC, i.index_id ASC;

				IF		@tmp_object_id IS NOT NULL
				SELECT	TOP (1) @unqindex = i.index_id
				FROM	tempdb.sys.indexes i
				LEFT	JOIN
				(
						SELECT	DISTINCT i.index_id
						FROM	tempdb.sys.index_columns i
						JOIN	tempdb.sys.columns c
						ON		i.object_id = c.object_id
						AND		i.column_id = c.column_id
						JOIN	tempdb.sys.types t
						ON		c.user_type_id = t.user_type_id
						LEFT	JOIN tempdb.sys.types st
						ON		c.system_type_id = st.user_type_id
						WHERE	i.object_id = @object_id
						AND		((c.is_filestream = 1
						AND		@filestream = 0)
						OR		c.is_computed = 1
						OR		(c.is_identity = 1
						AND		@identity = 0)
						OR		(st.name IN (N'timestamp',N'rowversion')
						AND		@rowversion = 0)
						OR		(st.name IS NULL AND t.name IN (N'hierarchyid',N'geography',N'geometry')))
						AND		i.is_included_column = 0
				) x
				ON		i.index_id = x.index_id
				WHERE	i.object_id = @tmp_object_id
				AND		i.is_unique = 1
				AND		x.index_id IS NULL
				ORDER	BY i.is_primary_key DESC, i.is_unique_constraint DESC, i.index_id ASC;

				/* Raiserror if no unique index was found */
				IF		@unqindex IS NULL
				AND		@identity = 0
				BEGIN	;
						RAISERROR('MERGE requires a merge key but no unique index was found. Specify with @mergekey parameter instead.',16,1);
						RETURN -1;
				END;
		END;

		DECLARE @col TABLE
		(
				ColumnOrder SMALLINT NOT NULL PRIMARY KEY,
				ColumnName NVARCHAR(128) COLLATE DATABASE_DEFAULT NULL,
				TypeName NVARCHAR(128) COLLATE DATABASE_DEFAULT NULL,
				is_identity BIT,
				is_key BIT
		);

		IF		@object_id IS NOT NULL
		INSERT	INTO @col (ColumnName, TypeName, ColumnOrder, is_identity, is_key)
		SELECT	ColumnName, TypeName, ColumnOrder, is_identity, is_key
		FROM
		(
				/* Build column table */
				SELECT	c.name ColumnName,
						COALESCE(st.name, t.name) TypeName,
						ROW_NUMBER() OVER (ORDER BY c.column_id) ColumnOrder,
						c.is_identity,
						CASE WHEN i.column_id IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS is_key
				FROM	sys.objects o
				JOIN	sys.columns c
				ON		c.object_id = o.object_id
				JOIN	sys.types t
				ON		c.user_type_id = t.user_type_id
				LEFT	JOIN	sys.types st
				ON		c.system_type_id = st.user_type_id
				LEFT	JOIN
				(		/* MERGE key columns if required */
						SELECT	column_id
						FROM	sys.index_columns
						WHERE	object_id = @object_id
						AND		index_id = @unqindex
						AND		is_included_column = 0
				) i
				ON		c.column_id = i.column_id
				WHERE	o.object_id = @object_id
				AND		(c.is_filestream = 0
				OR		@filestream = 1)
				AND		c.is_computed = 0
				AND		(c.is_identity = 0
				OR		@identity = 1)
				AND		(ISNULL(st.name,N'') NOT IN (N'timestamp',N'rowversion')
				OR		@rowversion = 1)
				AND		(st.name IS NOT NULL
				OR		(st.name IS NULL AND t.name IN (N'hierarchyid',N'geography',N'geometry')))
		) AS t;

		IF		@tmp_object_id IS NOT NULL
		INSERT	INTO @col (ColumnName, TypeName, ColumnOrder, is_identity, is_key)
		SELECT	ColumnName, TypeName, ColumnOrder, is_identity, is_key
		FROM
		(
				/* Build column table */
				SELECT	c.name ColumnName,
						COALESCE(st.name, t.name) TypeName,
						ROW_NUMBER() OVER (ORDER BY c.column_id) ColumnOrder,
						c.is_identity,
						CASE WHEN i.column_id IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS is_key
				FROM	tempdb.sys.objects o
				JOIN	tempdb.sys.columns c
				ON		c.object_id = o.object_id
				JOIN	tempdb.sys.types t
				ON		c.user_type_id = t.user_type_id
				LEFT	JOIN	tempdb.sys.types st
				ON		c.system_type_id = st.user_type_id
				LEFT	JOIN
				(		/* MERGE key columns if required */
						SELECT	column_id
						FROM	tempdb.sys.index_columns
						WHERE	object_id = @tmp_object_id
						AND		index_id = @unqindex
						AND		is_included_column = 0
				) i
				ON		c.column_id = i.column_id
				WHERE	o.object_id = @tmp_object_id
				AND		(c.is_filestream = 0
				OR		@filestream = 1)
				AND		c.is_computed = 0
				AND		(c.is_identity = 0
				OR		@identity = 1)
				AND		(ISNULL(st.name,N'') NOT IN (N'timestamp',N'rowversion')
				OR		@rowversion = 1)
				AND		(st.name IS NOT NULL
				OR		(st.name IS NULL AND t.name IN (N'hierarchyid',N'geography',N'geometry')))
		) AS t;

		SELECT	/* Create a SELECT list that will return the actual values from the table */
				@sql = @sql + N'+'', ''+' +
								CASE
									WHEN t.TypeName IN (N'bigint',N'int',N'smallint',N'tinyint',N'numeric',N'decimal',N'money',N'smallmoney',N'bit')
										THEN N'ISNULL(CAST(' + QUOTENAME(t.ColumnName) + N' AS NVARCHAR(40)),N''NULL'')'
									WHEN t.TypeName IN (N'float',N'real')
										THEN N'ISNULL(CONVERT(NVARCHAR(40),' + QUOTENAME(t.ColumnName) + N',' + @floatstyle + N'),N''NULL'')'
									WHEN t.TypeName = N'date'
										THEN N'ISNULL(''''''''+CONVERT(NVARCHAR(10),' + QUOTENAME(t.ColumnName) + N',120)+'''''''',N''NULL'')'
									WHEN t.TypeName IN (N'datetime',N'smalldatetime')
										THEN N'ISNULL(''''''''+CONVERT(NVARCHAR(30),' + QUOTENAME(t.ColumnName) + N',126)+'''''''',N''NULL'')'
									WHEN t.TypeName = N'datetime2'
										THEN N'ISNULL(''''''''+CONVERT(NVARCHAR(30),' + QUOTENAME(t.ColumnName) + N',121)+'''''''',N''NULL'')'
									WHEN t.TypeName IN (N'geography',N'geometry') AND @geo = 0
										THEN N'ISNULL(CASE DATALENGTH(' + QUOTENAME(t.ColumnName) + N') WHEN 0 THEN CAST(N''0x'' AS NVARCHAR(MAX)) ELSE CAST( master.dbo.fn_varbintohexstr(CAST(' + QUOTENAME(t.ColumnName) + N' AS VARBINARY(MAX))) AS NVARCHAR(MAX)) END,N''NULL'')'
									WHEN t.TypeName = N'geometry' AND @geo = 1
										THEN N'ISNULL(''geometry::STGeomFromText(''''''+' + QUOTENAME(t.ColumnName) + N'.ToString()+'''''',''+ CAST(' + QUOTENAME(t.ColumnName) + N'.STSrid AS NVARCHAR(10))+ '')'',N''NULL'')'
									WHEN t.TypeName = N'geography' AND @geo = 1
										THEN N'ISNULL(''geography::STGeomFromText(''''''+' + QUOTENAME(t.ColumnName) + N'.ToString()+'''''',''+ CAST(' + QUOTENAME(t.ColumnName) + N'.STSrid AS NVARCHAR(10))+ '')'',N''NULL'')'
									WHEN t.TypeName IN (N'binary',N'varbinary',N'timestamp',N'rowversion',N'image',N'hierarchyid')
										THEN N'ISNULL(CASE DATALENGTH(' + QUOTENAME(t.ColumnName) + N') WHEN 0 THEN CAST(N''0x'' AS NVARCHAR(MAX)) ELSE CAST( master.dbo.fn_varbintohexstr(CAST(' + QUOTENAME(t.ColumnName) + N' AS VARBINARY(MAX))) AS NVARCHAR(MAX)) END,N''NULL'')'
									WHEN t.TypeName IN (N'char',N'varchar',N'text')
										THEN N'ISNULL(''''''''+REPLACE(CAST(' + QUOTENAME(t.ColumnName) + N' AS NVARCHAR(MAX)),'''''''','''''''''''')+'''''''',N''NULL'')'
									WHEN t.TypeName IN (N'nchar',N'nvarchar',N'ntext')
										THEN N'ISNULL(''N''''''+REPLACE(CAST(' + QUOTENAME(t.ColumnName) + N' AS NVARCHAR(MAX)),'''''''','''''''''''')+'''''''',N''NULL'')'
									ELSE     N'ISNULL(''''''''+REPLACE(CAST(' + QUOTENAME(t.ColumnName) + N' AS NVARCHAR(MAX)),'''''''','''''''''''')+'''''''',N''NULL'')'
								END +CHAR(10)+CHAR(13),
				@ColumnList = @ColumnList +
								CASE
									WHEN @script = 'I'
										THEN N',' + REPLACE(CAST(QUOTENAME(t.ColumnName) AS NVARCHAR(MAX)),N'''',N'''''')
									ELSE     N',' +         CAST(QUOTENAME(t.ColumnName) AS NVARCHAR(MAX))
								END,
				@SetList = @SetList +
								CASE WHEN t.is_identity = 1 THEN N''
								ELSE CHAR(13) + CHAR(10) + N',' + QUOTENAME(t.ColumnName) + N' = s.' + QUOTENAME(t.ColumnName) END,
				@KeyList = @KeyList +
								CASE
									WHEN t.is_key = 1 OR (@unqindex IS NULL AND CHARINDEX(N','+t.ColumnName+N',',N','+@mergekey+N',')>0)
										THEN CHAR(13) + CHAR(10) + N'AND t.' + QUOTENAME(t.ColumnName) + N' = s.' + QUOTENAME(t.ColumnName)
									WHEN (@script = 'M' OR @script = 'U') AND t.is_identity = 1 AND @identity = 1 AND @unqindex IS NULL AND ISNULL(@mergekey,N'') = N''
										THEN CHAR(13) + CHAR(10) + N'AND t.' + QUOTENAME(t.ColumnName) + N' = s.' + QUOTENAME(t.ColumnName)
								ELSE N'' END
		FROM	@col AS t
		ORDER	BY ColumnOrder;

		IF		@ColumnList IS NULL
		OR		@ColumnList = N''
		BEGIN	;
				RAISERROR('No valid columns in the specified table',16,1);
				RETURN -1;
		END;

		/* Tidy up the dynamic SQL delimiters */
		SET		@ColumnList = STUFF(@ColumnList,1,1,N'');
		SET		@KeyList    = STUFF(@KeyList,1,6,N' ');
		SET		@SetList    = STUFF(@SetList,1,3,N' ');

		/* INSERT was specified as the script option so the INSERT statement needs to be on every line (@startrow, @endrow) */
		IF		@script = 'I'
		BEGIN	;
				SET		@startrow = N'INSERT INTO '+@fullobjectname+N' ('+@ColumnList+N') VALUES (';
				SET		@endrow   = N');';
		END;

		/* Set-based INSERT or MERGE was specified. Rows are bracketed as row-value constructors */
		IF		@script = 'S' OR @script = 'M' OR @script = 'U'
		BEGIN	;
				SET		@startrow = N',(';
				SET		@endrow   = N')';
		END;

		SET		@sql    = STUFF(@sql,1,6,N'SELECT N'''+@startrow+N'''+') + N'+ '+QUOTENAME(@endrow,N'''') + N' COLLATE Latin1_General_BIN FROM '+@fullobjectname
		SET		@sql    = @sql + ISNULL(N' WHERE ('+ NULLIF(LTRIM(RTRIM(@where)),N'') + N')',N'');
		SET		@sql    = @sql + N';';
		
		/* Table to hold the header and trailing statements and clauses */
		DECLARE	@hdr TABLE
		(
				id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
				txt NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
				seq TINYINT NOT NULL
		);

		IF		@identity = 1
		/* If we're including an IDENTITY column then set the IDENTITY_INSERT option */
		INSERT	INTO @hdr (txt,seq) VALUES (N'SET IDENTITY_INSERT '+@fullobjectname+N' ON;',0);

		IF		@script = 'S'
		BEGIN	;
		/* Single INSERT statement */
		INSERT	INTO @hdr (txt,seq) VALUES (N'INSERT INTO '+@fullobjectname+N' ('+@ColumnList+N')',0);
		INSERT	INTO @hdr (txt,seq) VALUES (N'VALUES',0);
		END;

		IF		@script = 'M' OR @script = 'U'
		BEGIN	;
		/* MERGE statement */
		INSERT	INTO @hdr (txt,seq) VALUES (N'MERGE INTO '+@fullobjectname+N' AS t USING (',0);
		INSERT	INTO @hdr (txt,seq) VALUES (N'VALUES',0);
		END;

		/* Debug option  - print the SQL before executing it */
		IF		@printsql = 1
		BEGIN	;
		PRINT	@sql;
		END;

		/* Temp table to hold the result set */
		/* Unusual name to avoid any clash if @objname is a temp table */
		CREATE	TABLE #result_6EC1D0F69CED499B8D9A3AE6DD9C215C_
		(
				id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
				txt NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
				seq TINYINT NOT NULL DEFAULT (1)
		);

		/* Now insert the results of our dynamic SQL */
		INSERT	#result_6EC1D0F69CED499B8D9A3AE6DD9C215C_ (txt)
		EXEC	(@sql);

		SET		@rowcount = @@ROWCOUNT;

		IF		@script = 'S' OR @script = 'M' OR @script = 'U'
		/* Remove initial delimiters if this is a single INSERT or MERGE statement */
		UPDATE	#result_6EC1D0F69CED499B8D9A3AE6DD9C215C_
		SET		txt = STUFF(txt,1,1,N' ')
		WHERE	id % @page = 1
		OR		@page = 1;

		IF		@script = 'S'
		/* Add terminating semicolons if this is a single INSERT */
		UPDATE	#result_6EC1D0F69CED499B8D9A3AE6DD9C215C_
		SET		txt = txt + N';'
		WHERE	id % @page = 0
		OR		id = SCOPE_IDENTITY();

		IF		@script = 'M' OR @script = 'U'
		/* Additional clauses for MERGE */
		BEGIN	;
		INSERT	INTO @hdr (txt,seq) VALUES (N') s ('+@ColumnList+N')',2);
		INSERT	INTO @hdr (txt,seq) VALUES (N'ON '+ISNULL(@KeyList,N'/* ?? '+ISNULL(@mergekey,N'')+N' not found!! */'),2);
		INSERT	INTO @hdr (txt,seq) VALUES (N'WHEN NOT MATCHED THEN',2);
		INSERT	INTO @hdr (txt,seq) VALUES (N'INSERT ('+@ColumnList+N')',2);
		INSERT	INTO @hdr (txt,seq) VALUES (N'VALUES ('+@ColumnList+N')',2);

				IF		@SetList > N''
				BEGIN	;
				INSERT	INTO @hdr (txt,seq) VALUES (N'WHEN MATCHED THEN UPDATE SET',2);
				INSERT	INTO @hdr (txt,seq) VALUES (@SetList,2);
				END;

				IF		@script = 'M'
				AND		@page >= @rowcount
				/* Can't include the DELETE clause when paging */
				INSERT	INTO @hdr (txt,seq) VALUES (N'WHEN NOT MATCHED BY SOURCE THEN DELETE',2);

		UPDATE	@hdr
		SET		txt = txt + N';'
		WHERE	id = SCOPE_IDENTITY();

		END;

		IF		@identity = 1
		/* Turn off IDENTITY_INSERT if we need to */
		INSERT	INTO @hdr (txt,seq) VALUES (N'SET IDENTITY_INSERT '+@fullobjectname+N' OFF;',2);

		WHILE	@nextid <= @rowcount
		BEGIN	;

				/* Output the final results */
				SELECT	txt [ ]
				FROM
				(
						SELECT	seq, id, txt
						FROM	@hdr
						WHERE	seq = 0
						UNION	ALL

						SELECT	seq, id, txt
						FROM	#result_6EC1D0F69CED499B8D9A3AE6DD9C215C_
						WHERE	id >= @nextid
						AND		id <  @nextid + @page

						UNION	ALL
						SELECT	seq, id, txt
						FROM	@hdr
						WHERE	seq = 2
				) t
				ORDER	BY seq, id;

				SET		@nextid = @nextid + @page;

		END;

		/* In case of zero rows returned */
		IF		ISNULL(@rowcount,0)=0
		BEGIN	;
				IF @script = 'M'
				SELECT N'DELETE FROM ' + @fullobjectname + N';' AS [ ];

				IF @script <> 'M'
				SELECT N'/* ' + @fullobjectname + N' - 0 rows */' AS [ ];
		END;

		RETURN	0;

END