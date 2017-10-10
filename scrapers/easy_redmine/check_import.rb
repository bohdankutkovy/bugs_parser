class CheckImport < EasyRedmine
  
  def initialize
    @easy_bug_ids = read_dump('easy_bug_ids')

    super
  end

  def check_all from=0, to=-1

    p 'EasyRedmine <-> Bugzilla data comparison...'

    mysql  = Settings.bugzilla[:mysql]
    config = {}
    config[:host]     = mysql[:host]     if mysql[:host]     && !mysql[:host].empty?
    config[:port]     = mysql[:port]     if mysql[:port]     && !mysql[:port].to_s.empty?
    config[:database] = mysql[:database]
    config[:username] = mysql[:username] if mysql[:username] && !mysql[:username].empty?
    config[:password] = mysql[:password] if mysql[:password] && !mysql[:password].empty?
    @mysql_connection  = Mysql2::Client.new(config)

    @easy_bug_ids[:data][from.to_i..to.to_i].each do |project_bugs|
      project_id = project_bugs.keys.first.to_s
      bug_ids    = project_bugs.values.first

      project_url = "#{@homepage_url}/projects/#{project_id}/issues"
      visit project_url

      easy_redmine_count = find('#easy-query-heading-count').text.to_i
      bugzilla_count     = bug_ids.count

      result = true
      bugs = JSON.load(open("#{project_url}.json"))
      bugs = Hashie.symbolize_keys bugs

      if bugs[:issues] && !bugs[:issues].empty?
        [bugs[:issues].first, bugs[:issues].last].each do |bug|
          status      = bug[:status][:name]
          author      = bug[:author][:name]
          assigned_to = bug[:assigned_to][:name]
          subject     = bug[:subject]

          bugzilla_id = bug[:custom_fields].select{ |f| f[:name].eql? 'Bugzilla ID' }.first[:value]

          bugzilla_data = @mysql_connection.query("SELECT * FROM bugs WHERE bug_id = #{bugzilla_id}").first

          reporter_id     = bugzilla_data['reporter']
          bugzilla_author = @mysql_connection.query("SELECT * FROM profiles WHERE userid = #{reporter_id}").first

          assigned_to_id       = bugzilla_data['assigned_to']
          bugzilla_assigned_to = @mysql_connection.query("SELECT * FROM profiles WHERE userid = #{assigned_to_id}").first

          result = bugzilla_data['short_desc'].eql?(subject)
          result = bugzilla_data['bug_status'].eql?(status)
          result = bugzilla_author['realname'].split(' ').last.eql? author.split(' ').last
          result = bugzilla_assigned_to['realname'].split(' ').last.eql? assigned_to.split(' ').last
        end
      end

      if !result || !easy_redmine_count.eql?(bugzilla_count)
        puts "#{easy_redmine_count}\t\t#{bugzilla_count}\t\t not equal: #{project_url}"
      else
        puts "#{easy_redmine_count}\t\t#{bugzilla_count}\t\t ok & correct data."
      end

    end
  end

end