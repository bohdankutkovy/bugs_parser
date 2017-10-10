class UserFiller < EasyRedmine

  def initialize
    @users = read_dump 'users'
    super
  end

  def fill_all
    p 'Importing users...'

    progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total:          @users[:users].count + 1
    )

    @users[:users].each do |user|
      fill_one user
      progressbar.increment
    end

    progressbar.finish
  end

  def fill_one data
    timestamp = Time.now

    login              = data[:login]
    hashed_password    = "9469e0b67b856bd6761317b92ef116cc2e9d7ef4" # regin2017
    firstname          = data[:first_name]
    lastname           = data[:last_name]
    admin              = false
    status             = 1
    language           = "en"
    created_on         = timestamp
    updated_on         = timestamp
    type               = "User"
    mail_notification  = "only_my_events"
    salt               = "014a67ae36fd7a9f6cdb498fdae8b243" # salt for regin2017
    must_change_passwd = true
    passwd_changed_on  = timestamp
    easy_system_flag   = false
    easy_user_type_id  = 1
    easy_lesser_admin  = false
    self_registered    = false
    easy_digest_token  = "4139f70530b8148f5ac17f53dde5bc14"

    # create user
    result = @pg_connection.exec "
      INSERT INTO users (login,      hashed_password,      firstname,      lastname,      admin,    status,    language,      created_on,      updated_on,      type,      mail_notification,      salt,      must_change_passwd,    passwd_changed_on,      easy_system_flag,    easy_user_type_id,    easy_lesser_admin,    self_registered,    easy_digest_token) 
      VALUES            ('#{login}', '#{hashed_password}', '#{firstname}', '#{lastname}', #{admin}, #{status}, '#{language}', '#{created_on}', '#{updated_on}', '#{type}', '#{mail_notification}', '#{salt}', #{must_change_passwd}, '#{passwd_changed_on}', #{easy_system_flag}, #{easy_user_type_id}, #{easy_lesser_admin}, #{self_registered}, '#{easy_digest_token}')
      RETURNING id
    "

    # fill bugzilla id
    user_id         = result.first['id']
    custom_field_id = get_custom_field_id 'Bugzilla ID'
    value           = data[:bugzilla_id]
    fill_custom_field user_id, custom_field_id, value

    # create email_address for user
    @pg_connection.exec "
      INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
      VALUES (#{user_id}, '#{data[:email]}', #{true}, #{true}, '#{created_on}', '#{updated_on}')
    "
  end

  protected

  def get_custom_field_id field_name
    result = @pg_connection.exec "
      SELECT * FROM custom_fields 
      WHERE type = 'IssueCustomField' AND name = '#{field_name}'
    "
    result.first['id']
  end

  def fill_custom_field redmine_id, custom_field_id, value
    @pg_connection.exec "
      INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value) 
      VALUES ('Issue', #{redmine_id}, #{custom_field_id}, '#{value}') 
      RETURNING id
    "
  end

end