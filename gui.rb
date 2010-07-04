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
require 'sqlite3'
require 'model'

DATABASE = SQLite3::Database.new 'race.db'

class TimeWidget < Shoes::Widget
  def initialize opts = {}
    @field = edit_line :width => 96, :state => opts[:state]
    @field.change opts[:handler]
    @original_time = nil
  end

  def time
    begin
      if (@field.text =~ /^\d{1,2}:\d{2}(?::\d{2})?$/)
        time = Time.parse(@field.text, @original_time.nil? ? Time.now : @original_time)
        return time
      else
        error('KO')
        @field.focus()
        return nil
      end
    rescue => e
      error(e)
      @field.focus()
      return nil
    end
  end

  def time=(time)
    @original_time = time
    if time.nil? then
      @field.text = ''
    else
      @field.text = time.strftime('%H:%M:%S')
    end
  end
end

# FIXME window and dialog cannot be made modal!
Shoes.app :title => 'FFCMC 2010',
  :width => 220, :height => 150, :resizable => false do
  extend Model
  init_model(DATABASE)

  stack do
    list_box :items => races(), :choose => nil, :margin => 5, :width => 1.0 do |list|
      race_selected(race_by_name(list.text))
    end
    @set_button = button 'Settings', :state => 'disabled', :margin => 5, :width => 1.0 do
      window :title => 'Settings', :width => 280, :height => 190 do
        @current_race = owner.current_race
        change_handler = proc { |src| race_changed }
        flow do
          stack :width => 90 do
            para 'Name:'
            para 'Start Time:'
            para 'Closed:'
          end
          stack :width => -90 do
            para @current_race.name
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
            err_msg = owner.update_and_reload_race(time, @close_check.checked?)
            if err_msg.nil? then
              close()
            else
              error(err_msg)
              @error.replace(err_msg[0,60])
            end
          end
          @cancel_button = button 'Cancel', :margin => 5, :width => 0.5, :click => proc { |src| close() }
        end
        @error = para :stroke => red, :underline => 'single', :click => proc { |src| Shoes.show_log }

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
          reset_action = proc { |src|
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
                display_error('End time must be greater than start time!')
                next
              end
            else
              end_time = @end_time.time
              next if end_time.nil?
              if end_time <= @current_race.startTime then
                display_error('End time must be greater than start time!')
                next
              end
            end
            if @current_race.intervalStarts then
              err_msg, timelogs = owner.add_timelogs(@current_race, racer, start_time, end_time)
            else
              err_msg, timelogs = owner.add_timelogs(@current_race, racer, end_time)
            end
            if err_msg.nil? then
              display_timelogs(timelogs)
              reset_action.call(nil)
            else
              display_error(err_msg)
            end
          end
          # TODO Useful?
          button 'Reset', :margin => 5, :width => 0.3, :click => reset_action
          button 'Close', :margin => 5, :width => 0.3, :click => proc { |src| close() }
        end
        @timelogs_slot = stack :width => 1.0, :height => 150, :scroll => true do
=begin Nested dialogs don't display correctly
            para link "last #{i} timelog...", :click => proc {
              if confirm('Really delete?') then
              end
            }
=end
        end
        @error = para :stroke => red, :underline => 'single', :click => proc { |src| Shoes.show_log }

        @timelogs = []
        def display_timelogs(timelogs)
          @timelogs_slot.prepend do
            f = flow do
              p = para timelogs.first.racerName, ' (', timelogs.first.racerNumber, ')',
                ' : ', timelogs.first.time.strftime('%H:%M:%S'),
                (@current_race.intervalStarts ? ' - ' +timelogs[1].time.strftime('%H:%M:%S') : '')
              l = para '| remove'
              check :click => proc { |c|
                err_msg = owner.delete_timelogs(timelogs)
                if err_msg.nil? then
                  p.strikethrough = 'single'
                  c.remove()
                  l.remove()
                else
                  display_error(err_msg)
                end
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
    if (not @current_race.closed) && (@current_race.intervalStarts || (not @current_race.startTime.nil?)) then
      @manifests_button.state = nil
    else
      @manifests_button.state = 'disabled'
    end
  end

  # FIXME attr :current_race
  def current_race
    return @current_race
  end
  def update_and_reload_race(startTime, closed)
    err_msg = update_race(@current_race, startTime, closed)
    if err_msg.nil? then
      race_selected(@current_race)
      # info("Race '#{@current_race.name}' updated")
    end
    return err_msg
  end
  #Shoes.show_log
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
