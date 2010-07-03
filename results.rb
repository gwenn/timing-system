require 'sqlite3'
require 'model'
require 'erb'

trap('INT') do
  puts 'ByeBye...'
  exit(0)
end

DB_NAME = 'race.db'
DATABASE = SQLite3::Database.new DB_NAME

extend Model
init_model(DATABASE)

@current_race = @first_open_race
puts @current_race

erb = ERB.new(File.read('results.rhtml'))

old_mtime = nil
old_version = 0
loop do
  mtime = File.mtime(DB_NAME)
  # Database modification seems to be a good/cheap way to test if anything
  # changes...
  if (old_mtime.nil? || old_mtime != mtime) then
    version = last_results_version(@current_race)
    if (version > old_version) then
      old_mtime = mtime
      old_version = version
      p overall_results_by_gender(@current_race)
      p results_by_country_and_gender(@current_race)
    end
  end
  sleep(120) # TODO Adjusts
end

=begin
Shoes::app do
  start do
    exit
  end
end
=end
# vim: set expandtab softtabstop=2 shiftwidth=2:
