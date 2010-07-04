module Model
  Struct.new('Racer', :id, :number, :name)
  Struct.new('Race', :id, :name, :closed, :intervalStarts, :startTime)
  Struct.new('Timelog', :raceId, :racerId, :racerNumber, :racerName, :time, :type)
  Struct.new('Result', :rank, :manifests, :status, :time, :number, :name, :company, :city, :country, :gender)

  def init_model(db)
    @db = db
    @db.type_translation = true
    @db.execute_batch <<SQL
PRAGMA foreign_keys=ON;
PRAGMA count_changes=ON;
PRAGMA recursive_triggers=ON;
SQL
    load_races()
    load_racers()
  end

  def races
    return @races.keys
  end

  def race_by_name(name)
    return @races[name]
  end

  def update_race(race, startTime, closed)
    if race.startTime != startTime || race.closed != closed then
      begin
        @db.execute('UPDATE race SET startTime = ?, status = ? WHERE id = ?',
                         to_iso_8601(startTime), closed ? 1 : 0, race.id)
        race.startTime = startTime
        race.closed = closed
      rescue => e
        return e.message
      else
        return nil
      end
    end
    nil
  end

  def racer_by_number(number)
    return @racers[number]
  end

  def add_timelogs(race, racer, *times)
    # TODO One racer can be filled only once (=> max two entries in the
    # timelog) for Qualif.
    timelogs = []
    begin
      @db.transaction do |db|
        db.prepare('INSERT INTO timelog VALUES (?, ?, ?, ?)') do |stmt|
          times.each_index do |i|
            time = times[i]
            type = (i == 0 && race.intervalStarts) ? 0 : 1
            stmt.execute(race.id, racer.id, to_iso_8601(time), type)
            timelogs.push Struct::Timelog.new(race.id, racer.id, racer.number, racer.name, time, type)
          end
        end
      end
    rescue => e
      return e.message, nil
    else
      return nil, timelogs
    end
  end

  def delete_timelogs(timelogs)
    begin
      @db.transaction do |db|
        timelogs.each do |t|
          db.execute('DELETE FROM timelog WHERE raceId = ? AND racerId = ? AND time = ?',
                     t.raceId, t.racerId, to_iso_8601(t.time))
        end
      end
    rescue => e
      return e.message
    else
      return nil
    end
  end

  def check_race_status(race)
    return @db.get_first_value('SELECT status FROM race WHERE id = ?', race.id)
  end

  def last_results_version(race)
    return @db.get_first_value('SELECT time FROM resultVersion WHERE raceId = ?', race.id) || 0
  end
  
  RESULTS_QUERY = <<SQL
SELECT rank, nb, CASE WHEN prevRank IS NULL THEN NULL
                         WHEN rank - prevRank > 0 THEN '-'
                         WHEN rank - prevRank < 0 THEN '+'
                         ELSE '=' END as delta, time(duration, 'unixepoch'), number, firstName, lastName, company, city, country,
       CASE gender WHEN 1 THEN 'M' ELSE 'F' END AS g
FROM result
INNER JOIN racer ON racer.id = result.racerId
WHERE result.raceId = ? AND result.type = ?
SQL

  def overall_results_by_gender(race)
    results = Hash.new { |h,k| h[k] = [] }
    @db.execute(RESULTS_QUERY, race.id, 0) do |row|
      result = Struct::Result.new(row[0], row[1], row[2], row[3], row[4],
                                  format_names(row[5..6]), row[7], row[8], row[9], row[10])
      results[result.gender].push result
    end
    return results
  end

  def results_by_country_and_gender(race)
    results = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = [] } }
    @db.execute(RESULTS_QUERY, race.id, 1) do |row|
      result = Struct::Result.new(row[0], row[1], row[2], row[3], row[4],
                                  format_names(row[5..6]), row[7], row[8], row[9], row[10])
      results[result.country][result.gender].push result
    end
    return results
  end

  private
  def load_races
    @races = {}
    @db.execute('SELECT id, name, status, intervalStarts, startTime FROM race') do |row|
      race = Struct::Race.new(row[0], row[1], row[2], row[3], row[4])
      @races[row[1]] = race
    end
  end

  def load_racers
    @racers = {}
    @db.execute('SELECT id, number, firstName, lastName FROM racer') do |row|
      @racers[row[1]] = Struct::Racer.new(row[0], row[1], format_names(row[2, 2]))
    end
  end

  def to_iso_8601(time)
      time.strftime('%Y-%m-%d %H:%M:%S') unless time.nil?
  end
  def format_names(names)
    names.compact!
    names.delete('')
    #names.map! {|name| name.capitalize! } # FIXME Doesn't work!!!
    return names.join(' ')
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
