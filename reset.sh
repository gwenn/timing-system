rm race.db
sqlite3 race.db < race_schema.sql
sqlite3 race.db < racers.sql
sqlite3 race.db < races.sql
