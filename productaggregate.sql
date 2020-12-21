-- Product aggregate
-- Returns the product of a table of integers
-- SQL Server 2000
-- Adapted from a similar idea by Joe Celko

CREATE TABLE SomeValues (x INTEGER NOT NULL);

INSERT INTO SomeValues VALUES (2);
INSERT INTO SomeValues VALUES (2);
INSERT INTO SomeValues VALUES (3);
INSERT INTO SomeValues VALUES (4);

SELECT CAST(  ROUND(
  COALESCE(EXP(SUM(LOG(ABS(NULLIF(x,0))))),0) -- exp( sum of log x )
   * SIGN(MIN(ABS(x))) -- catch the zero product
   * (COUNT(NULLIF(SIGN(x),1))%2*-2+1) -- count the +/- to determine the sign of the product
  ,0)  AS INTEGER) AS product
 FROM SomeValues;
