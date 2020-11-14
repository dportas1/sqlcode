/*
	genpassword.sql   v2.0
	Generates random passwords - MS SQL Server 2016

	Public domain. No warranties.

	Parameters:

	@size       Total number of characters required
	@lc         Minimum number of lower-case letters required (zero means no lower-case)
	@uc         Minimum number of upper-case letters required (zero means no upper-case)
	@num        Minimum number of numeric digits required (zero means no numbers)
	@sym        Minimum number of symbol characters required (zero means no symbols)
	@pwd        Output parameter for generated password
	@symset     Set of (non-alpha, non-numeric) symbols
	@leetsafe   excludes l,O,0

*/
CREATE OR ALTER PROCEDURE dbo.genpassword
(
	@size     INT = NULL,
	@lc       TINYINT = NULL,
	@uc       TINYINT = NULL,
	@num      TINYINT = NULL,
	@sym      TINYINT = NULL,
	@pwd      NVARCHAR(256) = NULL OUT,
	@symset   NVARCHAR(256) = NULL,
	@leetsafe BIT = 1
)
AS
BEGIN;

	DECLARE @charset NVARCHAR(128),
			@lcchar NVARCHAR(128),
			@ucchar NVARCHAR(128),
			@numchar NVARCHAR(128),
			@symchar NVARCHAR(128),
			@sympat NVARCHAR(256),
			@try SMALLINT,
			@randbin VARBINARY(256),
			@charsetlength TINYINT,
			@charsetoffset TINYINT,
			@seed VARBINARY(256);

	SELECT	@size   = CASE WHEN @size > 256 THEN 256 WHEN @size > 0 THEN @size ELSE 8 END,
			@lc     = COALESCE(@lc,0),
			@uc     = COALESCE(@uc,0),
			@num    = COALESCE(@num,0),
			@sym    = COALESCE(@sym,0),
			@sympat = N'',
			/* If no complexity requirements specified then default to lower-case only */
			@lc     = CASE WHEN @lc + @uc + @num + @sym = 0 THEN 1 ELSE @lc END;

			/* Set the upper-case, lower-case, numeric and symbol character sets */

			IF @leetsafe = 1 OR @leetsafe IS NULL
			BEGIN;
				SELECT
				@ucchar  = N'ABCDEFGHIJKLMNPQRSTUVWXYZ', /* excludes O to avoid confusion with zero */
				@lcchar  = N'abcdefghijkmnopqrstuvwxyz', /* excludes l to avoid confusion with one */
				@numchar = N'123456789', /* excludes zero */
				@symchar = CASE WHEN @symset>N'' THEN @symset ELSE N'-,;+%&!.' END;
			END;

			IF @leetsafe = 0
			BEGIN;
				SELECT
				@ucchar  = N'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
				@lcchar  = N'abcdefghijklmnopqrstuvwxyz',
				@numchar = N'0123456789',
				@symchar = CASE WHEN @symset>N'' THEN @symset ELSE N'-,;+%&!.' END;
			END;
			
			/* Add escape characters to the symbol pattern*/
			WHILE LEN(@sympat)<LEN(@symchar)*2
				SET @sympat = @sympat+N'x'+SUBSTRING(@symchar,(LEN(@sympat)/2)+1,1)

			/* Now define the composite character set we are actually going to use */
			SELECT @charset =
			  CASE WHEN @lc  > 0 THEN @lcchar  ELSE N'' END
			+ CASE WHEN @uc  > 0 THEN @ucchar  ELSE N'' END
			+ CASE WHEN @num > 0 THEN @numchar ELSE N'' END
			+ CASE WHEN @sym > 0 THEN @symchar ELSE N'' END,

			@charsetlength = LEN(@charset),
			@pwd = '',
			@try = 0;

	WHILE @pwd = '' AND @try < 900 /* Loop: try upto 900 times to get a good password */
	BEGIN;

		SET @try = @try + 1;

		SET @seed =
			 CAST(HASHBYTES('SHA2_512',CAST(NEWID() AS VARBINARY(16))) AS VARBINARY(64))
			+CAST(HASHBYTES('SHA2_512',CAST(NEWID() AS VARBINARY(16))) AS VARBINARY(64))
			+CAST(HASHBYTES('SHA2_512',CAST(NEWID() AS VARBINARY(16))) AS VARBINARY(64))
			+CAST(HASHBYTES('SHA2_512',CAST(NEWID() AS VARBINARY(16))) AS VARBINARY(64));

		/* Generate random binary */
		SET	@randbin = CRYPT_GEN_RANDOM(@size,@seed);

		/* Convert the binary to a password based on the required character set */
		WHILE @charsetlength > 0 AND LEN(@pwd) < @size /* repeat until we reach the required size */
			SET @pwd = @pwd
						+ SUBSTRING(@charset
						  , CAST(SUBSTRING(@randbin,LEN(@pwd)+1,1) % @charsetlength + 1 AS INT),1);

		/* Check if the password meets complexity requirements. If not then set to '' so we can try again */
		IF NOT ( @pwd LIKE REPLICATE(N'%['+@lcchar+N']',@lc)+N'%' COLLATE Latin1_General_CS_AS
				AND @pwd LIKE REPLICATE(N'%['+@ucchar+N']',@uc)+N'%' COLLATE Latin1_General_CS_AS
				AND @pwd LIKE REPLICATE(N'%['+@numchar+N']',@num)+N'%' COLLATE Latin1_General_CS_AS
				AND @pwd LIKE REPLICATE(N'%['+@sympat+']',@sym)+N'%' COLLATE Latin1_General_CS_AS
									ESCAPE N'x' COLLATE Latin1_General_CS_AS)
			SET @pwd = N'';
	END;

	PRINT @pwd;

END;

GO

/* Generate some passwords */
DECLARE @pass VARCHAR(MAX);
EXEC GenPassword @size=10, @lc=1, @uc=1, @num=1, @sym=1, @leetsafe = 1;

GO 100