/* Reorder the ranking of items in a list. T-SQL (SQL Server) */

DECLARE @old_rank SMALLINT, @new_rank SMALLINT;

CREATE TABLE ranking
 (r SMALLINT NOT NULL PRIMARY KEY,
  t VARCHAR(10) NOT NULL);

/* Sample data */
INSERT INTO ranking (r,t)
VALUES
(1,'aaaa'),
(2,'bbbb'),
(3,'cccc'),
(4,'dddd');

/* Change the rank of one item from 1 to 3 */
SET @old_rank = 1;
SET @new_rank = 3;

UPDATE ranking
SET r =
 CASE 
  WHEN r = @old_rank THEN @new_rank
  WHEN r > @old_rank THEN r - 1
  WHEN r < @old_rank THEN r + 1
 END
 WHERE(r BETWEEN @old_rank AND @new_rank
    OR r BETWEEN @new_rank AND @old_rank)
   AND EXISTS (SELECT * FROM ranking WHERE r = @old_rank);

SELECT r,t FROM ranking ORDER BY t;

/*

r      t
------ ----------
3      aaaa
1      bbbb
2      cccc
4      dddd

*/
