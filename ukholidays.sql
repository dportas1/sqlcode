/*
UK holiday data based on:
https://www.dmo.gov.uk/media/15008/ukbankholidays.xls

ALTER TABLE dbo.calendar ADD IsUKPublicHoliday BIT NULL;
ALTER TABLE dbo.calendar ADD IsUKWorkDay BIT NULL;
*/

UPDATE dbo.calendar SET IsUKPublicHoliday = 0, IsUKWorkDay = IsWeekDay;

ALTER TABLE dbo.calendar ALTER COLUMN IsUKPublicHoliday BIT NOT NULL;
ALTER TABLE dbo.calendar ALTER COLUMN IsUKWorkDay BIT NOT NULL;

UPDATE dbo.calendar SET IsUKPublicHoliday = 1, IsUKWorkDay = 0
WHERE EXISTS
 (SELECT 1 FROM
	(VALUES
		('1998-01-01'),
		('1998-04-10'),
		('1998-04-13'),
		('1998-05-04'),
		('1998-05-25'),
		('1998-08-31'),
		('1998-12-25'),
		('1998-12-28'),
		('1999-01-01'),
		('1999-04-02'),
		('1999-04-05'),
		('1999-05-03'),
		('1999-05-31'),
		('1999-08-30'),
		('1999-12-27'),
		('1999-12-28'),
		('1999-12-31'),
		('2000-01-03'),
		('2000-04-21'),
		('2000-04-24'),
		('2000-05-01'),
		('2000-05-29'),
		('2000-08-28'),
		('2000-12-25'),
		('2000-12-26'),
		('2001-01-01'),
		('2001-04-13'),
		('2001-04-16'),
		('2001-05-07'),
		('2001-05-28'),
		('2001-08-27'),
		('2001-12-25'),
		('2001-12-26'),
		('2002-01-01'),
		('2002-03-29'),
		('2002-04-01'),
		('2002-05-06'),
		('2002-06-03'),
		('2002-06-04'),
		('2002-08-26'),
		('2002-12-25'),
		('2002-12-26'),
		('2003-01-01'),
		('2003-04-18'),
		('2003-04-21'),
		('2003-05-05'),
		('2003-05-26'),
		('2003-08-25'),
		('2003-12-25'),
		('2003-12-26'),
		('2004-01-01'),
		('2004-04-09'),
		('2004-04-12'),
		('2004-05-03'),
		('2004-05-31'),
		('2004-08-30'),
		('2004-12-27'),
		('2004-12-28'),
		('2005-01-03'),
		('2005-03-25'),
		('2005-03-28'),
		('2005-05-02'),
		('2005-05-30'),
		('2005-08-29'),
		('2005-12-26'),
		('2005-12-27'),
		('2006-01-02'),
		('2006-04-14'),
		('2006-04-17'),
		('2006-05-01'),
		('2006-05-29'),
		('2006-08-28'),
		('2006-12-25'),
		('2006-12-26'),
		('2007-01-01'),
		('2007-04-06'),
		('2007-04-09'),
		('2007-05-07'),
		('2007-05-28'),
		('2007-08-27'),
		('2007-12-25'),
		('2007-12-26'),
		('2008-01-01'),
		('2008-03-21'),
		('2008-03-24'),
		('2008-05-05'),
		('2008-05-26'),
		('2008-08-25'),
		('2008-12-25'),
		('2008-12-26'),
		('2009-01-01'),
		('2009-04-10'),
		('2009-04-13'),
		('2009-05-04'),
		('2009-05-25'),
		('2009-08-31'),
		('2009-12-25'),
		('2009-12-28'),
		('2010-01-01'),
		('2010-04-02'),
		('2010-04-05'),
		('2010-05-03'),
		('2010-05-31'),
		('2010-08-30'),
		('2010-12-27'),
		('2010-12-28'),
		('2011-01-03'),
		('2011-04-22'),
		('2011-04-25'),
		('2011-04-29'),
		('2011-05-02'),
		('2011-05-30'),
		('2011-08-29'),
		('2011-12-26'),
		('2011-12-27'),
		('2012-01-02'),
		('2012-04-06'),
		('2012-04-09'),
		('2012-05-07'),
		('2012-06-04'),
		('2012-06-05'),
		('2012-08-27'),
		('2012-12-25'),
		('2012-12-26'),
		('2013-01-01'),
		('2013-03-29'),
		('2013-04-01'),
		('2013-05-06'),
		('2013-05-27'),
		('2013-08-26'),
		('2013-12-25'),
		('2013-12-26'),
		('2014-01-01'),
		('2014-04-18'),
		('2014-04-21'),
		('2014-05-05'),
		('2014-05-26'),
		('2014-08-25'),
		('2014-12-25'),
		('2014-12-26'),
		('2015-01-01'),
		('2015-04-03'),
		('2015-04-06'),
		('2015-05-04'),
		('2015-05-25'),
		('2015-08-31'),
		('2015-12-25'),
		('2015-12-28'),
		('2016-01-01'),
		('2016-03-25'),
		('2016-03-28'),
		('2016-05-02'),
		('2016-05-30'),
		('2016-08-29'),
		('2016-12-26'),
		('2016-12-27'),
		('2017-01-02'),
		('2017-04-14'),
		('2017-04-17'),
		('2017-05-01'),
		('2017-05-29'),
		('2017-08-28'),
		('2017-12-25'),
		('2017-12-26'),
		('2018-01-01'),
		('2018-03-30'),
		('2018-04-02'),
		('2018-05-07'),
		('2018-05-28'),
		('2018-08-27'),
		('2018-12-25'),
		('2018-12-26'),
		('2019-01-01'),
		('2019-04-19'),
		('2019-04-22'),
		('2019-05-06'),
		('2019-05-27'),
		('2019-08-26'),
		('2019-12-25'),
		('2019-12-26'),
		('2020-01-01'),
		('2020-04-10'),
		('2020-04-13'),
		('2020-05-04'),
		('2020-05-25'),
		('2020-08-31'),
		('2020-12-25'),
		('2020-12-28'),
		('2021-01-01'),
		('2021-04-02'),
		('2021-04-05'),
		('2021-05-03'),
		('2021-05-31'),
		('2021-08-30'),
		('2021-12-27'),
		('2021-12-28'),
		('2022-01-03'),
		('2022-04-15'),
		('2022-04-18'),
		('2022-05-02'),
		('2022-05-30'),
		('2022-08-29'),
		('2022-12-26'),
		('2022-12-27'),
		('2023-01-02'),
		('2023-04-07'),
		('2023-04-10'),
		('2023-05-01'),
		('2023-05-29'),
		('2023-08-28'),
		('2023-12-25'),
		('2023-12-26'),
		('2024-01-01'),
		('2024-03-29'),
		('2024-04-01'),
		('2024-05-06'),
		('2024-05-27'),
		('2024-08-26'),
		('2024-12-25'),
		('2024-12-26'),
		('2025-01-01'),
		('2025-04-18'),
		('2025-04-21'),
		('2025-05-05'),
		('2025-05-26'),
		('2025-08-25'),
		('2025-12-25'),
		('2025-12-26'),
		('2026-01-01'),
		('2026-04-03'),
		('2026-04-06'),
		('2026-05-04'),
		('2026-05-25'),
		('2026-08-31'),
		('2026-12-25'),
		('2026-12-28'),
		('2027-01-01'),
		('2027-03-26'),
		('2027-03-29'),
		('2027-05-03'),
		('2027-05-31'),
		('2027-08-30'),
		('2027-12-27'),
		('2027-12-28'),
		('2028-01-03'),
		('2028-04-14'),
		('2028-04-17'),
		('2028-05-01'),
		('2028-05-29'),
		('2028-08-28'),
		('2028-12-25'),
		('2028-12-26'),
		('2029-01-01'),
		('2029-03-30'),
		('2029-04-02'),
		('2029-05-07'),
		('2029-05-28'),
		('2029-08-27'),
		('2029-12-25'),
		('2029-12-26'),
		('2030-01-01'),
		('2030-04-19'),
		('2030-04-22'),
		('2030-05-06'),
		('2030-05-27'),
		('2030-08-26'),
		('2030-12-25'),
		('2030-12-26'),
		('2031-01-01'),
		('2031-04-11'),
		('2031-04-14'),
		('2031-05-05'),
		('2031-05-26'),
		('2031-08-25'),
		('2031-12-25'),
		('2031-12-26'),
		('2032-01-01'),
		('2032-03-26'),
		('2032-03-29'),
		('2032-05-03'),
		('2032-05-31'),
		('2032-08-30'),
		('2032-12-27'),
		('2032-12-28'),
		('2033-01-03'),
		('2033-04-15'),
		('2033-04-18'),
		('2033-05-02'),
		('2033-05-30'),
		('2033-08-29'),
		('2033-12-26'),
		('2033-12-27'),
		('2034-01-02'),
		('2034-04-07'),
		('2034-04-10'),
		('2034-05-01'),
		('2034-05-29'),
		('2034-08-28'),
		('2034-12-25'),
		('2034-12-26'),
		('2035-01-01'),
		('2035-03-23'),
		('2035-03-26'),
		('2035-05-07'),
		('2035-05-28'),
		('2035-08-27'),
		('2035-12-25'),
		('2035-12-26'),
		('2036-01-01'),
		('2036-04-11'),
		('2036-04-14'),
		('2036-05-05'),
		('2036-05-26'),
		('2036-08-25'),
		('2036-12-25'),
		('2036-12-26'),
		('2037-01-01'),
		('2037-04-03'),
		('2037-04-06'),
		('2037-05-04'),
		('2037-05-25'),
		('2037-08-31'),
		('2037-12-25'),
		('2037-12-28'),
		('2038-01-01'),
		('2038-04-23'),
		('2038-04-26'),
		('2038-05-03'),
		('2038-05-31'),
		('2038-08-30'),
		('2038-12-27'),
		('2038-12-28'),
		('2039-01-03'),
		('2039-04-08'),
		('2039-04-11'),
		('2039-05-02'),
		('2039-05-30'),
		('2039-08-29'),
		('2039-12-26'),
		('2039-12-27'),
		('2040-01-02'),
		('2040-03-30'),
		('2040-04-02'),
		('2040-05-07'),
		('2040-05-28'),
		('2040-08-27'),
		('2040-12-25'),
		('2040-12-26'),
		('2041-01-01'),
		('2041-04-19'),
		('2041-04-22'),
		('2041-05-06'),
		('2041-05-27'),
		('2041-08-26'),
		('2041-12-25'),
		('2041-12-26'),
		('2042-01-01'),
		('2042-04-04'),
		('2042-04-07'),
		('2042-05-05'),
		('2042-05-26'),
		('2042-08-25'),
		('2042-12-25'),
		('2042-12-26'),
		('2043-01-01'),
		('2043-03-27'),
		('2043-03-30'),
		('2043-05-04'),
		('2043-05-25'),
		('2043-08-31'),
		('2043-12-25'),
		('2043-12-28'),
		('2044-01-01'),
		('2044-04-15'),
		('2044-04-18'),
		('2044-05-02'),
		('2044-05-30'),
		('2044-08-29'),
		('2044-12-26'),
		('2044-12-27'),
		('2045-01-02'),
		('2045-04-07'),
		('2045-04-10'),
		('2045-05-01'),
		('2045-05-29'),
		('2045-08-28'),
		('2045-12-25'),
		('2045-12-26'),
		('2046-01-01'),
		('2046-03-23'),
		('2046-03-26'),
		('2046-05-07'),
		('2046-05-28'),
		('2046-08-27'),
		('2046-12-25'),
		('2046-12-26'),
		('2047-01-01'),
		('2047-04-12'),
		('2047-04-15'),
		('2047-05-06'),
		('2047-05-27'),
		('2047-08-26'),
		('2047-12-25'),
		('2047-12-26'),
		('2048-01-01'),
		('2048-04-03'),
		('2048-04-06'),
		('2048-05-04'),
		('2048-05-25'),
		('2048-08-31'),
		('2048-12-25'),
		('2048-12-28'),
		('2049-01-01'),
		('2049-04-16'),
		('2049-04-19'),
		('2049-05-03'),
		('2049-05-31'),
		('2049-08-30'),
		('2049-12-27'),
		('2049-12-28'),
		('2050-01-03'),
		('2050-04-08'),
		('2050-04-11'),
		('2050-05-02'),
		('2050-05-30'),
		('2050-08-29'),
		('2050-12-26'),
		('2050-12-27'),
		('2051-01-02'),
		('2051-03-31'),
		('2051-04-03'),
		('2051-05-01'),
		('2051-05-29'),
		('2051-08-28'),
		('2051-12-25'),
		('2051-12-26'),
		('2052-01-01'),
		('2052-04-19'),
		('2052-04-22'),
		('2052-05-06'),
		('2052-05-27'),
		('2052-08-26'),
		('2052-12-25'),
		('2052-12-26'),
		('2053-01-01'),
		('2053-04-04'),
		('2053-04-07'),
		('2053-05-05'),
		('2053-05-26'),
		('2053-08-25'),
		('2053-12-25'),
		('2053-12-26'),
		('2054-01-01'),
		('2054-03-27'),
		('2054-03-30'),
		('2054-05-04'),
		('2054-05-25'),
		('2054-08-31'),
		('2054-12-25'),
		('2054-12-28'),
		('2055-01-01'),
		('2055-04-16'),
		('2055-04-19'),
		('2055-05-03'),
		('2055-05-31'),
		('2055-08-30'),
		('2055-12-27'),
		('2055-12-28'),
		('2056-01-03'),
		('2056-03-31'),
		('2056-04-03'),
		('2056-05-01'),
		('2056-05-29'),
		('2056-08-28'),
		('2056-12-25'),
		('2056-12-26'),
		('2057-01-01'),
		('2057-04-20'),
		('2057-04-23'),
		('2057-05-07'),
		('2057-05-28'),
		('2057-08-27'),
		('2057-12-25'),
		('2057-12-26'),
		('2058-01-01'),
		('2058-04-12'),
		('2058-04-15'),
		('2058-05-06'),
		('2058-05-27'),
		('2058-08-26'),
		('2058-12-25'),
		('2058-12-26'),
		('2059-01-01'),
		('2059-03-28'),
		('2059-03-31'),
		('2059-05-05'),
		('2059-05-26'),
		('2059-08-25'),
		('2059-12-25'),
		('2059-12-26'),
		('2060-01-01'),
		('2060-04-16'),
		('2060-04-19'),
		('2060-05-03'),
		('2060-05-31'),
		('2060-08-30'),
		('2060-12-27'),
		('2060-12-28'),
		('2061-01-03'),
		('2061-04-08'),
		('2061-04-11'),
		('2061-05-02'),
		('2061-05-30'),
		('2061-08-29'),
		('2061-12-26'),
		('2061-12-27'),
		('2062-01-02'),
		('2062-03-24'),
		('2062-03-27'),
		('2062-05-01'),
		('2062-05-29'),
		('2062-08-28'),
		('2062-12-25'),
		('2062-12-26'),
		('2063-01-01'),
		('2063-04-13'),
		('2063-04-16'),
		('2063-05-07'),
		('2063-05-28'),
		('2063-08-27'),
		('2063-12-25'),
		('2063-12-26'),
		('2064-01-01'),
		('2064-04-04'),
		('2064-04-07'),
		('2064-05-05'),
		('2064-05-26'),
		('2064-08-25'),
		('2064-12-25'),
		('2064-12-26'),
		('2065-01-01'),
		('2065-03-27'),
		('2065-03-30'),
		('2065-05-04'),
		('2065-05-25'),
		('2065-08-31'),
		('2065-12-25'),
		('2065-12-28'),
		('2066-01-01'),
		('2066-04-09'),
		('2066-04-12'),
		('2066-05-03'),
		('2066-05-31'),
		('2066-08-30'),
		('2066-12-27'),
		('2066-12-28'),
		('2067-01-03'),
		('2067-04-01'),
		('2067-04-04'),
		('2067-05-02'),
		('2067-05-30'),
		('2067-08-29'),
		('2067-12-26'),
		('2067-12-27'),
		('2068-01-02'),
		('2068-04-20'),
		('2068-04-23'),
		('2068-05-07'),
		('2068-05-28'),
		('2068-08-27'),
		('2068-12-25'),
		('2068-12-26'),
		('2069-01-01'),
		('2069-04-12'),
		('2069-04-15'),
		('2069-05-06'),
		('2069-05-27'),
		('2069-08-26'),
		('2069-12-25'),
		('2069-12-26'),
		('2070-01-01'),
		('2070-03-28'),
		('2070-03-31'),
		('2070-05-05'),
		('2070-05-26'),
		('2070-08-25'),
		('2070-12-25'),
		('2070-12-26'),
		('2071-01-01'),
		('2071-04-17'),
		('2071-04-20'),
		('2071-05-04'),
		('2071-05-25'),
		('2071-08-31'),
		('2071-12-25'),
		('2071-12-28'),
		('2072-01-01'),
		('2072-04-08'),
		('2072-04-11'),
		('2072-05-02'),
		('2072-05-30'),
		('2072-08-29'),
		('2072-12-26'),
		('2072-12-27'),
		('2073-01-02'),
		('2073-03-24'),
		('2073-03-27'),
		('2073-05-01'),
		('2073-05-29'),
		('2073-08-28'),
		('2073-12-25'),
		('2073-12-26'),
		('2074-01-01'),
		('2074-04-13'),
		('2074-04-16'),
		('2074-05-07'),
		('2074-05-28'),
		('2074-08-27'),
		('2074-12-25'),
		('2074-12-26'),
		('2075-01-01'),
		('2075-04-05'),
		('2075-04-08'),
		('2075-05-06'),
		('2075-05-27'),
		('2075-08-26'),
		('2075-12-25'),
		('2075-12-26'),
		('2076-01-01'),
		('2076-04-17'),
		('2076-04-20'),
		('2076-05-04'),
		('2076-05-25'),
		('2076-08-31'),
		('2076-12-25'),
		('2076-12-28'),
		('2077-01-01'),
		('2077-04-09'),
		('2077-04-12'),
		('2077-05-03'),
		('2077-05-31'),
		('2077-08-30'),
		('2077-12-27'),
		('2077-12-28'),
		('2078-01-03'),
		('2078-04-01'),
		('2078-04-04'),
		('2078-05-02'),
		('2078-05-30'),
		('2078-08-29'),
		('2078-12-26'),
		('2078-12-27'),
		('2079-01-02'),
		('2079-04-21'),
		('2079-04-24'),
		('2079-05-01'),
		('2079-05-29'),
		('2079-08-28'),
		('2079-12-25'),
		('2079-12-26'),
		('2080-01-01'),
		('2080-04-05'),
		('2080-04-08'),
		('2080-05-06'),
		('2080-05-27'),
		('2080-08-26'),
		('2080-12-25'),
		('2080-12-26'),
		('2081-01-01'),
		('2081-03-28'),
		('2081-03-31'),
		('2081-05-05'),
		('2081-05-26'),
		('2081-08-25'),
		('2081-12-25'),
		('2081-12-26'),
		('2082-01-01'),
		('2082-04-17'),
		('2082-04-20'),
		('2082-05-04'),
		('2082-05-25'),
		('2082-08-31'),
		('2082-12-25'),
		('2082-12-28'),
		('2083-01-01'),
		('2083-04-02'),
		('2083-04-05'),
		('2083-05-03'),
		('2083-05-31'),
		('2083-08-30'),
		('2083-12-27'),
		('2083-12-28'),
		('2084-01-03'),
		('2084-03-24'),
		('2084-03-27'),
		('2084-05-01'),
		('2084-05-29'),
		('2084-08-28'),
		('2084-12-25'),
		('2084-12-26'),
		('2085-01-01'),
		('2085-04-13'),
		('2085-04-16'),
		('2085-05-07'),
		('2085-05-28'),
		('2085-08-27'),
		('2085-12-25'),
		('2085-12-26'),
		('2086-01-01'),
		('2086-03-29'),
		('2086-04-01'),
		('2086-05-06'),
		('2086-05-27'),
		('2086-08-26'),
		('2086-12-25'),
		('2086-12-26'),
		('2087-01-01'),
		('2087-04-18'),
		('2087-04-21'),
		('2087-05-05'),
		('2087-05-26'),
		('2087-08-25'),
		('2087-12-25'),
		('2087-12-26'),
		('2088-01-01'),
		('2088-04-09'),
		('2088-04-12'),
		('2088-05-03'),
		('2088-05-31'),
		('2088-08-30'),
		('2088-12-27'),
		('2088-12-28'),
		('2089-01-03'),
		('2089-04-01'),
		('2089-04-04'),
		('2089-05-02'),
		('2089-05-30'),
		('2089-08-29'),
		('2089-12-26'),
		('2089-12-27'),
		('2090-01-02'),
		('2090-04-14'),
		('2090-04-17'),
		('2090-05-01'),
		('2090-05-29'),
		('2090-08-28'),
		('2090-12-25'),
		('2090-12-26'),
		('2091-01-01'),
		('2091-04-06'),
		('2091-04-09'),
		('2091-05-07'),
		('2091-05-28'),
		('2091-08-27'),
		('2091-12-25'),
		('2091-12-26'),
		('2092-01-01'),
		('2092-03-28'),
		('2092-03-31'),
		('2092-05-05'),
		('2092-05-26'),
		('2092-08-25'),
		('2092-12-25'),
		('2092-12-26'),
		('2093-01-01'),
		('2093-04-10'),
		('2093-04-13'),
		('2093-05-04'),
		('2093-05-25'),
		('2093-08-31'),
		('2093-12-25'),
		('2093-12-28'),
		('2094-01-01'),
		('2094-04-02'),
		('2094-04-05'),
		('2094-05-03'),
		('2094-05-31'),
		('2094-08-30'),
		('2094-12-27'),
		('2094-12-28'),
		('2095-01-03'),
		('2095-04-22'),
		('2095-04-25'),
		('2095-05-02'),
		('2095-05-30'),
		('2095-08-29'),
		('2095-12-26'),
		('2095-12-27'),
		('2096-01-02'),
		('2096-04-13'),
		('2096-04-16'),
		('2096-05-07'),
		('2096-05-28'),
		('2096-08-27'),
		('2096-12-25'),
		('2096-12-26'),
		('2097-01-01'),
		('2097-03-29'),
		('2097-04-01'),
		('2097-05-06'),
		('2097-05-27'),
		('2097-08-26'),
		('2097-12-25'),
		('2097-12-26'),
		('2098-01-01'),
		('2098-04-18'),
		('2098-04-21'),
		('2098-05-05'),
		('2098-05-26'),
		('2098-08-25'),
		('2098-12-25'),
		('2098-12-26'),
		('2099-01-01'),
		('2099-04-10'),
		('2099-04-13'),
		('2099-05-04'),
		('2099-05-25'),
		('2099-08-31'),
		('2099-12-25'),
		('2099-12-28'),
		('2100-01-01'),
		('2100-03-26'),
		('2100-03-29'),
		('2100-05-03'),
		('2100-05-31'),
		('2100-08-30'),
		('2100-12-27'),
		('2100-12-28'),
		('2101-01-03'),
		('2101-04-15'),
		('2101-04-18'),
		('2101-05-02'),
		('2101-05-30'),
		('2101-08-29'),
		('2101-12-26'),
		('2101-12-27'),
		('2102-01-02'),
		('2102-04-07'),
		('2102-04-10'),
		('2102-05-01'),
		('2102-05-29'),
		('2102-08-28'),
		('2102-12-25'),
		('2102-12-26'),
		('2103-01-01'),
		('2103-03-23'),
		('2103-03-26'),
		('2103-05-07'),
		('2103-05-28'),
		('2103-08-27'),
		('2103-12-25'),
		('2103-12-26'),
		('2104-01-01'),
		('2104-04-11'),
		('2104-04-14'),
		('2104-05-05'),
		('2104-05-26'),
		('2104-08-25'),
		('2104-12-25'),
		('2104-12-26'),
		('2105-01-01'),
		('2105-04-03'),
		('2105-04-06'),
		('2105-05-04'),
		('2105-05-25'),
		('2105-08-31'),
		('2105-12-25'),
		('2105-12-28'),
		('2106-01-01'),
		('2106-04-16'),
		('2106-04-19'),
		('2106-05-03'),
		('2106-05-31'),
		('2106-08-30'),
		('2106-12-27'),
		('2106-12-28'),
		('2107-01-03'),
		('2107-04-08'),
		('2107-04-11'),
		('2107-05-02'),
		('2107-05-30'),
		('2107-08-29'),
		('2107-12-26'),
		('2107-12-27'),
		('2108-01-02'),
		('2108-03-30'),
		('2108-04-02'),
		('2108-05-07'),
		('2108-05-28'),
		('2108-08-27'),
		('2108-12-25'),
		('2108-12-26'),
		('2109-01-01'),
		('2109-04-19'),
		('2109-04-22'),
		('2109-05-06'),
		('2109-05-27'),
		('2109-08-26'),
		('2109-12-25'),
		('2109-12-26'),
		('2110-01-01'),
		('2110-04-04'),
		('2110-04-07'),
		('2110-05-05'),
		('2110-05-26'),
		('2110-08-25'),
		('2110-12-25'),
		('2110-12-26')) t(dt)
	WHERE t.dt = calendar.date);