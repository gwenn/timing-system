CREATE TABLE racer (
    id          INT NOT NULL,
    number      INT NOT NULL,
    country     TEXT NOT NULL,
    city        TEXT,
    company     TEXT,
    gender      INT NOT NULL CHECK (gender IN (1, 2)),
    firstName   TEXT NOT NULL,
    lastName    TEXT NOT NULL,
    nickName    TEXT,
    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX racer_number ON racer(number);
CREATE INDEX racer_country ON racer(country);
CREATE INDEX racer_gender ON racer(gender);

CREATE TABLE race (
    id          INT NOT NULL,
    name        TEXT NOT NULL,
    startTime   TEXT, -- null when each racer has its own startTime
    status      INT NOT NULL DEFAULT 0, -- 0 | START | 1 | END
    PRIMARY KEY (id)
);

CREATE TABLE timelog (
    raceId      INT NOT NULL,
    racerId     INT NOT NULL,
    time        TEXT NOT NULL,
    PRIMARY KEY (raceId, racerId, time),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE TABLE position ( -- intermediary data to ease results generation
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
    time        INT NOT NULL, -- Last time results were generated
    PRIMARY KEY (raceId),
    FOREIGN KEY (raceId) REFERENCES race(id) -- ON DELETE CASCADE
);

CREATE TABLE result (
    type        INT NOT NULL, -- 0 | Overall | 1 | Country | 2 | Gender | 3 | Country and Gender | ...
    raceId      INT NOT NULL,
    racerId     INT NOT NULL,
    nb          INT NOT NULL CHECK (nb >= 0), -- Number of manifests
    duration    INT NOT NULL CHECK (duration >= 0), -- Number of seconds
    rank        INT NOT NULL CHECK (nb >= 1),
    prevRank    INT CHECK (prevRank IS NULL or prevRank >= 1), -- To see progression/regression
    PRIMARY KEY (type, raceId, racerId),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE TRIGGER rank_progression AFTER UPDATE OF rank ON result
WHEN (NEW.rank <> OLD.rank) -- TODO Validate
BEGIN
    UPDATE result SET prevRank = OLD.rank;
END;

CREATE TRIGGER results_generation AFTER INSERT ON timelog
-- TODO Adjust delay (every minute)?
WHEN (SELECT 1 FROM resultVersion v WHERE v.raceId = NEW.raceId AND (strftime('%s','now') - v.time) < 60) IS NULL
BEGIN
    -- Create intermediary data/stats
    DELETE FROM position WHERE raceId = NEW.raceId;
    INSERT INTO position SELECT raceId, racerId, count(1),
        strftime('%s', max(time)) - strftime('%s', ifnull(startTime, min(time)))
        FROM timelog
        INNER JOIN race on race.id = timelog.raceId
        WHERE raceId = NEW.raceId GROUP BY racerId;
    -- Generate results
    ---- Overall results
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 0, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
	        WHERE p2.raceId = p1.raceId
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        WHERE raceId = NEW.raceId;
    ---- Results by country
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 1, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = NEW.raceId;
    ---- Results by gender
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 2, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.gender = r1.gender
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = NEW.raceId;
    ---- Results by country and gender
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 3, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
            AND r2.gender = r1.gender
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = NEW.raceId;
    -- Update last time results generation to now
    REPLACE INTO resultVersion VALUES (NEW.raceId, strftime('%s','now'));
END;

CREATE TRIGGER race_end AFTER UPDATE OF status ON race
WHEN NEW.status = 1
BEGIN
-- TODO Keep synchronized with results_generation
    -- Create intermediary data/stats
    DELETE FROM position WHERE raceId = OLD.id;
    INSERT INTO position SELECT raceId, racerId, count(1),
        strftime('%s', max(time)) - strftime('%s', ifnull(startTime, min(time)))
        FROM timelog
        INNER JOIN race on race.id = timelog.raceId
        WHERE raceId = OLD.id GROUP BY racerId;
    -- Generate results
    ---- Overall results
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 0, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
	        WHERE p2.raceId = p1.raceId
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        WHERE raceId = OLD.id;
    ---- Results by country
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 1, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = OLD.id;
    ---- Results by gender
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 2, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.gender = r1.gender
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = OLD.id;
    ---- Results by country and gender
    REPLACE INTO result (type, raceId, racerId, nb, duration, rank)
        SELECT 3, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
            AND r2.gender = r1.gender
	        AND p2.nb >= p1.nb AND p2.duration <= p1.duration)
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = OLD.id;
    -- Update last time results generation to now
    REPLACE INTO resultVersion VALUES (OLD.id, strftime('%s','now'));
END;

/*
Pango
XSL-FO

PRAGMA count_changes;
PRAGMA foreign_keys;
*/
