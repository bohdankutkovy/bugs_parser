class BugFiller < EasyRedmine

  def initialize
    @easy_bug_ids = read_dump('easy_bug_ids')

    super
  end

  def fill_all from=0, to=-1

    p "[#{Time.now}] Parsing bugs, comments, attachments..."

    progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total:          Dir['data/bugs/*'].count + 1
    )

    @easy_bug_ids[:data][from.to_i..to.to_i].each_with_index do |project_bugs, index|
      project_id = project_bugs.keys.first.to_s
      bug_ids    = project_bugs.values.first

      bug_ids.each do |bug_id|
        @bug = read_dump "bugs/#{bug_id}"

        fill_members project_id

        redmine_id = create_issue project_id

        fill_attachments   redmine_id
        fill_watchers      redmine_id
        fill_comments      redmine_id
        fill_custom_fields redmine_id

        progressbar.increment
        #p bug_id
      end
    end

    progressbar.finish
    p "[#{Time.now}]"
  end

  private

  def fill_members project_id
    users  = @bug[:comments].map{ |comment| comment[:user] }
    users << @bug[:created_by]
    users << @bug[:assigned_to]
    users  = users.uniq unless users.empty?

    role_id = @pg_connection.exec("SELECT * FROM roles WHERE name = 'Team Member'").first['id']

    users.each do |fullname|
      user_id = get_user_id fullname

      if @pg_connection.exec("SELECT * FROM members WHERE user_id = #{user_id}").count == 0
        member_id = @pg_connection.exec("INSERT INTO members (user_id, project_id) VALUES (#{user_id}, #{project_id}) RETURNING id").first['id']
        @pg_connection.exec("INSERT INTO member_roles (role_id, member_id) VALUES (#{role_id}, #{member_id} )")
      end
    end
  end

  def fill_attachments issue_id
    @bug[:attachments].each do |attachment|
      attachment[:file] = File.absolute_path(attachment[:file])
      create_attachment issue_id, attachment
    end
  end

  def fill_watchers issue_id
    if @bug[:cc] && !@bug[:cc].empty?
      @bug[:cc].uniq.each do |fullname|
        if user_id = get_user_id(fullname)
          save_issue_watcher issue_id, user_id
        end
      end
    end
  end

  def fill_comments redmine_id
    if @bug[:comments] && !@bug[:comments].empty?
      @bug[:comments].each do |comment|
        begin
          notes     = @pg_connection.escape_string comment[:note]
          date      = comment[:date]
          user_id   = get_user_id comment[:user]

          @pg_connection.exec "INSERT INTO journals (journalized_id, journalized_type, user_id, notes, created_on) VALUES (#{redmine_id}, 'Issue', #{user_id}, '#{notes}', '#{date}')"
        rescue => e
          #p e.message
          #p @bug[:id]
        end
      end
    end
  end

  def create_issue project_id
    tracker_id     = @pg_connection.query("SELECT * FROM trackers WHERE name = 'Bugzilla Tracker'").first['id']
    subject        = @pg_connection.escape_string @bug[:name]
    status_id      = @pg_connection.exec( "SELECT * FROM issue_statuses WHERE name = '#{@bug[:status]}'").first['id']
    assigned_to_id = get_user_id @bug[:assigned_to]
    author_id      = get_user_id @bug[:created_by]
    priority_id    = @pg_connection.exec("SELECT * FROM enumerations WHERE name = '#{@bug[:priority]}'").first['id']
    created_on     = @bug[:created_at]
    updated_on     = @bug[:updated_at]

    result = @pg_connection.exec "
      INSERT INTO issues (tracker_id, project_id, subject, status_id, assigned_to_id, author_id, priority_id, created_on, updated_on) 
      VALUES (#{tracker_id}, #{project_id}, '#{subject}', #{status_id}, #{assigned_to_id}, #{author_id}, #{priority_id}, '#{created_on}', '#{updated_on}') 
      RETURNING id
    "
    issue_id = result.first['id']

    set_lft_rgt issue_id, 1, 2

    issue_id
  end

  def fill_custom_fields redmine_id

    # Bugzilla ID
    custom_field_id = get_custom_field_id 'Bugzilla ID'
    value           = @bug[:id]
    fill_custom_field redmine_id, custom_field_id, value

    # CC
    if @bug[:cc] && !@bug[:cc].empty?
      custom_field_id = get_custom_field_id 'CC'
      value           = @pg_connection.escape_string @bug[:cc].join(', ')
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Keywords
    if @bug[:keywords] && !@bug[:keywords].empty?
      custom_field_id = get_custom_field_id 'Keywords'
      value           = @pg_connection.escape_string @bug[:keywords].join(' ')
      fill_custom_field redmine_id, custom_field_id, value
    end

    # URL
    if @bug[:url] && !@bug[:url].empty?
      custom_field_id = get_custom_field_id 'URL'
      value           = @pg_connection.escape_string @bug[:url]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Version
    if @bug[:version] && !@bug[:version].empty?
      custom_field_id = get_custom_field_id 'Version'
      value           = @pg_connection.escape_string @bug[:version]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Severity
    if @bug[:severity] && !@bug[:severity].empty? && @bug[:severity] != '-'
      custom_field_id = get_custom_field_id 'Severity'
      value           = @bug[:severity]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Resolution
    if @bug[:resolution] && !@bug[:resolution].empty? && @bug[:resolution] != '-'
      custom_field_id  = get_custom_field_id 'Resolution'
      value            = @bug[:resolution]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Operation System
    if @bug[:operation_system] && !@bug[:operation_system].empty? && @bug[:operation_system] != '-'
      custom_field_id = get_custom_field_id 'OS Version'
      value           = @bug[:operation_system]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Platform
    if @bug[:hardware] && !@bug[:hardware].empty? && @bug[:hardware] != '-'
      custom_field_id = get_custom_field_id 'Platform'
      value           = @bug[:hardware]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Product
    if @bug[:product] && !@bug[:product].empty?
      custom_field_id = get_custom_field_id 'Product'
      value           = @pg_connection.escape_string @bug[:product]
      fill_custom_field redmine_id, custom_field_id, value
    end

    # Component
    if @bug[:component] && !@bug[:component].empty?
      custom_field_id = get_custom_field_id 'Component'
      value           = @pg_connection.escape_string @bug[:component]
      fill_custom_field redmine_id, custom_field_id, value
    end

  end

  def create_attachment redmine_id, attachment_data

    attachment  = attachment_data[:file]
    timestamp   = Time.parse attachment_data[:created_at]
    description = @pg_connection.escape_string attachment_data[:description]

    File.rename attachment, attachment.sub("'", "")
    attachment = attachment.sub("'", "")

    current_year_dir  = File.join Settings.easy_redmine[:uploads_dir], Time.now.strftime('%Y')
    current_month_dir = File.join current_year_dir, Time.now.strftime('%m')

    FileUtils.mkdir_p current_year_dir  
    FileUtils.mkdir_p current_month_dir

    container_id   = redmine_id
    filename       = File.basename attachment
    disk_filename  = "#{timestamp.strftime("%Y%m%d%H%M%S")}_#{filename}"
    author_id      = get_user_id attachment_data[:author]
    filesize       = File.size attachment
    disk_directory = "#{Time.now.strftime('%Y')}/#{Time.now.strftime('%m')}"

    FileUtils.cp attachment, current_month_dir

    old_name = File.join current_month_dir, filename
    new_name = File.join current_month_dir, disk_filename
    File.rename old_name, new_name

    result = @pg_connection.exec "
      INSERT INTO attachments (container_id, container_type, filename, disk_filename, filesize, author_id, created_on, description, version, disk_directory) 
      VALUES (#{redmine_id}, 'Issue', '#{filename}', '#{disk_filename}', #{filesize}, #{author_id}, '#{timestamp}', '#{description}', 1, '#{disk_directory}') 
      RETURNING id
    "
    attachment_id = result.first['id']

    @pg_connection.exec "
      INSERT INTO attachment_versions (attachment_id, version, container_id, container_type, filename, disk_filename, filesize, author_id, description, created_on, disk_directory, updated_at) 
      VALUES (#{attachment_id}, 1, #{redmine_id}, 'Issue', '#{filename}', '#{disk_filename}', #{filesize}, #{author_id}, '#{description}', '#{timestamp}', '#{disk_directory}', '#{timestamp}') 
      RETURNING id
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

  def get_user_id fullname
    firstname = fullname.split(' ').first
    lastname  = fullname.split(' ').last

    user = @pg_connection.exec "SELECT * FROM users WHERE firstname = '#{firstname}' AND lastname = '#{lastname}'"

    return nil if user.count == 0
    user.first['id']
  end

  def save_issue_watcher issue_id, user_id
    @pg_connection.exec "
      INSERT INTO watchers (watchable_type, watchable_id, user_id) 
      VALUES ('Issue', #{issue_id}, #{user_id})
    "
  end

  def set_lft_rgt issue_id, lft, rgt
    @pg_connection.exec "
      UPDATE issues
      SET root_id = #{issue_id}, lft = #{lft}, rgt = #{rgt}
      WHERE id = #{issue_id};
    "
  end

end