module Model
  Struct.new('Racer', :id, :number, :name)
  Struct.new('Race', :id, :name, :closed, :intervalStarts, :startTime)
  Struct.new('Timelog', :raceId, :racerId, :racerNumber, :racerName, :time, :type)

  def init(db)
    @db = db
    @db.type_translation = true
    @db.execute_batch <<SQL
PRAGMA foreign_keys=ON;
PRAGMA count_changes=ON;
PRAGMA recursive_triggers=ON;
SQL
  end

  def setup(db)
    init(db)
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
      rescue Exception => e then
        return e
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
    rescue Exception => e then
      return e, nil
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
    rescue Exception => e then
      return e
    else
      return nil
    end
  end

  private
  def load_races
    @races = {}
    @db.execute( "SELECT id, name, status, intervalStarts, startTime FROM race" ) do |row|
      @races[row[1]] = Struct::Race.new(row[0], row[1], row[2], row[3], row[4])
    end
  end

  def load_racers
    @racers = {}
    @db.execute( "SELECT id, number, firstName, lastName FROM racer" ) do |row|
      names = row[2, 2]
      names.compact!
      names.delete('')
      @racers[row[1]] = Struct::Racer.new(row[0], row[1], names.join(' '))
    end
  end

  def to_iso_8601(time)
      time.strftime('%Y-%m-%d %H:%M:%S') unless time.nil?
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
