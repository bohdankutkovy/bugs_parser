require './scrapers/dump_manager'

class Bugzilla
  include DumpManager

  def initialize
    @homepage_url = Settings.bugzilla[:host]

    connect_to_mysql!
  end

  def login_as_admin
    admin_login    = Settings.bugzilla[:admin][:login]
    admin_password = Settings.bugzilla[:admin][:password]

    visit @homepage_url

    within :css, '#header' do
      if has_css?('#login_link_top')
        click_link 'Log In'

        fill_in 'Bugzilla_login_top',    with: admin_login
        fill_in 'Bugzilla_password_top', with: admin_password

        click_button 'log_in_top'
      end
    end
  end

  def connect_to_mysql!
    mysql  = Settings.bugzilla[:mysql]
    config = {}

    config[:host]     = mysql[:host]     if mysql[:host]     && !mysql[:host].empty?
    config[:port]     = mysql[:port]     if mysql[:port]     && !mysql[:port].to_s.empty?
    config[:database] = mysql[:database]
    config[:username] = mysql[:username] if mysql[:username] && !mysql[:username].empty?
    config[:password] = mysql[:password] if mysql[:password] && !mysql[:password].empty?

    @mysql_connection = Mysql2::Client.new(config)
  end

end