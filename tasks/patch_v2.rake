namespace :patch_v2 do

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

    its_project_id = @pg_connection.query("
      SELECT * FROM projects
      WHERE name = 'ITS'
    ").first['id']

    product_ids    = @pg_connection.exec("
      SELECT id FROM projects
      WHERE parent_id = #{its_project_id}
    ").map{ |p| p['id'] }

    p 'Updating members inheritance field...'
    @pg_connection.exec("
      UPDATE projects
      SET inherit_members = true
      WHERE parent_id = #{its_project_id} OR parent_id IN (#{product_ids.join(',')})
    ")

    p 'Finish!'

  end
end