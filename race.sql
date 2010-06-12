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
    comment     text,
    primary key (id)
);
INSERT INTO racer VALUES(1,1,'FRA','Paris','Urban',1,'A','','',NULL);
INSERT INTO racer VALUES(2,2,'FRA','Paris','Urban',1,'B','','',NULL);
INSERT INTO racer VALUES(3,3,'FRA','Paris','Urban',1,'C','','',NULL);
CREATE TABLE race (
    id          int not null,
    name        text not null,
    location    text,
    description text,
    primary key (id)
);
INSERT INTO race VALUES(1,'Qualif','Pantin',NULL);
INSERT INTO race VALUES(2,'Main race','Pantin',NULL);
CREATE TABLE timeLog (
    raceId      int not null,
    racerId     int not null,
    step        int not null check (step >= 0),
    time text not null,
    primary key (raceId, racerId, step),
    foreign key (raceId) references race(id),
    foreign key (racerId) references racer(id)
);
INSERT INTO timeLog VALUES(1,1,0,'2010-05-16T09:00:00.000');
INSERT INTO timeLog VALUES(1,2,0,'2010-05-16T09:00:30.000');
INSERT INTO timeLog VALUES(1,3,0,'2010-05-16T09:01:00.000');
INSERT INTO timeLog VALUES(1,1,1,'2010-05-16T09:24:49.000');
INSERT INTO timeLog VALUES(1,2,1,'2010-05-16T09:25:39.000');
INSERT INTO timeLog VALUES(1,3,1,'2010-05-16T09:26:12.000');
CREATE UNIQUE INDEX racer_number on racer(number);
CREATE INDEX racer_country on racer(country);
CREATE INDEX racer_team on racer(team);
CREATE INDEX racer_gender on racer(gender);
COMMIT;
/*
-- classement général
select country, gender, number, firstName, max(step) as n, strftime('%s', max(time)) - strftime('%s', min(time)) as t
from timeLog
inner join racer on racer.id = timeLog.racerId
where raceId = 1
group by racerId order by n desc, t asc
-- classement par pays
select country, gender, number, firstName, max(step) as n, strftime('%s', max(time)) - strftime('%s', min(time)) as t
from timeLog
inner join racer on racer.id = timeLog.racerId
where raceId = 1 and country in ('FRA', 'FIN')
group by racerId order by country asc, n desc, t asc
-- classement par sexe
select country, gender, number, firstName, max(step) as n, strftime('%s', max(time)) - strftime('%s', min(time)) as t
from timeLog
inner join racer on racer.id = timeLog.racerId
where raceId = 1 and country in ('FRA', 'FIN')
group by racerId order by country asc, gender asc, n desc, t asc
*/
