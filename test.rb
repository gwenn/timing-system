require 'sqlite3'
require 'model'
require 'test/unit'
require 'fileutils'

class TestModel < Test::Unit::TestCase
  include Model
  def setup
    FileUtils.cp 'race.db', 'test.db'
    @db = SQLite3::Database.new 'test.db'
    setup_db(@db)
  end
  def teardown
    @db.close
  end

  def test_races
    init_model(@db)
    names = races()
    assert_same(2, names.size)
    names.each do |name|
      race = race_by_name(name)
      assert(! race.closed)
      assert_nil(race.startTime)
    end
  end

  def test_racers
    init_model(@db)
    assert(! @racers.nil?)
    assert(! @racers.empty?)
    assert(! racer_by_number(@racers[0].number).nil?)
  end

  def test_timelog_checks
    racer = Struct::Racer.new(1)
    now = Time.now
    # Qualifs:
    race = Struct::Race.new(1)
    assert_equal('constraint failed', update_race(race, now, false))
    add_timelogs(race, racer, now, now + 3600)
    assert_equal('Only two timelogs expected during qualifications.', add_timelogs(race, racer, now + 7200)[0])

    # Finals:
    race = Struct::Race.new(2)
    assert_equal('No timelog can be inserted until race start time is specified.', add_timelogs(race, racer, now)[0])
    assert_nil(update_race(race, now, false))
    assert_equal('No timelog can be inserted with a time lesser than race start time.', add_timelogs(race, racer, now - 3600)[0])
    err, timelogs = add_timelogs(race, racer, now + 3600)
    assert_nil(err)
    assert(1, timelogs.size)
    assert_equal('Race start time cannot be lesser than associated timelog(s).', update_race(race, now + 7200, false))

    # Closed Race
    assert_nil(update_race(race, now, true))
    assert_equal('No timelog can be inserted for a closed race.', add_timelogs(race, racer, now + 7200)[0])
    assert_equal('No timelog can be deleted for a closed race.', delete_timelogs(timelogs))
  end

  def test_qualifs_result
    now = Time.now
    race = Struct::Race.new(1)
    racer1 = Struct::Racer.new(1)
    racer2 = Struct::Racer.new(2)
    racer3 = Struct::Racer.new(3)
    racer4 = Struct::Racer.new(4)
    racer5 = Struct::Racer.new(5)
    add_timelogs(race, racer1, now, now + 3600)
    add_timelogs(race, racer2, now, now + 3500)
    add_timelogs(race, racer3, now, now + 3700)
    add_timelogs(race, racer4, now, now + 3400)
    add_timelogs(race, racer5, now, now + 3800)
    version = last_results_version(race)
    assert_not_equal(0, version)
    assert_nil(update_race(race, nil, true))
    new_version = last_results_version(race)
    #assert_not_equal(version, new_version)
    results = overall_results_by_gender(race)
    assert_equal(1, results.size)
    p results
  end

  def test_finals_results
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
