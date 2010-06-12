UPDATE race SET status = 1 WHERE id = 1; -- trigger results generation
SELECT 'Overall results';
SELECT rank, number, firstName, company, city, duration, country FROM result INNER JOIN racer ON racer.id = result.racerId WHERE raceId = 1 AND type = 0 ORDER BY rank;
SELECT 'Results by country';
SELECT rank, number, firstName, company, city, duration, country FROM result INNER JOIN racer ON racer.id = result.racerId WHERE raceId = 1 AND type = 1 ORDER BY country, rank;
SELECT 'Results by gender';
SELECT rank, number, firstName, company, city, duration, country, CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g FROM result INNER JOIN racer ON racer.id = result.racerId WHERE raceId = 1 AND type = 2 ORDER BY g, rank;
SELECT 'Results by country and gender';
SELECT rank, number, firstName, company, city, duration, country, CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g FROM result INNER JOIN racer ON racer.id = result.racerId WHERE raceId = 1 AND type = 3 ORDER BY country, g, rank;
