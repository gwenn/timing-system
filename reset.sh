rm race.db
sqlite3 race.db < race_schema.sql
sqlite3 race.db < race_test_data.sql
sqlite3 race.db < race_test_queries.sql
