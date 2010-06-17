PRAGMA recursive_triggers=ON;
UPDATE race SET status = 1 WHERE id = 1; -- trigger results generation
SELECT 'Overall results';
SELECT result.rank, CASE WHEN resultHisto.rank IS NULL THEN NULL
                         WHEN result.rank - resultHisto.rank > 0 THEN '+'
                         WHEN result.rank - resultHisto.rank < 0 THEN '-'
                         ELSE '=' END as delta, number, firstName, company, city, duration, country
FROM result
INNER JOIN racer ON racer.id = result.racerId
LEFT OUTER JOIN resultHisto ON resultHisto.type = result.type AND resultHisto.raceId = result.raceId AND resultHisto.racerId = result.racerId
WHERE result.raceId = 1 AND result.type = 0
ORDER BY result.rank;
SELECT 'Results by country';
SELECT result.rank, CASE WHEN resultHisto.rank IS NULL THEN NULL
                         WHEN result.rank - resultHisto.rank > 0 THEN '+'
                         WHEN result.rank - resultHisto.rank < 0 THEN '-'
                         ELSE '=' END as delta, number, firstName, company, city, duration, country
FROM result
INNER JOIN racer ON racer.id = result.racerId
LEFT OUTER JOIN resultHisto ON resultHisto.type = result.type AND resultHisto.raceId = result.raceId AND resultHisto.racerId = result.racerId
WHERE result.raceId = 1 AND result.type = 1
ORDER BY country, result.rank;
SELECT 'Results by gender';
SELECT result.rank, CASE WHEN resultHisto.rank IS NULL THEN NULL
                         WHEN result.rank - resultHisto.rank > 0 THEN '+'
                         WHEN result.rank - resultHisto.rank < 0 THEN '-'
                         ELSE '=' END as delta, number, firstName, company, city, duration, country,
       CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g
FROM result
INNER JOIN racer ON racer.id = result.racerId
LEFT OUTER JOIN resultHisto ON resultHisto.type = result.type AND resultHisto.raceId = result.raceId AND resultHisto.racerId = result.racerId
WHERE result.raceId = 1 AND result.type = 2
ORDER BY g, result.rank;
SELECT 'Results by country and gender';
SELECT result.rank, CASE WHEN resultHisto.rank IS NULL THEN NULL
                         WHEN result.rank - resultHisto.rank > 0 THEN '+'
                         WHEN result.rank - resultHisto.rank < 0 THEN '-'
                         ELSE '=' END as delta, number, firstName, company, city, duration, country,
       CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g
FROM result
INNER JOIN racer ON racer.id = result.racerId
LEFT OUTER JOIN resultHisto ON resultHisto.type = result.type AND resultHisto.raceId = result.raceId AND resultHisto.racerId = result.racerId
WHERE result.raceId = 1 AND result.type = 3
ORDER BY country, g, result.rank;
