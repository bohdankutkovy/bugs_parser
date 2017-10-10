require 'yaml'
require 'hashie'

class Settings
  include Singleton

  def self.all
    settings = YAML.load_file('config/settings.yml')
    Hashie.symbolize_keys settings
  end

  def self.bugzilla
    all[:bugzilla]
  end

  def self.easy_redmine
    all[:easy_redmine]
  end

end