=begin rdoc
=GUI to enter timelogs
1) Race selection and optional race start.

2) Filling timelogs for the selected race (1)
 * interval starts (qualifs)
  - specify racer number, start time and end time (two timelogs are generated).
 * one start (finals)
  - specify racer number, nth manifest completion time (one timelog by manifest).

3) Race closing/validation (to generate definitive results)
=end
BEGIN {
  p "BEGIN";
}

END {
  p "END"; # FIXME Never called (linux:wmii)!
}

Struct.new('Racer', :id, :number, :name)
Struct.new('Race', :id, :name, :closed, :intervalStarts, :startTime)
Struct.new('Timelog', :raceId, :racerId, :time)

class Model
  def initialize
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
      race.startTime = startTime
      race.closed = closed
      # UPDATE race SET startTime = :startTime, status = :status WHERE id =
      # :id
      return nil # err_msg or nil
    end
  end

#  def reload_races
#    load_races()
#  end

  def racer_by_number(number)
    return @racers[number]
  end

  def add_timelogs(race, racer, *times)
    # TODO One racer can be filled only once (=> max two entries in the
    # timelog) for Qualif. 
    # BEGIN TRANSACTION
    # INSERT INTO timelog VALUES (:raceId, :racerId, :time)
    # ...
    # COMMIT
    timelogs = []
    times.each do |time|
      timelogs.push Struct::Timelog.new(race.id, racer.id, time)
    end
    return nil, times
  end

  def deleteTimeLog(timelog)
    # DELETE FROM timelog WHERE raceId = :raceId AND racerId = :racerId AND
    # time = :time
  end

  private
  def load_races
    @races = { 'Main Race Qualif' => Struct::Race.new(1, 'Main Race Qualif', true, true, nil),
      'Main Race Final' => Struct::Race.new(2, 'Main Race Final', false, false, nil) }
  end

  def load_racers
    @racers = { 1 => Struct::Racer.new(1, 1, 'A'),
      2 => Struct::Racer.new(2, 2, 'B') }
  end
end

class TimeWidget < Shoes::Widget
  # TODO Auto-next when previous field is filled
  # TODO How to make controls (only numbers, max 2 digits, in [0, 23]
  # for hour and [0, 59] for min/sec?
  def initialize opts = {}
    @hour = edit_line :width => 24, :state => opts[:state]
    @hour.change opts[:handler]
    para ':'
    @min = edit_line :width => 24, :state => opts[:state]
    @min.change opts[:handler]
    para ':'
    @sec = edit_line :width => 24, :state => opts[:state]
    @sec.change opts[:handler]
  end

  def time
    # TODO Factorize
    if @hour.text !~ /^\d{2}$/ || (not (0..23).include? @hour.text.to_i) then
      @hour.focus()
      return nil
    end
    if @min.text !~ /^\d{2}$/ || (not (0..59).include? @min.text.to_i) then
      @min.focus()
      return nil
    end
    # TODO Are seconds mandatory?
    if @sec.text !~ /^\d{2}$/ || (not (0..59).include? @sec.text.to_i) then
      @sec.focus()
      return nil
    end
    # FIXME Ugly
    now = Time.now.to_a
    now[0..2] = [@sec.text.to_i, @min.text.to_i, @hour.text.to_i]
    return Time.local(*now)
  end

  def time=(time)
    if time.nil? then
      @hour.text = ''
      @min.text = ''
      @sec.text = ''
    else
      @hour.text = format '%02d', time.hour
      @min.text = format '%02d', time.min
      @sec.text = format '%02d', time.sec
    end
  end
end

# FIXME window and dialog cannot be made modal!

