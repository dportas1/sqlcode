CREATE TABLE dbo.calendar(
		DateKey int NOT NULL,
		Date date NOT NULL,
		DatetimeValue datetime2(7) NOT NULL,
		DateString char(20) NOT NULL,
		DayName char(15) NOT NULL,
		IsWeekDay bit NOT NULL,
		WeekDayNumber tinyint NOT NULL,
		MonthDayNumber tinyint NOT NULL,
		YearDayNumber smallint NOT NULL,
		MonthNumber tinyint NOT NULL,
		YearMonthNumber int NOT NULL,
		MonthName char(15) NOT NULL,
		YearMonthName char(20) NOT NULL,
		QuarterNumber tinyint NOT NULL,
		YearQuarterNumber int NOT NULL,
		QuarterName char(2) NOT NULL,
		YearQuarterName char(6) NOT NULL,
		HalfYearName char(2) NOT NULL,
		YearHalfYearName char(6) NOT NULL,
		YearNumber int NOT NULL,
		PreviousMonth date NOT NULL,
		PreviousQuarter date NOT NULL,
		PreviousYear date NOT NULL,
		NextMonth date NOT NULL,
		NextQuarter date NOT NULL,
		NextYear date NOT NULL,
CONSTRAINT pk_calendar_datekey PRIMARY KEY (DateKey),
CONSTRAINT ak_calendar_date UNIQUE (Date),
CONSTRAINT ak_calendar_datetimevalue UNIQUE (DatetimeValue));

DECLARE	@StartDt DATE = '2000-01-01';
DECLARE	@EndDt DATE = '2100-01-01';

WITH	dtc(Date) AS
(
		SELECT	@StartDt
		UNION	ALL
		SELECT	DATEADD(DAY,1,Date)
		FROM	dtc
		WHERE	DATEADD(DAY,1,Date) < @EndDt
),		cal AS
(	SELECT 	CAST(YEAR(d.Date)*10000+MONTH(d.Date)*100+DAY(d.Date) AS INT) AS DateKey,
			CAST(d.Date AS DATE) AS Date,
			CAST(d.Date AS DATETIME2) AS DatetimeValue,
			CONVERT(CHAR(20), d.Date, 107) AS DateString,
			CAST(DATENAME(WEEKDAY, d.Date) AS CHAR(15)) AS DayName,
			CAST(CASE WHEN (DATEDIFF(DAY,'00010101',d.Date) + 2) %7 < 2 THEN 0 ELSE 1 END AS BIT) IsWeekDay,
			CAST((DATEDIFF(DAY,'00010102',d.Date) + 2) %7 + 1 AS TINYINT) AS WeekDayNumber,
			CAST(DATEPART(DAY, d.Date) AS TINYINT) AS MonthDayNumber,
			CAST(DATEPART(DAYOFYEAR, d.Date) AS SMALLINT) AS YearDayNumber,
			CAST(DATEPART(MONTH, d.Date) AS TINYINT) AS MonthNumber,
			CAST(DATEPART(YEAR, d.Date) *100 + DATEPART(MONTH, d.Date) AS INT) AS YearMonthNumber,
			CAST(DATENAME(MONTH, d.Date) AS CHAR(15)) AS MonthName,
			CAST(DATENAME(MONTH, d.Date)+' '+DATENAME(YEAR, d.Date) AS CHAR(20)) AS YearMonthName, 
			CAST(DATEPART(QUARTER, d.Date) AS TINYINT) AS QuarterNumber,
			CAST(DATEPART(YEAR, d.Date) *100 + DATEPART(QUARTER, d.Date) AS INT) AS YearQuarterNumber,
			CAST('Q'+CAST(DATENAME(QUARTER, d.Date) AS CHAR(2)) AS CHAR(2)) AS QuarterName,
			CAST(DATENAME(YEAR, d.Date)+'Q'+CAST(DATENAME(QUARTER, d.Date) AS CHAR(1)) AS CHAR(6)) AS YearQuarterName,
			CAST(CASE WHEN DATEPART(QUARTER, d.Date) < 3 THEN 'H1' ELSE 'H2' END AS CHAR(2)) AS HalfYearName,
			CAST(DATENAME(YEAR, d.Date)+CAST(CASE WHEN DATEPART(QUARTER, d.Date) < 3 THEN 'H1' ELSE 'H2' END AS CHAR(2)) AS CHAR(6)) AS YearHalfYearName,
			DATEPART(YEAR, d.Date) AS YearNumber,
			CAST(COALESCE(DATEADD(MONTH,-1,CASE WHEN d.Date > '00010131' THEN d.Date END),'00010101') AS DATE) AS PreviousMonth,
			CAST(COALESCE(DATEADD(MONTH,-3,CASE WHEN d.Date > '00010331' THEN d.Date END),'00010101') AS DATE) AS PreviousQuarter,
			CAST(COALESCE(DATEADD(YEAR, -1,CASE WHEN d.Date > '00011231' THEN d.Date END),'00010101') AS DATE) AS PreviousYear,
			CAST(COALESCE(DATEADD(MONTH, 1,CASE WHEN d.Date < '99991201' THEN d.Date END),'99991231') AS DATE) AS NextMonth,
			CAST(COALESCE(DATEADD(MONTH, 3,CASE WHEN d.Date < '99991001' THEN d.Date END),'99991231') AS DATE) AS NextQuarter,
			CAST(COALESCE(DATEADD(YEAR,  1,CASE WHEN d.Date < '99990101' THEN d.Date END),'99991231') AS DATE) AS NextYear
	FROM	(	SELECT Date FROM dtc
				UNION
				SELECT CAST('99991231' AS DATE)
			) d
)
MERGE	INTO dbo.calendar AS t
USING	cal AS s
ON		t.DateKey = s.DateKey
WHEN NOT MATCHED THEN
INSERT	(DateKey,Date,DatetimeValue,DateString,DayName,IsWeekDay,WeekDayNumber,MonthDayNumber,YearDayNumber,MonthNumber,YearMonthNumber,MonthName,YearMonthName,QuarterNumber,YearQuarterNumber,QuarterName,YearQuarterName,HalfYearName,YearHalfYearName,YearNumber,PreviousMonth,PreviousQuarter,PreviousYear,NextMonth,NextQuarter,NextYear)
VALUES	(DateKey,Date,DatetimeValue,DateString,DayName,IsWeekDay,WeekDayNumber,MonthDayNumber,YearDayNumber,MonthNumber,YearMonthNumber,MonthName,YearMonthName,QuarterNumber,YearQuarterNumber,QuarterName,YearQuarterName,HalfYearName,YearHalfYearName,YearNumber,PreviousMonth,PreviousQuarter,PreviousYear,NextMonth,NextQuarter,NextYear)
WHEN	MATCHED THEN UPDATE SET
		 DateKey = s.DateKey
		,Date = s.Date
		,DatetimeValue = s.DatetimeValue
		,DateString = s.DateString
		,DayName = s.DayName
		,IsWeekDay = s.IsWeekDay
		,WeekDayNumber = s.WeekDayNumber
		,MonthDayNumber = s.MonthDayNumber
		,YearDayNumber = s.YearDayNumber
		,MonthNumber = s.MonthNumber
		,YearMonthNumber = s.YearMonthNumber
		,MonthName = s.MonthName
		,YearMonthName = s.YearMonthName
		,QuarterNumber = s.QuarterNumber
		,YearQuarterNumber = s.YearQuarterNumber
		,QuarterName = s.QuarterName
		,YearQuarterName = s.YearQuarterName
		,HalfYearName = s.HalfYearName
		,YearHalfYearName = s.YearHalfYearName
		,YearNumber = s.YearNumber
		,PreviousMonth = s.PreviousMonth
		,PreviousQuarter = s.PreviousQuarter
		,PreviousYear = s.PreviousYear
		,NextMonth = s.NextMonth
		,NextQuarter = s.NextQuarter
		,NextYear = s.NextYear
OPTION	(MAXRECURSION 0);