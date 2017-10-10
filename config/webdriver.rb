require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  driver = Capybara::Poltergeist::Driver.new(app, timeout: 60)
end

Capybara.default_driver = :poltergeist