Shoes.app :title => 'FFCMC 2010',
  :width => 220, :height => 150, :resizable => false do
  @model = Model.new
  stack do
    @race = list_box :items => @model.races, :choose => nil, :margin => 5, :width => 1.0
    @race.change do
      race_selected(@model.race_by_name(@race.text))
    end
    @set_button = button 'Settings', :state => 'disabled', :margin => 5, :width => 1.0 do
      window :title => "Settings", :width => 230, :height => 190, :resizable => false do
        @current_race = owner.current_race
        change_handler = lambda { race_changed }
        flow do
          stack :width => 90 do
            para 'Name:'
            para 'Start Time:'
            para 'Closed:'
          end
          stack :width => -90 do
            para "#{@current_race.name}"
            @time = time_widget :state => (@current_race.intervalStarts ? 'disabled' : nil),
                :handler => change_handler
            @time.time = @current_race.startTime
            @close_check = check :checked => @current_race.closed, :click => change_handler
          end
        end
        flow do
          # FIXME Disabled state does not work properly
          @ok_button = button 'Ok', :state => 'disabled', :margin => 5, :width => 0.5 do
            if not @current_race.intervalStarts then
              time = @time.time
              # TODO Allow time in the future? 
              next if time.nil?
            end
            err_msg = owner.update_race(time, @close_check.checked?)
            if err_msg.nil? then
              close()
            else
              error(err_msg)
              @error.replace(err_msg[0,60])
            end
          end
          @cancel_button = button 'Cancel', :margin => 5, :width => 0.5, :click => lambda { close() }
        end
        @error = para :stroke => red, :underline => 'single', :click => lambda { Shoes.show_log }

        def race_changed
          @ok_button.state = nil if @ok_button.state == 'disabled'
        end
      end
    end
    @manifests_button = button 'Manifests', :state => 'disabled', :margin => 5, :width => 1.0 do
      window :title => "Manifests - #{@current_race.name}", :width => 380, :height => 360 do
        @current_race = owner.current_race
        flow do
          stack :width => 130 do
            para 'Racer Number:', :margin => 10
            if @current_race.intervalStarts then
              para 'Start Time:'
              para 'End Time:'
            else
              para 'Inter./End Time:'
            end
          end
          stack :width => -130 do
            @racer_number = edit_line :width => 48, :margin => 5
            if @current_race.intervalStarts then
              @start_time = time_widget
            end
            @end_time = time_widget
          end
        end
        flow do
          reset_action = lambda {
            @racer_number.text = nil
            if @current_race.intervalStarts then
              @start_time.time = nil
            end
            @end_time.time = nil
            @racer_number.focus()
            @error.text = nil
          }
          button 'Add', :margin => 5, :width => 0.3 do
            # @racer_number: numeric only, max 4 digits
            if @racer_number.text !~ /^\d{1,4}$/ then
              @racer_number.focus()
              next
            else
              racer = owner.racer_by_number(@racer_number.text.to_i)
              if racer.nil? then
                @racer_number.focus()
                display_error("There is no racer with number: #{@racer_number.text}")
                next
              end
            end
            # @start_time < @end_time
            if @current_race.intervalStarts then
              start_time = @start_time.time
              next if start_time.nil?
              end_time = @end_time.time
              next if end_time.nil?
              if end_time <= start_time then
                display_error("End time must be greater than start time!")
                next
              end
            else
              end_time = @end_time.time
              next if end_time.nil?
            end
            if @current_race.intervalStarts then
              err_msg, timelogs = owner.add_timelogs(@current_race, racer, start_time, end_time)
            else
              err_msg, timelogs = owner.add_timelogs(@current_race, racer, end_time)
            end
            if err_msg.nil? then
              display_timelogs(timelogs)
              reset_action.call
            else
              display_error(err_msg)
            end
          end
          # TODO Useful?
          button 'Reset', :margin => 5, :width => 0.3, :click => reset_action 
          button 'Close', :margin => 5, :width => 0.3, :click => lambda { close() }
        end
        @timelogs_slot = stack :width => 1.0, :height => 150, :scroll => true do
=begin Nested dialogs don't display correctly
            para link "last #{i} timelog...", :click => lambda {
              if confirm('Really delete?') then
                # TODO
              end
            }
=end
        end
        @error = para :stroke => red, :underline => 'single', :click => lambda { Shoes.show_log }

        @timelogs = []
        def display_timelogs(timelogs)
          @timelogs_slot.append do
            f = flow do
              p = para "last timelog..."
              l = para '| remove'
              check :click => lambda { |c|
                p.strikethrough = 'single'
                c.remove()
                l.remove()
              }
            end
            @timelogs.unshift f
            @timelogs.pop.remove if @timelogs.size > 10
          end
        end
        def display_error(err_msg)
          error(err_msg)
          @error.replace(err_msg[0,60])
        end
      end
    end
  end

  def race_selected(race)
    @current_race = race
    @set_button.state = nil if @set_button.state == 'disabled'
    if not @current_race.closed then
      @manifests_button.state = nil
    else
      @manifests_button.state = 'disabled'
    end
  end

  # FIXME attr :current_race
  def current_race
    return @current_race
  end
  def update_race(startTime, closed)
    err_msg = @model.update_race(@current_race, startTime, closed)
    if err_msg.nil? then
      race_selected(@current_race)
      # info("Race '#{@current_race.name}' updated")
    end
    return err_msg
  end
  def racer_by_number(number)
    return @model.racer_by_number(number)
  end
  def add_timelogs(race, racer, *times)
    err_msg, timelogs = @model.add_timelogs(@current_race, racer, times)
    return err_msg, timelogs
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2: