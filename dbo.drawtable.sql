/*

	drawtable.sql

	Draws a tabular, fixed-width representation of a query result
	Public domain. No warranties.

	Parameters:

		@qry        NVARCHAR(MAX)   Query string
		@width      SMALLINT        Width of display (default 100)
		@drawchar   NCHAR(5)        Table borders character set (default: "-|+|+")
		@topborder  BIT             Include top /bottom border? 1=yes(default), 0=no
		@padding    TINYINT         Number of extra spaces on the right of each column (default 0)

	Examples:

		(use Results to Text option)

		EXEC drawtable
			@qry='SELECT TOP (2) 1234 AS x, name FROM sys.types;';

		+----+------+
		|x   |name  |
		+----+------+
		|1234|bigint|
		|1234|binary|
		+----+------+

		EXEC drawtable
			@qry='SELECT 1 AS col1, NULL AS col2;',
			@drawchar = '=  ',
			@topborder = 0;

		col1 col2
		==== ====
		1    NULL

		EXEC drawtable
			@qry='SELECT TOP 5 ProductID, ProductNumber, Name
					FROM AdventureWorks.Production.Product',
			@width = 41;

		+---------+-------------+---------------+
		|ProductID|ProductNumber|Name           |
		+---------+-------------+---------------+
		|1        |AR-5381      |Adjustable Race|
		|2        |BA-8327      |Bearing Ball   |
		|3        |BE-2349      |BB Ball Bearing|
		|4        |BE-2908      |Headset Ball Be|
		|316      |BL-2036      |Blade          |
		+---------+-------------+---------------+

*/

