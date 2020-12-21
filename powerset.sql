/* Power set */

WITH
t(x) AS
(
	SELECT CAST(x AS VARCHAR(MAX))
	FROM (VALUES ('A'),('B'),('C'),('D'),('E'),('F'),('G'),('H'),('I'),('J'))
	t(x)
),
p(x) AS
(
   SELECT '' x
   UNION ALL
   SELECT x FROM t
   UNION ALL
   SELECT t.x+p.x FROM t,p
   WHERE t.x<LEFT(p.x,1)
)
SELECT *
FROM p
ORDER BY x;
