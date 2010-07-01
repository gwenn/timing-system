PRAGMA recursive_triggers=ON;
-- UPDATE race SET status = 1 WHERE id = 1; -- trigger results generation
SELECT 'Overall results by gender';
SELECT rank, nb, CASE WHEN prevRank IS NULL THEN NULL
                         WHEN rank - prevRank > 0 THEN '+'
                         WHEN rank - prevRank < 0 THEN '-'
                         ELSE '=' END as delta, duration, number, firstName || ' ' || lastName, company, city, country,
       CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g
FROM result
INNER JOIN racer ON racer.id = result.racerId
WHERE result.raceId = 1 AND result.type = 0
ORDER BY g, rank;
SELECT 'Results by country and gender';
SELECT rank, nb, CASE WHEN prevRank IS NULL THEN NULL
                         WHEN rank - prevRank > 0 THEN '+'
                         WHEN rank - prevRank < 0 THEN '-'
                         ELSE '=' END as delta, duration, number, firstName || ' ' || lastName, company, city, country,
       CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g
FROM result
INNER JOIN racer ON racer.id = result.racerId
WHERE result.raceId = 1 AND result.type = 1
ORDER BY country, g, rank;
