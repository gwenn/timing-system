PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE racer (
    id          int not null,
    number      int not null, -- TODO Validate
    country     text not null,
    city        text,
    team        text,
    gender      int not null check (gender in (1, 2)),
    firstName   text not null,
    lastName    text not null,
    nickName    text,
    primary key (id)
);
INSERT INTO racer VALUES(1,1,'FRA','Paris','Urban',1,'A','','');
INSERT INTO racer VALUES(2,2,'FRA','Paris','Urban',1,'B','','');
INSERT INTO racer VALUES(3,3,'FRA','Paris','Urban',2,'C','','');
INSERT INTO racer VALUES(4,4,'FRA','Paris','Urban',1,'D','','');
INSERT INTO racer VALUES(5,5,'FIN','Paris','Cyclair',1,'E','','');
CREATE TABLE race (
    id          int not null,
    name        text not null,
    startTime   text, -- null when each racer has its own startTime
    primary key (id)
);
INSERT INTO race VALUES(1,'Qualif',NULL);
INSERT INTO race VALUES(2,'Main race','2010-05-16T14:00:00.000');
CREATE TABLE timeLog (
    raceId      int not null,
    racerId     int not null,
    time        text not null,
    primary key (raceId, racerId, time),
    foreign key (raceId) references race(id),
    foreign key (racerId) references racer(id)
);
-- Qualif starts
INSERT INTO timeLog VALUES(1,1,'2010-05-16T09:00:00.000');
INSERT INTO timeLog VALUES(1,2,'2010-05-16T09:00:30.000');
INSERT INTO timeLog VALUES(1,3,'2010-05-16T09:01:00.000');
INSERT INTO timeLog VALUES(1,4,'2010-05-16T09:01:30.000');
INSERT INTO timeLog VALUES(1,5,'2010-05-16T09:02:00.000');
-- Qualif finishes
INSERT INTO timeLog VALUES(1,1,'2010-05-16T09:24:49.000');
INSERT INTO timeLog VALUES(1,2,'2010-05-16T09:25:39.000');
INSERT INTO timeLog VALUES(1,3,'2010-05-16T09:26:12.000');
INSERT INTO timeLog VALUES(1,4,'2010-05-16T09:27:05.000');
INSERT INTO timeLog VALUES(1,5,'2010-05-16T09:30:58.000');

CREATE UNIQUE INDEX racer_number on racer(number);
CREATE INDEX racer_country on racer(country);
CREATE INDEX racer_team on racer(team);
CREATE INDEX racer_gender on racer(gender);
COMMIT;
/*
create temporary table position
as select raceId, racerId, count(1) as nb, strftime('%s', max(time)) - strftime('%s', min(time)) as time
from timelog
group by raceId, racerId;

-- Classement général
select country, gender,  number, firstName, (select count(*)
	from position p2
	where p2.raceId = p1.raceId
	and p2.nb >= p1.nb and p2.time <= p1.time) as position
from position p1
inner join racer on id = racerId
where raceId = 1
order by position asc;

-- Classement par pays
select country, gender,  number, firstName, (select count(*)
	from position p2
	inner join racer r2 on r2.id = p2.racerId
	where p2.raceId = p1.raceId
	and r2.country = r1.country
	and p2.nb >= p1.nb and p2.time <= p1.time) as position
from position p1
inner join racer r1 on r1.id = p1.racerId
where raceId = 1
order by country asc, position asc;

-- Classement par pays et par sexe
select country, gender, number, firstName, (select count(*)
	from position p2
	inner join racer r2 on r2.id = p2.racerId
	where p2.raceId = p1.raceId
	and r2.country = r1.country
	and r2.gender = r1.gender
	and p2.nb >= p1.nb and p2.time <= p1.time) as position
from position p1
inner join racer r1 on r1.id = p1.racerId
where raceId = 1
order by country asc, gender asc, position asc;
*/

/*
XSL-FO

*/

/*
create view position
as select raceId, racerId, count(1) as nb, strftime('%s', max(time)) - strftime('%s', min(time)) as time
from timelog
group by raceId, racerId;

select racerId, (select count(*)
	from position p2
	where p2.raceId = p1.raceId
	and p2.nb > p1.nb and p2.time < p1.time)
from position p1 where raceId = 1;
-- Error: misuse of aggregate
*/

