require 'pry'
require 'ruby-progressbar'
require 'fileutils'
require 'open-uri'
require 'time'

require "mysql2"
require "pg"

Dir["./config/*.rb"].each   { |f| require f }

Dir["./scrapers/*.rb"].each { |f| require f }
Dir["./scrapers/bugzilla/*.rb"].each     { |f| require f }
Dir["./scrapers/easy_redmine/*.rb"].each { |f| require f }

Dir["./tasks/*.rake"].each { |r| import r }