namespace :bugzilla do

  namespace :scrape do

    task :all do
      DumpManager.clear_dumps!
      tasks = %w(users products components bugs)
      tasks.each{ |task| Rake.application["bugzilla:scrape:#{task}"].invoke }
    end

    task :users do
      bot = UserScraper.new
      bot.scrape_all
    end

    task :products do
      bot = ProductScraper.new
      bot.scrape_all
    end

    task :components do
      bot = ComponentScraper.new
      bot.scrape_all
    end

    task :bugs, [:from, :to] do |t, args|
      bot = BugScraper.new

      if args[:from] || args[:to]
        bot.scrape_all args[:from], args[:to]
      else
        bot.scrape_all
      end
    end

  end
  
end