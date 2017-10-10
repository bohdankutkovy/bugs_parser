class UserScraper < Bugzilla

  def initialize
    super
  end

  def scrape_all
    p "Parsing users..."

    progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total: 120
    )

    data = {users: []}

    users = @mysql_connection.query("SELECT * FROM profiles")

    users.each do |user|
      data[:users] << {
        bugzilla_id:           user['userid'],
        login:                 user['login_name'],
        email:                 "#{user['login_name'].downcase}@regin.se",
        first_name:            user['realname'].split(' ').first,
        last_name:             user['realname'].split(' ').last,
        password:              'regin2017',
        password_confirmation: 'regin2017'
      }

      progressbar.increment
    end

    progressbar.finish

    write_dump 'users', data
  end

end