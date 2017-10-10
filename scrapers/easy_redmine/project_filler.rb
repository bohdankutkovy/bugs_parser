class ProjectFiller < EasyRedmine

  def initialize
    super

    @easy_bugs = []
    @admin_id                = get_admin_id 
    @its_id                  = get_project_id 'ITS'
    @default_project_modules = get_project_modules(@its_id) if @its_id 
    @tracker_id              = @pg_connection.query("SELECT * FROM trackers WHERE name = 'Bugzilla Tracker'").first['id']
  end

  def fill_all
    unless @its_id
      p 'no project with name ITS, please create it.'
      return
    end
    p 'Importing projects...'

    @data = read_dump 'components'

    progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total:          @data[:products].count + 1
    )

    @data[:products].each do |product|
      fill_project product, @its_id
      progressbar.increment
    end

    write_dump 'easy_bug_ids', {data: @easy_bugs}

    progressbar.finish
  end

  def update_positions
    counter = 0
    get_project_ids(nil).each do |root_project_id|
      counter = update_project_position root_project_id, counter
    end
  end

  private

  def fill_project data, parent_id
    author_id  = data[:author] ? get_user_id(data[:author]) : @admin_id
    attributes = {
      name:        data[:name],
      description: data[:description],
      parent_id:   parent_id,
      author_id:   author_id,
      easy_level:  1
    }

    project_id = create_project attributes

    data[:components].each do |component, index|
      fill_subproject component, project_id
    end    

  end

  def fill_subproject data, parent_id
    author_id  = data[:author] ? get_user_id(data[:author]) : @admin_id
    attributes = {
      name:        data[:name],
      description: data[:description],
      parent_id:   parent_id,
      author_id:   author_id,
      easy_level:  2
    }

    component_id   = create_project attributes
    component_bugs = data[:bug_ids]

    @easy_bugs << {component_id => component_bugs}
  end

  def update_project_position project_id, counter
    counter = counter + 1
    lft     = counter

    get_project_ids(project_id).each do |sub_project_id|
      counter = update_project_position sub_project_id, counter
    end

    counter = counter + 1
    rgt     = counter

    set_lft_rgt project_id, lft, counter

    counter
  end

  protected

  def get_project_ids parent_id=nil
    if parent_id
      result = @pg_connection.exec("SELECT (id) FROM projects WHERE parent_id = #{parent_id} ORDER BY name")
    else
      result = @pg_connection.exec("SELECT (id) FROM projects WHERE parent_id IS NULL ORDER BY name")
    end
    result.map{ |p| p['id'].to_i }
  end

  def create_project attributes
    name               = @pg_connection.escape_string attributes[:name]
    description        = @pg_connection.escape_string attributes[:description]
    is_public          = true
    parent_id          = attributes[:parent_id]
    status             = 1
    identifier         = max_identifier.to_i + 1
    inherit_members    = false
    author_id          = attributes[:author_id]
    easy_is_easy_template = false
    easy_level            = attributes[:easy_level]

    project = @pg_connection.exec "
      INSERT INTO projects (name, description, is_public, parent_id, status, identifier, inherit_members, author_id, easy_is_easy_template, easy_level) 
      VALUES ('#{name}', '#{description}', #{is_public}, #{parent_id}, #{status}, #{identifier}, #{inherit_members}, #{author_id}, #{easy_is_easy_template}, #{easy_level})
      RETURNING id
    "
    project_id = project.first['id']
    set_project_modules project_id
    set_project_tracker project_id
    project_id
  end

  def get_user_id fullname
    firstname = fullname.split(' ').first
    lastname  = fullname.split(' ').last

    user = @pg_connection.exec "SELECT * FROM users WHERE firstname = '#{firstname}' AND lastname = '#{lastname}'"

    return nil if user.count == 0
    user.first['id']
  end

  def get_admin_id
    user = @pg_connection.exec "SELECT * FROM users WHERE login = 'admin'"
    user.first['id']
  end

  def get_project_id name
    result = @pg_connection.exec "
      SELECT * FROM projects 
      WHERE name = '#{name}'
    "
    result.first['id']
  rescue
    nil
  end

  def max_identifier
    result = @pg_connection.exec "SELECT identifier FROM projects ORDER BY (length(identifier), identifier) DESC LIMIT 1"
    result.first['identifier']
  end

  def set_lft_rgt project_id, lft, rgt
    @pg_connection.exec "
      UPDATE projects
      SET lft = #{lft}, rgt = #{rgt}
      WHERE id = #{project_id};
    "
  end

  def set_project_modules project_id
    @default_project_modules.each do |name|
      @pg_connection.exec "
        INSERT INTO enabled_modules (project_id, name) 
        VALUES (#{project_id}, '#{name}')
      "
    end
  end

  def get_project_modules project_id
    result = @pg_connection.exec("
      SELECT (name) 
      FROM enabled_modules 
      WHERE project_id = #{project_id}"
    )

    result.map{ |m|  m['name'] }
  end

  def set_project_tracker project_id
    @pg_connection.exec "
      INSERT INTO projects_trackers (project_id, tracker_id) 
      VALUES (#{project_id}, #{@tracker_id})
    "
  end

end