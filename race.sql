create table racer (
    id          int not null,
    number      int not null, -- TODO Validate
    country     text not null, -- TODO Validate country table?
    city        text,
    team        text, -- TODO Validate team table?
    gender      int not null check (gender in (1, 2)),
    firstName   text not null,
    lastName    text not null,
    nickName    text,
    comment     text,
    primary key (id)
);

create unique index racer_number on racer(number); 
create index racer_country on racer(country);
create index racer_team on racer(team);
create index racer_gender on racer(gender);

create table race (
    id          int not null,
    name        text not null,
    location    text,
    description text,
    primary key (id)
);

create table timeLog (
    raceId      int not null,
    racerId     int not null,
    step        int not null check (step >= 0) default 0,
--    stage       text, -- Steps are sequential but stage may be done/distributed in random/different order...
    time text not null,
--    creditTime  text, -- TODO Validate time vs points, negative values are penalties
--    status      int, -- TODO To be specified
    primary key (raceId, racerId, step), -- TODO Validate
    foreign key (raceId) references race(id),
    foreign key (racerId) references racer(id)
);

/*
create trigger nextStep
after update of endTime, status -- endTime or status...
on timeLog
when new.endTime is not null and new.status in (0) -- TODO To be specified 
begin
    insert into timeLog (raceId, racerId, step, startTime) values (old.raceId, old.racerId, old.step + 1, new.endTime); -- TODO next start time may not be automatic!
end;
*/
