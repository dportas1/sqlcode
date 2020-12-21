-- Concatenation aggregate using FOR XML PATH
-- SQL Server 2008

CREATE TABLE dbo.tbl (col1 INT NOT NULL, col2 VARCHAR(10) NOT NULL,
PRIMARY KEY (col1,col2));

INSERT INTO dbo.tbl (col1,col2) VALUES (1,'ABC');
INSERT INTO dbo.tbl (col1,col2) VALUES (1,'DEF');
INSERT INTO dbo.tbl (col1,col2) VALUES (2,'GHI');
INSERT INTO dbo.tbl (col1,col2) VALUES (2,'JKL');

SELECT DISTINCT col1,
STUFF(
 (SELECT '|'+col2 AS [text()]
  FROM tbl
  WHERE col1 = T.col1
  ORDER BY col2
  FOR XML PATH( '' )
 ), 1, 1, '') AS concat
FROM tbl AS T
ORDER BY col1 ;
