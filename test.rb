require 'sqlite3'
require 'model'
require 'test/unit'

class TestModel < Test::Unit::TestCase
  include Model
  def setup
    File.delete 'test.db'
    # @db.execute_batch(IO.read 'race_schema.sql') # SQLite3::MisuseException
    assert(system('sqlite3 test.db < race_schema.sql'))
    @db = SQLite3::Database.new 'test.db'
    @db.execute_batch <<SQL
PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;
INSERT INTO race VALUES(NULL,'Main Race Qualification',1,NULL,0);
INSERT INTO race VALUES(NULL,'Main Race Final',0,NULL,0);
COMMIT;
SQL
    init_model(@db)
    
  end
  def teardown
    @db.close
  end

  def test_races
    names = races()
    assert_same(2, names.size)
    names.each do |name|
      race = race_by_name(name)
      assert(! race.closed)
      assert_nil(race.startTime)
    end
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
