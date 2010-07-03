=begin rdoc
=GUI to generate results
=end
require 'sqlite3'
require 'model'
require 'erb'
require 'uri'
require 'fileutils'

RACERS_PER_PAGE = 5 # 20
SLEEP_DURATION = 120

DB_NAME = 'race.db'
DATABASE = SQLite3::Database.new DB_NAME

TEMPLATE = ERB.new(File.read('results.rhtml'), nil, '<>')
TMP_FILE_PATH = './results.tmp'

class ResultPage
  def initialize(race, country, gender, results, page)
    @race = race
    @results_title = get_title(country, gender)
    @path = get_path(country, gender, page)
    @results = results
    @display_status = (not @race.closed) && (not @race.intervalStarts)
    @display_manifests = (not @race.intervalStarts)
  end

  def path
    return @path
  end

  def next_page=(next_page)
    @next_page = URI.parse 'file://' + File.expand_path(next_page)
  end

  def get_binding
    binding
  end

  private
  def get_title(country, gender)
    parts = []
    parts << get_country_label(country) + ' Results'
    parts << get_gender_label(gender)
    parts.compact!
    return parts.join(' - ')
  end
  def get_path(country, gender, page)
    parts = []
    parts << (get_country_label(country) + 'Results')
    parts << get_gender_label(gender)
    parts << (page + 1)
    parts << '.html'
    parts.compact!
    return parts.join()
  end

  def get_country_label(country)
    if country.nil? then
      'Overall'
    elsif country == 'FIN' then
      'Finland'
    elsif country == 'FRA' then
      'France'
    else
      'TODO'
    end
  end
  def get_gender_label(gender)
    if gender == 'F' then
      'Women'
    elsif gender == 'M' then
      'Men'
    else
      nil
    end
  end
end

Shoes.app :title => 'FFCMC 2010 - Results Generation',
  :width => 300, :height => 150, :resizable => false do
  extend Model
  init_model(DATABASE)

  @current_race = @first_open_race
  stack do
    para 'Current race: ', @current_race.name
    @status = para '...'
    @error = para :stroke => red, :underline => 'single', :click => proc { |src| Shoes.show_log }
  end

  old_mtime = nil
  old_version = 0

  start do
    Thread.start do
      begin
        loop do
          mtime = File.mtime(DB_NAME)
          # Database modification seems to be a good/cheap way to test if anything
          # changes...
          if (old_mtime.nil? || old_mtime != mtime) then
            version = last_results_version(@current_race)
            if (version > old_version) then
              @status.replace "Updating..."
              old_mtime = mtime
              old_version = version
             
              pages = [] 
              # Sort OK: 'F' < 'M'
              overall_results_by_gender(@current_race).sort.each do |pair|
                gender = pair[0]
                results = pair[1]
                results.sort! { |x,y| x.rank <=> y.rank }

                for i in 0..((results.size - 1) / RACERS_PER_PAGE)
                  pages << ResultPage.new(@current_race, nil, gender, results[i * RACERS_PER_PAGE,RACERS_PER_PAGE], i)
                end
              end

              # Sort OK: 'FIN' < 'FRA'
              results_by_country_and_gender(@current_race).sort.each do |pair|
                country = pair[0]
                sub_results = pair[1]
                # Sort OK: 'F' < 'M'
                sub_results.sort.each do |sub_pair|
                  gender = sub_pair[0]
                  results = sub_pair[1]
                  results.sort! { |x,y| x.rank <=> y.rank }

                  for i in 0..((results.size - 1) / RACERS_PER_PAGE)
                    pages << ResultPage.new(@current_race, country, gender, results[i * RACERS_PER_PAGE,RACERS_PER_PAGE], i)
                  end
                end
              end

              # Next pages
              pages.each_with_index do |page, i|
                next_page = pages[i+1]
                if next_page.nil? then # Loop
                  page.next_page = pages.first.path
                else
                  page.next_page = next_page.path
                end
              end

              # Writing
              pages.each do |page|
                update_page(page.path, page)
              end
            else
              @status.replace "Sleeping..."
            end
          else
            @status.replace "Sleeping..."
          end
          sleep(SLEEP_DURATION)
        end
      rescue => e 
        error(e)
        @error.replace(e.message[0,60])
      end
    end
  end

  def update_page(page_path, content)
    File.open(TMP_FILE_PATH, 'w') do |file|
      file.write(TEMPLATE.result(content.get_binding))
    end
    FileUtils.mv TMP_FILE_PATH, page_path, :force => true
  end
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