CREATE OR ALTER PROC [dbo].[drawtable]
(
		@qry NVARCHAR(MAX) = N'SELECT ''Please specify a query'' [@qry];',
		@width SMALLINT = NULL,
		@drawchar NCHAR(5) = '-|+|+',
		@topborder BIT = 1,
		@padding TINYINT = 0,
		@printsql BIT = 0,
		@execsql BIT = 1
)
AS
BEGIN TRY;

		SET NOCOUNT ON;

		DECLARE	@Sql NVARCHAR(MAX),
				@ColumnList NVARCHAR(MAX),
				@ColCount SMALLINT,
				@TableWidth SMALLINT,
				@Adjust FLOAT,
				@RowCount SMALLINT,
				@ob NVARCHAR(1),
				@ox NVARCHAR(1),
				@err nvarchar(4000);

		IF @drawchar = N'MS' -- MSSQL text results style
			SELECT @drawchar = N'-'
				, @topborder = 0
				, @padding = 0;

		SET @width =
			CASE
				WHEN @width IS NULL THEN 100
				WHEN @width <1 THEN 32767
				ELSE @width
			END;

		SET @ob = LTRIM(SUBSTRING(@drawchar,4,1)); -- outside border |
		SET @ox = LTRIM(SUBSTRING(@drawchar,5,1)); -- outside border +

		IF LEN(@ob)<>LEN(@ox) -- Must be the same size
			SELECT @ox = COALESCE(NULLIF(@ob,''),NULLIF(@ox,''))
				,  @ob = COALESCE(NULLIF(@ob,''),NULLIF(@ox,''));

		CREATE TABLE #unpivoted
		(rownum SMALLINT NOT NULL, colnum VARCHAR(4) NOT NULL, txt NVARCHAR(255) NOT NULL, isanull BIT NOT NULL
		, PRIMARY KEY (rownum, colnum));

		/* Retrieve metadata for the specified query */
		SELECT	colname, colorder
				, CAST(colorder AS VARCHAR(4)) AS colnum
				, CAST(0 AS SMALLINT) AS colwidth
				, LEN(colname)+@padding AS minwidth
				, coltype
				, CASE WHEN    coltype LIKE N'varchar(%)'
							OR coltype LIKE N'nvarchar(%)'
							OR coltype LIKE N'char(%)'
							OR coltype LIKE N'nchar(%)'
					THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS willtrunc
				, error_number
				, error_message
		INTO	#columns
		FROM
		(		SELECT COALESCE(LEFT(c.name,50),'') AS colname
				, c.system_type_name AS coltype
				, ROW_NUMBER() OVER (ORDER BY c.column_ordinal) AS colorder
				, error_number
				, error_message
				FROM sys.dm_exec_describe_first_result_set(@qry,null,0) AS c
		) AS t;

		SET @ColCount = @@ROWCOUNT;
		SET @ColumnList = (SELECT STRING_AGG(QUOTENAME(colnum),',') FROM #columns);

		IF EXISTS (SELECT 1 FROM #columns WHERE error_number IS NOT NULL)
		BEGIN;
			/* Something wrong with the query */
			SET @err = (SELECT TOP 1 CONCAT('Error ',error_number,' ',error_message) FROM #columns);
			PRINT @err;
			RETURN -1;
		END;

		/* Unpivot the output of the specified query */
		SET @Sql = N'WITH n AS
			(SELECT value AS v, CAST(NULL AS nvarchar(MAX)) AS x
			 FROM STRING_SPLIT(''@@ColumnList'' , '',''))

			-- create an empty table with nvarchar(MAX) columns
			SELECT TOP (0) IDENTITY(SMALLINT) AS rownum, *
			INTO #sample
			FROM n PIVOT (MAX(x) FOR v IN (@@ColumnList)) AS p;

			-- implicit conversion to nvarchar(MAX)
			INSERT TOP (1000) INTO #sample (@@ColumnList) @@Query;
			SET @RowCount = @@ROWCOUNT;

			INSERT INTO #unpivoted (rownum, txt, colnum, isanull)
			SELECT rownum, RIGHT(RTRIM(txt),255), colnum, 0
			FROM #sample UNPIVOT (txt FOR colnum IN (@@ColumnList)) p;';

		SET @Sql = REPLACE(REPLACE(@Sql,'@@ColumnList',@ColumnList),'@@Query',@qry);

		/* Debug option  - print the SQL before executing it */
		IF @printsql = 1
		BEGIN;
		PRINT	@Sql;
		END;

		/* Do the unpivot */
		EXEC sp_executesql	@Sql, N'@RowCount INT OUT', @RowCount OUT;
		/* @RowCount returns the number of rows output by the original query */

		/* Fix datetime/smalldatetime formatting
		   Implicit conversion of these types is locale-specific and truncates the fractional seconds
		   Convert to datetime2 format instead */
		WITH d AS 
		(
		  SELECT txt, TRY_CAST(txt AS datetime2(0)) AS dt2
		  FROM #unpivoted AS u
		  JOIN #columns AS c
		  ON u.colnum = c.colnum AND c.coltype IN (N'datetime',N'smalldatetime')
		)
		UPDATE d SET txt = dt2 WHERE dt2 IS NOT NULL;

		/* Recreate any null cells, which otherwise get left out by unpivot */
		IF @RowCount > 0
			WITH r AS
			(
			  SELECT 1 AS rownum
			  UNION ALL
			  SELECT rownum + 1
			  FROM r
			  WHERE rownum < @RowCount
			)
			INSERT INTO #unpivoted (rownum, colnum, txt, isanull)
			SELECT r.rownum, c.colnum, N'NULL', 1
			FROM r, #columns AS c
			WHERE NOT EXISTS
					(	SELECT *
						FROM #unpivoted AS ux
						WHERE r.rownum = ux.rownum
						AND   c.colnum = ux.colnum )
			OPTION (MAXRECURSION 1000);

		/* Set the column widths based on the size of the data */
		WITH co AS
		(SELECT colwidth, minwidth, colname
			,(	SELECT MAX(LEN(u.txt))
				FROM #unpivoted AS u
				WHERE u.colnum = t.colnum) AS Widest
			,(	SELECT TOP (1) 1
				FROM #unpivoted AS u
				WHERE u.colnum = t.colnum
				AND u.isanull=1) AS HasNulls
			FROM #columns AS t),
		c AS
		(SELECT colwidth, minwidth, colname, Widest,
			CASE WHEN minwidth < 4+@padding AND HasNulls = 1
			THEN 4+@padding
			ELSE minwidth END AS newmin
			FROM co)
		UPDATE c SET
			minwidth = newmin,
			colwidth = CASE WHEN Widest+@padding > newmin
							THEN Widest+@padding
							ELSE newmin END;

		SET @TableWidth = (SELECT SUM(colwidth)+@ColCount-1+LEN(@ob)*2 FROM #columns);

		WHILE @TableWidth > @width
		/* The table is too wide so reduce the size of any truncatable columns */
		BEGIN;

			/* Calculate how much adjustment is needed */
			SET @Adjust = (@TableWidth - @width)/
				CAST((SELECT SUM(colwidth-minwidth)
					FROM #columns
					WHERE willtrunc = 1
					AND colwidth > minwidth
					) AS float);

			/* Apply the adjustment
			   The point of using TOP is to avoid over-truncation where @Adjust is < 1 */
			WITH t AS
				(SELECT TOP (@TableWidth - @width) colname, colwidth, minwidth,
					CAST((colwidth-minwidth) * @Adjust AS INT) AS AdjLength
				FROM #columns
					WHERE willtrunc = 1
					AND colwidth>minwidth
				)
			UPDATE t
				SET colwidth =
					CASE
						WHEN AdjLength <= 0 THEN colwidth - 1
						WHEN colwidth - AdjLength <= minwidth THEN minwidth
						ELSE colwidth - AdjLength
					END;

			IF @@ROWCOUNT = 0
			/* Nothing more to do */
				BREAK;

			SET @TableWidth = (SELECT SUM(colwidth)+@ColCount-1+LEN(@ob)*2 FROM #columns);
		END;

		/* Insert top and bottom borders and column names */
		INSERT INTO #unpivoted (rownum, txt, colnum, isanull)
		SELECT t.rownum, REPLICATE(SUBSTRING(@drawchar,1,1),colwidth), colnum, 0
		FROM #columns, (VALUES (-2),(0),(9999)) AS t(rownum)
		WHERE @topborder = 1 OR rownum = 0
		UNION ALL
		SELECT -1, COALESCE(colname,''), colnum, 0
		FROM #columns;

		/* Pivot the data into a single-column table */
		SET @Sql = N'WITH u AS
			(SELECT CONCAT(
				CASE WHEN c.colorder = 1 THEN
					CASE WHEN u.rownum IN (0,-2,9999) THEN ''@@ox'' ELSE ''@@ob'' END
					ELSE '''' END
				, LEFT(u.txt,c.colwidth)
				, REPLICATE(CHAR(32),c.colwidth-LEN(u.txt))
				, CASE WHEN c.colorder = @@ColCount THEN
					CASE WHEN u.rownum IN (0,-2,9999) THEN ''@@ox'' ELSE ''@@ob'' END
					ELSE
					CASE WHEN u.rownum IN (0,-2,9999) THEN ''@@+'' ELSE ''@@|'' END
					END
				) AS txt, u.rownum, u.colnum
			FROM #unpivoted AS u
			JOIN #columns AS c
			ON u.colnum = c.colnum
			)
			SELECT CONCAT(@@ColumnList, N'''') AS [ ]
			FROM u PIVOT (MAX(u.txt) FOR colnum IN
				(@@ColumnList)) p
			ORDER BY rownum; ';

		SET @Sql = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Sql,'@@ColCount',@ColCount),'@@ob',@ob),'@@ox',@ox),'@@-',SUBSTRING(@drawchar,1,1)),'@@|',SUBSTRING(@drawchar,2,1)),'@@+',SUBSTRING(@drawchar,3,1)),'@@ColumnList',@ColumnList);

		/* Debug option  - print the SQL before executing it */
		IF @printsql = 1
		BEGIN;
		PRINT	@Sql;
		END;

		/* Do the pivot */
		IF @execsql = 1
		BEGIN	;
		EXEC	(@Sql);
		END		;

		RETURN	0;

END TRY
BEGIN CATCH;

		DECLARE	@errmsg NVARCHAR(4000),
				@errsev INT;

		SELECT	@errmsg = ERROR_MESSAGE(),
				@errsev = ERROR_SEVERITY();

		RAISERROR(@errmsg, @errsev, 1);

		RETURN -1;

END CATCH;
