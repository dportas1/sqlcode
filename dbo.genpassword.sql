/*
	genpassword.sql
	Generates random passwords - MS SQL Server 2016

	Public domain. No warranties.

	Parameters:

	@size	Total number of characters required
	@lc		Minimum number of lower-case letters required (zero means no lower-case)
	@uc		Minimum number of upper-case letters required (zero means no upper-case)
	@num	Minimum number of numeric digits required (zero means no numbers)
	@sym	Minimum number of symbol characters required (zero means no symbols)
	@pwd	Output parameter for generated password

*/
CREATE OR ALTER PROCEDURE dbo.genpassword
(
	@size INT = NULL,
	@lc   TINYINT = NULL,
	@uc   TINYINT = NULL,
	@num  TINYINT = NULL,
	@sym  TINYINT = NULL,
	@pwd  NVARCHAR(MAX) = NULL OUT
)
AS
BEGIN;

	DECLARE @charset NVARCHAR(128),
			@lcchar NVARCHAR(128),
			@ucchar NVARCHAR(128),
			@numchar NVARCHAR(128),
			@symchar NVARCHAR(128),
			@try TINYINT,
			@seednum BIGINT,
			@charsetlength TINYINT,
			@charsetoffset TINYINT;

	SELECT	@size = CASE WHEN @size > 0 THEN @size ELSE 8 END,
			@lc   = COALESCE(@lc,0),
			@uc   = COALESCE(@uc,0),
			@num  = COALESCE(@num,0),
			@sym  = COALESCE(@sym,0),
			/* If no complexity requirements specified then default to lower-case only */
			@lc   = CASE WHEN @lc + @uc + @num + @sym = 0 THEN 1 ELSE @lc END,

			/* Set the upper-case, lower-case, numeric and symbol character sets */
			@ucchar  = N'ABCDEFGHIJKLMNPQRSTUVWXYZ', /* excludes O to avoid confusion with zero */
			@lcchar  = N'abcdefghijklmnopqrstuvwxyz',
			@numchar = N'123456789', /* excludes zero */
			@symchar = N'-,;+$!',
			
			@charset =
			  CASE WHEN @lc  > 0 THEN @lcchar  ELSE N'' END
			+ CASE WHEN @uc  > 0 THEN @ucchar  ELSE N'' END
			+ CASE WHEN @num > 0 THEN @numchar ELSE N'' END
			+ CASE WHEN @sym > 0 THEN @symchar ELSE N'' END,

			@charsetlength = LEN(@charset),
			@pwd = N'',
			@try = 0;

	WHILE @pwd = N'' AND @try < 100 /* Loop: try upto 100 times to get a good password */
	BEGIN;

		SET @try = @try + 1;

		WHILE @charsetlength > 1 AND LEN(@pwd) < @size /* repeat until we reach the required size */
		BEGIN;

			SELECT	/* Mix the character set a little */
					@charsetoffset = @charsetlength-ABS(CHECKSUM(NEWID()))%(@charsetlength/2),
					@charset = SUBSTRING(@charset,@charsetoffset+1,@charsetlength)
								+LEFT(@charset,@charsetoffset),
					/* Generate a random number */
					@seednum = RIGHT('9023716854923716854'
										+REPLACE(REPLACE(CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(40))
										+CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(40))
										+CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(40))
										+CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(40))
										+CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(40)),' ',''),'.','')
									,18);

					/* Turn the random number into a password string*/
			WHILE	@seednum > 0
					SELECT	@pwd = SUBSTRING(@charset, @seednum % @charsetlength + 1,1) + COALESCE(@pwd,N''),
							@seednum = @seednum / @charsetlength;

		END;

		SET @pwd = LEFT(@pwd,@size);

		/* Check if the password meets complexity requirements. If not then set to '' so we can try again */
		IF NOT ( @pwd LIKE REPLICATE(N'%['+@lcchar+N']',@lc)+N'%' COLLATE Latin1_General_CS_AS
				AND @pwd LIKE REPLICATE(N'%['+@ucchar+N']',@uc)+N'%' COLLATE Latin1_General_CS_AS
				AND @pwd LIKE REPLICATE(N'%['+@numchar+N']',@num)+N'%' COLLATE Latin1_General_CS_AS
				AND @pwd LIKE REPLICATE(N'%['+@symchar+N']',@sym)+N'%' COLLATE Latin1_General_CS_AS )
		SET @pwd = N'';

	END;

	PRINT @pwd;

END;

GO

/* Generate some passwords */
DECLARE @pass NVARCHAR(MAX);
EXEC GenPassword @size=10, @lc=2, @uc=2, @num=1, @sym=1, @pwd = @pass OUT;

GO 10
