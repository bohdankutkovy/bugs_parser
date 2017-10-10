namespace :easy_redmine do

  namespace :fill do

    task :all do
      tasks = %w(settings users projects bugs check)
      tasks.each{ |task| Rake.application["easy_redmine:fill:#{task}"].invoke }
    end

    task :settings do
      sf = SettingsFiller.new
      sf.create_role
      sf.create_custom_fields
      sf.create_statuses
      sf.create_priorities
      sf.create_tracker
      sf.add_custom_fields_to_tracker
      sf.create_workflow
    end

    task :users do
      bot = UserFiller.new
      bot.fill_all
    end

    task :projects do
      bot = ProjectFiller.new
      bot.fill_all
      bot.update_positions
    end

    task :bugs, [:from, :to] do |t, args|
      bot = BugFiller.new

      if args[:from] || args[:to]
        bot.fill_all args[:from], args[:to]
      else
        bot.fill_all
      end
    end

    task :check, [:from, :to] do |t, args|
      bot = CheckImport.new
      bot.login_as_admin
      bot.check_all
      DumpManager.clear_dumps!
    end

  end
  
end