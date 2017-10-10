# Migration from Bugzilla to EasyRedmine

Update file `bugs_parser/config/settings.yml` with:

* correct Bugzilla    host and admin's creadentials
* correct EasyRedmine host and admin's creadentials
* correct Bugzilla's    MySQL      database settings
* correct EasyRedmine's PostgreSQL database settings
* correct full path to EasyRedmine attachments's uploads directory (default is '[REDMINE_APP_FOLDER]/files')

Put `bugs_parser` folder to the EasyRedmine's server,
Open terminal in `bugs_parser` folder and run these commands:

1.Setup Ruby environment

Install Ruby 2.3.1 (tutorials: https://rvm.io/rvm/install)
```sh
ruby -v # => ruby 2.3.1p112 ...
bundle install
```

2.Dump all data from Bugzilla:

```sh
bundle exec rake bugzilla:scrape:all
```

3.Setup EasyRedmine

```sh
bundle exec rake easy_redmine:fill:settings
```

This command will setup EasyRedmine with Bugzilla these settings:

* create default user role (to see projects, manage tasks)
* create custom fields for tasks (resolution, severity, platform, OS, version, CC, URL, keywords, bugzilla ID)
* create default task statuses
* create default task priorities
* create default tracker
* create default workflow

4.Import data to EasyRedmine

Now we can import bugzilla users (109) to EasyRedmine:
```sh
bundle exec rake easy_redmine:fill:users
```

5.Once users are loaded, let's import bugzilla products and components to EasyRedmine:
```sh
bundle exec rake easy_redmine:fill:projects
```

6.Once projects are loaded - 380 projects (16 parent project, and 364 subprojects).

Please, open New Task page and check that all form fields are accessible and correct.
(status dropdown contains all statuses etc.)

Import bugzilla tasks to EasyRedmine projects сonsistently:
```sh
bundle exec rake easy_redmine:fill:bugs
```

7.Check migrated data:

Before running check migrated data script, please be sure that
EasyRedmine default Task Filter is configured to show all tasks (not only with opened status).
(Administration -> Filter Settings -> Tasks -> chenge default filters status from 'opened' to 'any')

```sh
bundle exec rake easy_redmine:fill:check
```

8. To migrate bugs blockers, dependencies and development_issue flag, please run this command:

```sh
bundle exec rake patch:run
```