class SettingsFiller < EasyRedmine

  def initialize
    super
  end

  def create_role
    name                    = 'Team Member'
    assignable              = true
    permissions             = "---\n- :view_issues\n- :edit_issues\n- :edit_issue_notes\n- :edit_assigned_issue\n"
    issues_visibility       = 'all'
    users_visibility        = 'all'
    time_entries_visibility = 'all'
    all_roles_managed       = true
    settings                = "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\npermissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  view_issues: 1\n  add_issues: 1\n  edit_issues: 1\n  add_issue_notes: 1\n  delete_issues: 1\npermissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  view_issues: []\n  add_issues: []\n  edit_issues: []\n  add_issue_notes: []\n  delete_issues: []\n"
    limit_assignable_users  = false

    @pg_connection.exec "INSERT INTO roles (name, assignable, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings, limit_assignable_users) VALUES ('#{name}', #{assignable}, '#{permissions}', '#{issues_visibility}', '#{users_visibility}', '#{time_entries_visibility}', #{all_roles_managed}, '#{settings}', #{limit_assignable_users})"
  end

  def create_custom_fields
    user_bugzilla_id 1

    issue_product 1
    issue_component 2

    issue_resolution 3
    issue_severity 4
    issue_platform 5
    issue_operation_system 6
    issue_version 7
    issue_cc 6
    issue_url 9
    issue_keywords 10
    issue_bugzilla_id 11

    #binding.pry
    #result = @pg_connection.exec "SELECT * FROM custom_fields"
  end

  def create_statuses
    @pg_connection.exec "INSERT INTO issue_statuses (name, is_closed, position) VALUES ( 'UNCONFIRMED', false, 1)"
    @pg_connection.exec "INSERT INTO issue_statuses (name, is_closed, position) VALUES ( 'NEW', false, 2)"
    @pg_connection.exec "INSERT INTO issue_statuses (name, is_closed, position) VALUES ( 'ASSIGNED', false, 3)"
    @pg_connection.exec "INSERT INTO issue_statuses (name, is_closed, position) VALUES ( 'REOPENED', false, 4)"
    @pg_connection.exec "INSERT INTO issue_statuses (name, is_closed, position) VALUES ( 'RESOLVED', true, 5)"
    @pg_connection.exec "INSERT INTO issue_statuses (name, is_closed, position) VALUES ( 'CLOSED', true, 6)"
  end

  def create_priorities
    @pg_connection.exec "INSERT INTO enumerations (name, position, is_default, type, active, position_name, allow_time_entry_zero_hours, allow_time_entry_negative_hours) VALUES ('-'  ,1 , true,  'IssuePriority', true, 'lowest',  false, false)"
    @pg_connection.exec "INSERT INTO enumerations (name, position, is_default, type, active, position_name, allow_time_entry_zero_hours, allow_time_entry_negative_hours) VALUES ('P1' ,2 , false, 'IssuePriority', true, 'low2',    false, false)"
    @pg_connection.exec "INSERT INTO enumerations (name, position, is_default, type, active, position_name, allow_time_entry_zero_hours, allow_time_entry_negative_hours) VALUES ('P2' ,3 , false, 'IssuePriority', true, 'default', false, false)"
    @pg_connection.exec "INSERT INTO enumerations (name, position, is_default, type, active, position_name, allow_time_entry_zero_hours, allow_time_entry_negative_hours) VALUES ('P3' ,4 , false, 'IssuePriority', true, 'high3',   false, false)"
    @pg_connection.exec "INSERT INTO enumerations (name, position, is_default, type, active, position_name, allow_time_entry_zero_hours, allow_time_entry_negative_hours) VALUES ('P4' ,5 , false, 'IssuePriority', true, 'high2',   false, false)"
    @pg_connection.exec "INSERT INTO enumerations (name, position, is_default, type, active, position_name, allow_time_entry_zero_hours, allow_time_entry_negative_hours) VALUES ('P5' ,6 , false, 'IssuePriority', true, 'highest', false, false)"
  end

  def create_tracker
    name        = 'Bugzilla Tracker'
    is_in_chlog = false
    position    = 1
    is_in_roadmap = false
    fields_bits = 0
    default_status_id = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'UNCONFIRMED'").first['id']
    easy_send_invitation = false
    easy_do_not_allow_close_if_subtasks_opened = false
    easy_do_not_allow_close_if_no_attachments = false
    easy_distributed_tasks = false

    @pg_connection.exec "INSERT INTO trackers (name, is_in_chlog, position, is_in_roadmap, fields_bits, default_status_id, easy_send_invitation, easy_do_not_allow_close_if_subtasks_opened, easy_do_not_allow_close_if_no_attachments, easy_distributed_tasks) VALUES ('#{name}', #{is_in_chlog}, #{position}, #{is_in_roadmap}, #{fields_bits}, #{default_status_id}, #{easy_send_invitation}, #{easy_do_not_allow_close_if_subtasks_opened}, #{easy_do_not_allow_close_if_no_attachments}, #{easy_distributed_tasks})"
  end

  def add_custom_fields_to_tracker
    tracker_id = @pg_connection.query("SELECT * FROM trackers WHERE name = 'Bugzilla Tracker'").first['id']

    severity_id    = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Severity'").first['id']
    resolution_id  = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Resolution'").first['id']
    os_version_id  = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'OS Version'").first['id']
    platform_id    = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Platform'").first['id']
    keywords_id    = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Keywords'").first['id']
    url_id         = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'URL'").first['id']
    cc_id          = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'CC'").first['id']
    version_id     = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Version'").first['id']
    bugzilla_id_id = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Bugzilla ID'").first['id']

    product_id     = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Product'").first['id']
    component_id   = @pg_connection.query("SELECT * FROM custom_fields WHERE type = 'IssueCustomField' AND name = 'Component'").first['id']

    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{severity_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{resolution_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{os_version_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{platform_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{keywords_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{url_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{cc_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{version_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{bugzilla_id_id}, #{tracker_id})"

    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{product_id}, #{tracker_id})"
    @pg_connection.exec "INSERT INTO custom_fields_trackers (custom_field_id, tracker_id) VALUES (#{component_id}, #{tracker_id})"
  end

  def create_workflow
    role_id    = @pg_connection.query("SELECT * FROM roles WHERE name = 'Team Member'").first['id']
    tracker_id = @pg_connection.query("SELECT * FROM trackers WHERE name = 'Bugzilla Tracker'").first['id']

    # statuses
    just_created_id = 0
    unconfirmed_id  = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'UNCONFIRMED'").first['id']
    new_id          = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'NEW'").first['id']
    assigned_id     = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'ASSIGNED'").first['id']
    reopened_id     = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'REOPENED'").first['id']
    resolved_id     = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'RESOLVED'").first['id']
    closed_id       = @pg_connection.query("SELECT * FROM issue_statuses WHERE name = 'CLOSED'").first['id']

    workflow_hash = [
      {just_created_id => unconfirmed_id},
      {just_created_id => new_id},
      {just_created_id => assigned_id},
      {just_created_id => reopened_id},
      {just_created_id => resolved_id},
      {just_created_id => closed_id},

      {unconfirmed_id => new_id},
      {unconfirmed_id => assigned_id},
      {unconfirmed_id => resolved_id},

      {new_id => assigned_id},
      {new_id => resolved_id},
      {new_id => closed_id},

      {assigned_id => new_id},
      {assigned_id => resolved_id},

      {reopened_id => new_id},
      {reopened_id => assigned_id},
      {reopened_id => resolved_id},

      {resolved_id => unconfirmed_id},
      {resolved_id => reopened_id},
      {resolved_id => closed_id},

      {closed_id => unconfirmed_id},
      {closed_id => reopened_id},
      {closed_id => resolved_id}
    ]

    workflow_hash.each do |old_new_hash|
      old_status_id = old_new_hash.keys.first
      new_status_id = old_new_hash[old_status_id]
      @pg_connection.exec "INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id, assignee, author, type) VALUES (#{tracker_id}, #{old_status_id}, #{new_status_id}, #{role_id}, false, false, 'WorkflowTransition')"
    end
  end

  protected

  def user_bugzilla_id position=1
    type = "UserCustomField"
    name = "Bugzilla ID"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_bugzilla_id  position=1
    type = "IssueCustomField"
    name = "Bugzilla ID"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_version position=1
    type = "IssueCustomField"
    name = "Version"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_cc position=1
    type = "IssueCustomField"
    name = "CC"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_url position=1
    type = "IssueCustomField"
    name = "URL"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_keywords position=1
    type = "IssueCustomField"
    name = "Keywords"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_platform position=1
    type = "IssueCustomField"
    name = "Platform"
    field_format = "list"
    possible_values = "---\n- Error\n- Change\n- Addition\n- Task\n"

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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, possible_values, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', '#{possible_values}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_operation_system position=1
    type = "IssueCustomField"
    name = "OS Version"
    field_format = "list"
    possible_values = "---\n- Windows\n- Windows XP\n- Windows Vista\n- Windows 7\n- Windows 8\n- Windows 10\n- Windows Server 2003\n- Windows Server 2008\n- Windows Server 2012\n- Windows Server 2016\n- ExoReal 2.x\n- ExoRealC (3.x)\n- Linux\n- Other\n"

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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, possible_values, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', '#{possible_values}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_resolution position=1
    type = "IssueCustomField"
    name = "Resolution"
    field_format = "list"
    possible_values = "---\n- FIXED\n- DOC_PENDING\n- TEST_PENDING\n- UNPUBLISHED_FIX\n- SOLVED\n- INVALID\n- WONTFIX\n- DUPLICATE\n- WORKSFORME\n- MOVED\n"

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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, possible_values, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', '#{possible_values}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_severity position=1
    type = "IssueCustomField"
    name = "Severity"
    field_format = "list"
    possible_values = "---\n- critical\n- major\n- normal\n- minor\n"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, possible_values, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', '#{possible_values}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_product position=1
    type = "IssueCustomField"
    name = "Product"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

  def issue_component position=1
    type = "IssueCustomField"
    name = "Component"
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

    @pg_connection.exec "INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, is_filter, position, searchable, editable, visible, multiple, format_store, is_primary, show_empty, show_on_list, non_deletable, non_editable, show_on_more_form, disabled, mail_notification) VALUES ('#{type}', '#{name}', '#{field_format}', #{is_required}, #{is_for_all}, #{is_filter}, #{position}, #{searchable}, #{editable}, #{visible}, #{multiple}, '#{format_store}', #{is_primary}, #{show_empty}, #{show_on_list}, #{non_deletable}, #{non_editable}, #{show_on_more_form}, #{disabled}, #{mail_notification})"
  end

end