require 'sqlite3'
require 'model'
require 'test/unit'
require 'fileutils'

class TestModel < Test::Unit::TestCase
  include Model
  def setup
    FileUtils.cp 'race.sdb', 'test.sdb'
    @db = SQLite3::Database.new 'test.sdb'
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

  WOMENS = [ Struct::Racer.new(21), Struct::Racer.new(48), Struct::Racer.new(55), Struct::Racer.new(59) ]
  FINISH_MENS = [ Struct::Racer.new(19), Struct::Racer.new(27), Struct::Racer.new(56), Struct::Racer.new(65),
                  Struct::Racer.new(72) ]
  FRENCH_MENS = [ Struct::Racer.new(12), Struct::Racer.new(14), Struct::Racer.new(22), Struct::Racer.new(24),
                  Struct::Racer.new(42), Struct::Racer.new(57), Struct::Racer.new(70), Struct::Racer.new(73),
                  Struct::Racer.new(74), Struct::Racer.new(47) ]
  OTHER_MENS = [ Struct::Racer.new(32), Struct::Racer.new(39), Struct::Racer.new(45), Struct::Racer.new(53),
                  Struct::Racer.new(54), Struct::Racer.new(62) ]
  RACERS = WOMENS + FINISH_MENS + FRENCH_MENS + OTHER_MENS

  def test_qualifs_result
    srand 1234
    now = Time.now
    race = Struct::Race.new(1, 'Qualifs', false, true)
    RACERS.each do |racer|
      add_timelogs(race, racer, now, now + 3600 + rand(3600))
    end
    version = last_results_version(race)
    assert_not_equal(0, version)
    sleep 1
    assert_nil(update_race(race, nil, true))
    new_version = last_results_version(race)
    assert_not_equal(version, new_version)
    results = overall_results_by_gender(race)
    # TODO Assertions
  end

  def test_finals_results
    srand 1234
    now = Time.now
    race = Struct::Race.new(2, 'Finals', false, false)
    assert_nil(update_race(race, now, false))
    previous_times = Array.new(RACERS.length, now)
    15.times do |t|
      RACERS.each_with_index do |racer,i|
        if t < 10 || rand(t) < 10 then
          next_time = previous_times[i] + 3600 + rand(3600)
          previous_times[i] = next_time
          add_timelogs(race, racer, next_time)
        end
      end
    end
    version = last_results_version(race)
    assert_not_equal(0, version)
    sleep 1
    assert_nil(update_race(race, race.startTime, true))
    new_version = last_results_version(race)
    assert_not_equal(version, new_version)
    results = overall_results_by_gender(race)
    # TODO Assertions
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
