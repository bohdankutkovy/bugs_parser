namespace :patch do

  task :run do

    # PG connection
    pg        = Settings.easy_redmine[:postgres]
    pg_config = {}
    pg_config[:host]     = pg[:host]     if pg[:host]     && !pg[:host].empty?
    pg_config[:port]     = pg[:port]     if pg[:port]     && !pg[:port].to_s.empty?
    pg_config[:dbname]   = pg[:db_name]
    pg_config[:user]     = pg[:username] if pg[:username] && !pg[:username].empty?
    pg_config[:password] = pg[:password] if pg[:password] && !pg[:password].empty?
    @pg_connection = PG.connect(pg_config)

    # MySQL connection
    mysql        = Settings.bugzilla[:mysql]
    mysql_config = {}
    mysql_config[:host]     = mysql[:host]     if mysql[:host]     && !mysql[:host].empty?
    mysql_config[:port]     = mysql[:port]     if mysql[:port]     && !mysql[:port].to_s.empty?
    mysql_config[:database] = mysql[:database]
    mysql_config[:username] = mysql[:username] if mysql[:username] && !mysql[:username].empty?
    mysql_config[:password] = mysql[:password] if mysql[:password] && !mysql[:password].empty?
    @mysql_connection = Mysql2::Client.new(mysql_config)

    def redmine_id_by_bugzilla_id bugzilla_bug_id
      bugzilla_id_field    = @pg_connection.exec "
        SELECT * FROM custom_fields 
        WHERE type = 'IssueCustomField' AND name = 'Bugzilla ID'
      "
      bugzilla_id_field_id = bugzilla_id_field.first['id'].to_i
      
      custom_value         = @pg_connection.exec "
        SELECT * FROM custom_values 
        WHERE customized_type = 'Issue' AND custom_field_id = '#{bugzilla_id_field_id}' AND value = '#{bugzilla_bug_id}'
      "
      redmine_bug_id       = custom_value.first['customized_id'].to_i

      redmine_bug_id
    end

    p 'Importing duplications...'
    # Get duplicates from bugzilla
    duplicates = @mysql_connection.query("SELECT * FROM duplicates")
    duplicates = duplicates.map{ |d| d.to_h } # [ {"dupe_of"=>2220, "dupe"=>2894} ]

    duplicates.each do |duplication|
      redmine_dupe_of = redmine_id_by_bugzilla_id duplication['dupe_of']
      redmine_dupe    = redmine_id_by_bugzilla_id duplication['dupe']

      begin
        @pg_connection.exec "
          INSERT INTO issue_relations (issue_from_id, issue_to_id, relation_type) 
          VALUES (#{redmine_dupe}, #{redmine_dupe_of}, 'duplicates')
        "
      rescue
        #p "duplication #{redmine_dupe} of #{redmine_dupe_of}"
      end
    end

    p 'Importing blockers...'
    # Get blocks from bugzilla
    blockers = @mysql_connection.query("SELECT * FROM dependencies")
    blockers = blockers.map{ |d| d.to_h } # [ {"blocked"=>2220, "dependson"=>2894} ]

    blockers.each do |blocker|
      redmine_blocked   = redmine_id_by_bugzilla_id blocker['blocked']
      redmine_dependson = redmine_id_by_bugzilla_id blocker['dependson']

      begin
        @pg_connection.exec "
          INSERT INTO issue_relations (issue_from_id, issue_to_id, relation_type) 
          VALUES (#{redmine_dependson}, #{redmine_blocked}, 'blocks')
        "
      rescue
        #p "blocked - #{redmine_blocked} by #{redmine_dependson}"
      end
    end 

    p 'Creating Flag Development Issue'
    # Add Development Issue Field
    type = "IssueCustomField"
    name = "Development Issue"
    field_format = "string"
    is_required = false
    is_for_all = true
    is_filter = true
    searchable = false
    editable = true
    visible = true
    multiple = false
    format_store = "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n" + "text_formatting: ''\n" + "url_pattern: ''\n"
    is_primary = true
    show_empty = true
    show_on_list = false
    non_deletable = false
    non_editable = false
    show_on_more_form = true
    disabled = false
    mail_notification = true
    position = 12

    @pg_connection.exec "
      INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) 
      VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})
    "

    tracker_id      = @pg_connection.query("
      SELECT * FROM trackers 
      WHERE name = 'Bugzilla Tracker'
    ").first['id']

    custom_field_id = @pg_connection.query("
      SELECT * FROM custom_fields 
      WHERE type = 'IssueCustomField' AND name = 'Development Issue'
    ").first['id']

    @pg_connection.exec "
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) 
      VALUES (#{custom_field_id}, #{tracker_id})
    "

    # update development issue field for all bugs
    flags = @mysql_connection.query("SELECT * FROM flags")
    flags = flags.map{ |d| d.to_h } # [ {"status"=>'+', "bug_id"=>2894} ]

    flags.each do |flag|
      redmine_id = redmine_id_by_bugzilla_id flag['bug_id']
      value      = flag['status']

      @pg_connection.exec "
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value) 
        VALUES ('Issue', #{redmine_id}, #{custom_field_id}, '#{value}') 
        RETURNING id
      "
    end

  end

end