require 'sqlite3'
require 'model'

trap('INT') do
  puts 'ByeBye...'
  exit(0)
end

DB_NAME = 'race.db'
DATABASE = SQLite3::Database.new DB_NAME

extend Model
init_model(DATABASE)

old_mtime = nil
loop do
  mtime = File.mtime(DB_NAME)
  # Database modification seems to be a good/cheap way to test if anything
  # changes...
  if (old_mtime.nil? || old_mtime != mtime) then
    old_mtime = mtime
  end
  sleep(120) # TODO Adjusts
end
# vim: set expandtab softtabstop=2 shiftwidth=2:
