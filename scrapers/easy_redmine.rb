require './scrapers/dump_manager'

class EasyRedmine
  include Capybara::DSL
  include DumpManager

  def initialize
    @homepage_url   = Settings.easy_redmine[:host]

    connect_to_postgres!
  end

  def login_as_admin
    admin_login    = Settings.easy_redmine[:admin][:login]
    admin_password = Settings.easy_redmine[:admin][:password]

    visit "#{@homepage_url}/login"

    fill_in 'username', with: admin_login
    fill_in 'password', with: admin_password

    find('#login_submit_field button').click
  end

  def connect_to_postgres!
    pg = Settings.easy_redmine[:postgres]

    config = {}
    config[:host]     = pg[:host]     if pg[:host]     && !pg[:host].empty?
    config[:port]     = pg[:port]     if pg[:port]     && !pg[:port].to_s.empty?
    config[:dbname]   = pg[:db_name]
    config[:user]     = pg[:username] if pg[:username] && !pg[:username].empty?
    config[:password] = pg[:password] if pg[:password] && !pg[:password].empty?

    @pg_connection = PG.connect(config)
  end

end