CREATE TABLE racer (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    number      INTEGER NOT NULL,
    country     TEXT NOT NULL,
    city        TEXT,
    company     TEXT,
    gender      INTEGER NOT NULL CHECK (gender IN (1, 2)),
    firstName   TEXT NOT NULL,
    lastName    TEXT NOT NULL,
    nickName    TEXT
);
CREATE UNIQUE INDEX racer_number ON racer(number);
CREATE INDEX racer_country ON racer(country);
CREATE INDEX racer_gender ON racer(gender);

CREATE TABLE race (
    id              INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name            TEXT NOT NULL,
    intervalStarts  BOOLEAN NOT NULL CHECK (intervalStarts IN (0, 1)), -- 0 | false | 1 | true
    startTime       DATETIME CHECK (intervalStarts = 0 OR startTime IS NULL), -- null for interval starts
    status          BOOLEAN NOT NULL DEFAULT 0 -- 0 | START | 1 | END
);
CREATE UNIQUE INDEX race_name ON race(name);

CREATE TABLE timelog (
    raceId      INTEGER NOT NULL,
    racerId     INTEGER NOT NULL,
    time        DATETIME NOT NULL,
    type        INTEGER NOT NULL DEFAULT 0 CHECK (type >= 0), -- 0 | START | ...
    PRIMARY KEY (raceId, racerId, time),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE TABLE position ( -- intermediary data to ease results generation
    raceId      INTEGER NOT NULL,
    racerId     INTEGER NOT NULL,
    nb          INTEGER NOT NULL CHECK (nb >= 0), -- Number of manifests
    duration    INTEGER NOT NULL CHECK (duration >= 0), -- Number of seconds
    PRIMARY KEY (raceId, racerId),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE TABLE resultVersion (
    raceId      INTEGER NOT NULL,
    time        INTEGER NOT NULL, -- Last time results were generated
    PRIMARY KEY (raceId),
    FOREIGN KEY (raceId) REFERENCES race(id) -- ON DELETE CASCADE
);

CREATE TABLE result (
    type        INTEGER NOT NULL, -- 0 | Overall | 1 | Country | 2 | Gender | 3 | Country and Gender | ...
    raceId      INTEGER NOT NULL,
    racerId     INTEGER NOT NULL,
    nb          INTEGER NOT NULL CHECK (nb >= 0), -- Number of manifests
    duration    INTEGER NOT NULL CHECK (duration >= 0), -- Number of seconds
    rank        INTEGER NOT NULL CHECK (rank >= 1),
    prevRank    INTEGER CHECK (prevRank IS NULL OR prevRank >= 1), -- Previous rank
    latency     INTEGER CHECK (latency IS NULL OR latency >= 0), -- Previous rank latency
    PRIMARY KEY (type, raceId, racerId),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

-- To see progression/regression
CREATE TABLE resultHisto (
    type        INTEGER NOT NULL, -- 0 | Overall | 1 | Country | 2 | Gender | 3 | Country and Gender | ...
    raceId      INTEGER NOT NULL,
    racerId     INTEGER NOT NULL,
    rank        INTEGER NOT NULL CHECK (rank >= 1),
    prevRank    INTEGER CHECK (prevRank IS NULL OR prevRank >= 1), -- Previous rank
    latency     INTEGER CHECK (latency IS NULL OR latency >= 0), -- Previous rank latency
    PRIMARY KEY (type, raceId, racerId),
    FOREIGN KEY (raceId) REFERENCES race(id), -- ON DELETE CASCADE
    FOREIGN KEY (racerId) REFERENCES racer(id) -- ON DELETE CASCADE
);

CREATE TRIGGER result_backup AFTER DELETE ON result
-- no rank progression needed when a race is closed or during qualifications
WHEN (SELECT 1 FROM race r WHERE r.id = OLD.raceId AND (r.status = 1 OR r.intervalStarts = 1)) IS NULL
BEGIN
    REPLACE INTO resultHisto VALUES (OLD.type, OLD.raceId, OLD.racerId, OLD.rank, OLD.prevRank, OLD.latency);
END;

CREATE TRIGGER rank_progression AFTER INSERT ON result
-- no rank progression needed when a race is closed or during qualifications
WHEN (SELECT 1 FROM race r WHERE r.id = NEW.raceId AND (r.status = 1 OR r.intervalStarts = 1)) IS NULL
BEGIN
    -- TODO Adjust latency...
    UPDATE result SET
    prevRank =
        (SELECT CASE WHEN (OLD.rank <> NEW.rank OR OLD.latency > 10) THEN OLD.rank ELSE OLD.prevRank END
            FROM resultHisto OLD WHERE OLD.type = NEW.type AND OLD.raceId = NEW.raceId AND OLD.racerId = NEW.racerId),
    latency = 
        (SELECT CASE WHEN (OLD.rank <> NEW.rank OR OLD.latency > 10) THEN 0 ELSE OLD.latency + 1 END
            FROM resultHisto OLD WHERE OLD.type = NEW.type AND OLD.raceId = NEW.raceId AND OLD.racerId = NEW.racerId)
    WHERE type = NEW.type AND raceId = NEW.raceId AND racerId = NEW.racerId;
END;

CREATE TRIGGER closed_race_lock1 AFTER INSERT ON timelog
WHEN (SELECT 1 FROM race r WHERE r.id = NEW.raceId AND r.status = 1) IS NOT NULL
BEGIN
    SELECT RAISE(FAIL, 'No timelog can be inserted for a closed race.');
END;
CREATE TRIGGER closed_race_lock2 AFTER UPDATE ON timelog
WHEN (SELECT 1 FROM race r WHERE r.id = OLD.raceId AND r.status = 1) IS NOT NULL
BEGIN
    SELECT RAISE(FAIL, 'No timelog can be upated for a closed race.');
END;
CREATE TRIGGER closed_race_lock3 AFTER DELETE ON timelog
WHEN (SELECT 1 FROM race r WHERE r.id = OLD.raceId AND r.status = 1) IS NOT NULL
BEGIN
    SELECT RAISE(FAIL, 'No timelog can be deleted for a closed race.');
END;

CREATE TRIGGER results_generation AFTER INSERT ON timelog
WHEN NEW.type <> 0 -- Prevent result update when a start time is inserted.
AND (SELECT 1 FROM race r WHERE r.id = NEW.raceId AND r.status = 1) IS NULL -- Prevent result update for closed race
-- TODO Adjust delay (every minute)?
AND (SELECT 1 FROM resultVersion v WHERE v.raceId = NEW.raceId AND (strftime('%s','now') - v.time) < 60) IS NULL
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
    REPLACE INTO result
        SELECT 0, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
	        WHERE p2.raceId = p1.raceId
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        WHERE raceId = NEW.raceId;
    ---- Results by country
    REPLACE INTO result
        SELECT 1, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = NEW.raceId;
    ---- Results by gender
    REPLACE INTO result
        SELECT 2, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.gender = r1.gender
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = NEW.raceId;
    ---- Results by country and gender
    REPLACE INTO result
        SELECT 3, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
            AND r2.gender = r1.gender
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = NEW.raceId;
    -- Update last time results generation to now
    REPLACE INTO resultVersion VALUES (NEW.raceId, strftime('%s','now'));
    -- Remove intermediary data/stats
    -- DELETE FROM position WHERE raceId = NEW.raceId;
END;

-- To regenerate result (after manual corrections in timelog for example), just
-- change race status: UPDATE race set status = 1 where id = ?
CREATE TRIGGER race_end AFTER UPDATE OF status ON race
WHEN NEW.status = 1
BEGIN
    DELETE FROM resultHisto WHERE raceId = OLD.id; -- TODO Validate
-- XXX Keep synchronized with results_generation
    -- Create intermediary data/stats
    DELETE FROM position WHERE raceId = OLD.id;
    INSERT INTO position SELECT raceId, racerId, count(1),
        strftime('%s', max(time)) - strftime('%s', ifnull(startTime, min(time)))
        FROM timelog
        INNER JOIN race on race.id = timelog.raceId
        WHERE raceId = OLD.id GROUP BY racerId;
    -- Generate results
    ---- Overall results
    REPLACE INTO result
        SELECT 0, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
	        WHERE p2.raceId = p1.raceId
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        WHERE raceId = OLD.id;
    ---- Results by country
    REPLACE INTO result
        SELECT 1, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = OLD.id;
    ---- Results by gender
    REPLACE INTO result
        SELECT 2, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.gender = r1.gender
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = OLD.id;
    ---- Results by country and gender
    REPLACE INTO result
        SELECT 3, raceId, racerId, nb, duration, (SELECT count(*)
	        FROM position p2
            INNER JOIN racer r2 ON r2.id = p2.racerId
	        WHERE p2.raceId = p1.raceId
            AND r2.country = r1.country
            AND r2.gender = r1.gender
	        AND (p2.nb > p1.nb OR (p2.nb = p1.nb AND p2.duration <= p1.duration))), NULL, NULL
        FROM position p1
        INNER JOIN racer r1 ON r1.id = p1.racerId
        WHERE raceId = OLD.id;
    -- Update last time results generation to now
    REPLACE INTO resultVersion VALUES (OLD.id, strftime('%s','now'));
    -- Remove intermediary data/stats
    -- DELETE FROM position WHERE raceId = OLD.id;
END;
-- vim: set expandtab softtabstop=4 shiftwidth=4:
