PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;
CREATE TABLE racer (
    id          INT NOT NULL,
    number      INT NOT NULL, -- TODO Validate
    country     TEXT NOT NULL,
    city        TEXT,
    company     TEXT,
    gender      INT NOT NULL CHECK (gender IN (1, 2)),
    firstName   TEXT NOT NULL,
    lastName    TEXT NOT NULL,
    nickName    TEXT,
    PRIMARY KEY (id)
);
INSERT INTO racer VALUES(1,1,'FRA','Paris','Urban',1,'A','','');
INSERT INTO racer VALUES(2,2,'FRA','Paris','Urban',1,'B','','');
INSERT INTO racer VALUES(3,3,'FRA','Paris','Urban',2,'C','','');
INSERT INTO racer VALUES(4,4,'FRA','Paris','Urban',1,'D','','');
INSERT INTO racer VALUES(5,5,'FIN','Paris','Cyclair',1,'E','','');
CREATE TABLE race (
    id          INT NOT NULL,
    name        TEXT NOT NULL,
    startTime   TEXT, -- null when each racer has its own startTime
    PRIMARY KEY (id)
);
INSERT INTO race VALUES(1,'Main Race Qualification',NULL);
INSERT INTO race VALUES(2,'Main Race Final','2010-05-16T14:00:00.000');
CREATE TABLE timeLog (
    raceId      INT NOT NULL,
    racerId     INT NOT NULL,
    time        TEXT NOT NULL,
    PRIMARY KEY (raceId, racerId, time),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);
-- Qualification start times
INSERT INTO timeLog VALUES(1,1,'2010-05-16T09:00:00.000');
INSERT INTO timeLog VALUES(1,2,'2010-05-16T09:00:30.000');
INSERT INTO timeLog VALUES(1,3,'2010-05-16T09:01:00.000');
INSERT INTO timeLog VALUES(1,4,'2010-05-16T09:01:30.000');
INSERT INTO timeLog VALUES(1,5,'2010-05-16T09:02:00.000');
-- Qualification finish times
INSERT INTO timeLog VALUES(1,1,'2010-05-16T09:24:49.000');
INSERT INTO timeLog VALUES(1,2,'2010-05-16T09:25:39.000');
INSERT INTO timeLog VALUES(1,3,'2010-05-16T09:26:12.000');
INSERT INTO timeLog VALUES(1,4,'2010-05-16T09:27:05.000');
INSERT INTO timeLog VALUES(1,5,'2010-05-16T09:30:58.000');

CREATE TABLE position ( -- temporary table/transient table to ease results generation
    raceId      INT NOT NULL,
    racerId     INT NOT NULL,
    nb          INT NOT NULL CHECK (nb >= 0), -- Number of manifests
    duration    INT NOT NULL CHECK (duration >= 0), -- Number of seconds
    PRIMARY KEY (raceId, racerId),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE TABLE resultVersion (
    raceId      INT NOT NULL,
    time        TEXT NOT NULL, -- Last time results were generated
    PRIMARY KEY (raceId),
    FOREIGN KEY (raceId) REFERENCES race(id) -- ON DELETE CASCADE
);

CREATE TABLE result (
    type        INT NOT NULL, -- 0 | Overall | 1 | Country | 2 | Gender | 3 | Country and Gender | ...
    raceId      INT NOT NULL,
    racerId     INT NOT NULL,
    nb          INT NOT NULL CHECK (nb >= 0), -- Number of manifests
    duration    INT NOT NULL CHECK (duration >= 0), -- Number of seconds
    PRIMARY KEY (type, raceId, racerId),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE UNIQUE INDEX racer_number ON racer(number);
CREATE INDEX racer_country ON racer(country);
CREATE INDEX racer_gender ON racer(gender);
COMMIT;
/*
*/
/*
CREATE TEMPORARY TABLE position
AS SELECT raceId, racerId, count(1) AS nb, strftime('%s', max(time)) - strftime('%s', min(time)) AS duration
FROM timelog
GROUP BY raceId, racerId;

-- Overall Results
SELECT country, gender,  number, firstName, (SELECT count(*)
	FROM position p2
	WHERE p2.raceId = p1.raceId
	AND p2.nb >= p1.nb AND p2.duration <= p1.duration) AS position
FROM position p1
INNER JOIN racer ON id = racerId
WHERE raceId = 1
ORDER BY position;

-- Results by country
SELECT country, gender,  number, firstName, (SELECT count(*)
	FROM position p2
	INNER JOIN racer r2 ON r2.id = p2.racerId
	WHERE p2.raceId = p1.raceId
	AND r2.country = r1.country
	AND p2.nb >= p1.nb AND p2.duration <= p1.duration) AS position
FROM position p1
INNER JOIN racer r1 ON r1.id = p1.racerId
WHERE raceId = 1
ORDER BY country, position;

-- Results by country and by gender
SELECT country, gender, number, firstName, (SELECT count(*)
	FROM position p2
	INNER JOIN racer r2 ON r2.id = p2.racerId
	WHERE p2.raceId = p1.raceId
	AND r2.country = r1.country
	AND r2.gender = r1.gender
	AND p2.nb >= p1.nb AND p2.duration <= p1.duration) AS position
FROM position p1
INNER JOIN racer r1 ON r1.id = p1.racerId
WHERE raceId = 1
ORDER BY country, gender, position;
*/

/*
Pango
XSL-FO

PRAGMA count_changes;
PRAGMA foreign_keys;
*/
