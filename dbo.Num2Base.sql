-- Integer to number base string

CREATE FUNCTION dbo.Num2Base
(
	@num BIGINT,
	@charset VARCHAR(128)	
)
/*
	SELECT dbo.Num2Base(123,16);
*/
RETURNS	VARCHAR(128)
WITH	RETURNS NULL ON NULL INPUT
AS
BEGIN;

		SET		@charset =
		CASE	@charset
		WHEN	'2'  THEN '01'
		WHEN	'8'  THEN '012345678'
		WHEN	'10' THEN '0123456789'
		WHEN	'16' THEN '0123456789ABCDEF'
		WHEN	'26' THEN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		WHEN	'31' THEN '0123456789BCDFGHJKLMNPQRSTVWXYZ'
		WHEN	'32' THEN '0123456789ABCDEFGHIJKLMNOPQRSTUV'
		WHEN	'36' THEN '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		ELSE	@charset
		END;

		DECLARE	@b TINYINT = LEN(@charset),
				@r BIGINT = ABS(@num),
				@result VARCHAR(128) = CASE @num WHEN 0 THEN LEFT(@charset,1) ELSE '' END;

		WHILE	@r > 0
		AND		@b > 1
				SELECT	@result = SUBSTRING(@charset, @r % @b + 1,1) + @result,
						@r = @r/@b;

		RETURN	CASE WHEN @num<0 THEN '-' ELSE '' END + NULLIF(@result,'');
END;
GO

SELECT dbo.Num2Base(255,16);
